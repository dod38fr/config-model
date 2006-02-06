# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-02-06 12:34:35 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $
use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Config::Model ;

BEGIN { plan tests => 23; }

use strict;

my $trace = shift || 0;

$::verbose = 1 if $trace > 2;
$::debug   = 1 if $trace > 3;

ok(1,"Compilation done");

my @rules = (
    F => { choice => [qw/A B C F F2/], default => 'F' },
    G => { choice => [qw/A B C G G2/], default => 'G' }
);

my @args = (
    value_type => 'enum',
    mandatory  => 1,
    choice     => [qw/A B C/]
);

my @wrong_rules = ( 'XXX' => { choice => [qw/A B C F/], default => 'F' } );


my $model = Config::Model->new() ;
$model ->create_config_class 
  (
   name => "Master",
   element 
   => [
       enum => {type => 'leaf',
		class => 'Config::Model::Value',
		value_type => 'enum',
		choice =>[qw/F G H/], 
		default => undef
	       },
       wrong_syntax_rule => {type => 'leaf',
			     class => 'Config::Model::Value',
			     warp => { follow => '- enum', 
				      rules  => [ F => [ default => 'F' ]] },
			     @args
			    },
       wrong_rule_semantic => { type => 'leaf',
				class => 'Config::Model::Value',
				warp => { follow => '- enum', 
					  rules  => \@wrong_rules},
				@args
			      },
       warped_object => { type => 'leaf',
			  class =>'Config::Model::Value', 
			  @args, 
			  warp => { follow => '- enum' , 
				    rules  => \@rules  }
			},
       recursive_warped_object 
       => { type => 'leaf',
	    class => 'Config::Model::Value', @args, 
	    warp => { follow => '- warped_object' , rules  => \@rules }
	  },
       [qw/w2 w3/] => { type => 'leaf',
			class => 'Config::Model::Value', 
			@args, 
			warp =>  { follow => '- enum', rules  => \@rules },
	     },
      ] , # dummy class
  ) ;

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my ( $w1, $w2, $w3, $bad_w, $rec_wo , $t);

eval {$bad_w = $root->get_element_for('wrong_syntax_rule') ;};
ok($@,"set up warped object with wrong rules syntax" ) ;
print "normal error:\n", $@, "\n" if $trace;

eval {$bad_w = $root->get_element_for('wrong_rule_semantic') ;} ;
ok($@, "set up warped object with wrong rules semantic" ) ;
print "normal error:\n", $@, "\n" if $trace;

eval { $t = $bad_w->fetch ; } ;
ok( $@,"wrong rules semantic warped object blows up" );
print "normal error:\n", $@, "\n" if $trace;

ok( $w1 = $root->get_element_for('warped_object'), 
    "set up warped object");

eval { my $str = $w1->fetch ; } ;
ok($@, "try to read warped object while warp master is undef"  );
print "normal error:\n", $@, "\n" if $trace;

my $warp_master = $root->get_element_for('enum') ;
is( $warp_master->store('F'), 'F', 
    "store F in warp master" );
is( $w1->fetch, 'F', "read warped object default value" );

is( $w1 -> store ('F2'), 'F2', "store F2 in  warped object");
is( $w1->fetch, 'F2',"and read" );


ok($rec_wo=$root->get_element_for('recursive_warped_object'), 
   "set up recursive_warped_object");

eval { my $str = $rec_wo->fetch ; } ;
ok($@, "try to read recursive warped object while its warp master is F2"  );
print "normal error:\n", $@, "\n" if $trace;

eval { $t = $rec_wo->fetch ;};
ok( $@,"recursive_warped_object blows up" );
print "normal error:\n", $@, "\n" if $trace;

is( $w1 -> store ('F'), 'F', "store F in warped object");
is($rec_wo->fetch , 'F',
   "read recursive_warped_object: default value was set by warp master");

$warp_master->store('G') ;
is($w1->fetch, 'G',
   "warp 'enum' so that F2 value is clobbered (outside new choice)" );


$w1->store('A') ;
$warp_master->store('F') ;
is($w1->fetch, 'A',
   "set value valid for both warp, warp w1 to G and test that the value is still ok");

$w2 = $root->get_element_for('w2');
$w3 = $root->get_element_for('w3');

is($w2->fetch, 'F',
   "test unset value for w2 after setting warp master");
is($w3->fetch, 'F',
   "idem for w3");

$warp_master->store('G') ;
is($w1->fetch, 'A',
   "set warp master to G and test unset value for w1 ... 2 and w3");
is($w2->fetch, 'G', "... and w2 ...");
is($w3->fetch, 'G', "... and w3");

__END__


#####

print 'create computed integer variable ($a + $b)' . "\n" if $trace;
my ( $av, $bv, $ci );
tie($av, 'Config::Model::Value',
    value_type => 'integer',
    @test, name => 'av'
);
tie($bv, 'Config::Model::Value',
    value_type => 'integer',
    @test, name => 'bv'
);

