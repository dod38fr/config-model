# -*- cperl -*-

use warnings;
use strict;
use 5.10.0;

use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Test::Differences;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

my ($model, $trace) = init_test();

my @slave_classes = ('Slave0' .. 'Slave1');
my @master_elems ;
foreach my $slave_class (@slave_classes) {
    $model->create_config_class(
        name      => $slave_class,
        element => [
            [qw/X Y/] => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/Av Bv Cv/]
            }
        ]
    );

    push @master_elems , $slave_class => {
        type => 'warped_node',
        level => 'hidden',
        config_class_name => $slave_class,
        warp => {
            follow => { selected => '- macro1' },
            'rules' => [
                '$selected.is_set(&element_name)' => {
                    level => 'normal'
                }
            ]
        },
    };
}

$model->create_config_class(
    name       => 'Master',

    element => [
        macro1 => {
            type       => 'check_list',
            choice     => \@slave_classes
        },
        @master_elems
    ]
);

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

ok( $root, "Created Root" );

eq_or_diff( [$root->get_element_name], ['macro1'],"all slaves are hidden");

note("setting ",$slave_classes[0]) if $trace;
my $mac = $root->fetch_element('macro1');
$mac->check($slave_classes[0]);

eq_or_diff( [$root->get_element_name], ['macro1', $slave_classes[0]],"first slave is enabled");

$mac->check($slave_classes[1]);

eq_or_diff( [$root->get_element_name], ['macro1', @slave_classes[0,1]],"2 slave is enabled");

$mac->uncheck($slave_classes[0]);

eq_or_diff( [$root->get_element_name], ['macro1', $slave_classes[1]],"second slave is enabled");

$mac->uncheck($slave_classes[1]);
eq_or_diff( [$root->get_element_name], ['macro1'],"all slaves are hidden again");

memory_cycle_ok($model, "memory cycle");

done_testing;

