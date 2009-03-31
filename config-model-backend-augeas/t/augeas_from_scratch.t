# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-07-04 16:14:06 +0200 (Fri, 04 Jul 2008) $
# $Revision: 846 $

# test augeas backend 

use ExtUtils::testlib;
use Test::More ;
use Config::Model;
use File::Path;
use File::Copy ;
use Data::Dumper ;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

# workaround Augeas locale bug
if ($ENV{LC_ALL} ne 'C' or $ENV{LANG} ne 'C') {
  $ENV{LC_ALL} = $ENV{LANG} = 'C';
  exec("perl $0 @ARGV");
}

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

$model = Config::Model -> new (legacy => 'ignore',) ;

eval { require Config::Augeas ;} ;
if ( $@ ) {
    plan skip_all => 'Config::Augeas is not installed';
}
else {
    plan tests => 4;
}

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root/';

# cleanup before tests
rmtree($wr_root);
mkpath($wr_root.'etc/ssh/', { mode => 0755 }) ;

# set_up data
do "t/test_model.pl" ;

my $have_pkg_config = `pkg-config --version` || '';
chomp $have_pkg_config ;

my $aug_version = $have_pkg_config ? `pkg-config --modversion augeas` : '' ;
chomp $aug_version ;

my $skip =  (not $have_pkg_config)  ? 'pkgconfig is not installed'
         :  $aug_version le '0.3.1' ? 'Need Augeas library > 0.3.1'
         :                            '';

SKIP: {
    skip $skip , 5 if $skip ;

my $i_sshd = $model->instance(instance_name    => 'sshd_inst',
			      root_class_name  => 'Sshd',
			      root_dir         => $wr_root ,
			     );

ok( $i_sshd, "Created instance for sshd" );

ok( $i_sshd, "Created instance for /etc/ssh/sshd_config" );

my $sshd_root = $i_sshd->config_root ;

my $ssh_augeas_obj = $sshd_root->{backend}{augeas}->_augeas_object ;

$ssh_augeas_obj->print('/files/etc/ssh/sshd_config/*') if $trace;
#my @aug_content = $ssh_augeas_obj->match("/files/etc/ssh/sshd_config/*") ;
#print join("\n",@aug_content) ;

# change data content, '~' is like a splice, 'record~0' like a "shift"
$sshd_root->load("HostbasedAuthentication=yes 
                  Subsystem:ddftp=/home/dd/bin/ddftp
                  ") ;

my $dump = $sshd_root->dump_tree ;
print $dump if $trace ;

$i_sshd->write_back ;

my @mod = ("HostbasedAuthentication yes\n",
	   "Protocol 1,2\n",
	   "Subsystem ddftp /home/dd/bin/ddftp\n"
	  );

my $aug_sshd_file      = $wr_root.'etc/ssh/sshd_config';
open(AUG,$aug_sshd_file) || die "Can't open $aug_sshd_file:$!"; 
is_deeply([<AUG>],\@mod,"check content of $aug_sshd_file") ;
close AUG;


} # end SKIP section
