# -*- cperl -*-

use warnings;

use ExtUtils::testlib;
use Test::More;
use Test::Warn;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

use strict;
use lib "t/lib";

use Test::Log::Log4perl;

my ($model, $trace) = init_test();

$model->create_config_class(
    name    => "WarnMaster",
    element => [
        warn_if => {
            type          => 'leaf',
            value_type    => 'string',
            warn_if_match => { 'foo' => { fix => '$_ = uc;' } },
        },
        warn_unless => {
            type              => 'leaf',
            value_type        => 'string',
            warn_unless_match => { foo => { msg => '', fix => '$_ = "foo".$_;' } },
        },
    ] );

my $messager ;
my $inst = $model->instance(
    root_class_name => 'WarnMaster',
    instance_name   => 'test1',
    root_dir        => 'foobar',
    on_message_cb   => sub { $messager = shift;},
);
ok( $inst, "created dummy instance" );

ok( $model->instance(name => 'test1'), "check that instance can be retrieved by name");

$inst->show_message('hello');
is($messager,'hello',"test show_message_cb");

isa_ok( $inst->config_root, 'Config::Model::Node', "test config root class" );

is( $inst->data('test'), undef, "test empty private data ..." );
$inst->data( 'test', 'coucou' );
is( $inst->data('test'), 'coucou', "retrieve private data" );

is( $inst->root_dir->stringify,  'foobar', "test config root directory" );

# test if fixes can be applied through the instance
my $root = $inst->config_root;
my $wip  = $root->fetch_element('warn_if');
my $wup  = $root->fetch_element('warn_unless');

my $wt = Test::Log::Log4perl->get_logger("User");
Test::Log::Log4perl->start(ignore_priority => "info");
$wt->warn(qr/should not match/);
$wt->warn(qr/should match/);
$wip->store('foobar');
$wup->store('bar');
Test::Log::Log4perl->end("test warn_if and warn_unless condition (instance test)");

is( $inst->has_warning, 2, "check warning count at instance level" );
$inst->apply_fixes;
is( $wup->fetch,        'foobar', "test if fixes were applied (instance test)" );
is( $wup->fetch,        'foobar', "test if fixes were applied (instance test)" );
is( $inst->has_warning, 0,        "check cleared warning count at instance level" );

my $binst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test2'
);
ok( $binst, "created dummy instance" );

my $root2 = $binst->config_root;

my $step =
      'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata" '
    . 'lista=a,b,c,d olist:0 X=Av - olist:1 X=Bv - listb=b,c,d '
    . '! hash_a:X2=x hash_a:Y2=xy  hash_b:X3=xy my_check_list=X2,X3';

ok( $root2->load( step => $step ), "set up data in tree with '$step'" );

is( $binst->has_warning, 0, "test has_warning with big model" );

memory_cycle_ok($model, "memory cycles");

done_testing;
