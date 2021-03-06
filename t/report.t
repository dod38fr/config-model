# -*- cperl -*-
use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

use warnings;
use strict;
use lib "t/lib";

my ($model, $trace) = init_test();

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;
ok( $root, "Config root created" );

my $step =
      'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata" '
    . 'lista=a,b,c,d olist:0 X=Av - olist:1 X=Bv - listb=b,c,d '
    . '! hash_a:X2=x hash_a:Y2=xy  hash_b:X3=xy my_check_list=X2,X3';
ok( $root->load( step => $step ), "set up data in tree with '$step'" );

$step = 'tree_macro=XY';
ok( $root->load( step => $step ), "set up data in tree with '$step'" );

my $report = $root->report;

print "report string:\n$report" if $trace;

my $expect = <<'EOF' ;
std_id:ab X = Bv

std_id:ab DX = Dv

std_id:bc X = Av

std_id:bc DX = Dv

  lista:0 = a

  lista:1 = b

  lista:2 = c

  lista:3 = d

  listb:0 = b

  listb:1 = c

  listb:2 = d

  hash_a:X2 = x

  hash_a:Y2 = xy

  hash_b:X3 = xy

olist:0 X = Av

olist:0 DX = Dv

olist:1 X = Bv

olist:1 DX = Dv

 tree_macro = XY
	DESCRIPTION: controls behavior of other elements
	SELECTED: XY help

 string_with_def = "yada yada"

 a_uniline = "yada yada"

 a_string = "toto tata"

 int_v = 10

 my_check_list = X2,X3
EOF

is_deeply(
    [ split /\n/, $report ],
    [ split /\n/, $expect ],
    "check dump of only customized values "
);

$report = $root->audit();
print "audit string:\n$report" if $trace;

$expect = <<'EOF' ;
std_id:ab X = Bv

std_id:bc X = Av

  lista:0 = a

  lista:1 = b

  lista:2 = c

  lista:3 = d

  listb:0 = b

  listb:1 = c

  listb:2 = d

  hash_a:X2 = x

  hash_a:Y2 = xy

  hash_b:X3 = xy

olist:0 X = Av

olist:1 X = Bv

 tree_macro = XY
	DESCRIPTION: controls behavior of other elements
	SELECTED: XY help

 a_string = "toto tata"

 my_check_list = X2,X3
EOF

is_deeply( [ split /\n/, $report ], [ split /\n/, $expect ], "check dump of all values " );

my $list = $model->list_class_element;
ok( $list, "check list_class_element" );
print $list if $trace;

#use Tk::ObjScanner; Tk::ObjScanner::scan_object($model) ;
memory_cycle_ok($model, "memory cycle");

done_testing;

