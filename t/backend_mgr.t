# -*- cperl -*-

use Test::More;
use Test::Memory::Cycle;
use Config::Model;

use Config::Model::Tester::Setup qw/init_test setup_test_dir/;

use warnings;
use strict;

my ($model, $trace) = init_test();

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir();

$model->create_config_class(
    'rw_config' => {
        'auto_create' => '1',
        'file'        => 'test.ini',
        'backend'     => 'ini_file',
        'config_dir'  => 'test'
    },
    'name'    => 'Test',
    'element' => [ 'source' => { 'type' => 'leaf', value_type => 'string', } ]
);

subtest "Check reading of global comments" => sub {
    my $inst = $model->instance( root_class_name => 'Test', root_dir => $wr_root, );
    my $root = $inst->config_root;
    $root->init;

    my @copy = my @lines = (
        '## cme comment 1',
        '## cme comment 2',
        '',
        '# global comment1',
        '# global comment2',
        '',
        '# data comment',
        'stuff',
    );

    $root->backend_mgr->backend_obj->read_global_comments(\@lines, '#');

    is_deeply(\@lines, [ @copy[-2,-1] ], "check untouched lines" );
    is($root->annotation,join("\n", map {s/#\s+//; $_;} @copy[3,4]), "check extracted global comment");

};

memory_cycle_ok($model);

done_testing;
