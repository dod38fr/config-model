# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 10;
use Config::Model;
use Config::Model::ObjTreeScanner ;

use warnings;
no warnings qw(once);

use strict;

use Data::Dumper;
# use Config::Model::ObjTreeScanner;

use vars qw/$model/;

$model = Config::Model -> new (legacy => 'ignore',) ;

sub disp_node_content {
    my ( $scanner, $data_r, $node, @element ) = @_;

    $$data_r .= "disp_node_content " . $node->name . " element: @element\n";

    map { $scanner->scan_element(  $data_r, $node, $_ ) } @element;
}

sub disp_node_elt {
    my ( $scanner, $data_r, $node, $element, $key, $next ) = @_;

    $$data_r .= "disp_node_elt " . $node->name . " element: $element";
    $$data_r .= " key $key" if defined $key;
    $$data_r .= "\n";

    $scanner->scan_node( $data_r, $next);
}

sub disp_hash {
    my ( $scanner, $data_r, $node, $element, @keys ) = @_;

    return unless @keys;

    $$data_r .= "disp_hash " . $node->name . " element($element): @keys\n";

    map { $scanner->scan_hash( $data_r, $node, $element, $_ ) } @keys;
}

sub disp_check_list {
    my ( $scanner, $data_r, $node, $element, @choices ) = @_;

    return unless @choices;

    $$data_r .= "disp_check_list " . $node->name . " element($element): "
      . join(',',$node->fetch_element($element)->get_checked_list) . " are set\n";

}

sub disp_leaf {
    my ( $scanner, $data_r, $node, $element, $index ) = @_;

    my $value = $node->fetch_element($element) ;
    $value = $value-> fetch_with_id($index) if defined $index ;

    $$data_r .= "disp_leaf " . $node->name . " element $element ";
    $$data_r .= "value ".$value->fetch  if defined $value->fetch;
    $$data_r .= "\n";
}

sub disp_up {
    my ($scanner, $data_r, $node) = @_;

    $$data_r .= "disp_up " . $node->name . "\n";

}

my $arg = shift || '';

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

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata" '
 .'hash_a:X2=x hash_a:Y2=xy  hash_b:X3=xy my_check_list=X2,X3';
ok( $root->load( step => $step, experience => 'advanced' ),
  "set up data in tree with '$step'");

my $scan = Config::Model::ObjTreeScanner->new(

    #min_level => 'EXPERT',
    list_element_cb       => \&disp_hash,
    check_list_element_cb => \&disp_check_list,
    hash_element_cb       => \&disp_hash,
    node_element_cb       => \&disp_node_elt,
    node_content_cb       => \&disp_node_content,
    leaf_cb               => \&disp_leaf,
    enum_value_cb         => \&disp_leaf,
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
disp_node_content Master element: std_id lista listb hash_a hash_b ordered_hash olist slave_y string_with_def a_uniline a_string int_v my_check_list my_reference
disp_hash Master element(std_id): ab bc
disp_node_elt Master element: std_id key ab
disp_node_content std_id:ab element: Z X DX
disp_leaf std_id:ab element Z
disp_leaf std_id:ab element X value Bv
disp_leaf std_id:ab element DX value Dv
disp_up std_id:ab
disp_node_elt Master element: std_id key bc
disp_node_content std_id:bc element: Z X DX
disp_leaf std_id:bc element Z
disp_leaf std_id:bc element X value Av
disp_leaf std_id:bc element DX value Dv
disp_up std_id:bc
disp_hash Master element(hash_a): X2 Y2
disp_leaf Master element hash_a value x
disp_leaf Master element hash_a value xy
disp_hash Master element(hash_b): X3
disp_leaf Master element hash_b value xy
disp_node_elt Master element: slave_y
disp_node_content slave_y element: X std_id sub_slave warp2 Y
disp_leaf slave_y element X
disp_node_elt slave_y element: sub_slave
disp_node_content slave_y sub_slave element: aa ab ac ad sub_slave
disp_leaf slave_y sub_slave element aa
disp_leaf slave_y sub_slave element ab
disp_leaf slave_y sub_slave element ac
disp_leaf slave_y sub_slave element ad
disp_node_elt slave_y sub_slave element: sub_slave
disp_node_content slave_y sub_slave sub_slave element: aa2 ab2 ac2 ad2 Z
disp_leaf slave_y sub_slave sub_slave element aa2
disp_leaf slave_y sub_slave sub_slave element ab2
disp_leaf slave_y sub_slave sub_slave element ac2
disp_leaf slave_y sub_slave sub_slave element ad2
disp_leaf slave_y sub_slave sub_slave element Z
disp_up slave_y sub_slave sub_slave
disp_up slave_y sub_slave
disp_node_elt slave_y element: warp2
disp_node_content slave_y warp2 element: aa ab ac ad sub_slave
disp_leaf slave_y warp2 element aa
disp_leaf slave_y warp2 element ab
disp_leaf slave_y warp2 element ac
disp_leaf slave_y warp2 element ad
disp_node_elt slave_y warp2 element: sub_slave
disp_node_content slave_y warp2 sub_slave element: aa2 ab2 ac2 ad2 Z
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
disp_leaf Master element a_uniline value yada yada
disp_leaf Master element a_string value toto tata
disp_leaf Master element int_v value 10
disp_check_list Master element(my_check_list): X2,X3 are set
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
disp_leaf std_id:ab element Z
disp_leaf std_id:ab element X value Bv
disp_leaf std_id:ab element DX value Dv
disp_leaf std_id:bc element Z
disp_leaf std_id:bc element X value Av
disp_leaf std_id:bc element DX value Dv
disp_leaf Master element hash_a value x
disp_leaf Master element hash_a value xy
disp_leaf Master element hash_b value xy
disp_leaf slave_y element X
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
disp_leaf Master element a_uniline value yada yada
disp_leaf Master element a_string value toto tata
disp_leaf Master element int_v value 10
disp_leaf Master element my_check_list value X2,X3
disp_leaf Master element my_reference
EOF

$result =~ s/\s+\n/\n/g;

is_deeply( [split /\n/,$result], [split /\n/,$expect], "check result" );

# test dump of mandatory values

my $model2 = Config::Model->new(legacy => 'ignore',) ;
$model2 ->create_config_class 
  (
   name => "SomeRootClass",
   element => [ a_string => { type => 'leaf',
			     mandatory => 1 ,
			     value_type => 'string'
			   },
	      ],
  ) ;

my $inst2 = $model2->instance(root_class_name => 'SomeRootClass',
			      instance_name => 'test',
			     );

my $root2 = $inst2->config_root ;

eval{ $root2->dump_tree(auto_vivify => 1) ;};
ok($@,"expected failure of dump with empty mandatory value") ;
print "normal error:", $@, "\n" if $trace;
