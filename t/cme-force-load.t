# -*- cperl -*-
use strict;
use warnings;
use Path::Tiny;
use Test::Exception;
use Test::More;
use 5.10.1;

use Config::Model qw/cme/;
use Config::Model::Tester::Setup qw/init_test  setup_test_dir/;

use lib "t/lib";

my ($model, $trace) = init_test();

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir();

my $etc_dir   = $wr_root->child('etc');

my $conf_file = $etc_dir->child('popularity-contest.conf');

# popcon data contains an error
my @orig = <DATA>;

$etc_dir->mkpath;
$conf_file->spew(@orig);

my $instance = cme(
    application => 'popcon',
    root_dir => $wr_root,
    'force-load' => 1,
);

ok($instance,"new instance created");

my $root = $instance->config_root;
$root->init;
ok($root, "loaded erroneous data");

my $tree = $root->dump_tree(check => 'no');
say $tree if $trace;

throws_ok { $root->dump_tree; }
    'Config::Model::Exception::WrongValue',
    "barfs on bad value";
print "normal error:\n", $@, "\n" if $trace;

cme('popcon')->modify("PARTICIPATE=yes");

ok( $root->dump_tree(check => 'no'), "can dump fixed tree");

$instance->save();
ok(1,"data saved");

my $new_data = $conf_file->slurp;
like $new_data,   qr/PARTICIPATE="yes"/,      "updated config data";

done_testing;

__END__
# Config file for Debian's popularity-contest package.
#
# To change this file, use:
#        dpkg-reconfigure popularity-contest

## should be removed

MY_HOSTID="aaaaaaaaaaaaaaaaaaaa"
# that's not a boolean value
PARTICIPATE="maybe"
USEHTTP="yes" # always http
DAY="6"

