# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 5;
use Config::Model ;
use Log::Log4perl qw(:easy) ;
use File::Path ;
use File::Copy ;

use warnings;
no warnings qw(once);

use strict;

my $arg = shift @ARGV || '';

my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($log ? $DEBUG: $ERROR);
}

# trap warning if Augeas backend is not installed
if (not  eval {require Config::Model::Backend::Augeas; } ) {
    # do not use Test::Warnings with this
    $SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /unknown backend/};
}

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_test';

my $testdir = 'custom_sshd' ;

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
			     backend => 'OpenSsh::Sshd',
			    );

ok($inst,"Read $wr_dir/etc/ssh/sshd_config and created instance") ;

my $root = $inst -> config_root ;

my $dump =  $root->dump_tree ();
print "First $testdir dump:\n",$dump if $trace ;

#like($dump,qr/Match:0/, "check Match section") if $testdir =~ /match/;

$root -> load("Port=2222") ; 


$inst->write_back() ;
ok(1,"wrote data in $wr_dir") ;


# copy data in wr_dir2
my $wr_dir2 = $wr_dir.'b' ;
mkpath($wr_dir2.'/etc/ssh/', { mode => 0755 }) ;
copy($wr_dir.'/etc/ssh/sshd_config',$wr_dir2.'/etc/ssh/') ;

my $inst2 = $model->instance (root_class_name   => 'Sshd',
			      instance_name     => 'sshd_instance2',
			      root_dir          => $wr_dir2,
			      backend => 'OpenSsh::Sshd',
			     );

ok($inst2,"Read $wr_dir2/etc/ssh/sshd_config and created instance") ;

my $root2 = $inst2 -> config_root ;
my $dump2 = $root2 -> dump_tree ();
print "Second $testdir dump:",$dump2 if $trace ;

my @mod = split /\n/,$dump ;
$mod[6] = 'Port=2222';
is_deeply([split /\n/,$dump2],\@mod, "check if both dumps are consistent") ;


__DATA__

# snatched from Debian config file
# Package generated configuration file
# See the sshd(8) manpage for details

# What ports, IPs and protocols we listen for
Port 221
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

