# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Exception;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

use strict;
use warnings;

my ($model, $trace) = init_test();

$model->create_config_class(
    name    => 'CommonOptions',
    element => [
        atime => {
            value_type => 'boolean',
            type       => 'leaf'
        },
    ],
);

$model->create_config_class(
    name    => 'NoneOptions',
    element => [
        bind => {
            value_type => 'boolean',
            type       => 'leaf',
        },
    ],
);

$model->create_config_class(
    name    => 'Master',
    element => [
        fs_vfstype => {
            value_type => 'enum',
            type       => 'leaf',
            choice     => [ 'auto', 'none', ]
        },
        fs_mntopts => {
            type   => 'warped_node',
            warp => {
                follow => { fst => '- fs_vfstype' },
                rules  => [
                    '$fst eq \'auto\'',
                    { config_class_name => 'Fstab::CommonOptions' },
                    '$fst eq \'none\'',
                    { config_class_name => 'Fstab::NoneOptions' },
                ],
            }
        },
        fs_passno => {
            value_type => 'integer',
            default    => 0,
            type       => 'leaf',
            warp       => {
                follow => {
                    fstyp   => '- fs_vfstype',
                    isbound => '- fs_mntopts bind',
                },
                rules => [ '$fstyp eq "none" and $isbound' => { max => 0, } ]
            }
        },
        type => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/node warped_node hash list leaf check_list/],
            mandatory  => 1,
        },
        cargo => {
            type    => 'warped_node',
            level   => 'hidden',
            warp => {
                follow  => { 't' => '- type' },
                'rules' => [
                    '$t eq "list" or $t eq "hash"' => {
                        level             => 'normal',
                        config_class_name => 'CommonOptions',
                    }
                ]
            }
        },
    ]
);

ok( 1, "compiled" );

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );
$inst->initial_load_stop;

my $root = $inst->config_root;

my $pass = $root->fetch_element('fs_passno');
is( $pass->fetch, '0', "check pass nb at 0" );

$pass->store(2);
is( $pass->fetch, '2', "check pass nb at 2" );

$root->load('fs_vfstype=none');
is( $pass->fetch, '2', "check pass nb at 2 after setting fs_vfstype" );

$root->load('fs_mntopts bind=1');
throws_ok { $pass->fetch; } 'Config::Model::Exception::WrongValue',
    "check that setting bind detects and error with passno";

# fix issue
$root->load('fs_mntopts bind=1 - fs_passno=0 fs_mntopts bind=0');

is( $pass->fetch, '0', "check pass nb at 2 after setting bind" );

# warp out bind
$root->load('fs_vfstype=auto');

throws_ok { $root->load('fs_mntopts bind=1'); }
'Config::Model::Exception::UnknownElement',
    "check that setting bind was warped out";

# fix issue
$root->load('fs_vfstype=none fs_mntopts bind=0 - fs_passno=3');
is( $pass->fetch, '3', "check pass nb at 3 " );

# break again
$root->load('fs_mntopts bind=1');
throws_ok { $pass->fetch; } 'Config::Model::Exception::WrongValue',
    "check that setting bind detects and error with passno again";

$root->load('fs_passno=0 fs_mntopts bind=1');

is( $pass->fetch, '0', "check pass nb at 2 after setting bind" );

ok( $root->load('type=hash cargo atime=1'), "check warping in of a node" );

memory_cycle_ok($model, "memory cycle");

done_testing;
