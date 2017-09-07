# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Path::Tiny;
use YAML::Tiny;

use warnings;
no warnings qw(once);

use strict;
use lib "t/lib";

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $arg =~ /l/ ? $TRACE : $ERROR );

my $model = Config::Model->new();

ok( 1, "compiled" );

# pseudo root where config files are written by config-model
my $wr_root = path('wr_root_p/backend-yaml');

# cleanup before tests
$wr_root->remove_tree;
my $yaml_dir = $wr_root->child('yaml');
$yaml_dir->mkpath();

my $i_hosts = $model->instance(
    instance_name   => 'hosts_inst',
    root_class_name => 'Hosts',
    root_dir        => $wr_root->stringify,
    model_file      => 'test_yaml_model.pl',
);

ok( $i_hosts, "Created instance" );

my $i_root = $i_hosts->config_root;

my $load = "record:0
  ipaddr=127.0.0.1
  canonical=localhost
  alias=localhost -
record:1
  ipaddr=192.168.0.1
  canonical=bilbo - -
";

$i_root->load($load);

$i_hosts->write_back;
ok( 1, "yaml write back done" );

# TODO: test yaml content for skipped element

my $yaml_file = $yaml_dir ->child('hosts.yml');
ok( $yaml_file->exists, "check that config file $yaml_file was written" );

my $written = $yaml_file->slurp;
unlike($written, qr/record/, "check that list element name is not written");

# create another instance to read the yaml that was just written
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

# test yaml content for single hash class
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
$yaml = $yaml_file->slurp || die "can't open $yaml_file:$!";

unlike( $yaml, qr/record/, "check single_hash yaml content" );

# test that yaml file is removed when no data is left
$i_single_hash->config_root->fetch_element("record")->clear;
$i_single_hash->write_back;
ok( ! $yaml_file->exists, "check that config file $yaml_file was removed by clearing content" );

# idem for more complex class defined in model
my $i_2_elements = $model->instance(
    instance_name   => '2 elements',
    root_class_name => 'TwoElements',
    root_dir        => $wr_root->stringify,
);

ok( $i_single_hash, "Created '2 elements' instance" );

$i_2_elements->config_root->load($load);

$i_2_elements->write_back;
ok( 1, "yaml 2 elements write back done" );

ok( $yaml_file->exists, "check that config file $yaml_file was written" );
$yaml = $yaml_file->slurp || die "can't open $yaml_file:$!";

like( $yaml, qr/record/, "check 2 elements yaml content" );

$i_2_elements->config_root->fetch_element("record")->clear;
$i_2_elements->write_back;

ok( ! $yaml_file->exists, "check that config file $yaml_file was removed by clearing content" );

memory_cycle_ok( $model, "check model mem cycles" );

done_testing;
