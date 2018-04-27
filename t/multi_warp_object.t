# -*- cperl -*-


use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

use strict;
use warnings;

my ($model, $trace) = init_test();

# minimal set up to get things working
$model->create_config_class(
    name      => 'SlaveY',
    'element' => [
        [qw/X Y/] => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/Av Bv Cv/] } ] );

$model->create_config_class(
    name    => 'SlaveZ',
    element => [
        [qw/X Z/] => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/Av Bv Cv/] } ] );

$model->create_config_class(
    name       => 'Master',

    #level => [bar => 'hidden'],
    'element' => [
        macro1 => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/A B/]
        },
        macro2 => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/C D/]
        },
        'bar' => {
            type       => 'hash',
            index_type => 'string',
            level      => 'hidden',    # goes normal when both m1 and m2 are defined
            'warp'     => {
                follow  => { m1 => '! macro1', m2 => '- macro2' },
                'rules' => [
                    '$m1 eq "A" and $m2 eq "D"' => { level => 'normal' },
                    '$m1 and $m2' => { level => 'normal', },

                    #		     '$m1 eq "A" and $m2 eq "C"' => { level => 'normal',  },
                    #		     '$m1 eq "B" and $m2 eq "C"' => { level => 'normal',  },
                    #		     '$m1 eq "B" and $m2 eq "D"' => { level => 'normal',  },
                ]
            },
            cargo => {
                type    => 'warped_node',
                morph   => 1,
                warp => {
                    follow  => [ '! macro1', '- macro2' ],
                    'rules' => [
                        [qw/A C/] => { 'config_class_name' => 'SlaveY' },
                        [qw/A D/] => { 'config_class_name' => 'SlaveY' },
                        [qw/B C/] => { 'config_class_name' => 'SlaveZ' },
                        [qw/B D/] => { 'config_class_name' => 'SlaveZ' },
                    ]
                }
            }
        }
    ]
);

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

ok( $root, "Created Root" );

is( $root->is_element_available( name => 'bar' ),
    0, 'check element bar for beginner user (not available because macro* are undef)' );
is( $root->is_element_available( name => 'bar' ),
    0, 'check element bar for advanced user (not available because macro* are undef)' );

ok( $root->load('macro1=A'), 'set macro1 to A' );

is( $root->is_element_available( name => 'bar' ),
    0, 'check element bar for beginner user (not available because macro2 is undef)' );
is( $root->is_element_available( name => 'bar' ),
    0, 'check element bar for advanced user (not available because macro2 is undef)' );

eval { $root->load('bar:1 X=Av') };
ok( $@, "writing to slave->bar (fails tree_macro is undef)" );
print "normal error:\n", $@, "\n" if $trace;

ok( $root->load('macro2=C'), 'set macro2 to C' );

is( $root->is_element_available( name => 'bar' ),
    1, 'check element bar' );

$root->load( step => 'bar:1 X=Av' );

is( $root->grab('bar:1')->config_class_name, 'SlaveY', 'check bar:1 config class name' );

ok( $root->load('macro2=D'), 'set macro2 to D' );

is( $root->grab('bar:1')->config_class_name, 'SlaveY',
    'check bar:1 config class name (is SlaveY)' );

ok( $root->load('macro1=B'), 'set macro1 to B' );

is( $root->grab('bar:1')->config_class_name,
    'SlaveZ', 'check bar:1 config class name (is now SlaveZ)' );

is( $root->is_element_available( name => 'bar' ),
    1, 'check element bar' );
memory_cycle_ok($model, "memory cycle");

done_testing;
