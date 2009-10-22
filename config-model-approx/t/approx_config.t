# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-04-15 13:57:49 +0200 (mar, 15 avr 2008) $
# $Revision: 608 $

use ExtUtils::testlib;
use Test::More tests => 5;
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
my $wr_root = 'wr_test';

my $testdir = 'approx_test' ;

# cleanup before tests
rmtree($wr_root);

my @orig = <DATA> ;

my $wr_dir = $wr_root.'/'.$testdir ;
mkpath($wr_dir.'/etc/approx', { mode => 0755 }) 
  || die "can't mkpath: $!";
open(CONF,"> $wr_dir/etc/approx/approx.conf")
  || die "can't open file: $!";
print CONF @orig ;
close CONF ;

my $inst = $model->instance (root_class_name   => 'Approx',
			     instance_name     => 'approx_instance',
			     root_dir          => $wr_dir,
			    );
my $approx_conf = "$wr_dir/etc/approx/approx.conf";
ok($inst,"Read $approx_conf and created instance") ;

my $cfg = $inst -> config_root ;

my $dump =  $cfg->dump_tree ();
print $dump if $trace ;

my $expect = 'max_rate=100K
verbose=1
distributions:debian=http://ftp.debian.org/debian
distributions:local=file:///my/local/repo
distributions:security=http://security.debian.org/debian-security -
';

is ($dump,$expect,"check data read from approx.conf") ;

$cfg->load("max_rate=200K") ;

$inst->write_back ;

open(APPROX,$approx_conf) || die "Can't open $approx_conf:$!" ;
my $approxlines = join('',<APPROX>) ;
close APPROX;

like($approxlines,qr/200K/,"checked written approx file") ;
like($approxlines,qr/\$verbose/,"new approx file contains new style param") ;

__END__


$max_rate 100K

# old style parameter (before approx 2.9.0)
verbose  1

debian          http://ftp.debian.org/debian
security        http://security.debian.org/debian-security
local           file:///my/local/repo
