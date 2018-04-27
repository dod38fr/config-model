# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;

use warnings;
use strict;
use lib "t/lib";

my ($model, $trace) = init_test();

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir();

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

$model->generate_doc('Master') if $trace;

$model->generate_doc( 'Master', $wr_root );

map { ok( -r "$wr_root/Config/Model/models/$_", "Found doc $_" ); }
    qw /Master.pod  SlaveY.pod  SlaveZ.pod  SubSlave2.pod  SubSlave.pod/;

memory_cycle_ok($model, "memory cycle");

done_testing;
