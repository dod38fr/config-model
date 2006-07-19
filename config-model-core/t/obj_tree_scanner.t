# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-07-19 12:26:53 $
# $Name: not supported by cvs2svn $
# $Revision: 1.5 $

use ExtUtils::testlib;
use Test::More tests => 9;
use Config::Model;
use Config::Model::ObjTreeScanner ;

use warnings;
no warnings qw(once);

use strict;

use Data::Dumper;
# use Config::Model::ObjTreeScanner;

use vars qw/$model/;

$model = Config::Model -> new ;

my $scan;
my $result = '';

sub disp_obj {
    my ( $obj, @element ) = @_;

    $result .= "disp_obj " . $obj->name . " element: @element\n";

    map { $scan->scan_element( $obj, $_ ) } @element;
}

sub disp_obj_elt {
    my ( $obj, $element, $key ) = @_;

    $result .= "disp_obj_elt " . $obj->name . " element: $element";
    $result .= " key $key" if defined $key;
    $result .= "\n";

    my $next = $obj->fetch_element($element) ;
    $next = $next-> fetch_with_id($key) if defined $key ;

    $scan->scan_node($next);
}

sub disp_hash {
    my ( $obj, $element, @keys ) = @_;

    return unless @keys;

    $result .= "disp_hash " . $obj->name . " element($element): @keys\n";

    map { $scan->scan_hash( $obj, $element, $_ ) } @keys;
}

sub disp_leaf {
    my ( $obj, $element, $index ) = @_;

    my $value = $obj->fetch_element($element) ;
    $value = $value-> fetch_with_id($index) if defined $index ;

    $result .= "disp_leaf " . $obj->name . " element $element ";
    $result .= "value ".$value->fetch  if defined $value->fetch;
    $result .= "\n";
}

sub disp_up {
    my ($obj) = @_;

    $result .= "disp_up " . $obj->name . "\n";

}

my $trace = shift || 0;
$::verbose          = 1 if $trace =~ /v/;
$::debug            = 1 if $trace =~ /d/;
Config::Model::Exception::Any->Trace(1) if $trace =~ /e/;

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file => 't/big_model.pm',
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata"';
ok( $root->load( step => $step, permission => 'intermediate' ),
  "set up data in tree with '$step'");

$scan = Config::Model::ObjTreeScanner->new(

    #min_level => 'EXPERT',
    list_cb               => \&disp_hash,
    hash_cb               => \&disp_hash,
    element_cb            => \&disp_obj,
    node_cb               => \&disp_obj_elt,
    leaf_cb               => \&disp_leaf,
    enum_value_cb         => \&disp_leaf,
    enum_integer_value_cb => \&disp_leaf,
    integer_value_cb      => \&disp_leaf,
    number_value_cb       => \&disp_leaf,
    boolean_value_cb      => \&disp_leaf,
    string_value_cb       => \&disp_leaf,
    up_cb                 => \&disp_up
);

ok($scan, 'set up ObjTreeScanner');

$scan->scan_node($root) ;
ok(1,"performed scan") ;

my $expect = << 'EOF' ;
disp_obj Master element: std_id lista listb hash_a hash_b olist string_with_def a_string int_v
disp_hash Master element(std_id): ab bc
disp_obj_elt Master element: std_id key ab
disp_obj std_id:ab element: X Z DX
disp_leaf std_id:ab element X value Bv
disp_leaf std_id:ab element Z 
disp_leaf std_id:ab element DX value Dv
disp_up std_id:ab
disp_obj_elt Master element: std_id key bc
disp_obj std_id:bc element: X Z DX
disp_leaf std_id:bc element X value Av
disp_leaf std_id:bc element Z 
disp_leaf std_id:bc element DX value Dv
disp_up std_id:bc
disp_leaf Master element string_with_def value yada yada
disp_leaf Master element a_string value toto tata
disp_leaf Master element int_v value 10
disp_up Master
EOF

is_deeply( [split /\n/,$result], [split /\n/,$expect], "check result" );


my $scan2 = Config::Model::ObjTreeScanner->new(
    fallback => 'all',
    leaf_cb  => \&disp_leaf
);

ok($scan2, 'set up ObjTreeScanner with fallback');

$result = '';
$scan2->scan_node($root) ;
ok(1,'performed scan with fallback');

$expect = << 'EOF' ;
disp_leaf std_id:ab element X value Bv
disp_leaf std_id:ab element Z 
disp_leaf std_id:ab element DX value Dv
disp_leaf std_id:bc element X value Av
disp_leaf std_id:bc element Z 
disp_leaf std_id:bc element DX value Dv
disp_leaf Master element string_with_def value yada yada
disp_leaf Master element a_string value toto tata
disp_leaf Master element int_v value 10
EOF

is_deeply( [split /\n/,$result], [split /\n/,$expect], "check result" );
