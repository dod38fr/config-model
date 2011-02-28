# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 31;
use Config::Model;
use Config::Model::Value ;
use Log::Log4perl qw(get_logger :levels) ;

use warnings;
no warnings qw(once);

use strict;

use Data::Dumper;
# use Config::Model::ObjTreeScanner;

use vars qw/$model/;

$model = Config::Model -> new (legacy => 'ignore',) ;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
my $log   = $arg =~ /l/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;
if (-r $log4perl_user_conf_file) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($log ? $TRACE: $WARN);
}

ok(1,"compiled");

$model->load(Master => 't/big_model.pm') ;

$model->augment_config_class(
    name => 'Master' ,
    element => [ 
        warn_if => { 
            type => 'leaf',
            value_type => 'string',
            warn_if_match => { 'foo' => { fix =>'$_ = uc;' }},
        },
	warn_unless => { 
	    type => 'leaf',
            value_type => 'string',
            warn_unless_match => { foo => { msg => '', fix =>'$_ = "foo".$_;' }},
        },
    ]
);

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

Config::Model::Exception::Any->Trace(1) if $trace =~ /e/;


my $step = qq!
warn_if=foobar
std_id:ab X=Bv -
std_id:ab2 -
std_id:bc X=Av -
std_id:"a b" X=Av -
std_id:"a b.c" X=Av -
tree_macro=mXY
hash_a:toto=toto_value
hash_a:titi=titi_value
hash_a:"ti ti"="ti ti value"
ordered_hash:z=1
ordered_hash:y=2
ordered_hash:x=3
lista=a,b,c,d
olist:0 X=Av -
olist:1 X=Bv -
my_reference="titi"
warp warp2 aa2="foo bar"
!;

$Config::Model::Value::nowarning=1;
ok( $root->load( step => $step, experience => 'advanced' ),
  "set up data in tree");

my @expected = (
		[ ''    , 'lista'],
		[ ''    , 'lista:0'],
		[ 'back', 'lista:1'],
		[ ''    , 'lista:0'],
		[ 'for' , 'lista'],
		[ ''    , 'lista:0'],
		[ ''    , 'lista:1'],
		[ ''    , 'lista:2'],
		[ ''    , 'lista:3'],
		[ ''    , 'hash_a'],
		[ ''    , 'hash_a:"ti ti"'],
		[ ''    , 'hash_a:titi'],
		[ ''    , 'hash_a:toto'],
		[ ''    , 'tree_macro' ],
		[ ''    , 'a_string' ] ,
		[ 'back', 'int_v' ] ,
		[ ''    , 'a_string' ] ,
		[ ''    , 'tree_macro' ],
		[ ''    , 'hash_a:toto'],
		[ 'for' , 'hash_a:titi'],
		[ ''    , 'hash_a:toto'],
		[ ''    , 'tree_macro' ],
		[ ''    , 'a_string' ] ,
		[ ''    , 'int_v' ] ,
		[ 'back'    , 'warn_if' ],
		[ 'bail' , 'int_v' ], 
	       ) ;

my $steer = sub {
    my ($iter, $item) = @_;
    my ($dir,$expect) = @$item ;
    $iter->bail_out    if $dir eq 'bail' ;
    $iter->go_forward  if $dir eq 'for' ;
    $iter->go_backward if $dir eq 'back' ;
    return @$item ;
} ;

my $leaf_element_cb = sub {
    my ($iter, $data_r,$node,$element,$index, $leaf_object) = @_ ;
    print "test: leaf_element_cb called for ",$leaf_object->location,"\n" 
      if $trace ;
    my ($dir, $expect) = $steer->($iter,shift @expected) ;
    is( $leaf_object->location, $expect, "leaf_element_cb got $expect and '$dir'" ) ;
};

my $int_cb = sub {
    my ($iter, $data_r,$node,$element,$index, $leaf_object) = @_ ;
    print "test: int_cb called for ",$leaf_object->location,"\n" 
      if $trace ;
    my ($dir, $expect) = $steer->($iter,shift @expected) ;
    is( $leaf_object->location, $expect, "int_cb got $expect and '$dir'" ) ;
};

my $hash_element_cb = sub {
    my ($iter, $data_r,$node,$element,@keys) = @_ ;
    print "test: hash_element_cb called for ",$node->location," element $element\n" 
      if $trace ;
    my $obj = $node->fetch_element($element) ;
    my ($dir, $expect) = $steer->($iter,shift @expected) ;
    is( $obj->location, $expect, "hash_element_cb got $expect and '$dir'" ) ;
};

my $list_element_cb = sub {
    my ($iter, $data_r,$node,$element,@idx) = @_ ;
    print "test: list_element_cb called for ",$node->location," element $element\n" 
      if $trace ;
    my $obj = $node->fetch_element($element) ;
    my ($dir, $expect) = $steer->($iter,shift @expected) ;
    is( $obj->location, $expect, "list_element_cb got $expect and '$dir'" ) ;
};

my $iterator = $inst->iterator(
    leaf_cb                => $leaf_element_cb,
    integer_value_cb       => $int_cb,
    hash_element_cb        => $hash_element_cb,
    list_element_cb        => $list_element_cb,
    experience             => 'advanced',
    call_back_on_warning   => 1,
    call_back_on_important => 1,
);
ok( $iterator, "created iterator helper" );

$iterator->start ;

is_deeply(\@expected,[],"iterator explored all items") ;


