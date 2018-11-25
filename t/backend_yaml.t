# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Path::Tiny;
use Config::Model::Tester::Setup qw/init_test  setup_test_dir/;

use warnings;

use strict;
use lib "t/lib";

my ($model, $trace) = init_test();

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir();

my $yaml_dir = $wr_root->child('yaml');
$yaml_dir->mkpath();

my $load = "record:0
  ipaddr=127.0.0.1
  canonical=localhost
  alias=localhost -
record:1
  ipaddr=192.168.0.1
  canonical=bilbo - -
";

my $yaml_file = $yaml_dir ->child('hosts.yml');

subtest 'Create YAML file from scratch' => sub {
    my $i_hosts = $model->instance(
        instance_name   => 'hosts_inst',
        root_class_name => 'Hosts',
        root_dir        => $wr_root->stringify,
        model_file      => 'test_yaml_model.pl',
    );

    ok( $i_hosts, "Created instance" );

    my $i_root = $i_hosts->config_root;

    $i_root->load($load);

    $i_hosts->write_back;
    ok( 1, "yaml write back done" );
    # TODO: test yaml content for skipped element

    ok( $yaml_file->exists, "check that config file $yaml_file was written" );

    my $written = $yaml_file->slurp;
    unlike($written, qr/record/, "check that list element name is not written");
};

subtest 'test automatic file backup' => sub {
    my $i_hosts = $model->instance(
        instance_name   => 'hosts_inst_backup',
        root_class_name => 'Hosts',
        root_dir        => $wr_root->stringify,
        model_file      => 'test_yaml_model.pl',
        backup => ''
    );

    ok( $i_hosts, "Created instance" );

    my $i_root = $i_hosts->config_root;

    $i_root->load("record:2 ipaddr=192.168.0.3 canonical=stuff");

    $i_hosts->write_back;
    ok( 1, "yaml write back done" );

    my $backup = path($yaml_file.'.old');
    ok ($backup->exists, "backup file was written");

    # restore backup to undo the load done 4 lines ago
    # so the next subtest tests that the backup content is right
    $backup->move($yaml_file);
};

subtest 'another instance to read the yaml that was just written' => sub {
    my $i2_hosts = $model->instance(
        instance_name   => 'hosts_inst2',
        root_class_name => 'Hosts',
        root_dir        => $wr_root->stringify,
    );

    ok( $i2_hosts, "Created instance" );

    my $i2_root = $i2_hosts->config_root;

    my $p2_dump = $i2_root->dump_tree;

    is( $p2_dump, $load, "compare original data with 2nd instance data" );

    # since full_dump is null, check that dummy param is not written in yaml files
    my $yaml = $yaml_file->slurp || die "can't open $yaml_file:$!";

    unlike( $yaml, qr/dummy/, "check yaml dump content" );

    $yaml_file->remove;
};

subtest 'test yaml content for single hash class' => sub {
    my $i_single_hash = $model->instance(
        instance_name   => 'single_hash',
        root_class_name => 'SingleHashElement',
        root_dir        => $wr_root->stringify,
    );

    ok( $i_single_hash, "Created single hash instance" );

    $load = "record:foo
  ipaddr=127.0.0.1
  canonical=localhost
  alias=localhost -
record:bar
  ipaddr=192.168.0.1
  canonical=bilbo - -
";

    $i_single_hash->config_root->load($load);

    $i_single_hash->write_back;
    ok( 1, "yaml single_hash write back done" );

    ok( $yaml_file->exists, "check that config file $yaml_file was written" );
    my $yaml = $yaml_file->slurp || die "can't open $yaml_file:$!";

    unlike( $yaml, qr/record/, "check single_hash yaml content" );

    # test that yaml file is removed when no data is left
    $i_single_hash->config_root->fetch_element("record")->clear;
    $i_single_hash->write_back;
    ok( ! $yaml_file->exists, "check that config file $yaml_file was removed by clearing content" );
};

subtest 'test yaml content for complex class' => sub {
    my $i_2_elements = $model->instance(
        instance_name   => '2 elements',
        root_class_name => 'TwoElements',
        root_dir        => $wr_root->stringify,
    );

    ok( $i_2_elements, "Created '2 elements' instance" );

    $i_2_elements->config_root->load($load);

    $i_2_elements->write_back;
    ok( 1, "yaml 2 elements write back done" );

    ok( $yaml_file->exists, "check that config file $yaml_file was written" );
    my $yaml = $yaml_file->slurp || die "can't open $yaml_file:$!";

    like( $yaml, qr/record/, "check 2 elements yaml content" );

    $i_2_elements->config_root->fetch_element("record")->clear;
    $i_2_elements->write_back;

    ok( ! $yaml_file->exists, "check that config file $yaml_file was removed by clearing content" );
};

memory_cycle_ok( $model, "check model mem cycles" );

done_testing;
