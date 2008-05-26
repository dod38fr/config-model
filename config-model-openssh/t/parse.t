# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-04-15 13:57:49 +0200 (mar, 15 avr 2008) $
# $Revision: 608 $

use ExtUtils::testlib;
use Test::More tests => 5;
use Config::Model ;
use Log::Log4perl qw(:easy) ;

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

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

mkdir('wr_test') unless -d 'wr_test' ;

opendir(TDIR,'data') || die "cannot read dir 'data': $!";

foreach my $testdir (readdir(TDIR)) {
    next if $testdir =~ /^\./;
    print "Test from directory $testdir\n" if $trace ;
    my $wr_dir = "wr_test/$testdir" ;
    mkdir($wr_dir) unless -d $wr_dir;

    my $inst = $model->instance (root_class_name   => 'Sshd',
				 instance_name     => 'sshd_instance',
				 'read_directory'  => "data/$testdir",
				 'write_directory' => $wr_dir,
				);

    ok($inst,"Read sshd.conf and created instance") ;

    my $root = $inst -> config_root ;

    my $dump =  $root->dump_tree ();
    print $dump if $trace ;

    like($dump,qr/Match:0/, "check Match section") ;

    $inst->write_back($wr_dir) ;
    ok(1,"wrote data in $wr_dir") ;

    my $inst2 = $model->instance (root_class_name   => 'Sshd',
				  instance_name     => 'sshd_instance2',
				  'read_directory'  => $wr_dir,
				  'write_directory' => $wr_dir.'2',
                            );

    my $root2 = $inst2 -> config_root ;
    my $dump2 = $root2 -> dump_tree ();
    print $dump2 if $trace ;

    is_deeply([split /\n/,$dump2],[split /\n/,$dump],
	      "check if both dumps are identical") ;
}
