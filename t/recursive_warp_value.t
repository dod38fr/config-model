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
    name      => 'Master',
    'element' => [
        macro => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/A B C/]
        },
        m1 => {
            type       => 'leaf',
            value_type => 'string',
            warp       => {
                follow => '- macro',
                rules  => [
                    A => { default => 'm1_A' },
                    B => { default => 'm1_B' },
                    C => { default => 'm1_C' } ] }
        },
        compute => {
            type       => 'leaf',
            value_type => 'string',
            compute    => {
                formula => 'macro is $m, my slot is &slot',
                variables => { 'm' => '!  macro'}
            }
        },

        # second level warp (kinda recursive and scary ...)
        m2a => {
            type       => 'leaf',
            value_type => 'string',
            warp       => {
                follow => '- m1',
                rules  => [
                    m1_A => { default => 'm2a_A' },
                    m1_B => { default => 'm2a_B' },
                    m1_C => { default => 'm2a_C' } ] }
        },

        # second level warp (kinda recursive and scary ...)
        m2b => {
            type       => 'leaf',
            value_type => 'string',
            warp       => {
                follow => '- m1',
                rules  => [
                    m1_A => { default => 'm2b_A' },
                    m1_B => { default => 'm2b_B' },
                    m1_C => { default => 'm2b_C' } ] }
        },
        e1 => {
            type       => 'leaf',
            value_type => 'enum',
            'warp'     => {
                follow  => '- macro',
                'rules' => [
                    A => { choice => [qw/e1_A e1_B/], default => 'e1_A' },
                    B => { choice => [qw/e1_B e1_C/], default => 'e1_B' },
                    C => { choice => [qw/e1_C e1_D/], default => 'e1_C' } ] }
        },
        e2 => {
            type       => 'leaf',
            value_type => 'string',
            warp       => {
                follow => '- e1',
                rules  => [
                    e1_A => { default => 'e2_A' },
                    e1_B => { default => 'e2_B' },
                    e1_C => { default => 'e2_C' } ] }
        },
    ],
);

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

foreach my $mv (qw/A B C/) {
    ok( $root->fetch_element('macro')->store($mv), "Set macro to $mv" );

    foreach my $element (qw/m1 m2a m2b/) {
        is(
            $root->fetch_element($element)->fetch(),
            $element . '_' . $mv,
            "Reading Master element $element"
        );
    }

    foreach my $element (qw/e1 e2/) {
        is(
            $root->fetch_element($element)->fetch(),
            $element . '_' . $mv,
            "Reading Master element $element"
        );
    }

}

memory_cycle_ok($model, "memory cycle");

done_testing;
