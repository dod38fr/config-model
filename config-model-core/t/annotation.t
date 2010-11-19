# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 16;
use Config::Model;
use Config::Model::Annotation;
use File::Path ;
use Data::Dumper ; 

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

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root/';

# cleanup before tests
rmtree($wr_root);
mkpath($wr_root, { mode => 0755 }) ;


use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file => 't/big_model.pm',
			     root_dir => $wr_root ,
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;
ok($root,"Config root created") ;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata" '
  .'lista=a,b,c,d olist:0 X=Av - olist:1#olist1_comment X=Bv - listb=b,c,d '
    . '! hash_a:X2=x hash_a:Y2=xy hash_a:toto#"index comment"
        hash_b:X3=xy my_check_list=X2,X3' ;
ok( $root->load( step => $step, experience => 'advanced' ),
  "set up data in tree with '$step'");

my @annotate = map { [ $_ => "$_ annotation" ] }
  ('std_id','std_id:bc X','my_check_list','olist:0','olist:2') ;
my %expect = ( 'hash_a:toto' => "index comment", 'olist:1' => 'olist1_comment');

foreach (@annotate) {
    my ($l,$a) = @$_ ;
    $expect{$l} = $a ;
    $root->grab($l)->annotation($a) ;
    ok(1,"set annotation of $l") ;
}

my $annotate_saver = Config::Model::Annotation
  -> new (
	  config_class_name => 'Master',
	  instance => $inst ,
	  root_dir => $wr_root ,
	 ) ;
ok($annotate_saver,"created annotation read/write object") ;

my $yaml_dir = $annotate_saver->dir;
is($yaml_dir,'wr_root/config-model/',"check saved dir") ;

my $yaml_file = $annotate_saver->file;
is($yaml_file,'wr_root/config-model/Master-note.pl',"check saved file") ;

my $h_ref = $annotate_saver->get_annotation_hash() ;

print Dumper ( $h_ref ) if $trace ;

is_deeply ($h_ref,\%expect ,"check annotation data") ;

$annotate_saver->save ;

ok(-e $yaml_file,"check annotation file exists" );


my $inst2 = $model->instance (root_class_name => 'Master', 
			      root_dir => $wr_root ,
			      instance_name => 'test2');

my $root2 = $inst2 -> config_root ;

my $saver2 = Config::Model::Annotation
  -> new (
	  config_class_name => 'Master',
	  instance => $inst2 ,
	  root_dir => $wr_root ,
	 ) ; 
$saver2->load ;
my $h2_ref = $saver2->get_annotation_hash() ;

#use Data::Dumper ; print Dumper ( $h_ref ) ;
print Dumper ( $h2_ref ) if $trace ;
my %expect2 = %expect ;

# delete annotations loaded on missing elements
delete $expect2{'std_id:bc X'} ;
delete $expect2{'hash_a:toto'} ;
delete $expect2{'olist:0'} ;
delete $expect2{'olist:1'} ;
delete $expect2{'olist:2'} ;

is_deeply ($h2_ref,\%expect2 ,"check loaded annotation data with empty tree") ;

$root2->load( step => $step, experience => 'advanced' ) ;
$saver2->load ;

my %expect3 = %expect ;
# delete annotations loaded on missing elements
delete $expect3{'olist:2'} ;

my $h3_ref = $saver2->get_annotation_hash() ;
print Dumper ( $h3_ref ) if $trace ;
is_deeply ($h3_ref,\%expect3 ,"check loaded annotation data with non-empty tree") ;
