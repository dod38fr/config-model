
use warnings;
use strict;

use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test  setup_test_dir/;

use lib "t/lib";

sub check {
    my ($node, $msg) = @_;
    is($node->grab_value('foo:0'),'foo1',"$msg: foo:0 is set");
    is($node->grab_value('class1 lista:0'),'lista1',"$msg: lista:0 is set");
    is($node->grab_value('class1 listb:0'),undef,"$msg: listb:0 is not set");
    is($node->instance->needs_save,0, "$msg: instance has no data to save");
}

my ($model, $trace) = init_test();

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir();

# set_up data
my @ini_data = <DATA>;

my $test1     = 'ini1';
my $wr_dir    = $wr_root->child($test1);
my $etc_dir   = $wr_dir->child('etc');
$etc_dir->mkpath;
my $conf_file = $etc_dir->child("test.ini");
$conf_file->remove;

$conf_file->spew_utf8(@ini_data);

my $i_test = $model->instance(
    instance_name   => 'to_reset',
    root_class_name => 'IniTest',
    root_dir        => $wr_dir,
    model_file      => 'test_ini_backend_model.pl',
);

ok( $i_test, "Created instance" );

my $i_root = $i_test->config_root;
ok( $i_root, "created tree root" );
$i_root->init;
ok( 1, "root init done" );

check($i_root, "before reset");

my $dump = $i_root->dump_tree;
print "Before reset:\n",$dump if $trace;

$i_root->load("foo:=blork1 class1 listb:=blork");

ok($i_root->needs_save, "instance has something to save");

my $new_root = $i_test->reset_config;

ok(1, "config was reset");

check($new_root, "after reset");

is($new_root->dump_tree, $dump, "check dump tree after reset");

ok($i_root->needs_save, "instance has something to save");

memory_cycle_ok( $model, "memory cycle test" );

done_testing;

__DATA__
foo = foo1

[class1]

lista=lista1
