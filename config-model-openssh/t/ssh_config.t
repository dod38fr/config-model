# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-04-15 13:57:49 +0200 (mar, 15 avr 2008) $
# $Revision: 608 $

use ExtUtils::testlib;
use Test::More tests => 9;
use Config::Model ;
use Config::Model::OpenSsh ; # required for tests
use Log::Log4perl qw(:easy) ;
use File::Path ;

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

mkdir('wr_test') unless -d 'wr_test' ;
rmtree('wr_test', { keep_root => 1 }) ;

opendir(TDIR,'data') || die "cannot read dir 'data': $!";

# special global variable used only for tests
my $joe_home = "/home/joe" ;
&Config::Model::OpenSsh::_set_test_ssh_home($joe_home) ; 

sub read_user_ssh {
    my $file = shift ;
    open(IN, $file)||die "can't read $file:$!";
    my @res = grep {/\w/} map { chomp; s/\s+/ /g; $_ ;} <IN> ;
    close (IN);
    return @res ;
}

foreach my $testdir (readdir(TDIR)) {
    next if $testdir =~ /^\./;
    print "Test from directory $testdir\n" if $trace ;
    my $read_dir = "data/$testdir" ;
    my $wr_dir = "wr_test/$testdir" ;
    mkdir($wr_dir) unless -d $wr_dir;

    # special global variable used only for tests
    &Config::Model::OpenSsh::_set_test_ssh_root_file(1);

    my $root_inst = $model->instance (root_class_name   => 'Ssh',
				      instance_name     => 'root_ssh_instance',
				      read_root_dir     => $read_dir,
				      write_root_dir    => $wr_dir,
				     );

    ok($root_inst,"Read /etc/ssh/ssh_config and created instance") ;

    my $root_cfg = $root_inst -> config_root ;

    my $dump =  $root_cfg->dump_tree ();
    print $dump if $trace ;

    like($dump,qr/Host:1/, "check Host section") ;
    like($dump,qr/patterns=foo\.\*,\*\.bar/,"check Host pattern") ;

    $root_inst->write_back() ;
    ok(1,"wrote ssh_config data in $wr_dir") ;

    my $inst2 = $model->instance (root_class_name   => 'Ssh',
				  instance_name     => 'root_ssh_instance2',
				  read_root_dir     => $wr_dir,
				  write_root_dir    => $wr_dir.'2',
                                 );

    my $root2 = $inst2 -> config_root ;
    my $dump2 = $root2 -> dump_tree ();
    print $dump2 if $trace ;

    is_deeply([split /\n/,$dump2],[split /\n/,$dump],
	      "check if both root_ssh dumps are identical") ;

    # now test reading user configuration file on top of root file
    &Config::Model::OpenSsh::_set_test_ssh_root_file(0);

    my $user_inst = $model->instance (root_class_name   => 'Ssh',
				      instance_name     => 'user_ssh_instance',
				      read_root_dir     => "data/$testdir",
				      write_root_dir    => $wr_dir,
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
    my @orig    = read_user_ssh($read_dir.$joe_home.'/.ssh/config') ;
    my @written = read_user_ssh($joe_file) ;
    is_deeply(\@written,\@orig,"check user .ssh/config files") ;

    # write some data
    $user_cfg->load('EnableSSHKeysign=1') ;
    $user_inst->write_back() ;
    unshift @orig,'EnableSSHKeysign yes';
    @written = read_user_ssh($joe_file) ;
    is_deeply(\@written,\@orig,"check user .ssh/config files after modif") ;

    last ;
}
