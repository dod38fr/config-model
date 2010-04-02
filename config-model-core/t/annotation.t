# -*- cperl -*-
# $Author$
# $Date$
# $Revision$

use ExtUtils::testlib;
use Test::More tests => 8;
use Config::Model;
use Config::Model::Annotation;

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

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file => 't/big_model.pm',
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;
ok($root,"Config root created") ;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata" '
  .'lista=a,b,c,d olist:0 X=Av - olist:1 X=Bv - listb=b,c,d '
    . '! hash_a:X2=x hash_a:Y2=xy  hash_b:X3=xy my_check_list=X2,X3' ;
ok( $root->load( step => $step, permission => 'intermediate' ),
  "set up data in tree with '$step'");

my @annotate = map { [ $_ => "$_ annotation" ] }
  ('std_id','std_id:bc X','my_check_list') ;
my %expect ;

foreach (@annotate) {
    my ($l,$a) = @$_ ;
    $expect{$l} = $a ;
    $root->grab($l)->annotation($a) ;
    ok(1,"set annotation of $l") ;
}

my $annotate_saver = Config::Model::Annotation->new (instance => $inst) ;
ok($annotate_saver,"created annotation read/write object") ;

my $h_ref = $annotate_saver->get_annotation_hash() ;

#use Data::Dumper ; print Dumper ( $h_ref ) ;

is_deeply ($h_ref,\%expect ,"check annotation data") ;
