use ExtUtils::testlib;
use Test::More tests => 8;
use Config::Model;
use Log::Log4perl qw(:easy) ;
use Data::Dumper ;
use Config::Model::Itself ;
use File::Path ;
use File::Find ;
use File::Copy ;

use warnings;
no warnings qw(once);

use strict;

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
my $log             = 1 if $arg =~ /l/;

Log::Log4perl->easy_init($log ? $DEBUG: $WARN);

my $meta_model = Config::Model -> new ( ) ;# model_dir => '.' );

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

my $wr_test = "wr_test" ;
rmtree($wr_test) if -d $wr_test ;
mkdir($wr_test) ;

# copy test model
my $wanted = sub { 
    return if /svn|data$|~$/ ;
    s!data/!! ;
    -d $File::Find::name && mkpath( ["$wr_test/$_"], 0, 0755) ;
    -f $File::Find::name && copy($File::Find::name,"$wr_test/$_") ;
};
find ({ wanted =>$wanted, no_chdir=>1} ,'data') ;

my $inst = $meta_model->instance (root_class_name   => 'Itself::Model', 
				  instance_name     => 'itself_instance',
				  root_dir          => $wr_test,
				 );
ok($inst,"Read Itself::Model and created instance") ;

my $root = $inst -> config_root ;

my $model_dir = 'lib/Config/Model/models';
my $rw_obj    = Config::Model::Itself->new(
    model_dir    => $model_dir,
    model_object => $root
);

my $map = $rw_obj->read_all( root_model => 'Itself' );

ok(1,"Read all models from $model_dir") ;

my $cds = $root->dump_tree (full_dump => 1) ;

print $cds if $trace ;
ok($cds,"dumped full tree in cds format") ;

#create a 2nd empty model
my $inst2 = $meta_model->instance (root_class_name   => 'Itself::Model', 
				   instance_name     => 'itself_instance', );

my $root2 = $inst -> config_root ;
$root2 -> load ($cds) ;
ok(1,"Created and loaded 2nd instance") ;

my $cds2 = $root2 ->dump_tree (full_dump => 1) ;

is($cds2,$cds,"Compared the 2 full dumps") ; 

my $pdata2 = $root2 -> dump_as_data ;
print Dumper $pdata2 if $trace ;

# create 3rd instance 

my $inst3 = $meta_model->instance (root_class_name   => 'Itself::Model', 
				   instance_name     => 'itself_instance', );

my $root3 = $inst -> config_root ;
$root3 -> load_data ($pdata2) ;
ok(1,"Created and loaded 3nd instance with perl data") ;

my $cds3 = $root3 ->dump_tree (full_dump => 1) ;

is($cds3,$cds,"Compared the 3rd full dump with first one") ; 

$rw_obj->write_all(  ) ;

# require Tk::ObjScanner; Tk::ObjScanner::scan_object($meta_model) ;

