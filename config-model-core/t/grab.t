# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 35;
use Config::Model;

use warnings;
no warnings qw(once);

use strict;

use Data::Dumper;
# use Config::Model::ObjTreeScanner;

use vars qw/$model/;

$model = Config::Model -> new (legacy => 'ignore',) ;

my $arg = shift || '';
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
my $trace = $arg =~ /t/ ? 1 : 0 ;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file => 't/big_model.pm',
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

Config::Model::Exception::Any->Trace(1) if $trace =~ /e/;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - std_id:"b c" X=Av - a_string="titi , toto" ';
ok( $root->load( step => $step, experience => 'advanced' ),
  "load '$step'");

my $grabbed = $root->grab('olist:0' ) ;
is($grabbed->location, 'olist:0', 'test grab olist:0 (obj)') ;
is($root->grab('olist:0' )->index_value,0,'test grab olist:0 (index)') ;

my $wp = 'olist:0';
eval {$root->grab(\$wp )->index_value; };
ok($@,"Test grab with wrong parameter") ;
print "normal error:\n", $@, "\n" if $trace;

eval {$root->grab('std_xid:toto')->index_value; };
ok($@,"Test grab with wrong element") ;
print "normal error:\n", $@, "\n" if $trace;


like($root->grab('olist' )->name,qr/olist/,'test grab olist') ;

is( $root->location(), '','location test' );

foreach my $wstep ( 
		   'std_id:ab', 'olist:0', 'olist:1', 
		   'warp',
		   'warp std_id:toto',
		   'warp std_id:"b c"'
		  )
{
    my $obj = $root->grab( $wstep );
    ok($obj,"grab $wstep...");
    is( $obj->location, $wstep,"... and test its location" );
}


print $root->dump_tree( ) if $trace =~ /t/;

my $leaf = $root->grab('warp std_id:toto DX');

my @tests = ( [ '?warp' ,      'warp',           'WarpedNode'],
	      [ '?std_id:ab' , 'warp std_id:ab', 'Node'],
	      [ '?hash_a:ab' , 'hash_a:ab'   , 'Value'],
	      [ '?std_id' ,     'warp std_id', 'HashId'],
	    ) ;

foreach my $unit_test (@tests) {
    my $obj = $leaf->grab($unit_test->[0]) ;
    is($obj->location, 
       $unit_test->[1],
       "test grab with '$unit_test->[0]'") ;
    isa_ok ($obj, 'Config::Model::'.$unit_test->[2]) ;
}

eval { $leaf->grab('?argh' ); };
ok($@,"test grab with wrong step: '?argh'");
print "normal error:\n", $@, "\n" if $trace;

eval { $root->grab(step => 'std_id:zzz', autoadd => 0 ); };
ok($@,"test autoadd 0 with 'std_id:zzz'");
print "normal error:\n", $@, "\n" if $trace;


$root->grab(step => 'std_id:zzz', autoadd => 1 );
ok(1,"test autoadd 1 with 'std_id:zzz'");

my $obj = $root->grab(step => 'std_id:zzz foobar', strict => 0 );
is($obj->location,"std_id:zzz","test no strict grab");

$obj = $root->grab(step => 'std_id:ab X', type => 'node' , strict => 0);
is($obj->location,"std_id:ab","test no strict grab with type node");

eval { $root->grab(step => 'std_id:ab X', type => 'node' , strict => 1); } ;
ok($@,"test strict grab with type node");
print "normal error:\n", $@, "\n" if $trace;
