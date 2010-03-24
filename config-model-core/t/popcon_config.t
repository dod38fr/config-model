# -*- cperl -*-

use ExtUtils::testlib;
use Test::More skip_all => 'unfinished';#tests => 5;
use Config::Model ;
use Log::Log4perl qw(:easy) ;
use File::Path ;

use warnings;

use strict;

my $arg = shift || '';

my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

Log::Log4perl->easy_init($log ? $TRACE: $WARN);

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root';

my $testdir = 'popcon_test' ;

# cleanup before tests
rmtree($wr_root);


my @orig = <DATA> ;

my $wr_dir = $wr_root.'/'.$testdir ;
my $conf_file = "$wr_dir/etc/popularity-contest.conf" ;

mkpath($wr_dir.'/etc', { mode => 0755 }) 
  || die "can't mkpath: $!";
open(CONF,"> $conf_file" ) || die "can't open $conf_file: $!";
print CONF @orig ;
close CONF ;

my $inst = $model->instance (root_class_name   => 'PopCon',
			     root_dir          => $wr_dir,
			    );
ok($inst,"Read $conf_file and created instance") ;

my $cfg = $inst -> config_root ;

my $dump =  $cfg->dump_tree ();
print $dump if $trace ;

my $expect = 'max_rate=100K
verbose=1
distributions:debian=http://ftp.debian.org/debian
distributions:local=file:///my/local/repo
distributions:security=http://security.debian.org/debian-security -
';

is ($dump,$expect,"check data read from popcon.conf") ;

$cfg->load("max_rate=200K") ;

$inst->write_back ;

open(POPCON,$conf_file) || die "Can't open $conf_file:$!" ;
my $popconlines = join('',<POPCON>) ;
close POPCON;

like($popconlines,qr/200K/,"checked written popcon file") ;
like($popconlines,qr/\$verbose/,"new popcon file contains new style param") ;

__END__


# Config file for Debian's popularity-contest package.
#
# To change this file, use:
#        dpkg-reconfigure popularity-contest
#
# You can also edit it by hand, if you so choose.
#
# See /usr/share/popularity-contest/default.conf for more info
# on the options.

MY_HOSTID="aaaaaaaaaaaaaaaaaaaa"
PARTICIPATE="yes"
USEHTTP="yes"
DAY="6"
