# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Test::Differences ;
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

my $log = 0;
my $arg = $ARGV[0] || '' ;

my $trace = ($arg =~ /t/) ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($log ? $WARN: $ERROR);
}

my $wr_test = 'wr_test' ;
my $wr_conf1 = "$wr_test/wr_conf1";
my $wr_model1 = "$wr_test/wr_model1";


plan tests => 6 ; 

my $meta_model = Config::Model -> new ( ) ;# model_dir => '.' );

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

rmtree($wr_test) if -d $wr_test ;


my $meta_inst = $meta_model->instance(
    root_class_name => 'Itself::Model',
    instance_name   => 'itself_instance',
    root_dir => $wr_model1,
);
ok( $meta_inst, "Read Itself::Model and created instance" );

my $meta_root = $meta_inst -> config_root ;

my $rw_obj = Config::Model::Itself -> new(model_object => $meta_root) ;

# add a new class 
my @list = (1..3);
foreach my $i (@list) {
    $meta_root->load(
    qq/class:Master::Created$i#"my great class $i"
        class_description="Master class created nb $i\nfor tests purpose." 
        author="dod\@foo.com" copyright="2011 dod" license="LGPL"
       element:created1 type=leaf#"not autumn" value_type=number description="element 1" - 
    element:created2 type=leaf value_type=uniline description="another element"/) ;
}
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

print $rw_obj->generate_pod(
    [ map {"Master::Created$_"} @list ], 
    [ map {$rw_obj->get_perl_data_model(class_name => "Master::Created$_") } @list ],
) if $trace;

$rw_obj->write_all( model_dir => $wr_model1 ) ;
ok(1,"wrote back all stuff") ;

my $meta_root2 = $meta_model -> instance (
    root_class_name   => 'Itself::Model', 
    instance_name     => 'itself_instance2',
    root_dir          => $wr_model1,
) -> config_root ;
              
ok($meta_root2,"Read Itself::Model and created instance2") ;
my $rw_obj2 = Config::Model::Itself -> new(model_object => $meta_root2 ) ;
$rw_obj2->read_all( model_dir => $wr_model1 , root_model => 'Master' ) ;

eq_or_diff($meta_root2->dump_tree, $meta_root->dump_tree,"compare 2 dumps");


# require Tk::ObjScanner; Tk::ObjScanner::scan_object($meta_model) ;

