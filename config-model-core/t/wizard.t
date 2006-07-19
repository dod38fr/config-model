# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-07-19 12:26:53 $
# $Name: not supported by cvs2svn $
# $Revision: 1.2 $

use ExtUtils::testlib;
use Test::More tests => 6;
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

my @leaf_cb_expect = ( 'Master tree_macro', 'Master a_string' ) ;
my @hash_cb_expect = ( 'Master hash_a id' ) ;

my $leaf_cb = sub {
    my ($node,$element,$index, $leaf_object) = @_ ;
    print "test: leaf_cb called for ",$leaf_object->name,"\n" 
      if $::trace ;
    my $expect = shift @leaf_cb_expect ;
    is( $leaf_object->name, $expect, "leaf_cb got $expect" ) ;
};

my $hash_cb = sub {
    my ($node,$element,@keys) = @_ ;
    print "test: hash_cb called for ",$node->name," element $element\n" 
      if $::trace ;
    my $obj = $node->fetch_element($element) ;
    my $expect = shift @hash_cb_expect ;
    is( $obj->name, $expect, "hash_cb got $expect" ) ;
};

my $wizard = $inst->wizard_helper(leaf_cb => $leaf_cb, 
				  hash_cb => $hash_cb,
				  permission => 'advanced') ;
ok($wizard,"created wizard helper") ;

$wizard->start ;

