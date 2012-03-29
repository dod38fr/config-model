use ExtUtils::testlib;
use Test::More tests => 4;
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

Log::Log4perl->easy_init($log ? $DEBUG: $WARN);

my $meta_model = Config::Model -> new ( ) ;# model_dir => '.' );

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

mkdir('wr_test') unless -d 'wr_test' ;

my $meta_inst = $meta_model
  -> instance (root_class_name   => 'Itself::Model', 
	       instance_name     => 'itself_instance',
	       root_dir          => "data",
	      );
ok($meta_inst,"Read Itself::Model and created instance") ;

my $meta_root = $meta_inst -> config_root ;

my $model_dir = 'lib/Config/Model/models';
my $rw_obj    = Config::Model::Itself->new(
    model_dir    => $model_dir,
    model_object => $meta_root
);

my $map = $rw_obj->read_all(
    root_model => 'Itself',
    force_load => 1,
);

ok(1,"Read all models from $model_dir") ;

my $list =  $rw_obj->list_class_element;
ok($list,"got structure") ;

print $list if $trace ;

