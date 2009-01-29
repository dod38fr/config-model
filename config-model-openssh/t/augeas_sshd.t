# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-04-15 13:57:49 +0200 (mar, 15 avr 2008) $
# $Revision: 608 $

use ExtUtils::testlib;
use Test::More ;
use Config::Model ;
use Log::Log4perl qw(:easy) ;
use File::Path ;
use File::Copy ;

use warnings;
no warnings qw(once);

use strict;

# workaround Augeas locale bug
if ($ENV{LC_ALL} ne 'C' or $ENV{LANG} ne 'C') {
  $ENV{LC_ALL} = $ENV{LANG} = 'C';
  exec("perl $0 @ARGV");
}

my $arg = shift || '';

my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

Log::Log4perl->easy_init($log ? $TRACE: $WARN);

#$::RD_ERRORS = 1 ;  
#$::RD_WARN   = 1 ;  # unless undefined, also report non-fatal problems
#$::RD_HINT   = 1 ;  # if defined, also suggestion remedies
$::RD_TRACE  = 1 if $arg =~ /p/;

if (eval {require Config::Model::Backend::Augeas; } ) {
    plan tests => 6 ;
}
else {
    plan skip_all => "Config::Model::Backend::Augeas is not installed";
}

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_test';

my $testdir = 'augeas_sshd' ;

# cleanup before tests
rmtree($wr_root);

my @orig = <DATA> ;

my $wr_dir = $wr_root.'/'.$testdir ;
mkpath($wr_dir.'/etc/ssh', { mode => 0755 }) 
  || die "can't mkpath: $!";
open(SSHD,"> $wr_dir/etc/ssh/sshd_config")
  || die "can't open file: $!";
print SSHD @orig ;
close SSHD ;

my $inst = $model->instance (root_class_name   => 'Sshd',
			     instance_name     => 'sshd_instance',
			     root_dir          => $wr_dir,
			    );

ok($inst,"Read $wr_dir/etc/ssh/sshd_config and created instance") ;

my $root = $inst -> config_root ;

my $dump =  $root->dump_tree ();
print "$testdir dump:\n",$dump if $trace ;

$inst->write_back(backend => 'augeas') ;
ok(1,"wrote data in $wr_dir directory") ;

my $wr_file = "$wr_dir/etc/ssh/sshd_config";
open(SSHD2,$wr_file) || die "can't open file $wr_file: $!";
my @new = <SSHD2> ;
close SSHD2 ;

is_deeply(\@new,\@orig,"check written file $wr_file (no modif)") ;

$root->load("HostbasedAuthentication=yes 
             Subsystem:ddftp=/home/dd/bin/ddftp
            ") ;

$inst->write_back(backend => 'augeas') ;
ok(1,"wrote data in $wr_dir") ;

open(SSHD2, $wr_file) || die "can't open file $wr_file: $!";

my @new2 = <SSHD2> ;
close SSHD2 ;

my @mod = @orig;
$mod[38] = "HostbasedAuthentication yes\n";
splice @mod, 76,0, "Subsystem ddftp /home/dd/bin/ddftp\n";

is_deeply(\@new2,\@mod,"check written file $wr_file (with modifs)") ;

__DATA__

# snatched from Debian config file
# Package generated configuration file
# See the sshd(8) manpage for details

# What ports, IPs and protocols we listen for
Port 22
# Use these options to restrict which interfaces/protocols sshd will bind to
#ListenAddress ::
#ListenAddress 0.0.0.0
Protocol 2
# HostKeys for protocol version 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
#Privilege Separation is turned on for security
UsePrivilegeSeparation yes

# Lifetime and size of ephemeral version 1 server key
KeyRegenerationInterval 3600

# Logging
SyslogFacility AUTH
LogLevel INFO

# Authentication:
LoginGraceTime 120
PermitRootLogin yes
StrictModes yes

RSAAuthentication yes
PubkeyAuthentication yes
#AuthorizedKeysFile	%h/.ssh/authorized_keys

# Don't read the user's ~/.rhosts and ~/.shosts files
IgnoreRhosts yes
# For this to work you will also need host keys in /etc/ssh_known_hosts
RhostsRSAAuthentication no
# similar for protocol version 2
HostbasedAuthentication no
# Uncomment if you don't trust ~/.ssh/known_hosts for RhostsRSAAuthentication
#IgnoreUserKnownHosts yes

# To enable empty passwords, change to yes (NOT RECOMMENDED)
PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
ChallengeResponseAuthentication no

# Change to no to disable tunnelled clear text passwords
#PasswordAuthentication yes

# Kerberos options
#KerberosAuthentication no
#KerberosGetAFSToken no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes

X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
#UseLogin no

MaxStartups 10:30:60
#Banner /etc/issue.net

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

Subsystem sftp /usr/lib/openssh/sftp-server

UsePAM yes

AllowUsers foo bar@192.168.0.*

ClientAliveCountMax 5
ClientAliveInterval 300 

