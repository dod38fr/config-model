# -*- cperl -*-

use warnings;

use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Value;
use Config::Model::Tester::Setup qw/init_test/;
use Data::Dumper;
use Test::Log::Log4perl;

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
        },
        'chained-fix' => {
            type            => 'leaf',
            value_type      => 'uniline',
            'warn_if_match' => {
                '^\s' => {
                    'msg' => 'leading white space',
                    'fix' => 's/^\s+//;'
                },
            },
            warn_unless_match => {
                '^https://' => {
                    msg => 'secure http',
                    fix => 's!^http://!https://!'
                },
                '^https?://bugs\.debian\.org/' => {
                    msg => 'unknown host',
                    fix => 's!https?://[^/]*!https://bugs.debian.org!'
                }
            },
        },
    ]
);

$model->create_config_class(
    name => "Master",

    element => [
        [ map { "my_broken_node_$_" } (qw/a b c/) ] => {
            type              => 'node',
            config_class_name => 'NodeFix',
        }
    ]
);

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

foreach my $w (qw/a b c/) {
    my $foo = Test::Log::Log4perl->expect(
        ignore_priority => info => [
            'User',
            warn => qr/deprecated in favor of Debian GNU/,
            warn => qr/Line too long/,
            warn => qr/leading white space/,
            warn => qr/secure http/,
            warn => qr/unknown host/,
        ]
    );
    $root->load (qq!my_broken_node_$w fix-gnu="Debian GNU/Linux for $w"!
                     . qq! fix-long="$w is way too long"!
                     . qq! chained-fix=" http://floc/$w$w$w"!
                 );
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

$root -> apply_fixes;
map {
    is( $root->grab_value("my_broken_node_$_ chained-fix"),
        "https://bugs.debian.org/$_$_$_", "check that $_ secure url was fixed" );
} qw /a b c/;

print $root->dump_tree if $trace;

memory_cycle_ok($model, "memory cycle");

done_testing;
