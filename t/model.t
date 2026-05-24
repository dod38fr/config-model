# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Exception;
use Test::Warn 0.11;
use Test::Differences;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Lister;
use Config::Model::Tester::Setup qw/init_test/;
use Data::Dumper;
use Log::Log4perl qw(:easy :levels);

use strict;
use warnings;

my ($model, $trace) = init_test();

subtest "check available models" => sub {
    my ( $cat, $models ) = Config::Model::Lister::available_models(1);

    eq_or_diff( $cat->{system}, [qw/fstab popcon/], "check available system models" );
    is( $models->{popcon}{model}, 'PopCon', "check available popcon" );
};

subtest "copy summary properties" => sub {
    my $raw_model = {
        element => [foo => {}, bar => {}],
        summary => {
            foo => 'foo summary',
            bar => 'bar summary',
        }
    };
    my $expect = {
        element => {
            foo => {
                summary => 'foo summary'
            },
            bar => {
                summary => 'bar summary'
            }
        },
        element_list => [qw/foo bar/],
    };
    my $normalized_model = {
        element_list => [qw/foo bar/],
        element => {foo => {}, bar => {} }
    };
    $model->copy_aliased_element_properties($normalized_model, $raw_model, "SummaryTest", ['summary']);
    eq_or_diff($normalized_model, $expect, "check copied summary");
};

subtest "copy status properties" => sub {
    my $raw_model = {
        element => [foo => {}, bar => {}, baz => {}, baz2 => {},],
        status => {
            deprecated => [qw/foo bar/],
            obsolete => 'baz',
        }
    };
    my $expect = {
        element => {
            foo => {
                status => 'deprecated'
            },
            bar => {
                status => 'deprecated'
            },
            baz => {
                status => 'obsolete'
            },
            baz2 => {}
        },
        element_list => [qw/foo bar baz baz2/],
    };
    my $normalized_model = {
        element_list => [qw/foo bar baz baz2/],
        element => {foo => {}, bar => {}, baz => {}, baz2 => {} }
    };
    $model->copy_reversed_element_properties($normalized_model, $raw_model, "StatusTest",['status']);
    eq_or_diff($normalized_model, $expect, "check copied status");
};

subtest "test simple model (Sarge)" => sub {
    my $class_name = $model->create_config_class(
        name       => 'Sarge',
        #could be obsolete, standard
        status      => [ D => 'deprecated', [qw/X Y Z/] => 'standard' ],
        description => [ [qw/X Y Z/] => 'a long description' ],
        summary     => [ [qw/X Y Z/] => 'a summary' ],

        element => [
            D => {
                type       => 'leaf',
                class      => 'Config::Model::Value',
                value_type => 'enum',
                choice     => [qw/Av Bv Cv/]
            },
            qw/X *D Y *D Z *D/
        ],
    );

    is( $class_name, 'Sarge', "check $class_name class name" );
    my $canonical_model = $model->get_model_clone($class_name);
    print "$class_name model:\n", Dumper($canonical_model) if $trace;

    eq_or_diff(
        $model->get_element_model( $class_name, 'D' ),
        {
            'value_type' => 'enum',
            'status'     => 'deprecated',
            'type'       => 'leaf',
            'class'      => 'Config::Model::Value',
            'choice'     => [ 'Av', 'Bv', 'Cv' ]
        },
        "check $class_name D element model"
    );

    eq_or_diff(
        $model->get_element_model( $class_name, 'X' ),
        {
            'value_type'  => 'enum',
            'summary'     => 'a summary',
            status        => 'standard',
            type          => 'leaf',
            'class'       => 'Config::Model::Value',
            'choice'      => [ 'Av', 'Bv', 'Cv' ],
            'description' => 'a long description'
        },
        "check $class_name X element model"
    );
};

subtest "create model with node element" => sub {
    my $class_name = $model->create_config_class(
        name       => 'Captain',
        element    => [
            bar => {
                type              => 'node',
                config_class_name => 'Sarge'
            }
        ]
    );
    is($class_name, 'Captain', "created class");
};

subtest "check bad model" => sub {
    my @bad_model = (
        name       => "Master",
        level => [ [qw/captain many/] => 'important' ],
        element    => [
            captain => {
                type              => 'node',
                config_class_name => 'Captain',
            },
        ],
    );

    throws_ok { $model->create_config_class(@bad_model) }
        "Config::Model::Exception::ModelDeclaration",
        "check model with orphan level";
};

subtest "model that use another model" => sub {
    my $class_name = $model->create_config_class(
        name       => "Master",
        level               => [ qw/captain/ => 'important' ],
        element             => [
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
        ]
    );

    ok( 1, "Model created" );

    is( $class_name, 'Master', "check $class_name class name" );
};

subtest "model clone" => sub {
    my $canonical_model = $model->get_model_clone('Master');
    ok($canonical_model, "got cloned model");
    print "Cloned Master model:\n", Dumper($canonical_model) if $trace;
};

memory_cycle_ok( $model, "memory cycles" );
done_testing;
