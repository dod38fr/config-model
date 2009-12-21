# -*- cperl -*-

use ExtUtils::testlib;

use Config::Augeas ;
use File::Path ;
use File::Copy ;

use warnings ;
use strict;
use Test::More tests => 23 ;

ok(1,"Compilation done");

# pseudo root were input config file are read
my $r_root = 'augeas-box/';

# pseudo root where config files are written by config-model
my $aug_root = 'augeas-root/';

# cleanup before tests
rmtree($aug_root);
mkpath($aug_root.'etc/ssh/', { mode => 0755 }) || die "Can't mkpath:$!";
copy($r_root.'etc/hosts',$aug_root.'etc/') || die "Can't copy etc/hosts:$!";
copy($r_root.'etc/ssh/sshd_config',$aug_root.'etc/ssh/')
  || die "Can't copy etc/ssh/sshd_config:$!" ;


# check that files were written
foreach my $f (qw!hosts ssh/sshd_config!) {
    my $testfile = $aug_root."etc/$f" ;
    next if -r $testfile ;
    die "Cannot test: file $testfile was not written";
}

my $written_file = $aug_root."etc/hosts.augnew" ;
unlink ($written_file) if -e $written_file ;

my $aug = Config::Augeas->new( root => $aug_root, save => 'newfile' ) ;

ok($aug,"Created new Augeas object");

my $ret = $aug->get("/files/etc/hosts/1/ipaddr") ;

is($ret,'127.0.0.1',"Called get (returned $ret )");

$ret = $aug->get("/files/etc/hosts/1/canonical") ;

is($ret,'localhost',"Called get (returned $ret )");

$aug->set("/files/etc/hosts/2/canonical","newbilbo") ;

ok($aug,"Set new host");

$ret = $aug->get("/files/etc/hosts/2/canonical") ;
is($ret,'newbilbo',"Called get after set (returned $ret )");

$aug->set("/files/etc/hosts/5/ipaddr","192.168.0.4") ;
$aug->set("/files/etc/hosts/5/canonical","gandalf") ;

$ret = $aug->move("/files/etc/hosts/5","/files/etc/hosts/4") ;
is($ret,1,"Called move");

$aug->insert(3 => before => "/files/etc/hosts/4" ) ;

ok($aug,"inserted new host");

$aug->set("/files/etc/hosts/3/ipaddr","192.168.0.3") ;
$aug->set("/files/etc/hosts/3/canonical","gandalf") ;

# stupid value that tests correctly augeas
$aug->set("/files/etc/ssh/sshd_config/Port",0) ; 

$aug->rm("/files/etc/hosts/4") ;
ok($aug,"removed entry");

my @a = $aug->match("/files/etc/hosts/") ;
is_deeply(\@a,["/files/etc/hosts"],"match result") ;

$ret = $aug->count_match("/files/etc/hosts/") ;
is($ret,1,"count_match result") ;

$ret = $aug->save ;
ok($ret,"save done") ;

ok(-e $written_file, "File was written" ) ;

open(SAVED,$written_file) || die "can't read $written_file";
my @expect = ("127.0.0.1 localhost localhost",
	      "192.168.0.1 newbilbo",
	      "192.168.0.3 gandalf",
	     );
my @content = <SAVED> ;
map{ chomp; s/\s+/ /g;} @content ;

is_deeply(\@content,\@expect,"check written file content");

#$aug->print('/files/') ; # print all nodes into $data string

$ret = $aug->defvar(etc => '/files/etc/*') ;
is($ret,2,"defvar /files/etc/*") ;

$ret = $aug->defvar(etc2 => '/files/etc') ;
is($ret,1,"defvar etc2 /files/etc/*") ;

$ret = $aug->get('$etc2/hosts/2/canonical') ;
is($ret,'newbilbo',"Called get defvar (returned $ret )");

my $v = '$etc2/hosts/1/ipaddr';
@a =  $aug->defnode(local => $v,'127.0.0.2') ;
is_deeply(\@a,[1,0],"defnode $v") ;

my $ec= $aug->error ;
is($ec, 'noerror', "no error found") ;
my $emsg= $aug->error_minor_message ;
is($emsg, undef, "no error message") ;

$ret = $aug->get('/files/[blast]') ;
$ec= $aug->error ;
is($ec, 'pathx', "found path error") ;
$emsg= $aug->error_minor_message ;
ok($emsg, "error_minor_message: $emsg") ;
$emsg= $aug->error_details ;
ok($emsg, "error_details: $emsg") ;

#$aug->print('') ;
