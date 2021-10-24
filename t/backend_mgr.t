# -*- cperl -*-

use Test::More;
use Test::Memory::Cycle;
use Test::File::Contents;
use Config::Model;
use List::MoreUtils qw/apply/;

use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Config::Model::Role::FileHandler;

use warnings;
use strict;
use 5.12.0;

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
    my $inst = $model->instance(
        name => "global-comment",
        root_class_name => 'Test',
        root_dir => $wr_root,
    );
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
    is($root->annotation,join("\n", apply {s/#\s+//; $_;} @copy[3,4]), "check extracted global comment");

};

subtest "check config file with absolute path" => sub {
    my $abs_test_dir = $wr_root->child('abs_path_test');
    $abs_test_dir->mkpath;
    my $ini_file = $abs_test_dir->child('test-abs.ini');
    $ini_file -> spew( "source =   fine");

    $model->create_config_class(
        'rw_config' => {
            'file'        => 'test-abs.ini',
            'backend'     => 'ini_file',
            'config_dir'  => $abs_test_dir->absolute->stringify.'/'
        },
        'name'    => 'TestAbsPath',
        'element' => ['source' => { 'type' => 'leaf', value_type => 'string', } ]
    );

    my $inst = $model->instance(
        name => 'test-abs-path',
        root_class_name => 'TestAbsPath'
    );

    my $root = $inst->config_root;
    $root->init;

    is($root->grab_value('source'),'fine', "check read data");
    $root->load("source=ok");
    $inst->write_back;

    file_contents_like( $ini_file->stringify, "source = ok","$ini_file content");

};

subtest "check config file override" => sub {
    my $abs_test_dir = $wr_root->child('cfg_file_override_test');
    $abs_test_dir->mkpath;

    $model->create_config_class(
        'rw_config' => {
            'backend'     => 'ini_file',
        },
        'name'    => 'TestCfo',
        'element' => ['source' => { 'type' => 'leaf', value_type => 'string', } ]
    );

    my $ini_file = $abs_test_dir->child('test-cfo.ini');

    # test 2 cases: relative and absolute paths
    my %test = (
        relative => $ini_file,
        absolute => $ini_file->absolute,
    );
    while ( my ($label, $cfg_file) = each %test) {
        $cfg_file -> spew( "source =   fine");

        my $inst = $model->instance(
            name => "test-cfo-$label",
            root_class_name => 'TestCfo',
            config_file  => $cfg_file->stringify
        );

        my $root = $inst->config_root;
        $root->init;

        is($root->grab_value('source'),'fine', "check read data ($label path)");
        $root->load("source=ok");
        $inst->write_back;

        file_contents_like( $ini_file->stringify, "source = ok","$ini_file content ($label path)");
    }
};

subtest "check string to Path::Tiny coercion" => sub {
    Config::Model::Role::FileHandler::_set_test_home('/home/joe');

    my $test_root_dir = $wr_root->child('coercion_test');
    my $joe_conf_dir = $test_root_dir->child('home/joe/conf');
    $joe_conf_dir->mkpath;
    my $ini_file = $joe_conf_dir->child('test-coercion.ini');
    $ini_file -> spew( "source =   fine");

    $model->create_config_class(
        'name'    => 'TestCoercion',
        'rw_config' => {
            'backend'     => 'ini_file',
            file  => 'test-coercion.ini',
        },
        'element' => ['source' => { 'type' => 'leaf', value_type => 'string', } ]
    );

    my $inst = $model->instance(
        name => 'test-coercion',
        root_class_name => 'TestCoercion',
        root_dir => $test_root_dir->stringify,
        'config_dir' => '~/conf/',
    );

    my $root = $inst->config_root;
    $root->init;
    is($root->grab_value('source'),'fine', "check read data");
    $root->load("source=ok");
    $inst->write_back;

    is($root->backend_mgr->config_dir,'/home/joe/conf',"check that ~ is coerced into /home/joe");

    file_contents_like( $ini_file->stringify, "source = ok","$ini_file content");
};

memory_cycle_ok($model, "memory cycle");

done_testing;
