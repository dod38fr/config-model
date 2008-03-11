# -*- cperl -*-
# $Author$
# $Date$
# $Revision$

use ExtUtils::testlib;
use Test::More tests => 14;
use Config::Model;

use warnings;
no warnings qw(once);

use strict;

use Data::Dumper;
# use Config::Model::ObjTreeScanner;

use vars qw/$model/;

$model = Config::Model -> new ;

my $trace = shift || 0;
$::verbose          = 1 if $trace =~ /v/;
$::debug            = 1 if $trace =~ /d/;
$::trace            = 1 if $trace =~ /t/;

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file => 't/big_model.pm',
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

Config::Model::Exception::Any->Trace(1) if $trace =~ /e/;

my @expected = (
		[ ''    , 'Master hash_a id'],
		[ ''    , 'Master tree_macro' ],
		[ ''    , 'Master a_string' ] ,
		[ 'back', 'Master int_v' ] ,
		[ ''    , 'Master a_string' ] ,
		[ ''    , 'Master tree_macro' ],
		[ 'for' , 'Master hash_a id'],
		[ ''    , 'Master tree_macro' ],
		[ ''    , 'Master a_string' ] ,
		[ ''    , 'Master int_v' ] ,
	       ) ;

my $steer = sub {
    my ($wiz, $item) = @_;
    my ($dir,$expect) = @$item ;
    $wiz->go_forward  if $dir eq 'for' ;
    $wiz->go_backward if $dir eq 'back' ;
    return $expect ;
} ;

my $leaf_element_cb = sub {
    my ($wiz, $data_r,$node,$element,$index, $leaf_object) = @_ ;
    print "test: leaf_element_cb called for ",$leaf_object->name,"\n" 
      if $::trace ;
    my $expect = $steer->($wiz,shift @expected) ;
    is( $leaf_object->name, $expect, "leaf_element_cb got $expect" ) ;
};

my $int_cb = sub {
    my ($wiz, $data_r,$node,$element,$index, $leaf_object) = @_ ;
    print "test: int_cb called for ",$leaf_object->name,"\n" 
      if $::trace ;
    my $expect = $steer->($wiz,shift @expected) ;
    is( $leaf_object->name, $expect, "int_cb got $expect" ) ;
};

my $hash_element_cb = sub {
    my ($wiz, $data_r,$node,$element,@keys) = @_ ;
    print "test: hash_element_cb called for ",$node->name," element $element\n" 
      if $::trace ;
    my $obj = $node->fetch_element($element) ;
    my $expect = $steer->($wiz,shift @expected) ;
    is( $obj->name, $expect, "hash_element_cb got $expect" ) ;
};

my $wizard = $inst->wizard_helper(leaf_cb          => $leaf_element_cb, 
				  integer_value_cb => $int_cb,
				  hash_element_cb  => $hash_element_cb,
				  permission       => 'advanced') ;
ok($wizard,"created wizard helper") ;

$wizard->start ;

is_deeply(\@expected,[],"wizard explored all items") ;


