# -*- cperl -*-
# $Author: ddumont $
# $Date: 2007-09-20 11:39:37 $
# $Name: not supported by cvs2svn $
# $Revision: 1.6 $
use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Config::Model ;

BEGIN { plan tests => 28; }

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;


ok(1,"Compilation done");


my $model = Config::Model->new() ;
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
		    compute    => [ '$bar', bar => '- sbv'],
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
      ]
 ) ;

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

# order is important. Do no use sort.
is_deeply([$root->get_element_name()],
	  [qw/av bv compute_int sav sbv one_var meet_test 
              compute_with_override/],
	 "check available elements");

my ( $av, $bv, $compute_int );
$av=$root->fetch_element('av') ;
$bv=$root->fetch_element('bv') ;

ok($bv,"created av and bv values") ;

ok($compute_int = $root->fetch_element('compute_int'),
   "create computed integer value (av + bv)");

no warnings 'once';

Parse::RecDescent->Precompile($Config::Model::ValueComputer::compute_grammar, "PreGrammar");

my $parser = Parse::RecDescent
  -> new($Config::Model::ValueComputer::compute_grammar) ;

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
	      rep1 => { bv => 'rbv' },
	     };

my $ref = $parser->pre_value( '$bar', 1, $object, $rules , $srules );
is( $$ref, '$bar' , "test pre_compute parser on a very small formula: '\$bar'");

$ref = $parser->value( '$bar', 1, $object, $rules , $srules  );
is($$ref,undef,"test compute parser on a very small formula with undef variable") ;

$root->fetch_element('sbv')->store('bv') ;
$ref = $parser->value( '$bar', 1, $object, $rules  , $srules);
is( $$ref, 'bv', "test compute parser on a very small formula: '\$bar'");

$ref = $parser->pre_value( '$rep1{$bar}', 1, $object, $rules , $srules );
is( $$ref, '$rep1{$bar}',"test pre-compute parser with substitution" );

$ref = $parser->value( '$rep1{$bar}', 1, $object, $rules , $srules );
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
