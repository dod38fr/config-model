# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Test::Exception;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;
use Test::Log::Log4perl;

use strict;
use warnings;

my ($model, $trace) = init_test();

$model->create_config_class(
    name       => 'Sarge',
    status      => [ D => 'deprecated' ],                 #could be obsolete, standard
    description => [ X => 'X-ray (long description)' ],
    summary     => [ X => 'X-ray (summary)' ],
    class => 'Config::Model::Node',

    gist => '{X} and {Y}',

    element => [
        [qw/D X Y Z/] => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'enum',
            choice     => [qw/Av Bv Cv/] }
    ],
);

$model->create_config_class(
    name       => 'Captain',

    gist => '{bar X} and {bar Y}',

    element    => [
        bar => {
            type              => 'node',
            config_class_name => 'Sarge'
        } ] );

$model->create_config_class(
    name       => "Master",
    level   => [ qw/captain/ => 'important' ],
    gist => '{captain bar X} and {captain bar Y}',
    element => [
        captain => {
            type              => 'node',
            config_class_name => 'Captain',
        },
        [qw/array_args hash_args/] => {
            type              => 'node',
            config_class_name => 'Captain',
        },
    ],
    class_description => "Master description",
    description       => [
        captain    => "officer",
        array_args => 'not officer'
    ] );

ok( 1, "Model created" );

my $instance = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);

ok( 1, "Instance created" );

Test::Log::Log4perl-> ignore_priority('INFO');

my $root = $instance->config_root;

ok( $root, "Config root created" );

is( $root->config_class_name, 'Master', "Created Master" );

is_deeply(
    [ sort $root->get_element_name( ) ],
    [qw/array_args captain hash_args/],
    "check Master elements"
);

my $w = $root->fetch_element('captain');
ok( $w, "Created Captain" );

is( $w->config_class_name, 'Captain', "test class_name" );

is( $w->element_name, 'captain', "test element_name" );
is( $w->name,         'captain', "test name" );
is( $w->location,     'captain', "test captain location" );

my $b = $w->fetch_element('bar');
ok( $b, "Created Sarge" );

is( $b->fetch_element_value('Z'), undef, "test Z value" );

subtest "check deprecated element warning" => sub{
    my $xp = Test::Log::Log4perl->expect([
        'User',
        warn => qr/Element 'D' of node 'captain bar' is deprecated/
    ]);
    $b->fetch_element('D');
};


$b->fetch_element('X')->store('Av');
$b->fetch_element('Y')->store('Bv');
my $expected_gist = 'Av and Bv';
is($b->fetch_gist,$expected_gist, 'test Sarge gist');
is($w->fetch_gist,$expected_gist, 'test Captain gist');
is($root->fetch_gist,$expected_gist, 'test Master gist');

my $tested = $root->fetch_element('hash_args')->fetch_element('bar');

is( $tested->config_class_name, 'Sarge',         "test bar config_class_name" );
is( $tested->element_name,      'bar',           "test bar element_name" );
is( $tested->name,              'hash_args bar', "test bar name" );
is( $tested->location,          'hash_args bar', "test bar location" );

my $inst2 = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test2'
);

isa_ok( $inst2, 'Config::Model::Instance', "Created 2nd Master" );

isa_ok( $inst2->config_root, 'Config::Model::Node', "created 2nd tree" );

# test help included with the model

is( $root->get_help, "Master description", "Test master global help" );

is( $root->get_help('captain'), "officer", "Test master slot help captain" );

is( $root->get_help('hash_args'), '', "Test master slot help hash_args" );

is( $tested->get_help('X'), "X-ray (long description)", "Test sarge slot help X" );

is(
    $tested->get_help( description => 'X' ),
    "X-ray (long description)",
    "Test sarge slot help X (description)"
);

is( $tested->get_help( summary => 'X' ), "X-ray (summary)", "Test sarge slot help X (summary)" );

is( $root->has_element('daughter'), 0, "Non-existing element" );
is( $root->has_element('captain'),  1, "existing element" );
is( $root->has_element( name => 'captain', type => 'node' ), 1, "existing node element" );
is( $root->has_element( name => 'captain', type => 'leaf' ), 0, "non existing leaf element" );

ok( $root->is_element_available( name => 'captain' ), "test element" );

is( $root->get_element_property( property => 'level', element => 'hash_args' ),
    'normal', "test (non) importance" );

is( $root->get_element_property( property => 'level', element => 'captain' ),
    'important', "test importance" );

is(
    $root->set_element_property(
        property => 'level',
        element  => 'captain',
        value    => 'hidden'
    ),
    'hidden',
    "test importance"
);

is( $root->get_element_property( property => 'level', element => 'captain' ),
    'hidden', "test hidden" );

is( $root->reset_element_property( property => 'level', element => 'captain' ),
    'important', "test importance" );

my @prev_next_tests = (
    [ undef, 'captain' ],
    [ '', 'captain' ],
    [qw/captain array_args/],
    [qw/array_args hash_args/]
);

foreach (@prev_next_tests) {
    my $key_label = defined $_->[0] ? $_->[0] : 'undef';
    is( $root->next_element( name => $_->[0] ), $_->[1], "test next_element ($key_label)" );
    is( $root->previous_element( name => $_->[1] ), $_->[0], "test previous_element ($key_label)" )
        unless ( defined $_->[0] and $_->[0] eq '' );
    };

memory_cycle_ok($model, "memory cycle");

done_testing ;
