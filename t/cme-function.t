# -*- cperl -*-
use strict;
use warnings;
use Path::Tiny;

use Test::More;
use Config::Model qw/cme/;

# pseudo root where config files are written by config-model
my $wr_root = path('wr_root_p/cme');

# cleanup before tests
$wr_root->remove_tree;

my $wr_dir    = $wr_root->child('popcon');
my $etc_dir   = $wr_dir->child('etc');

my $conf_file = $etc_dir->child('popularity-contest.conf');

# put popcon data in place
my @orig = <DATA>;

$etc_dir->mkpath;
$conf_file->spew(@orig);

{
    my $instance = cme(
        application => 'popcon',
        root_dir => $wr_dir->stringify,
        canonical => 1,
    );

    ok($instance,"new instance created");
}

{
    my $instance = cme('popcon');
    ok($instance,"found instance created above");

    # test minimal modif (re-order)
    $instance->save(force => 1);
    ok(1,"data saved");
}

my $new_data = $conf_file->slurp;
like   $new_data, qr/cme/,       "updated header";
like   $new_data, qr/yes"\nMY/, "reordered file";
unlike $new_data, qr/removed/,   "double comment is removed";

cme('popcon')->modify("PARTICIPATE=no");

ok(1,"load done and saved");


$new_data = $conf_file->slurp;
like $new_data,   qr/PARTICIPATE="no"/,      "updated config data";

done_testing;

__END__
# Config file for Debian's popularity-contest package.
#
# To change this file, use:
#        dpkg-reconfigure popularity-contest

## should be removed

MY_HOSTID="aaaaaaaaaaaaaaaaaaaa"
# we participate
PARTICIPATE="yes"
USEHTTP="yes" # always http
DAY="6"

