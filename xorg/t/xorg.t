# -*- cperl -*-
# $Author: ddumont $
# $Date: 2007-10-01 15:31:07 $
# $Name: not supported by cvs2svn $
# $Revision: 1.5 $

use ExtUtils::testlib;
use Test::More tests => 7;
use Config::Model;
use Log::Log4perl qw(:easy) ;
use Data::Dumper ;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;


my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
my $log             = 1 if $arg =~ /l/;

Log::Log4perl->easy_init($log ? $DEBUG: $WARN);

$model = Config::Model -> new ( ) ;# model_dir => '.' );

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

mkdir('wr_test') unless -d 'wr_test' ;

my $inst = $model->instance (root_class_name   => 'Xorg', 
			     instance_name     => 'xorg_instance',
			     'read_root_dir'   => "data",
			     'write_root_dir'  => "wr_test",
			    );
ok($inst,"Read xorg.conf and created instance") ;

my $root = $inst -> config_root ;

my $orig_data = Config::Model::Xorg::Read::read( object => $root,
						 root   => 'data',
						 config_dir => '/etc/X11',
						 test => 1
					       ) ;

open (FOUT,">wr_test/orig_data.pl") || die "can't open wr_test/orig_data.pl:$!";
print FOUT Dumper($orig_data) ;
close FOUT ;

#$inst->push_no_value_check('fetch') ;
my $res = $root->describe ;
#$inst->pop_no_value_check;
print "Root node description:\n\n",$res,"\n" if $trace ;

ok($inst,"created description") ;

my $orig_dump = $root->dump_tree ;
ok($inst,"created original xorg cds dump in wr_test") ;

open (FOUT,">wr_test/xorg_dump.cds") || die "can't open wr_test/xorg_dump.cds:$!";
print FOUT $orig_dump ;
close FOUT ;

$inst->write_back ;

ok($inst,"wrote back file in wr_test") ;

my $inst2 = $model->instance (root_class_name   => 'Xorg', 
			      instance_name     => 'xorg_instance2',
			     'read_root_dir'    => "wr_test",
			     'write_root_dir'   => "wr_test",
			    );

ok($inst2,"Read xorg.conf from wr_test and created 2nd instance" ) ;

my $wr_data = Config::Model::Xorg::Read::read( object => $root,
					       root   => 'wr_test',
					       config_dir => '/etc/X11',
					       test => 1
					     ) ;

open (FOUT,">wr_test/written_data.pl") || die "can't open wr_test/written_data.pl:$!";
print FOUT Dumper($wr_data) ;
close FOUT ;

my $wr_dump = $inst2->config_root->dump_tree ;

open (FOUT,">wr_test/2nd_dump.cds") || die "can't open wr_test/2nd_dump.cds:$!";
print FOUT $wr_dump ;
close FOUT ;

is_deeply([split /\n/, $wr_dump ],
	  [split /\n/, $orig_dump ],
	  "compare dump of original xorg with second dump") ;


# require Tk::ObjScanner; Tk::ObjScanner::scan_object($model) ;
