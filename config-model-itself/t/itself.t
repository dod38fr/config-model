# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Config::Model;
use Log::Log4perl qw(:easy) ;
use Data::Dumper ;
use File::Path ;
use File::Copy ;
use File::Find ;
use Config::Model::Itself ;

use warnings;
no warnings qw(once);

use strict;

my $arg = $ARGV[0] || '' ;

my $trace = ($arg =~ /t/) ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

Log::Log4perl->easy_init($arg =~ /l/ ? $DEBUG: $ERROR);

my $wr_test = 'wr_test' ;
my $wr_conf1 = "$wr_test/wr_conf1";
my $wr_model1 = "$wr_test/wr_model1";

sub wr_cds {
    my ($file,$cds) = @_ ;
    open(CDS,"> $file") || die "can't open $file:$!" ;
    print CDS $cds ;
    close CDS ;
}

# trap warning if Augeas backend is not installed
if (not  eval {require Config::Model::Backend::Augeas; } ) {
    # do not use Test::Warnings with this
    $SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /unknown backend/};
}
else {
    # workaround Augeas locale bug
    no warnings qw/uninitialized/;
    if ($ENV{LC_ALL} ne 'C' or $ENV{LANG} ne 'C') {
        $ENV{LC_ALL} = $ENV{LANG} = 'C';
        my $inc = join(' ',map("-I$_",@INC)) ;
        exec("$^X $inc $0 @ARGV");
    }
}

plan tests => 18 ; # avoid double print of plan when exec is run

my $meta_model = Config::Model -> new ( ) ;# model_dir => '.' );

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

rmtree($wr_test) if -d $wr_test ;

# "modern" API of File::Path does not work with perl 5.8.8
mkpath( [$wr_conf1, $wr_model1, "$wr_conf1/etc/ssh/"] , 0, 0755) ;
copy('augeas_box/etc/ssh/sshd_config', "$wr_conf1/etc/ssh/") ;

# copy test model
my $wanted = sub { 
    return if /svn|data$|~$/ ;
    s!data/!! ;
    -d $File::Find::name && mkpath( ["$wr_model1/$_"], 0, 0755) ;
    -f $File::Find::name && copy($File::Find::name,"$wr_model1/$_") ;
};
find ({ wanted =>$wanted, no_chdir=>1} ,'data') ;


my $model = Config::Model->new(legacy => 'ignore',model_dir => 'data' ) ;
ok(1,"loaded Master model") ;

# check that Master Model can be loaded by Config::Model
my $inst1 = $model->instance (root_class_name   => 'MasterModel', 
                              instance_name     => 'test_orig',
                              root_dir          => $wr_conf1,
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

my $meta_inst = $meta_model
  -> instance (root_class_name   => 'Itself::Model', 
               instance_name     => 'itself_instance',
               root_dir          => $wr_model1,
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
                          'MasterModel::TolerantNode',
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
     'MasterModel/References.pl' => [
                                     'MasterModel::References::Host',
                                     'MasterModel::References::If',
                                     'MasterModel::References::Lan',
                                     'MasterModel::References::Node',
                                     'MasterModel::References'
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

wr_cds("$wr_conf1/orig.cds",$cds);

#create a 2nd empty model
my $meta_inst2 = $meta_model->instance (root_class_name   => 'Itself::Model', 
                              instance_name     => 'itself_instance', );

my $meta_root2 = $meta_inst2 -> config_root ;
$meta_root2 -> load ($cds) ;
ok(1,"Created and loaded 2nd instance") ;

my $cds2 = $meta_root2 ->dump_tree (full_dump => 1) ;
wr_cds("$wr_conf1/inst2.cds",$cds2);

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
wr_cds("$wr_conf1/inst3.cds",$cds3);

is_deeply([split /\n/,$cds3],\@cds_orig,"Compared the 3rd full dump with first one") ; 

# check dump of one class
my $dump = $rw_obj -> get_perl_data_model ( class_name => 'MasterModel' ) ;

print Dumper $dump if $trace ;
ok($dump,"Checked dump of one class");

$rw_obj->write_all( model_dir => $wr_model1 ) ;

my $model4 = Config::Model->new(legacy => 'ignore',model_dir => $wr_model1) ;
#$model4 -> load ('X_base_class', 'wr_test/MasterModel/X_base_class.pl') ;
#ok(1,"loaded X_base_class") ;
#$model4 -> load ('MasterModel' , 'wr_test/MasterModel.pl') ;
#ok(1,"loaded MasterModel") ;
#$model4 -> load ('MasterModel::Created' , 'wr_test/Master/Created.pl') ;
#ok(1,"loaded MasterModel::Created") ;

my $inst4 = $model4->instance (root_class_name   => 'MasterModel', 
                               instance_name     => 'test_instance',
                               'root_dir'  => $wr_conf1,

                              );
ok($inst4,"Read MasterModel and created instance") ;

my $root4 = $inst4->config_root ;
ok($root4,"Created MasterModel root") ;

my @elt4 = $root4->get_element_name() ;
is(scalar @elt4,scalar @elt1,"Check number of elements of root4") ;

# require Tk::ObjScanner; Tk::ObjScanner::scan_object($meta_model) ;

