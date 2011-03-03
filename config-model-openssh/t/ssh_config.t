# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 20;
use Config::Model ;
use Config::Model::Backend::OpenSsh::Ssh ; # required for tests
use Log::Log4perl qw(:easy) ;
use File::Path ;
use English;


use warnings;
#no warnings qw(once);

use strict;

my $arg = shift || '';

my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
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
&Config::Model::Backend::OpenSsh::Ssh::_set_test_ssh_home($joe_home) ; 

# set up Joe's environment
my $joe_ssh = $wr_dir.$joe_home.'/.ssh';
mkpath($joe_ssh, { mode => 0755 }) || die "can't mkpath $joe_ssh: $!";
open(JOE,"> $joe_ssh/config") || die "can't open file: $!";
print JOE "Host mine.bar\n\nIdentityFile ~/.ssh/mine\n" ;
close JOE ;

sub read_user_ssh {
    my $file = shift ;
    open(IN, $file)||die "can't read $file:$!";
    my @res = grep {/\w/} map { chomp; s/\s+/ /g; $_ ;} grep { not /##/ } <IN> ;
    close (IN);
    return @res ;
}

print "Test from directory $testdir\n" if $trace ;

# special global variable used only for tests
&Config::Model::Backend::OpenSsh::Ssh::_set_test_ssh_root_file(1);

my $root_inst = $model->instance (root_class_name   => 'Ssh',
				  instance_name     => 'root_ssh_instance',
				  root_dir          => $wr_dir,
				 );

ok($root_inst,"Read $wr_dir/etc/ssh/ssh_config and created instance") ;

my $root_cfg = $root_inst -> config_root ;

my $dump =  $root_cfg->dump_tree ();
print $dump if $trace ;

like($dump,qr/^#"ssh global comment"/, "check global comment pattern") ;
like($dump,qr/Ciphers=aes192-cbc,aes128-cbc,3des-cbc,blowfish-cbc,aes256-cbc#"  Protocol 2,1\s+Cipher 3des"/,"check Ciphers comment");
like($dump,qr/SendEnv#"  PermitLocalCommand no"/,"check SendEnv comment");
like($dump,qr/Host:"foo\.\*,\*\.bar"/, "check Host pattern") ;
like($dump,qr/LocalForward:0\s+port=20022/, "check user LocalForward port") ;
like($dump,qr/host=10.3.244.4/, "check user LocalForward host") ;
like($dump,qr/LocalForward:1#"IPv6 example"\s+ipv6=1/, "check user LocalForward ipv6") ;
like($dump,qr/port=22080/, "check user LocalForward port ipv6") ;
like($dump,qr/host=2001:0db8:85a3:0000:0000:8a2e:0370:7334/, 
     "check user LocalForward host ipv6") ;

$root_inst->write_back() ; ok(1,"wrote ssh_config data in $wr_dir") ;

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
    &Config::Model::Backend::OpenSsh::Ssh::_set_test_ssh_root_file(0);

    my $user_inst = $model->instance (root_class_name   => 'Ssh',
				      instance_name     => 'user_ssh_instance',
				      root_dir          => $wr_dir,
				     );

    ok($user_inst,"Read user .ssh/config and created instance") ;

    my $user_cfg = $user_inst -> config_root ;

    $dump =  $user_cfg->dump_tree (mode => 'full' );
    print $dump if $trace ;

    like($dump,qr/Host:"foo\.\*,\*\.bar"/,"check root Host pattern") ;
    like($dump,qr/Host:mine.bar/,"check user Host pattern") ;

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
# ssh global comment


Host *
#   ForwardAgent no
#   ForwardX11 no
    Port 1022
#   Protocol 2,1
#   Cipher 3des
    Ciphers aes192-cbc,aes128-cbc,3des-cbc,blowfish-cbc,aes256-cbc
#   PermitLocalCommand no
    SendEnv LANG LC_*
    HashKnownHosts yes
    GSSAPIAuthentication yes
    GSSAPIDelegateCredentials no

# foo bar big
# comment
Host foo.*,*.bar
    # for and bar have X11
    ForwardX11 yes
    SendEnv FOO BAR

Host *.gre.hp.com
ForwardX11           yes
User                 tester

Host picosgw
ForwardAgent         yes
HostName             sshgw.truc.bidule
IdentityFile         ~/.ssh/%r
LocalForward         20022         10.3.244.4:22
# IPv6 example
LocalForward         all.com/22080       2001:0db8:85a3:0000:0000:8a2e:0370:7334/80
User                 k0013

Host picos
ForwardX11           yes
HostName             localhost
Port                 20022
User                 ocad

