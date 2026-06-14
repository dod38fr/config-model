# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Differences;
use Test::Memory::Cycle;
use Test::Log::Log4perl;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

use warnings;
use strict;
use lib "t/lib";
use boolean;

my $dump_model_file = 'dump_load_model.yml';

Test::Log::Log4perl->ignore_priority("info");

my ($model, $trace) = init_test();

my $inst = $model->instance(
    root_class_name => 'Master',
    model_file      => $dump_model_file,
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;
ok( $root, "Config root created" );

subtest "add fixture" => sub {
    my $step = '
std_id:ab X=Bv -
std_id:bc X=Av -
bool_list=0,1
tree_macro=mXY
another_string="toto\ntata"
hash_a:toto=toto_value
hash_a:titi=titi_value
ordered_hash:z=1
ordered_hash:y=2
ordered_hash:x=3
lista=a,b,c,d
listb=bb
olist:0 X=Av -
olist:1 X=Bv -
my_check_list=toto my_reference="titi"
warp warp2 aa2="foo bar"
';

    $step =~ s/\n/ /g;

    note("steps are $step") if $trace;
    ok( $root->load( step => $step ), "set up data in tree" );
};

my $yaml_str;
my $cml_dump;
subtest "yaml dump" => sub {
    $yaml_str = $root->dump_as_yaml(mode => 'custom');

    my $expect = <<EOL;
---
std_id:
  ab:
    X: Bv
  bc:
    X: Av
lista:
- a
- b
- c
- d
listb:
- bb
hash_a:
  titi: titi_value
  toto: toto_value
ordered_hash:
  z: '1'
  y: '2'
  x: '3'
olist:
- X: Av
- X: Bv
bool_list:
- false
- true
tree_macro: mXY
warp:
  warp2:
    aa2: foo bar
another_string: |-
  toto
  tata
my_check_list:
- toto
my_reference: titi
EOL

    note("yaml dump:\n$yaml_str") if $trace;
    #use Data::Dumper; print Dumper $yaml_str ;

    eq_or_diff( $yaml_str, $expect, "check yaml dump" );

    $cml_dump = $root->dump_tree;
};

subtest "load from yaml string" => sub {
    my $inst = $model->instance(
        root_class_name => 'Master',
        instance_name   => 'test2'
    );
    ok( $inst, "created 2nd dummy instance" );

    my $root2 = $inst->config_root;
    ok( $root2, "Config root2  created" );

    $root2->load_yaml($yaml_str);

    ok( 1, "loaded YAML data structure in 2nd instance" );

    my $cml_dump2 = $root2->dump_tree;

    eq_or_diff( $cml_dump2, $cml_dump,
                "check that dump of 2nd tree is identical to dump of the first tree" );
};

memory_cycle_ok($model, "memory cycles");

done_testing;
