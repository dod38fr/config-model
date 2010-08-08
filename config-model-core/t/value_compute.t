# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Config::Model ;

BEGIN { plan tests => 37; }

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"Compilation done");


my $model = Config::Model->new(legacy => 'ignore',) ;
$model -> create_config_class 
  (
   name => "Slave",
   element 
   =>  [
        find_node_element_name 
        => {
            type => 'leaf',
            value_type => 'string',
            compute    => { 
                           variables => { p => '-' },
                           formula   => '&element($p)', 
                          },
           },
        check_node_element_name 
        => {
            type => 'leaf',
            value_type => 'boolean',
            compute    => { 
                           variables => { p => '-' },
                           formula   => '&element($p) eq "foo2"', 
                          },
           },
       [qw/av bv/] => {type => 'leaf',
                       value_type => 'integer',
                       compute    => { 
                                      variables => { p => '! &element' },
                                      formula   => '$p', 
                                     },
                      },
       ]
  );

$model ->create_config_class 
  (
   name => "Master",
   element 
   => [
       [qw/av bv/] => {type => 'leaf',
                       class => 'Config::Model::Value',
                       value_type => 'integer',
                      },
       compute_int 
       => { type => 'leaf',
            class =>'Config::Model::Value',
            value_type => 'integer',
            compute    => [ '$a + $b', a => '- av', b => '- bv' ],
            min        => -4,
            max        => 4,
          },
       [qw/sav sbv/] => {type => 'leaf',
                         class => 'Config::Model::Value',
                         value_type => 'string',
                      },
       one_var => { type => 'leaf',
                    class =>'Config::Model::Value',
                    value_type => 'string',
                    compute    => [ '&element().$bar', bar => '- sbv'],
                    },
       one_wrong_var => { type => 'leaf',
                          class =>'Config::Model::Value',
                          value_type => 'string',
                          compute    => [ '$bar', bar => '- wrong_v'],
                        },
       meet_test 
       => { type => 'leaf',
            class =>'Config::Model::Value',
            value_type => 'string',
            compute => [ 'meet $a and $b', a => '- sav', b => '- sbv' ],
          },
       compute_with_override 
       => {  type => 'leaf',
            class => 'Config::Model::Value',
             value_type             => 'integer',
             allow_compute_override => 1,
             compute                => [ '$a + $b', a => '- av', b => '- bv' ],
             min                    => -4,
             max                    => 4,
          },
       compute_no_var 
       => { type => 'leaf',
            value_type => 'string',
            compute    => { 
                           formula   => '&element()', 
                          },
          },
       [qw/bar foo2/ ] => {
                           type => 'node',
                           config_class_name => 'Slave'
                          },

       'url' => { type => 'leaf',
                  value_type => 'uniline',
                },
       'host' 
       => { type => 'leaf',
            value_type => 'uniline',
            compute => { formula => '$url =~ m!http://([\w\.]+)!; $1 ;' , 
                         variables => { url => '- url' } ,
                         use_eval => 1,
                       },
          },

      ]
 ) ;

