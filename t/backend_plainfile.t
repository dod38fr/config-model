# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Test::Memory::Cycle;
use Config::Model;
use File::Path;
use File::Copy;
use Data::Dumper;
use IO::File;

use lib -d 't' ? 't/lib' : 'lib';
use MyTestLib qw/init_test setup_test_dir/;

use warnings;
use strict;

my ($model, $trace) = init_test(shift);

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir();

my $subdir = 'plain/';
mkpath( $wr_root . $subdir, { mode => 0755 } );

$model->create_config_class(
    name    => "WithPlainFile",
    element => [
        [qw/source new/] => {qw/type leaf value_type uniline/},
        clean => { qw/type list/, cargo => {qw/type leaf value_type uniline/} },
    ],
    rw_config => {
        backend    => 'plain_file',
        config_dir => $subdir,
    },
);

my $fh = IO::File->new;
$fh->open( $wr_root . $subdir . 'source', ">" );
$fh->print("2.0\n");
$fh->close;
ok( 1, "wrote source file" );

$fh->open( $wr_root . $subdir . 'clean', ">" );
$fh->print("foo\n*/*/bar\n");
$fh->close;
ok( 1, "wrote clean file" );

my $inst = $model->instance(
    root_class_name => 'WithPlainFile',
    root_dir        => $wr_root,
);

ok( $inst, "Created instance" );

my $root = $inst->config_root;

is( $root->grab_value("source"),  "2.0",     "got correct source value" );
is( $root->grab_value("clean:0"), "foo",     "got clean 0" );
is( $root->grab_value("clean:1"), "*/*/bar", "got clean 1" );

my $load = qq[source="3.0 (quilt)"\nnew="new stuff" clean:2="baz*"\n];

$root->load($load);

$inst->write_back;
ok( 1, "plain file write back done" );

my $new_file = $wr_root . 'plain/new';
ok( -e $new_file, "check that config file $new_file was written" );

is($root->grab('source')->backend_support_annotation(), 0, "check backend annotation support");

# create another instance to read the yaml that was just written
my $i2_plain = $model->instance(
    instance_name   => 'inst2',
    root_class_name => 'WithPlainFile',
    root_dir        => $wr_root,
);

ok( $i2_plain, "Created 2nd instance" );

my $i2_root = $i2_plain->config_root;

my $p2_dump = $i2_root->dump_tree;

is( $p2_dump, $root->dump_tree, "compare original data with 2nd instance data" );
memory_cycle_ok($model, "memory cycles");

done_testing;
