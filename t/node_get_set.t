# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

use warnings;
use strict;

use lib "t/lib";

my ($model, $trace) = init_test();

ok( 1, "compiled" );

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

# check with embedded \n
my $step = qq!std_id:ab X=Bv - std_id:bc X=Av - a_string="titi and toto" !;
ok( $root->load( step => $step ), "load '$step'" );

foreach ( [ "/std_id/cc/X", "Bv" ], ) {
    my ( $path, $exp ) = @$_;
    is( $root->set( $path, $exp ), 1, "Test set $path" );
}

foreach ( [ "/std_id/bc/X", "Av" ], [ "/std_id/cc/X", "Bv" ], ) {
    my ( $path, $exp ) = @$_;
    is( $root->get($path), $exp, "Test get $path" );
}

is(
    $root->get( path => "/std_id/bc/X", get_obj => 1 ),
    $root->grab("std_id:bc X"),
    "test get with get_obj"
);

is( $root->get( path => '/BDMV', check => 'skip' ), undef, "get with check skip does not die" );

memory_cycle_ok($model, "memory cycle");

done_testing;
