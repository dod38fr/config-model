# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 11 ;
use Test::Exception ;
use Test::Warn ;
use Test::Differences ;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Lister;
use Data::Dumper ;

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

my ($cat,$models) = Config::Model::Lister::available_models ;

eq_or_diff($cat->{system},[qw/fstab lcdproc popcon/],"check available system models");
is($models->{popcon}{model},'PopCon',"check available popcon");

eq_or_diff($cat->{application}, [qw/dpkg dpkg-control dpkg-copyright multistrap/ ] ,"check available application models");
is($models->{'dpkg-copyright'}{model},'Debian::Dpkg::Copyright',"check available dpkg-copyright");

my $class_name = $model->create_config_class 
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

is($class_name,'Sarge',"check $class_name class name");
my $canonical_model = $model->get_model($class_name) ;
print "$class_name model:\n",Dumper($canonical_model) if $trace;

eq_or_diff($model->get_element_model($class_name,'D') ,
   {
   'value_type' => 'enum',
   'status' => 'deprecated',
   'type' => 'leaf',
   'class' => 'Config::Model::Value',
   'choice' => [ 'Av', 'Bv', 'Cv' ]
   }, 
   "check $class_name D element model");

eq_or_diff($model->get_element_model($class_name,'X') ,
   {
   'value_type' => 'enum',
   'summary' => 'X-ray (summary)',
   'type' => 'leaf',
   'class' => 'Config::Model::Value',
   'experience' => 'master',
   'choice' => [ 'Av', 'Bv', 'Cv' ],
   'description' => 'X-ray (long description)' }, 
   "check $class_name X element model"
   );

$class_name = $model->create_config_class 
  (
   name => 'Captain',
   experience => [ bar => 'beginner' ],
   element => [
               bar => { type => 'node', 
                        config_class_name => 'Sarge' 
                      }
              ]
  );

my @bad_model =
  (
   name => "Master",
   experience => [[qw/captain many/] => 'beginner' ],
   element => [
                captain => { 
                         type => 'node',
                         config_class_name => 'Captain',
                        },
                ],
  );

throws_ok {$model ->create_config_class(@bad_model)}
           "Config::Model::Exception::ModelDeclaration",
           "check model with orphan experience"
           ;
           
$class_name = $model ->create_config_class 
  (
   name => "Master",
   experience => [[qw/captain array_args hash_args/] => 'beginner' ],
   level     => [qw/captain/ => 'important' ] ,
   force_element_order => [qw/captain array_args hash_args/],
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

is($class_name,'Master',"check $class_name class name");

$canonical_model = $model->get_model($class_name) ;
print "$class_name model:\n",Dumper($canonical_model) if $trace;

memory_cycle_ok($model);
