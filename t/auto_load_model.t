# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 6;
use Test::Memory::Cycle;
use Config::Model;

use warnings;
no warnings qw(once);

use strict;

my $model = Config::Model -> new(legacy => 'ignore',) ;

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);


ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file    => 't/big_model.pm' ,
			     instance_name => 'test1');

ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;
ok($root,"Config root created") ;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata" '
  .'lista=a,b,c,d olist:0 X=Av - olist:1 X=Bv - listb=b,c,d';
ok( $root->load( step => $step, experience => 'advanced' ),
  "set up data in tree with '$step'");

# no need to check more. The above command would have failed if
# the file containing the model was not loaded.

# check that loading a model without inheritance works

my $model2 = Config::Model -> new ( legacy => 'ignore',skip_include => 1 ) ;
my $inst2 = $model2->instance (root_class_name => 'Master', 
			     model_file    => 't/big_model.pm' ,
			     instance_name => 'test1');
ok($inst2,"created dummy instance 2") ;
memory_cycle_ok($model);
