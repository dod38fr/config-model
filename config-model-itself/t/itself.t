# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-03-10 12:57:54 $
# $Name: not supported by cvs2svn $
# $Revision: 1.5 $

use ExtUtils::testlib;
use Test::More tests => 15;
use Config::Model;
use Log::Log4perl qw(:easy) ;
use Data::Dumper ;
use Config::Model::Itself ;

use warnings;
no warnings qw(once);

use strict;

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
my $log             = 1 if $arg =~ /l/;

my $wr_dir = 'wr_test' ;

sub wr_cds {
    my ($file,$cds) = @_ ;
    open(CDS,"> $file") || die "can't open $file:$!" ;
    print CDS $cds ;
    close CDS ;
}

Log::Log4perl->easy_init($log ? $DEBUG: $WARN);

my $meta_model = Config::Model -> new ( ) ;# model_dir => '.' );

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

mkdir($wr_dir) unless -d $wr_dir ;

my $inst = $meta_model->instance (root_class_name   => 'Itself::Model', 
			     instance_name     => 'itself_instance',
			     'read_directory'  => "data",
			     'write_directory' => "wr_test",
			    );
ok($inst,"Read Itself::Model and created instance") ;

my $root = $inst -> config_root ;

my $rw_obj = Config::Model::Itself -> new(model_object => $root) ;

my $map = $rw_obj -> read_all( 
			      conf_dir => 'data',
			      root_model => 'MasterModel',
			     ) ;

ok(1,"Read all models in data dir") ;

my $expected_map 
  = {
     'MasterModel/HashIdOfValues.pl' => [
			     'MasterModel::HashIdOfValues'
			    ],
     'MasterModel/CheckListExamples.pl' => [
				'MasterModel::CheckListExamples'
			       ],
     'MasterModel.pl' => [
			  'MasterModel::SubSlave2',
			  'MasterModel::SubSlave',
			  'MasterModel::SlaveZ',
			  'MasterModel::SlaveY',
			  'MasterModel'
			 ],
     'MasterModel/WarpedId.pl' => [
		       'MasterModel::WarpedIdSlave',
		       'MasterModel::WarpedId'
		      ],
     'MasterModel/X_base_class.pl' => [
			   'MasterModel::X_base_class2',
			   'MasterModel::X_base_class',
			  ],
     'MasterModel/WarpedValues.pl' => [
			   'MasterModel::RSlave',
			   'MasterModel::Slave',
			   'MasterModel::WarpedValues'
			  ]
    };

is_deeply($expected_map, $map, "Check file class map") ;
print Dumper $map if $trace ;

# add a new class 
$root->load("class:Master::Created element:created1 type=leaf - element:created2 type=leaf") ;
ok(1,"added new class Master::Created") ;

my $cds = $root->dump_tree (full_dump => 1) ;
my @cds_orig = split /\n/,$cds ;

print $cds if $trace ;
ok($cds,"dumped full tree in cds format") ;

wr_cds("$wr_dir/orig.cds",$cds);

#create a 2nd empty model
my $inst2 = $meta_model->instance (root_class_name   => 'Itself::Model', 
			      instance_name     => 'itself_instance', );

my $root2 = $inst -> config_root ;
$root2 -> load ($cds) ;
ok(1,"Created and loaded 2nd instance") ;

my $cds2 = $root2 ->dump_tree (full_dump => 1) ;
wr_cds("$wr_dir/inst2.cds",$cds2);

is_deeply([split /\n/,$cds2],\@cds_orig,"Compared the 2 full dumps") ; 

my $pdata2 = $root2 -> dump_as_data ;
print Dumper $pdata2 if $trace ;

# create 3rd instance 

my $inst3 = $meta_model->instance (root_class_name   => 'Itself::Model', 
			      instance_name     => 'itself_instance', );

my $root3 = $inst -> config_root ;
$root3 -> load_data ($pdata2) ;
ok(1,"Created and loaded 3nd instance with perl data") ;

my $cds3 = $root3 ->dump_tree (full_dump => 1) ;
wr_cds("$wr_dir/inst3.cds",$cds3);

is_deeply([split /\n/,$cds3],\@cds_orig,"Compared the 3rd full dump with first one") ; 

# check dump of one class
my $dump = $rw_obj -> get_perl_data_model ( class_name => 'MasterModel' ) ;

print Dumper $dump if $trace ;
ok($dump,"Checked dump of one class");

$rw_obj->write_all( conf_dir => $wr_dir ) ;

my $model = Config::Model->new ;
$model -> load ('X_base_class', 'wr_test/MasterModel/X_base_class.pl') ;
ok(1,"loaded X_base_class") ;
$model -> load ('MasterModel' , 'wr_test/MasterModel.pl') ;
ok(1,"loaded MasterModel") ;
$model -> load ('MasterModel::Created' , 'wr_test/Master/Created.pl') ;
ok(1,"loaded MasterModel::Created") ;

my $inst4 = $model->instance (root_class_name   => 'MasterModel', 
			    instance_name     => 'test_instance',
			    'read_directory'  => "wr_test",
			    'write_directory' => "wr_test2",
			   );
ok($inst4,"Read MasterModel and created instance") ;

# require Tk::ObjScanner; Tk::ObjScanner::scan_object($meta_model) ;

