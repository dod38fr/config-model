# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Test::Exception;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

use warnings;
use strict;
use lib "t/lib";

my ($model, $trace) = init_test();

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - std_id:"b c" X=Av - a_string="titi , toto" ';
ok( $root->load( step => $step ), "load '$step'" );

my $grabbed = $root->grab('olist:0');
is( $grabbed->location,                  'olist:0', 'test grab olist:0 (obj)' );
is( $root->grab('olist:0')->index_value, 0,         'test grab olist:0 (index)' );

my $wp = 'olist:0';
throws_ok {
    $root->grab( \$wp )->index_value;
} qr/steps parameter must be a string or an array ref/, "Test grab with wrong parameter" ;
print "normal error:\n", $@, "\n" if $trace;

throws_ok {
    $root->grab('std_xid:toto')->index_value;
} qr/unknown element 'std_xid'/, "Test grab with wrong element" ;
print "normal error:\n", $@, "\n" if $trace;

like( $root->grab('olist')->name, qr/olist/, 'test grab olist' );

like( $root->grab('olist')->grab->name, qr/olist/, 'test grab without argument' );

is( $root->location(), '', 'location test' );

foreach
    my $wstep ( 'std_id:ab', 'olist:0', 'olist:1', 'warp', 'warp std_id:toto', 'warp std_id:"b c"' )
{
    my $obj = $root->grab($wstep);
    ok( $obj, "grab $wstep..." );
    is( $obj->location, $wstep, "... and test its location" );
}

print $root->dump_tree() if $trace;

my $leaf = $root->grab('warp std_id:toto DX');

my @tests = (
    [ '?warp',      'warp',             'WarpedNode' ],
    [ '?std_id:ab', 'warp std_id:ab',   'Node' ],
    [ '?hash_a:ab', 'hash_a:ab',        'Value' ],
    [ '?std_id',    'warp std_id',      'HashId' ],
    [ '!Master',    '',                 'Node' ],
    [ '!SlaveY',    'warp',             'Node' ],
    [ '!SlaveZ',    'warp std_id:toto', 'Node' ],
);

foreach my $unit_test (@tests) {
    my $obj = $leaf->grab( $unit_test->[0] );
    is( $obj->location, $unit_test->[1], "test grab with '$unit_test->[0]'" );
    isa_ok( $obj, 'Config::Model::' . $unit_test->[2] );
}

throws_ok {
    $leaf->grab('?argh');
} qr/cannot grab '\?argh'from warp std_id:toto DX/, "test grab with wrong step: '?argh'" ;
print "normal error:\n", $@, "\n" if $trace;

throws_ok {
    $root->grab( step => 'std_id:zzz', autoadd => 0 );
} qr/unknown identifier 'zzz'/, "test autoadd 0 with 'std_id:zzz'" ;
print "normal error:\n", $@, "\n" if $trace;

$root->grab( step => 'std_id:zzz', autoadd => 1 );
ok( 1, "test autoadd 1 with 'std_id:zzz'" );

my $obj = $root->grab( step => 'std_id:zzz foobar', mode => 'adaptative' );
is( $obj->location, "std_id:zzz", "test no strict grab" );

$obj = $root->grab( step => 'std_id:ab X', type => 'node', mode => 'adaptative' );
is( $obj->location, "std_id:ab", "test no strict grab with type node" );

throws_ok {
    $root->grab( step => 'std_id:ab X', type => 'node', mode => 'strict' );
} qr/wrong element type for element/, "test strict grab with type node" ;
print "normal error:\n", $@, "\n" if $trace;

subtest "test grab_value" => sub {
    is($root->grab_value('std_id:ab X'),'Bv',"grab value");

    throws_ok {
        my $trash = $root->grab_value('std_id:ab');
    } qr/Cannot get a value from 'std_id:ab'/, "test grab_value on list item" ;
};

memory_cycle_ok($model, "memory cycle");

done_testing;
