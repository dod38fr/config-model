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
			     backend => 'custom',
			    );

ok($inst,"Read $wr_dir/etc/ssh/sshd_config and created instance") ;

my $root = $inst -> config_root ;

my $dump =  $root->dump_tree ();
print "First $testdir dump:\n",$dump if $trace ;

#like($dump,qr/Match:0/, "check Match section") if $testdir =~ /match/;

$root -> load("Port=2222 
               HostbasedAuthentication=yes
               Subsystem:ddftp=/home/dd/bin/ddftp
               Match:1 Condition Host=elysee.*
              ") ; 


$inst->write_back() ;
ok(1,"wrote data in $wr_dir") ;


# copy data in wr_dir2
my $wr_dir2 = $wr_dir.'b' ;
mkpath($wr_dir2.'/etc/ssh/', { mode => 0755 }) ;
copy($wr_dir.'/etc/ssh/sshd_config',$wr_dir2.'/etc/ssh/') ;

my $inst2 = $model->instance (root_class_name   => 'Sshd',
			      instance_name     => 'sshd_instance2',
			      root_dir          => $wr_dir2,
			      backend => 'custom',
			     );

ok($inst2,"Read $wr_dir2/etc/ssh/sshd_config and created instance") ;

my $root2 = $inst2 -> config_root ;
my $dump2 = $root2 -> dump_tree ();
print "Second $testdir dump:\n",$dump2 if $trace ;

my @mod = split /\n/,$dump ;
unshift @mod, 'HostbasedAuthentication=yes', 'Port=2222';
splice @mod,2,0,'Subsystem:ddftp=/home/dd/bin/ddftp';
splice @mod,13,1,'    Group="pres.*"','    Host="elysee.*" -';
is_deeply([split /\n/,$dump2],\@mod, "check if both dumps are consistent") ;


__DATA__

X11Forwarding        yes

Match  User domi
AllowTcpForwarding   yes
PasswordAuthentication yes
RhostsRSAAuthentication no
RSAAuthentication    yes
X11DisplayOffset     10
X11Forwarding        yes

# sarkomment
Match User sarko Group pres.*
Banner /etc/bienvenue.txt
X11Forwarding no

# some comment
Match User bush Group pres.* Host white.house.*
Banner /etc/welcome.txt
