# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-01-18 17:06:20 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

use ExtUtils::testlib;
use Test::More tests => 33;
use Config::Model;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model -> new ;

my $file = 't/big_model.pm';

my $return ;
unless ($return = do $file) {
    warn "couldn't parse $file: $@" if $@;
    warn "couldn't do $file: $!"    unless defined $return;
    warn "couldn't run $file"       unless $return;
}

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
				 instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="titi , toto" ';
ok( $root->load( step => $step, role => 'intermediate' ),
  "load '$step'");
is( $root->get_element_for('a_string')->fetch, 'titi , toto',
  "check a_string");

ok( $root->load( step => 'tree_macro=XY', role => 'advanced' ),
  "Set tree_macro");


$step = 'std_id:ab ZZX=Bv - std_id:bc X=Bv';
eval {$root->load( step => $step, role => 'intermediate' ); };
ok($@,"load wrong '$step'");
print "normal error:\n", $@, "\n" if $trace;

$step = 'lista=a,b,c,d olist:0 X=Av - olist:1 X=Bv - listb=b,c,d';
ok( $root->load( step => $step, role => 'intermediate' ),
  "load '$step'");

# perform some checks
my $olist = $root->get_element_for('olist') ;
is($olist->fetch(0)->element_name, 'olist', 'check list element_name') ;

map {
    is($olist->fetch($_)->config_class_name, 'SlaveZ', 
       "check list element $_ class") ;
    } (0,1) ;

my $lista = $root->get_element_for('lista') ;
isa_ok($lista, 'Config::Model::ListId','check lista class');
map {
    isa_ok($lista->fetch($_), 'Config::Model::Value', 
       "check lista element $_ class") ;
    } (0,1) ;

is($olist->fetch(0)->get_element_for('X')->fetch, 'Av', 
   "check list element 0 content") ;
is($olist->fetch(1)->get_element_for('X')->fetch, 'Bv', 
   "check list element 1 content") ;

my @expect = qw/a b c d/;
map {
    is($lista->fetch($_)->fetch, $expect[$_], 
       "check lista element $_ content") ;
    } (0 .. 3) ;

$step = 'a_string="foo bar"';
ok( $root->load( step => $step, ), "load quoted string: '$step'");
is( $root->get_element_for('a_string')->fetch, "foo bar",
  'check result');


$step = 'a_string="foo bar baz" lista=a,b,c,d,e';
ok( $root->load( step => $step, ), "load : '$step'");
is( $root->get_element_for('a_string')->fetch, "foo bar baz",
  'check result' );

@expect = qw/a b c d e/;
map {
    is($lista->fetch($_)->fetch, $expect[$_], 
       "check lista element $_ content") ;
    } (0 .. 4) ;

# set the value of the previous obecjt
$step = 'std_id:f/o/o:b.ar X=Bv' ;
ok( $root->load( step => $step, ), "load : '$step'");
is_deeply( [sort $root->get_element_for('std_id')->get_all_indexes ],
	   [qw!ab bc f/o/o:b.ar!],
	   'check result' );

$step = 'hash_a:a=z hash_a:b=z2' ;
ok( $root->load( step => $step, ), "load : '$step'");
is_deeply( [sort $root->get_element_for('hash_a')->get_all_indexes ],
	   [qw!a b!],
	   'check result' );
is($root->get_element_for('hash_a')->fetch('a')->fetch,'z', 'check result');
