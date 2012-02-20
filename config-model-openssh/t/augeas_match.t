use ExtUtils::testlib;
use Test::More ;
use Config::Model ;
use Log::Log4perl qw(:easy) ;
use File::Path ;
use File::Copy ;
use Test::Differences ;

use warnings;
no warnings qw(once);

use strict;


my $arg = shift || '';

my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

if (eval {require Config::Model::Backend::Augeas; } ) {
    # workaround Augeas locale bug
    no warnings qw/uninitialized/;
    if ($ENV{LC_ALL} ne 'C' or $ENV{LANG} ne 'C') {
	$ENV{LC_ALL} = $ENV{LANG} = 'C';
	my $inc = join(' ',map("-I$_",@INC)) ;
	exec("$^X $inc $0 @ARGV");
    }
    plan tests => 7 ;
}
else {
    plan skip_all => "Config::Model::Backend::Augeas is not installed";
}

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

my $testdir = 'augeas_match' ;

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

$inst->write_back(backend => 'augeas', force => 1) ;
ok(1,"wrote data in $wr_dir") ;

open(SSHD2,"$wr_dir/etc/ssh/sshd_config")
  || die "can't open file: $!";
my @new = <SSHD2> ;
close SSHD2 ;

TODO: {
local $TODO = "The last X11Forwarding is a computed default value. As such, it is
written in the file. It would be smarter not to write it. For this,
Config::Model need to support computed value that provide a
'built_in' computed value instead of 'default' computed value. A
built_in value will not be written in sshd_config file";


eq_or_diff(\@new,\@orig,"check written file (no modif)") ;

# remove also this line with the todo
push @orig, "X11Forwarding yes\n";
}



eq_or_diff(\@new,\@orig,"check written file with workaround (no modif )") ;


$root->load("HostbasedAuthentication=yes 
             Subsystem:ddftp=/home/dd/bin/ddftp
            ") ;

$inst->write_back(backend => 'augeas') ;
ok(1,"wrote data in $wr_dir") ;

open(SSHD2,"$wr_dir/etc/ssh/sshd_config")
  || die "can't open file: $!";

my @new2 = <SSHD2> ;
close SSHD2 ;

my @mod = @orig;
splice @mod,1,0, "HostbasedAuthentication yes\n",
  "Subsystem ddftp /home/dd/bin/ddftp\n";

eq_or_diff(\@new2,\@mod,"check written file with workaround (and modifs)") ;

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
