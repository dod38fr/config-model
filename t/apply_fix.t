# -*- cperl -*-

use warnings;

use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Value;
use Config::Model::Tester::Setup qw/init_test/;
use Data::Dumper;
use Test::Log::Log4perl;
use Test::Differences;

use strict;
use 5.10.1;

Test::Log::Log4perl->ignore_priority("info");

my ($model, $trace) = init_test();

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
        # test data deletion from Dpkg/Copyright Disclaimer
        # using undef
        disclaimer_fix_with_undef => {
            type => 'leaf',
            value_type => 'string',
            warn_if_match => {
                'dh-make-perl' => {
                    fix => '$_ = undef ;',
                    msg => 'Disclaimer contains dh-make-perl boilerplate'
                }
            }
        },
        # same test as above using _store method
        disclaimer_fix_with_delete => {
            type => 'leaf',
            value_type => 'string',
            warn_if_match => {
                'dh-make-perl' => {
                    fix => '$self->store(undef) ;',
                    msg => 'Disclaimer contains dh-make-perl boilerplate'
                }
            }
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
my %expected_changes = (
    long => [],
    with_delete => [],
    with_undef => [] );

foreach my $w (qw/a b c/) {
    my $foo = Test::Log::Log4perl->expect(
        ignore_priority => info => [
            'User',
            warn => qr/deprecated in favor of Debian GNU/,
            warn => qr/Line too long/,
            warn => qr/leading white space/,
            warn => qr/secure http/,
            warn => qr/unknown host/,
            ( warn => qr/dh-make-perl/) x 2 # 2 disclaimer parameters
        ]
    );
    $root->load (qq!my_broken_node_$w fix-gnu="Debian GNU/Linux for $w"!
                     . qq! fix-long="$w is way too long"!
                     . qq! chained-fix=" http://floc/$w$w$w"!
                     . qq! disclaimer_fix_with_undef="blah dh-make-perl blah"!
                     . qq! disclaimer_fix_with_delete="blah dh-make-perl blah"!
                 );
    push @{$expected_changes{long}}, "my_broken_node_$w fix-long: '$w is way too long' -> '$w is way' # applied fix for :Line too long";
    push @{$expected_changes{with_delete}}, "my_broken_node_$w disclaimer_fix_with_delete deleted value: \'blah dh-make-perl blah\'";
    push @{$expected_changes{with_undef}}, "my_broken_node_$w disclaimer_fix_with_undef deleted value: \'blah dh-make-perl blah\' # applied fix for :Disclaimer contains dh-make-perl boilerplate";
}

print $root->dump_tree if $trace;

foreach my $filter (sort keys %expected_changes) {
    $inst->clear_changes;

    $root->apply_fixes($filter);

    eq_or_diff([$inst->list_changes], $expected_changes{$filter}, qq!change list for $filter apply_fix! );
}

foreach (qw/a b c/)  {
    is( $root->grab_value("my_broken_node_$_ fix-long"),
        "$_ is way", "check that '$_' long stuff was fixed" );
    is( $root->grab_value("my_broken_node_$_ disclaimer_fix_with_undef"),
        undef, "check that '$_ disclaimer_fix_with_undef' was fixed" );
    is( $root->grab_value("my_broken_node_$_ disclaimer_fix_with_delete"),
        undef, "check that '$_ disclaimer_fix_with_delete' was fixed" );
    is(
        $root->grab_value("my_broken_node_$_ fix-gnu"),
        "Debian GNU/Linux for $_",
        "check that '$_' gnu stuff was NOT fixed"
    );
}

$inst->clear_changes;
$root -> apply_fixes;

foreach (qw/a b c/)  {
    is( $root->grab_value("my_broken_node_$_ chained-fix"),
        "https://bugs.debian.org/$_$_$_", "check that $_ secure url was fixed" );
}

my @changes = $inst->list_changes;
is(scalar @changes, 3 * 4 , qq!number of changes applied for chained-fix apply_fix! );

print $root->dump_tree if $trace;

memory_cycle_ok($model, "memory cycle");

done_testing;
