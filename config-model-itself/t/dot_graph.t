# -*- cperl -*-
# $Author$
# $Date$
# $Revision$

use ExtUtils::testlib;
use Test::More tests => 4;
use Config::Model;
use Log::Log4perl qw(:easy) ;
use Config::Model::Itself ;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model -> new(legacy => 'ignore',)  ;

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"compiled");

mkdir('wr_test') unless -d 'wr_test' ;

my $meta_model = Config::Model -> new ( ) ;# model_dir => '.' );

my $meta_inst = $meta_model
  -> instance (root_class_name   => 'Itself::Model', 
	       instance_name     => 'itself_instance',
	       root_dir          => "data",
	      );
ok($meta_inst,"Read Itself::Model and created instance") ;

my $meta_root = $meta_inst -> config_root ;

my $rw_obj = Config::Model::Itself -> new(model_object => $meta_root ) ;

my $model_dir = 'lib/Config/Model/models' ;
my $map = $rw_obj -> read_all( model_dir => $model_dir,
			       root_model => 'Itself',
			       force_load   => 1,
			     ) ;

ok(1,"Read all models from $model_dir") ;

my $dot_file = "wr_test/config-test.dot";

my $res =  $rw_obj->get_dot_diagram ;
ok($res,"got dot data, written in $dot_file") ;

print $res if $trace ;

open(TMP,">$dot_file") || die "Cannot open $dot_file:$!";
print TMP $res;
close TMP ;

