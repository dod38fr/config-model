# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-03-10 12:57:54 $
# $Name: not supported by cvs2svn $
# $Revision: 1.5 $

use ExtUtils::testlib;
use Test::More tests => 18;
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


my $model = Config::Model->new(legacy => 'ignore',model_dir => 'data' ) ;
ok(1,"loaded Master model") ;

# check that Master Model can be loaded by Config::Model
my $inst1 = $model->instance (root_class_name   => 'MasterModel', 
			      instance_name     => 'test_orig',
			     );
ok($inst1,"created master_model instance") ;

my $root1 = $inst1->config_root ;
my @elt1 = $root1->get_element_name ;

$root1->load("a_string=toto lot_of_checklist macro=AD - "
	    ."! warped_values macro=C where_is_element=get_element "
	    ."                get_element=m_value_element m_value=Cv") ;
ok($inst1,"loaded some data in master_model instance") ;

my $dump1 = $root1->dump_tree(mode => 'full') ;
ok($dump1,"dumped master instance") ;

# ok now we can load test model in Itself

my $meta_inst = $meta_model->instance (root_class_name   => 'Itself::Model', 
			     instance_name     => 'itself_instance',
			     'read_directory'  => "data",
			     'write_directory' => "wr_test",
			    );
ok($meta_inst,"Read Itself::Model and created instance") ;



my $meta_root = $meta_inst -> config_root ;

my $rw_obj = Config::Model::Itself -> new(model_object => $meta_root) ;

my $map = $rw_obj -> read_all( 
			      model_dir => 'data',
			      root_model => 'MasterModel',
			      legacy => 'ignore',
			     ) ;

ok(1,"Read all models in data dir") ;

print $meta_model->list_class_element if $trace ;

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
			  ],
     'MasterModel/SshdWithAugeas.pl' => [
					 'MasterModel::SshdWithAugeas',
					],
    };

is_deeply($expected_map, $map, "Check file class map") ;
print Dumper $map if $trace ;

# add a new class 
$meta_root->load("class:Master::Created element:created1 type=leaf value_type=number - element:created2 type=leaf value_type=uniline") ;
ok(1,"added new class Master::Created") ;

if (0) {
    require Tk;
    require Config::Model::TkUI ;
    Tk->import ;

    my $mw = MainWindow-> new ;
    $mw->withdraw ;

    my $cmu = $mw->ConfigModelUI (-root => $meta_root) ;
    &MainLoop ; # Tk's
}

my $cds = $meta_root->dump_tree (full_dump => 1) ;
my @cds_orig = split /\n/,$cds ;

print $cds if $trace ;
ok($cds,"dumped full tree in cds format") ;

#like($cds,qr/dumb/,"check for a peculiar warp effet") ;

wr_cds("$wr_dir/orig.cds",$cds);

#create a 2nd empty model
my $meta_inst2 = $meta_model->instance (root_class_name   => 'Itself::Model', 
			      instance_name     => 'itself_instance', );

my $meta_root2 = $meta_inst2 -> config_root ;
$meta_root2 -> load ($cds) ;
ok(1,"Created and loaded 2nd instance") ;

my $cds2 = $meta_root2 ->dump_tree (full_dump => 1) ;
wr_cds("$wr_dir/inst2.cds",$cds2);

is_deeply([split /\n/,$cds2],\@cds_orig,"Compared the 2 full dumps") ; 

my $pdata2 = $meta_root2 -> dump_as_data ;
print Dumper $pdata2 if $trace ;

# create 3rd instance 

my $meta_inst3 = $meta_model->instance (root_class_name   => 'Itself::Model', 
			      instance_name     => 'itself_instance', );

my $meta_root3 = $meta_inst3 -> config_root ;
$meta_root3 -> load_data ($pdata2) ;
ok(1,"Created and loaded 3nd instance with perl data") ;

my $cds3 = $meta_root3 ->dump_tree (full_dump => 1) ;
wr_cds("$wr_dir/inst3.cds",$cds3);

is_deeply([split /\n/,$cds3],\@cds_orig,"Compared the 3rd full dump with first one") ; 

# check dump of one class
my $dump = $rw_obj -> get_perl_data_model ( class_name => 'MasterModel' ) ;

print Dumper $dump if $trace ;
ok($dump,"Checked dump of one class");

$rw_obj->write_all( model_dir => $wr_dir ) ;

my $model4 = Config::Model->new(legacy => 'ignore',model_dir => $wr_dir) ;
#$model4 -> load ('X_base_class', 'wr_test/MasterModel/X_base_class.pl') ;
#ok(1,"loaded X_base_class") ;
#$model4 -> load ('MasterModel' , 'wr_test/MasterModel.pl') ;
#ok(1,"loaded MasterModel") ;
#$model4 -> load ('MasterModel::Created' , 'wr_test/Master/Created.pl') ;
#ok(1,"loaded MasterModel::Created") ;

my $inst4 = $model4->instance (root_class_name   => 'MasterModel', 
			       instance_name     => 'test_instance',
			       'read_directory'  => "wr_test",
			       'write_directory' => "wr_test2",
			      );
ok($inst4,"Read MasterModel and created instance") ;

my $root4 = $inst4->config_root ;
ok($root4,"Created MasterModel root") ;

my @elt4 = $root4->get_element_name() ;
is(scalar @elt4,scalar @elt1,"Check number of elements of root4") ;

# require Tk::ObjScanner; Tk::ObjScanner::scan_object($meta_model) ;

