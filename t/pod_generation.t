# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Test::Exception;

use warnings;
use strict;
use lib "t/lib";

my ($model, $trace) = init_test();

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir();


throws_ok {
    $model->generate_doc('Blork');
} qr/Unknown configuration class/, "test generate_doc error handling";

$model->generate_doc('Master') if $trace;

$model->generate_doc( 'Master', $wr_root );

for (qw /Master.pod  SlaveY.pod  SlaveZ.pod  SubSlave2.pod  SubSlave.pod/) {
    ok( -r "$wr_root/Config/Model/models/$_", "Found doc $_" );
}

memory_cycle_ok($model, "memory cycle");

done_testing;
