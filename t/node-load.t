# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;
use 5.010;

use warnings;
use strict;

use lib 't/lib';

my ($model, $trace) = init_test();

ok( 1, "compiled" );

$model->create_config_class (
    name => "OverriddenNode",
    class => 'DummyNode',
    element => [
        [qw/foo bar baz/ ] => { type => 'leaf', value_type => 'uniline' },
    ],
) ;

$model->create_config_class (
    name => "PlainNode",
    element => [
        [qw/foo/ ] => { type => 'leaf', value_type => 'uniline' },
    ],
) ;

my $node = { type => 'node', config_class_name => 'OverriddenNode'} ;

$model->create_config_class (
    name => "OverriddenRoot",
    class => 'DummyNode',
    element => [
        a_node => $node,
        a_list => { type => 'list', cargo => $node} ,
        a_hash => { type => 'hash', index_type => 'string', cargo => $node},
        master_switch => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/plain dummy/]
        },

        'a_warped_node' => {
            type   => 'warped_node',
            warp => {
                follow => { ms => '! master_switch' },
                rules  => [
                    '$ms eq "plain"' => { config_class_name => 'PlainNode' },
                    '$ms eq "dummy"' => { config_class_name => 'OverriddenNode' },
                ]
            }
        },
    ],
) ;

my $inst = $model->instance(
    root_class_name => 'OverriddenRoot',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;
ok( $root, "Config root created" );

$root->load('master_switch=dummy a_node foo=boo ! a_list:0 bar=far ! a_list:1 bar=far2 ! a_hash:a baz=taz');

my $hook = sub {
    my ($scanner, $data_ref,$node,@element_list) = @_;
    isa_ok( $node, 'DummyNode', "check class of ".$node->name) ;
    $node->dummy($$data_ref) ;
};

my $count = 0;
Config::Model::ObjTreeScanner->new(
    node_content_hook => $hook,
    leaf_cb => sub { }
)->scan_node( \$count, $root );

is($count, 6, "check nb of dummy calls");

$root->load('master_switch=plain');

my $plain = $root->grab('a_warped_node')->get_actual_node;
isa_ok( $plain, 'Config::Model::Node', "check class of warped node on plain mode") ;
is($plain->can('dummy'),undef,"plain node is not a dummy");

memory_cycle_ok($model, "check memory cycles");

done_testing;
