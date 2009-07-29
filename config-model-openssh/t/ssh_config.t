# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-04-15 13:57:49 +0200 (mar, 15 avr 2008) $
# $Revision: 608 $

use ExtUtils::testlib;
use Test::More tests => 14;
use Config::Model ;
use Config::Model::OpenSsh ; # required for tests
use Log::Log4perl qw(:easy) ;
use File::Path ;
use English;

use warnings;
#no warnings qw(once);

use strict;

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

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_test';

my $testdir = 'ssh_test' ;

# cleanup before tests
rmtree($wr_root);

my @orig = <DATA> ;

my $wr_dir = $wr_root.'/'.$testdir ;
mkpath($wr_dir.'/etc/ssh', { mode => 0755 }) 
  || die "can't mkpath: $!";
open(SSHD,"> $wr_dir/etc/ssh/ssh_config")
  || die "can't open file: $!";
print SSHD @orig ;
close SSHD ;

# special global variable used only for tests
my $joe_home = "/home/joe" ;
&Config::Model::OpenSsh::_set_test_ssh_home($joe_home) ; 

# set up Joe's environment
my $joe_ssh = $wr_dir.$joe_home.'/.ssh';
mkpath($joe_ssh, { mode => 0755 }) || die "can't mkpath $joe_ssh: $!";
open(JOE,"> $joe_ssh/config") || die "can't open file: $!";
print JOE "Host mine.bar\n\nIdentityFile ~/.ssh/mine\n" ;
close JOE ;

sub read_user_ssh {
    my $file = shift ;
    open(IN, $file)||die "can't read $file:$!";
    my @res = grep {/\w/} map { chomp; s/\s+/ /g; $_ ;} <IN> ;
    close (IN);
    return @res ;
}

print "Test from directory $testdir\n" if $trace ;

# special global variable used only for tests
&Config::Model::OpenSsh::_set_test_ssh_root_file(1);

my $root_inst = $model->instance (root_class_name   => 'Ssh',
				  instance_name     => 'root_ssh_instance',
				  root_dir          => $wr_dir,
				 );

ok($root_inst,"Read $wr_dir/etc/ssh/ssh_config and created instance") ;

my $root_cfg = $root_inst -> config_root ;

my $dump =  $root_cfg->dump_tree ();
print $dump if $trace ;

like($dump,qr/Host:1/, "check Host section") ;
like($dump,qr/patterns=foo\.\*,\*\.bar/,"check Host pattern") ;

$root_inst->write_back() ;
ok(1,"wrote ssh_config data in $wr_dir") ;

my $inst2 = $model->instance (root_class_name   => 'Ssh',
			      instance_name     => 'root_ssh_instance2',
			      root_dir          => $wr_dir,
			     );

my $root2 = $inst2 -> config_root ;
my $dump2 = $root2 -> dump_tree ();
print $dump2 if $trace ;

is_deeply([split /\n/,$dump2],[split /\n/,$dump],
	  "check if both root_ssh dumps are identical") ;

SKIP: {
    skip "user tests when test is run as root", 8
       unless $EUID > 0 ;


    # now test reading user configuration file on top of root file
    &Config::Model::OpenSsh::_set_test_ssh_root_file(0);

    my $user_inst = $model->instance (root_class_name   => 'Ssh',
				      instance_name     => 'user_ssh_instance',
				      root_dir          => $wr_dir,
				     );

    ok($user_inst,"Read user .ssh/config and created instance") ;

    my $user_cfg = $user_inst -> config_root ;

    $dump =  $user_cfg->dump_tree (mode => 'full' );
    print $dump if $trace ;

    like($dump,qr/Host:1/, "check Host section") ;
    like($dump,qr/patterns=foo\.\*,\*\.bar/,"check root Host pattern") ;
    like($dump,qr/patterns=mine.bar/,"check user Host pattern") ;

    #require Tk::ObjScanner; Tk::ObjScanner::scan_object($user_cfg) ;
    $user_inst->write_back() ;
    my $joe_file = $wr_dir.$joe_home.'/.ssh/config' ;
    ok(1,"wrote user .ssh/config data in $joe_file") ;

    ok(-e $joe_file,"Found $joe_file") ;

    # compare original and written file
    my @joe_orig    = read_user_ssh($wr_dir.$joe_home.'/.ssh/config') ;
    my @joe_written = read_user_ssh($joe_file) ;
    is_deeply(\@joe_written,\@joe_orig,"check user .ssh/config files") ;

    # write some data
    $user_cfg->load('EnableSSHKeysign=1') ;
    $user_inst->write_back() ;
    unshift @joe_orig,'EnableSSHKeysign yes';
    @joe_written = read_user_ssh($joe_file) ;
    is_deeply(\@joe_written,\@joe_orig,"check user .ssh/config files after modif") ;
}

__END__



Host *
#   ForwardAgent no
#   ForwardX11 no
#   ForwardX11Trusted yes
#   RhostsRSAAuthentication no
#   RSAAuthentication yes
#   PasswordAuthentication yes
#   HostbasedAuthentication no
#   GSSAPIAuthentication no
#   GSSAPIDelegateCredentials no
#   GSSAPIKeyExchange no
#   GSSAPITrustDNS no
#   BatchMode no
#   CheckHostIP yes
#   AddressFamily any
#   ConnectTimeout 0
#   StrictHostKeyChecking ask
#   IdentityFile ~/.ssh/identity
#   IdentityFile ~/.ssh/id_rsa
#   IdentityFile ~/.ssh/id_dsa
    Port 1022
#   Protocol 2,1
#   Cipher 3des
    Ciphers aes192-cbc,aes128-cbc,3des-cbc,blowfish-cbc,aes256-cbc
#   MACs hmac-md5,hmac-sha1,umac-64@openssh.com,hmac-ripemd160
#   EscapeChar ~
#   Tunnel no
#   TunnelDevice any:any
#   PermitLocalCommand no
    SendEnv LANG LC_*
    HashKnownHosts yes
    GSSAPIAuthentication yes
    GSSAPIDelegateCredentials no

Host foo.*,*.bar
    ForwardX11 yes
    SendEnv FOO BAR
