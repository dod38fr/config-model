# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 53;
use Test::Exception ;
use Test::Warn ;
use Test::Memory::Cycle;
use Config::Model;

use warnings;
no warnings qw(once);

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"compiled") ;

my $model = Config::Model -> new()  ;

$model->create_config_class 
  (
   name => 'Sarge',
   experience => [ [qw/Y/] => 'beginner',  # default
                   X => 'master' 
                 ],
   status    => [ D => 'deprecated' ], #could be obsolete, standard
   description => [ X => 'X-ray (long description)' ],
   summary     => [ X => 'X-ray (summary)' ],

   element => [
               [qw/D X Y Z/] => {
                               type => 'leaf',
                               class => 'Config::Model::Value',
                               value_type => 'enum',
                               choice     => [qw/Av Bv Cv/]
                              }
              ],
  );

$model->create_config_class 
  (
   name => 'Captain',
   experience => [ bar => 'beginner' ],
   element => [
               bar => { type => 'node', 
                        config_class_name => 'Sarge' 
                      }
              ]
  );

$model ->create_config_class 
  (
   name => "Master",
   experience => [[qw/captain array_args hash_args/] => 'beginner' ],
   level     => [qw/captain/ => 'important' ] ,
   element => [
                captain => { 
                         type => 'node',
                         config_class_name => 'Captain',
                        },
                [qw/array_args hash_args/] 
                => { type => 'node',
                     config_class_name => 'Captain',
                   },
               ],
   class_description => "Master description",
   description => [
                   captain       => "officer",
                   array_args => 'not officer'
                  ]
  );

ok(1,"Model created") ;

my $instance = $model->instance (root_class_name => 'Master', 
                                 instance_name => 'test1');

ok(1,"Instance created") ;

my $root = $instance -> config_root ;

ok($root,"Config root created") ;

is( $root->config_class_name, 'Master', "Created Master" );

is_deeply( [ sort $root->get_element_name(for => 'beginner') ],
           [qw/array_args captain hash_args/], "check Master elements");

is_deeply( [ sort $root->get_element_name(for => 'advanced') ],
           [qw/array_args captain hash_args/], "check Master elements");

is_deeply( [ sort $root->get_element_name(for => 'master') ],
           [qw/array_args captain hash_args/], "check Master elements");

my $w = $root->fetch_element('captain') ;
ok( $w, "Created Captain" );

is($w->config_class_name,'Captain',"test class_name") ;

is($w->element_name,'captain',"test element_name") ;
is($w->name,'captain',"test name") ;
is($w->location,'captain',"test captain location") ;

my $b = $w->fetch_element('bar');
ok( $b, "Created Sarge" );

is($b->get_element_property(property => 'experience', element => 'Y'),
   'beginner',"check Y experience") ;
is($b->get_element_property(property => 'experience',element => 'Z'),
   'beginner',"check Z experience") ;
is($b->get_element_property(property => 'experience',element => 'X'),
   'master',      "check X experience") ;

is( $b->fetch_element_value('Z'), undef, "test Z value" );

# patch by Niko Tyni tp avoid Carp::Heavy failure. See 
# http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=582915
eval {$b->fetch_element(qw/name Z experience user/)};
like($@, qr/Unexpected experience/, "fetch_element with unexpected experience" );

# translated into beginner
throws_ok { $b->fetch_element(qw/name X experience beginner/); } 
  'Config::Model::Exception::RestrictedElement',
  'Restricted element error';

warning_like { $b->fetch_element('D'); } 
  qr/Element 'D' of node 'captain bar' is deprecated/,
  'Check deprecated element warning';

is( $root->fetch_element('array_args')
    ->get_element_property(property => 'experience',element => 'bar'),
    'beginner' , "check 'bar' experience");
is( $root->fetch_element('array_args')->fetch_element('bar')
    ->get_element_property(property => 'experience',element => 'X'), 
    'master', "check 'X' experience" );

my $tested = $root->fetch_element('hash_args')->fetch_element('bar');

is($tested->config_class_name,  'Sarge',"test bar config_class_name") ;
is($tested->element_name,'bar'  ,"test bar element_name") ;
is($tested->name,        'hash_args bar' ,"test bar name") ;
is($tested->location,    'hash_args bar' ,"test bar location") ;

is( $tested->get_element_property(property => 'experience',element => 'X'),
    'master',
    "checking X experience");

my $inst2 =  $model->instance (root_class_name => 'Master', 
                              instance_name => 'test2');

isa_ok( $inst2, 'Config::Model::Instance',
        "Created 2nd Master" );

isa_ok( $inst2->config_root, 'Config::Model::Node',
      "created 2nd tree");


# test help included with the model

is( $root->get_help, "Master description", "Test master global help" );

is( $root->get_help('captain'), "officer", "Test master slot help captain" );

is( $root->get_help('hash_args'),
    '', "Test master slot help hash_args" );

is( $tested->get_help('X'), "X-ray (long description)", "Test sarge slot help X" );

is( $tested->get_help(description => 'X'), 
    "X-ray (long description)", "Test sarge slot help X (description)" );

is( $tested->get_help(summary => 'X'), 
    "X-ray (summary)", "Test sarge slot help X (summary)" );

is($root->has_element('daughter'), 0 ,"Non-existing element" );
is($root->has_element('captain'), 1 ,"existing element" );
is($root->has_element(name => 'captain', type => 'node' ), 1 ,"existing node element" );
is($root->has_element(name => 'captain', type => 'leaf' ), 0 ,"non existing leaf element" );


ok( $root->is_element_available(name =>'captain'), "test element" );

is( $root->get_element_property( property => 'level',element =>'hash_args' ),
    'normal',
    "test (non) importance" );

is( $root->get_element_property(property => 'level',element => 'captain' ),
    'important',
    "test importance" );

is( $root->set_element_property( property => 'level',element =>'captain',
                                 value => 'hidden'), 
    'hidden',
    "test importance" );

is( $root->get_element_property(property => 'level',element => 'captain' ),
    'hidden',
    "test hidden" );

is( $root->reset_element_property( property => 'level',element =>'captain'), 
    'important',
    "test importance" );

map {
    my $key_label = defined $_->[0] ? $_->[0] : 'undef';
    is( $root->next_element(name => $_->[0]), $_->[1], 
        "test next_element ($key_label)" );
    is( $root->previous_element(name => $_->[1]), $_->[0], 
        "test previous_element ($key_label)" ) unless (defined $_->[0] and $_->[0] eq '');
} ( [ undef, 'captain'] ,
    [ '',    'captain'] ,
    [ qw/captain array_args/ ],
    [ qw/array_args hash_args/]
  ) ;
memory_cycle_ok($model);
