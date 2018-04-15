# -*- cperl -*-

use warnings;

use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Value;
use Config::Model::Tester::Setup qw/init_test/;
use Data::Dumper;

use strict;

my ($model, $trace) = init_test();

$::_use_log4perl_to_warn =1;
# minimal set up to get things working

$model->create_config_class(
    name    => "NodeFix",
    element => [
        'fix-gnu' => {
            type            => 'leaf',
            value_type      => 'uniline',
            'warn_if_match' => {
                'Debian GNU/Linux' => {
                    'msg' => 'deprecated in favor of Debian GNU',
                    'fix' => 's!Debian GNU/Linux!Debian GNU!g;'
                },
            },
        },
        'fix-long' => {
            type            => 'leaf',
            value_type      => 'uniline',
            'warn_if_match' => {
                '[^\\n]{10,}' => {
                    'msg' => 'Line too long',
                    'fix' => '$_ = substr $_,0,8;'
                },
            },
        } ]

);

$model->create_config_class(
    name => "Master",

    element => [
        [ map { "my_broken_node_$_" } (qw/a b c/) ] => {
            type              => 'node',
            config_class_name => 'NodeFix',
        } ] );

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

foreach my $w (qw/a b c/) {
    $root->load(
        qq!my_broken_node_$w fix-gnu="Debian GNU/Linux for $w" fix-long="$w is way too long"!);
}

print $root->dump_tree if $trace;

$root->apply_fixes('long');
map {
    is( $root->grab_value("my_broken_node_$_ fix-long"),
        "$_ is way", "check that $_ long stuff was fixed" );
    is(
        $root->grab_value("my_broken_node_$_ fix-gnu"),
        "Debian GNU/Linux for $_",
        "check that $_ gnu stuff was NOT fixed"
    );
} qw/a b c/;

print $root->dump_tree if $trace;

memory_cycle_ok($model, "memory cycle");

done_testing;
