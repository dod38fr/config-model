# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 10;
use Test::Memory::Cycle;
use Config::Model ;
use Log::Log4perl qw(:easy) ;
use File::Path ;

use warnings;

use strict;

my $arg = shift || '';

my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

Log::Log4perl->easy_init($log ? $TRACE: $WARN);

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root';


# cleanup before tests
rmtree($wr_root);


my @orig = <DATA> ;

my $test1 = 'popcon1' ;
my $wr_dir = $wr_root.'/'.$test1 ;
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

my $expect = '#"Config file for Debian\'s popularity-contest package.

To change this file, use:
       dpkg-reconfigure popularity-contest"
PARTICIPATE=yes#"we participate"
USEHTTP#"always http"
MY_HOSTID=aaaaaaaaaaaaaaaaaaaa
DAY=6 -
';

is ($dump,$expect,"check data read from popcon.conf") ;

$cfg->load("MY_HOSTID=bbbbbbbb") ;

$inst->write_back ;

open(POPCON,$conf_file) || die "Can't open $conf_file:$!" ;
my $popconlines = join('',<POPCON>) ;
close POPCON;

like($popconlines,qr/bbbbbbbb/,"checked written popcon file") ;
like($popconlines,qr/dpkg-reconfigure/,"checked commentns in written popcon file") ;

# test instance loaded with saved config file
my $test2 = 'popcon2' ;
my $inst2 = $model->instance (root_class_name   => 'PopCon',
			     instance_name     => $test2 ,
			     root_dir          => $wr_dir,
			    );
ok($inst2,"Created 2nd instance") ;

my $cfg2 = $inst2 -> config_root ;
$cfg2->load("MY_HOSTID=aaaaaaaaaaaaaaaaaaaa") ;
is($cfg2->dump_tree , $expect, "check data read from new popcon.conf") ;


## test instance loaded with dump string
my $test3 = 'popcon3' ;
my $wr_dir3 = $wr_root.'/'.$test3 ;

mkpath($wr_dir3.'/etc', { mode => 0755 }) 
  || die "can't mkpath: $!";

my $conf_file3 = "$wr_dir3/etc/popularity-contest.conf" ;
open(CONF,"> $conf_file3" ) || die "can't open $conf_file3: $!";
print CONF "## 3 nd test" ;
close CONF ;

my $inst3 = $model->instance (root_class_name   => 'PopCon',
			     instance_name     => $test3 ,
			     root_dir          => $wr_dir3,
			    );
ok($inst3,"Created 3nd instance") ;

my $cfg3 = $inst3 -> config_root ;
$cfg3->load($dump) ;
ok(1,"loaded 3nd instance with dump from 1st instance");
$cfg2->load("MY_HOSTID=bbbbbbbb") ;

memory_cycle_ok($model);

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