tie($ie, 'Config::Model::Value',
    value_type => 'integer',
    name       => 'my_c_scalar',
    compute    => [ '$a + $b', a => \$av, b => \$bv ],
    min        => -4,
    max        => 4,
    @test
);

print "test for undef variables\n" if $trace;
ok( not eval { my $ret = $ie; } );
print "normal error (normal display of SCALAR):\n", $@, "\n" if $trace;

my $parser = $Config::Model::Value::Compute::compute_parser;

$::RD_HINT  = 1 if $trace > 3;
$::RD_TRACE = 1 if $trace > 4;

my $bvref  = 'bv';
my $object = {
    variable        => { bar => 'bv' },
    value_type      => 'string',
    CMM_SLOT_NAME   => 'my_CMM_slot',
    CMM_INDEX_VALUE => 'my_CMM_idx'
};
my $rules = {
    bar  => \$bvref,
    rep1 => { bv => 'rbv' }
};

my $str = $parser->pre_value( '$bar', 1, $object, $rules );
ok( $str, '$bar' );

$str = $parser->value( '$bar', 1, $object, $rules );
ok( $str, 'bv' );

$str = $parser->pre_value( '$rep1{$bar}', 1, $object, $rules );
ok( $str, '$rep1{$bar}' );

$str = $parser->value( '$rep1{$bar}', 1, $object, $rules );
ok( $str, 'rbv' );

my $txt = 'my stuff is  $bar, indeed';
$str = $parser->pre_compute( $txt, 1, $object, $rules );
ok( $str, $txt );

$str = $parser->compute( $txt, 1, $object, $rules );
ok( $str, 'my stuff is  bv, indeed' );

$txt = 'local stuff is slot:&slot index &index!';
$str = $parser->pre_compute( $txt, 1, $object, $rules );
ok( $str, 'local stuff is slot:my_CMM_slot index my_CMM_idx!' );

$str = $parser->compute( $txt, 1, $object, $rules );
ok( $str, $txt );

ok( $av = 1 );
ok( $bv = 2 );
print "test result :  computed integer is $ie (a: $av, b: $bv)\n" if $trace;
ok( $ie, 3 );

print "test assignment to a computed value (normal error)\n" if $trace;
eval { $ie = 4; };
print $@ if $trace;
ok($@);

ok( $ie, 3 );

ok( $bv = -2 );
print "test result :  computed integer is $ie (a: $av, b: $bv)\n" if $trace;
ok( $ie, -1 );

ok( $bv = 4 );
print "computed integer: computed value error\n" if $trace;
ok( not eval { my $tmp = $ie } );
print "normal error:\n", $@, "\n" if $trace;

print "computed integer: computed value error (fetch check disabled)\n"
    if $trace;
$inst->push_no_value_check('fetch');

print "test result :  computed integer is undef (a: $av, b: $bv)\n"
    if $trace;
ok( not defined $ie );

$inst->pop_no_value_check;

my ( $as, $bs, $s );
tie( $as, 'Config::Model::Value', value_type => 'string', @test );
tie( $bs, 'Config::Model::Value', value_type => 'string', @test );

tie($s, 'Config::Model::Value',
    value_type => 'string',
    name       => 'my_c_scalar',
    compute    => [ 'meet $a and $b', a => \$as, b => \$bs ],
    @test
);

print "test for undef variables in string" if $trace;
ok( not eval { my $ret = $s; } );
print "normal error:\n", $@, "\n" if $trace;

ok( $as = 'Linus' );
ok( $bs = 'his penguin' );
print "test result :  computed string is '$s' (a: $as, b: $bs)\n" if $trace;

ok( $s, 'meet Linus and his penguin' );

my (@unique);
print "testing index_class" if $trace;
tie($unique[0], 'Config::Model::Value',
    value_type  => 'string',
    index_class => 'unique_test',
    @test
);
tie($unique[1], 'Config::Model::Value',
    value_type  => 'string',
    index_class => 'unique_test',
    @test
);

# index_class must be tested with Id tied hash

print "Testing integrated help\n" if $trace;

my $with_help;
my $obj = tie(
    $with_help, 'Config::Model::Value',
    value_type => 'enum',
    choice     => [qw/a b c/],
    help       => { a => 'a help' }
);

my $full_help = $obj->help;

ok( $full_help->{a}, 'a help' );
ok( $obj->help( 'a', 'a help' ) );
ok( not defined $obj->help('b') );

print "test allow_compute_override\n" if $trace;

my $ie2;
$bv = 2;
tie($ie2, 'Config::Model::Value',
    value_type             => 'integer',
    name                   => 'my_c_scalar',
    allow_compute_override => 1,
    compute                => [ '$a + $b', a => \$av, b => \$bv ],
    min                    => -4,
    max                    => 4,
    @test
);

ok( $ie2, 3 );
$ie2 = 4;
ok( $ie2, 4 );
