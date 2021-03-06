# -*- cperl -*-

use ExtUtils::testlib;
use List::MoreUtils qw/any/;
use Test::More;
use Path::Tiny;

use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test  setup_test_dir/;
use Config;

use warnings;
use strict;
use lib "t/lib";

# Config::Model::FuseUI is loaded later within an eval

if ( $Config{osname} ne 'linux' ) {
    plan skip_all => "Not a Linux system";
}

my @lsmod = eval { `lsmod`; };

if ($@) {
    plan skip_all => "Cannot check is fuse kernel module is loaded: $@";
}

if ( not any {/fuse/} @lsmod ) {
    plan skip_all => "fuse kernel module is not loaded";
}

if ( system(q!bash -c 'type -p fusermount' > /dev/null!) != 0 ) {
    plan skip_all => "fusermount not found";
}

my $umount_str = `bash -c 'umount --version'`;
my ($umount_v) = $umount_str =~ / (\d+\.\d+)/;
if ( $umount_v + 0 < 2.18 ) {
    plan skip_all => "Did not find umount with version >= 2.18";
}

eval { require Config::Model::FuseUI; };
if ($@) {
    plan skip_all => "Config::Model::FuseUI or Fuse is not installed";
}
else {
    # the forked process prints an ok, hence done_testing cannot be used
    plan tests => 17;
}


# required to handle warnings in forked process
#local $SIG{__WARN__} = sub { die $_[0] unless $_[0] =~ /deprecated/ };

use Data::Dumper;
use POSIX ":sys_wait_h";

my ($model, $trace, $args) = init_test('fuse_debug');
my $wr_root = setup_test_dir();


my $fused = $wr_root->child('fused');
$fused->mkpath( { mode => oct(755) } );

$model->load( Master => 'Config/Model/models/Master.pl' );

$model->augment_config_class(
    name    => 'Master',
    element => [
        'a_boolean' => { type => 'leaf', value_type => 'boolean', default => 0 },
    ],
);

my $inst = $model->instance( root_class_name => 'Master' );
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - std_id:"a/c" X=Av - a_string="toto tata"';
ok( $root->load( step => $step ), "set up data in tree with '$step'" );

my $ui = Config::Model::FuseUI->new(
    root            => $root,
    mountpoint      => "$fused",
    dir_char_mockup => '\\',
);
my $dir_char_mockup = $ui->dir_char_mockup;

ok( $ui, "Created ui (dir mockup is $dir_char_mockup)" );

# now fork
my $pid = fork;

if ( defined $pid and $pid == 0 ) {

    # child process, just run fuse and wait for exit
    $ui->run_loop( debug => $args->{fuse_debug} );
    exit;
}

# WARNING: the child process has its own copy of the config tree
# there's no use in modifying the tree on the parent process.

# wait for fuse to do its job
sleep 1;

# child process, continue tests
my @content = sort map { $_->relative($fused); } $fused->children;
is_deeply( \@content, [ sort $root->get_element_name() ], "check $fused content" );

my $std_id = $fused->child('std_id');
@content = sort map { $_->relative($std_id); } $std_id->children;
my @std_id_elements = sort $root->fetch_element('std_id')->fetch_all_indexes();
for ( @std_id_elements ) { s(/){$dir_char_mockup}g; };
is_deeply( \@content, \@std_id_elements, "check $std_id content (@content)" );

is(
    $fused->child('a_string')->slurp,
    $root->grab_value('a_string') . "\n",
    "check a_string content"
);
my $a_string_fhw = $fused->child('a_string')->openw;
$a_string_fhw->print("foo bar");
$a_string_fhw->close;

is( $fused->child('a_string')->slurp, "foo bar\n", "check new a_string content" );

$std_id->child('cd')->mkpath();
ok( 1, "mkpath on cd dir done" );
@content = sort map { $_->relative($std_id); } $std_id->children;
is_deeply( \@content, [ @std_id_elements, 'cd' ], "check $std_id new content (@content)" );

$std_id->child('cd')->remove_tree();
ok( 1, "remove_tree on cd dir done" );
@content = sort map { $_->relative($std_id); } $std_id->children;
is_deeply( \@content, \@std_id_elements, "check $std_id content after rmdir (@content)" );

is( $fused->child('a_boolean')->slurp, "0\n", "check new a_boolean content" );
my $a_boolean_fhw = $fused->child('a_boolean')->openw;
$a_boolean_fhw->print("1");
$a_boolean_fhw->close;
is( $fused->child('a_boolean')->slurp, "1\n", "check new a_boolean content (set to 1)" );

$a_boolean_fhw = $fused->child('a_boolean')->openw;
$a_boolean_fhw->print("a");
$a_boolean_fhw->close;
is( $fused->child('a_boolean')->slurp, "\n", "check new a_boolean content (blank after error)" );

END {
    if ($pid) {

        # run this only in parent process
        # umount so child process will exit
        system("fusermount -u $fused");

        # inspired from perlipc man page
        my $child;
        while ( ( $child = wait ) > 0 ) {
            ok( 1, "Process pid $child done" );
        }
    }
    exit;
}

memory_cycle_ok( $model, "memory cycles" );
