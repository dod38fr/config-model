# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Config::Model;

BEGIN { plan tests => 8; }

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"Compilation done");

my $model = Config::Model->new(legacy => 'ignore',) ;
$model ->create_config_class 
  (
   name => "Master",
   element => [ ]
  ) ;

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name   => 'test1',
			     root_dir        => 'foobar' );
ok($inst,"created dummy instance") ;

isa_ok( $inst->config_root , 'Config::Model::Node',"test config root class" );

is( $inst->data('test'),undef,"test empty private data ..." );
is( $inst->data( 'test', 'coucou' ), 'coucou', "store private data" );
is( $inst->data( 'test'), 'coucou', "retrieve private data" );

is( $inst->read_root_dir,  'foobar/', "test read directory") ;
is( $inst->write_root_dir, 'foobar/', "test write directory") ;
