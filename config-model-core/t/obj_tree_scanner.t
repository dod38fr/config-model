# -*- cperl -*-
# $Author: ddumont $
# $Date: 2007-01-08 12:51:49 $
# $Name: not supported by cvs2svn $
# $Revision: 1.7 $

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

sub disp_obj {
    my ( $scanner, $data_r, $obj, @element ) = @_;

    $$data_r .= "disp_obj " . $obj->name . " element: @element\n";

    map { $scanner->scan_element(  $data_r, $obj, $_ ) } @element;
}

sub disp_obj_elt {
    my ( $scanner, $data_r, $obj, $element, $key, $next ) = @_;

    $$data_r .= "disp_obj_elt " . $obj->name . " element: $element";
    $$data_r .= " key $key" if defined $key;
    $$data_r .= "\n";

    $scanner->scan_node( $data_r, $next);
}

sub disp_hash {
    my ( $scanner, $data_r, $obj, $element, @keys ) = @_;

    return unless @keys;

    $$data_r .= "disp_hash " . $obj->name . " element($element): @keys\n";

    map { $scanner->scan_hash( $data_r, $obj, $element, $_ ) } @keys;
}

sub disp_leaf {
    my ( $scanner, $data_r, $obj, $element, $index ) = @_;

    my $value = $obj->fetch_element($element) ;
    $value = $value-> fetch_with_id($index) if defined $index ;

    $$data_r .= "disp_leaf " . $obj->name . " element $element ";
    $$data_r .= "value ".$value->fetch  if defined $value->fetch;
    $$data_r .= "\n";
}

sub disp_up {
    my ($scanner, $data_r, $obj) = @_;

    $$data_r .= "disp_up " . $obj->name . "\n";

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

my $scan = Config::Model::ObjTreeScanner->new(

    #min_level => 'EXPERT',
    list_cb               => \&disp_hash,
    check_list_cb         => \&disp_hash,
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
    reference_value_cb    => \&disp_leaf,
    up_cb                 => \&disp_up
);

ok($scan, 'set up ObjTreeScanner');

my $result = '';

$scan->scan_node(\$result, $root) ;
ok(1,"performed scan") ;
print $result if $trace ;

my $expect = << 'EOF' ;
disp_obj Master element: std_id lista listb hash_a hash_b olist slave_y string_with_def a_string int_v my_check_list my_reference
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
disp_obj_elt Master element: slave_y
disp_obj slave_y element: std_id sub_slave warp2 Y
disp_obj_elt slave_y element: sub_slave
disp_obj slave_y sub_slave element: aa ab ac ad sub_slave
disp_leaf slave_y sub_slave element aa
disp_leaf slave_y sub_slave element ab
disp_leaf slave_y sub_slave element ac
disp_leaf slave_y sub_slave element ad
disp_obj_elt slave_y sub_slave element: sub_slave
disp_obj slave_y sub_slave sub_slave element: aa2 ab2 ac2 ad2 Z
disp_leaf slave_y sub_slave sub_slave element aa2
disp_leaf slave_y sub_slave sub_slave element ab2
disp_leaf slave_y sub_slave sub_slave element ac2
disp_leaf slave_y sub_slave sub_slave element ad2
disp_leaf slave_y sub_slave sub_slave element Z
disp_up slave_y sub_slave sub_slave
disp_up slave_y sub_slave
disp_obj_elt slave_y element: warp2
disp_obj slave_y warp2 element: aa ab ac ad sub_slave
disp_leaf slave_y warp2 element aa
disp_leaf slave_y warp2 element ab
disp_leaf slave_y warp2 element ac
disp_leaf slave_y warp2 element ad
disp_obj_elt slave_y warp2 element: sub_slave
disp_obj slave_y warp2 sub_slave element: aa2 ab2 ac2 ad2 Z
disp_leaf slave_y warp2 sub_slave element aa2
disp_leaf slave_y warp2 sub_slave element ab2
disp_leaf slave_y warp2 sub_slave element ac2
disp_leaf slave_y warp2 sub_slave element ad2
disp_leaf slave_y warp2 sub_slave element Z
disp_up slave_y warp2 sub_slave
disp_up slave_y warp2
disp_leaf slave_y element Y
disp_up slave_y
disp_leaf Master element string_with_def value yada yada
disp_leaf Master element a_string value toto tata
disp_leaf Master element int_v value 10
disp_leaf Master element my_reference
disp_up Master
EOF

$result =~ s/\s+\n/\n/g;
is_deeply( [split /\n/,$result], [split /\n/,$expect], "check result" );


my $scan2 = Config::Model::ObjTreeScanner->new(
    fallback => 'all',
    leaf_cb  => \&disp_leaf
);

ok($scan2, 'set up ObjTreeScanner with fallback');

$result = '';
$scan2->scan_node(\$result, $root) ;
ok(1,'performed scan with fallback');
print $result if $trace ;

$expect = << 'EOF' ;
disp_leaf std_id:ab element X value Bv
disp_leaf std_id:ab element Z
disp_leaf std_id:ab element DX value Dv
disp_leaf std_id:bc element X value Av
disp_leaf std_id:bc element Z
disp_leaf std_id:bc element DX value Dv
disp_leaf slave_y sub_slave element aa
disp_leaf slave_y sub_slave element ab
disp_leaf slave_y sub_slave element ac
disp_leaf slave_y sub_slave element ad
disp_leaf slave_y sub_slave sub_slave element aa2
disp_leaf slave_y sub_slave sub_slave element ab2
disp_leaf slave_y sub_slave sub_slave element ac2
disp_leaf slave_y sub_slave sub_slave element ad2
disp_leaf slave_y sub_slave sub_slave element Z
disp_leaf slave_y warp2 element aa
disp_leaf slave_y warp2 element ab
disp_leaf slave_y warp2 element ac
disp_leaf slave_y warp2 element ad
disp_leaf slave_y warp2 sub_slave element aa2
disp_leaf slave_y warp2 sub_slave element ab2
disp_leaf slave_y warp2 sub_slave element ac2
disp_leaf slave_y warp2 sub_slave element ad2
disp_leaf slave_y warp2 sub_slave element Z
disp_leaf slave_y element Y
disp_leaf Master element string_with_def value yada yada
disp_leaf Master element a_string value toto tata
disp_leaf Master element int_v value 10
disp_leaf Master element my_reference
EOF

$result =~ s/\s+\n/\n/g;

is_deeply( [split /\n/,$result], [split /\n/,$expect], "check result" );