my $inst = $model->instance (root_class_name => 'Master', 
                             instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

# order is important. Do no use sort.
is_deeply([$root->get_element_name()],
          [qw/av bv compute_int sav sbv one_var one_wrong_var 
              meet_test compute_with_override compute_no_var bar foo2 url host/],
         "check available elements");

my ( $av, $bv, $compute_int );
$av=$root->fetch_element('av') ;
$bv=$root->fetch_element('bv') ;

ok($bv,"created av and bv values") ;

ok($compute_int = $root->fetch_element('compute_int'),
   "create computed integer value (av + bv)");

no warnings 'once';

my $parser = new Parse::RecDescent ($Config::Model::ValueComputer::compute_grammar) ;

use warnings 'once';

{
    no warnings qw/once/;
    $::RD_HINT  = 1 if $trace > 4;
    $::RD_TRACE = 1 if $trace > 5;
}

my $object = $root->fetch_element('one_var') ;
my $rules =  { 
              bar => '- sbv',
             } ;
my $srules = {
               bv => 'rbv' 
             };

my $ref = $parser->pre_value( '$bar', 1, $object, $rules , $srules );
is( $$ref, '$bar' , "test pre_compute parser on a very small formula: '\$bar'");

$ref = $parser->value( '$bar', 1, $object, $rules , $srules  );
is($$ref,undef,"test compute parser on a very small formula with undef variable") ;

$root->fetch_element('sbv')->store('bv') ;
$ref = $parser->value( '$bar', 1, $object, $rules  , $srules);
is( $$ref, 'bv', "test compute parser on a very small formula: '\$bar'");

$ref = $parser->pre_value( '$replace{$bar}', 1, $object, $rules , $srules );
is( $$ref, '$replace{$bar}',"test pre-compute parser with substitution" );

$ref = $parser->value( '$replace{$bar}', 1, $object, $rules , $srules );
is( $$ref, 'rbv', "test compute parser with substitution");

my $txt = 'my stuff is  $bar, indeed';
$ref = $parser->pre_compute( $txt, 1, $object, $rules , $srules );
is( $$ref, $txt,"test pre_compute parser with a string" );

$ref = $parser->compute( $txt, 1, $object, $rules  , $srules);
is( $$ref, 'my stuff is  bv, indeed',
  "test compute parser with a string" );

$txt = 'local stuff is element:&element!';
$ref = $parser->pre_compute( $txt, 1, $object, $rules , $srules );
is( $$ref, 'local stuff is element:one_var!',
  "test pre_compute parser with function (&element)");

# In fact, function is formula is handled only by pre_compute.
$ref = $parser->compute( $txt, 1, $object, $rules , $srules );
is( $$ref, $txt,
    "test compute parser with function (&element)");

## test integer formula
my $result = $compute_int->fetch; 
is ($result, undef,"test that compute returns undef with undefined variables" );

$av->store(1) ;
$bv->store(2) ;

$result = $compute_int->fetch ;
is($result, 3, "test result :  computed integer is $result (a: 1, b: 2)");


eval { $compute_int->store(4); };
ok($@,"test assignment to a computed value (normal error)" );
print "normal error:\n", $@, "\n" if $trace;

$result = $compute_int->fetch ;
is($result, 3, "result has not changed") ;

$bv->store(-2) ;
$result = $compute_int->fetch ;
is($result, -1 ,
   "test result :  computed integer is $result (a: 1, b: -2)");

ok($bv->store(4),"change bv value") ;
eval { $result = $compute_int->fetch; };
ok($@,"computed integer: computed value error");
print "normal error:\n", $@, "\n" if $trace;

ok($inst->push_no_value_check('fetch'),
   "disable fetch value check");

is($compute_int->fetch, undef, 
   "test result :  computed integer is undef (a: 1, b: -2)");

ok($inst->pop_no_value_check,
   "enable fetch value check");

my $s = $root->fetch_element('meet_test') ;
$result = $s->fetch ;
is($result,undef,"test for undef variables in string") ;

my ($as,$bs) = ('Linus','his penguin') ;
$root->fetch_element('sav')->store($as) ;
$root->fetch_element('sbv')->store($bs) ;
$result = $s->fetch ;
is($result, 'meet Linus and his penguin',
  "test result :  computed string is '$result' (a: $as, b: $bs)") ;


print "test allow_compute_override\n" if $trace;

my $comp_over =  $root-> fetch_element('compute_with_override');
$bv->store(2) ;

is( $comp_over->fetch, 3, "test computed value" );
$comp_over->store(4);
is( $comp_over->fetch, 4, "test overridden value" );

my $owv = $root->fetch_element('one_wrong_var');
eval {$owv -> fetch ;} ;
ok($@,"expected failure with one_wrong_var");
print "normal error:\n", $@, "\n" if $trace;

my $cnv = $root->fetch_element('compute_no_var');
is( $cnv->fetch, 'compute_no_var', "test compute_no_var" );

my $foo2 = $root->fetch_element('foo2') ;
my $fen  = $foo2->fetch_element('find_node_element_name') ;
ok($fen,"created element find_node_element_name") ;
is($fen->fetch,'foo2',"did find node element name");

my $cen  = $foo2->fetch_element('check_node_element_name') ;
ok($cen,"created element check_node_element_name") ;
is($cen->fetch,1,"did check node element name");

my $slave_av = $root->fetch_element('bar')->fetch_element('av') ;
my $slave_bv = $root->fetch_element('bar')->fetch_element('bv') ;

is($slave_av->fetch,$av->fetch,"compare slave av and av") ;
is($slave_bv->fetch,$bv->fetch,"compare slave bv and bv") ;

$root->fetch_element('url')->store('http://foo.bar/baz.html');

my $h = $root->fetch_element('host');

is($h->fetch,'foo.bar',"check extracted host") ;
