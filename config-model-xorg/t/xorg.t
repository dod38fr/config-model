# -*- cperl -*-
# $Author: ddumont $
# $Date: 2007-10-01 15:31:07 $
# $Name: not supported by cvs2svn $
# $Revision: 1.5 $

use ExtUtils::testlib;
use Test::More ;
use Config::Model;
use Log::Log4perl qw(:easy) ;
use Data::Dumper ;
use File::Path ;
use File::Copy ;

use Config::Model::Xorg::Read ; # read function is called directly in test

use warnings;
no warnings qw(once);

use strict;


my $arg = shift || '' ;
my $want_test = shift || '' ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
my $log             = 1 if $arg =~ /l/;

Log::Log4perl->easy_init($log ? $DEBUG: $WARN);

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

my $data_dir = 't/xorg-files' ;
opendir(DIR,$data_dir) || die "can't open dir $data_dir:$!";
my @test_files = grep  {/\.conf$/ }  readdir(DIR);
closedir(DIR) ;

plan tests => scalar @test_files * 7 + 1;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_test';

# cleanup before tests
rmtree($wr_root);

my $model = Config::Model -> new ( ) ;# model_dir => '.' );

foreach my $file (@test_files) {
    my $test = $file ;
    $test =~ s/.conf//;
    next if $want_test && $want_test ne $test ;
 

    my $wr_dir = "$wr_root/$test" ;
    my $confdir = $wr_dir.'/etc/X11' ;
    mkpath($confdir, { mode => 0755 }) || die "can't mkpath $confdir: $!";

    my $f = "$data_dir/$file";

    ok(1,"Begin $test test with $f") ;

    copy($f,"$confdir/xorg.conf") || die "can't copy file $f:$!";;

    my $inst = $model->instance (root_class_name   => 'Xorg', 
				 instance_name     => "test_$test",
				 root_dir          => $wr_dir,
				);
    ok($inst,"$test: Read xorg.conf and created $test instance") ;

    my $root = $inst -> config_root ;

    my $orig_data = Config::Model::Xorg::Read::read( object => $root,
						     root   => $wr_dir,
						     config_dir => '/etc/X11',
						     test => 1
						   ) ;

    open (FOUT,">$wr_dir/orig_data.pl") || die "can't open $wr_dir/orig_data.pl:$!";
    print FOUT Dumper($orig_data) ;
    close FOUT ;

    #$inst->push_no_value_check('fetch') ;
    my $res = $root->describe ;
    #$inst->pop_no_value_check;
    print "Root node description:\n\n",$res,"\n" if $trace ;

    ok($inst,"$test: created description") ;

    my $orig_dump = $root->dump_tree ;
    ok($inst,"$test: created original xorg cds dump in $wr_dir") ;

    open (FOUT,">$wr_dir/xorg_dump.cds") || die "can't open $wr_dir/xorg_dump.cds:$!";
    print FOUT $orig_dump ;
    close FOUT ;

    $inst->write_back ;

    ok($inst,"$test: wrote back file in $wr_dir") ;

    my $inst2 = $model->instance (root_class_name   => 'Xorg', 
				  instance_name     => "test_2_$test",
				  root_dir          =>  $wr_dir,
				 );

    ok($inst2,"$test: Read xorg.conf from $wr_dir and created 2nd instance" ) ;

    my $wr_data = Config::Model::Xorg::Read::read( object => $root,
						   root   => $wr_dir,
						   config_dir => '/etc/X11',
						   test => 1
						 ) ;

    open (FOUT,">$wr_dir/written_data.pl") || die "can't open $wr_dir/written_data.pl:$!";
    print FOUT Dumper($wr_data) ;
    close FOUT ;

    my $wr_dump = $inst2->config_root->dump_tree ;

    open (FOUT,">$wr_dir/2nd_dump.cds") || die "can't open $wr_dir/2nd_dump.cds:$!";
    print FOUT $wr_dump ;
    close FOUT ;

    is_deeply([split /\n/, $wr_dump ],
	      [split /\n/, $orig_dump ],
	      "$test: compare dump of original xorg with second dump") ;


    # require Tk::ObjScanner; Tk::ObjScanner::scan_object($model) ;
}

