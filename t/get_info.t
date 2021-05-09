# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Differences;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

use warnings;
use strict;
use lib "t/lib";

use utf8;
use open      qw(:std :utf8);    # undeclared streams in UTF-8

my ($model, $trace) = init_test();


$model->load(Master => 'Config/Model/models/Master.pl');
ok( 1, "loaded big_model" );

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;
ok( $root, "Config root created" );

my $step =
      'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata" '
    . 'hash_a:toto=toto_value hash_a:titi=titi_value '
    . 'lista=a,b,c,d olist:0 X=Av - olist:1 X=Bv - '
    . 'my_check_list=toto my_reference="titi"';

ok( $root->load( step => $step ), "set up data in tree with '$step'" );

my @setup = (
    [ '!' => ['type: node','class name: Master' ] ],
    [ std_id => ['type: hash', 'index: string', 'cargo: node', 'cargo class: SlaveZ'] ],
    [ 'std_id:ab' => ['type: node', 'class name: SlaveZ']],
    [ 'std_id:ab X' => [ 'type: enum (Av,Bv,Cv)']],
    [ lista => [ 'type: list', 'index: integer','cargo: leaf', 'leaf value type: string' ]],
    [ olist => [ 'type: list','index: integer', 'cargo: node','cargo class: SlaveZ' ]],
    [ my_check_list => ['type: check_list','refer_to: - hash_a + ! hash_b','ordered: no']],
    [ a_boolean => [ 'type: boolean' ]],
    [ yes_no_boolean => [ 'type: boolean','upstream_default value: yes', 'write_as: no yes' ]],
    [ my_reference => ['type: reference','reference to: - hash_a + ! hash_b']],
);

foreach my $test (@setup) {
    my ($path, $expect) = @$test;
    my @info = $root->grab($path)->get_info;
    eq_or_diff( \@info, $expect , "check '$path' info " );
}

memory_cycle_ok($model, "check memory cycles");

done_testing;
