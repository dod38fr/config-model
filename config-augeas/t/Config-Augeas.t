# -*- cperl -*-

use ExtUtils::testlib;

use Config::Augeas ;

use warnings ;
use strict;
use Test::More tests => 14 ;


ok(1,"Compilation done");

my $aug_root = 'augeas-box/';
my $lens_dir ;

# work-around augeas 0.2.0. Hard-coded path will be removed
foreach my $d ('/usr/local/share/augeas/lenses/') {
    $lens_dir = $d if -d $d;
}

my $aug = Config::Augeas->new( root => $aug_root, loadpath => $lens_dir ) ;

ok($aug,"Created new Augeas object");

my $ret = $aug->get("/files/etc/hosts/1/ipaddr") ;

is($ret,'127.0.0.1',"Called get (returned $ret )");

$ret = $aug->get("/files/etc/hosts/1/canonical") ;

is($ret,'localhost',"Called get (returned $ret )");

$aug->set("/files/etc/hosts/2/ipaddr","192.168.0.1") ;
$aug->set("/files/etc/hosts/2/canonical","bilbo") ;

ok($aug,"Set new host");

$ret = $aug->get("/files/etc/hosts/2/canonical") ;
is($ret,'bilbo',"Called get after set (returned $ret )");

$aug->insert(inserted_host => before => "/files/etc/hosts/1" ) ;

ok($aug,"insert new label");


$aug->set("/files/etc/hosts/3/ipaddr","192.168.0.2") ;
$aug->rm("/files/etc/hosts/3") ;
ok($aug,"removed entry");

my @a = $aug->match("/files/etc/hosts/") ;
is_deeply(\@a,["/files/etc/hosts"],"match result") ;

$ret = $aug->count_match("/files/etc/hosts/") ;
is($ret,1,"count_match result") ;

$ret = $aug->save ;
ok($ret,"save done") ;

$ENV{AUG_ROOT} = $aug_root;
$ENV{AUGEAS_LENS_LIB}= $lens_dir if defined $lens_dir;

# work-around: augeas 0.2.0 does not understand env variables
# this test will fail with auges 0.2.0 installed in /usr/local
my $aug2 = Config::Augeas->new(root => $aug_root) ;

ok($aug2,"Created 2nd Augeas object");

$ret = $aug2->get("/files/etc/hosts/1/ipaddr") ;

is($ret,'127.0.0.1',"Called get (returned $ret )");

$ret = $aug2->get("/files/etc/hosts/1/canonical") ;

is($ret,'localhost',"Called get (returned $ret )");
