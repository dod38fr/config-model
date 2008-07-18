# -*- cperl -*-
# $Author$
# $Date$
# $Revision$

use ExtUtils::testlib;
use Test::More tests => 57;
use Config::Model;

use warnings;
no warnings qw(once);

use strict;

my $model = Config::Model -> new(legacy => 'ignore',)  ;

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file => 't/big_model.pm',
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

# check with embedded \n
my $step = qq!std_id:ab X=Bv -\na_string="titi and\ntoto" !;
ok( $root->load( step => $step, permission => 'intermediate' ),
  "load '$step'");
is( $root->fetch_element('a_string')->fetch, "titi and\ntoto",
  "check a_string");

$step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="titi , toto" ';
ok( $root->load( step => $step, permission => 'intermediate' ),
  "load '$step'");
is( $root->fetch_element('a_string')->fetch, 'titi , toto',
  "check a_string");


ok( $root->load( step => 'tree_macro=XZ', permission => 'advanced' ),
  "Set tree_macro to XZ");

# test load with warped_node below root (used to fail)
$step = 'slave_y warp2 aa2="foo bar baz"';
ok( $root->load( step => $step, permission => 'intermediate' ),
  "load '$step'");

ok( $root->load( step => 'tree_macro=XY', permission => 'advanced' ),
  "Set tree_macro to XY");

# use indexes with white spaces

$step = 'std_id:"a b" X=Bv - std_id:" b  c " X=Av " ';
ok( $root->load( step => $step, permission => 'intermediate' ),
  "load '$step'");

is_deeply([ $root->fetch_element('std_id')->get_all_indexes ],
	  [ ' b  c ', 'a b','ab','bc'],
	  "check indexes");

$step = 'std_id:ab ZZX=Bv - std_id:bc X=Bv';
eval {$root->load( step => $step, permission => 'intermediate' ); };
ok($@,"load wrong '$step'");
print "normal error:\n", $@, "\n" if $trace;

$step = 'lista=a,b,c,d olist:0 X=Av - olist:1 X=Bv - listb=b,c,d,,f,"",h,0';
ok( $root->load( step => $step, permission => 'intermediate' ),
  "load '$step'");

# perform some checks
my $olist = $root->fetch_element('olist') ;
is($olist->fetch_with_id(0)->element_name, 'olist', 'check list element_name') ;

map {
    is($olist->fetch_with_id($_)->config_class_name, 'SlaveZ', 
       "check list element $_ class") ;
    } (0,1) ;

my $lista = $root->fetch_element('lista') ;
isa_ok($lista, 'Config::Model::ListId','check lista class');
map {
    isa_ok($lista->fetch_with_id($_), 'Config::Model::Value', 
       "check lista element $_ class") ;
    } (0,1) ;

is($olist->fetch_with_id(0)->fetch_element('X')->fetch, 'Av', 
   "check list element 0 content") ;
is($olist->fetch_with_id(1)->fetch_element('X')->fetch, 'Bv', 
   "check list element 1 content") ;

my @expect = qw/a b c d/;
map {
    is($lista->fetch_with_id($_)->fetch, $expect[$_], 
       "check lista element $_ content") ;
    } (0 .. $#expect) ;

my $listb = $root->fetch_element('listb') ;
@expect = (qw/b c d/,undef,'f','','h','0');
map {
    is($listb->fetch_with_id($_)->fetch, $expect[$_], 
       "check listb element $_ content") ;
    } (0 .. $#expect) ;

$step = 'a_string="foo bar"';
ok( $root->load( step => $step, ), "load quoted string: '$step'");
is( $root->fetch_element('a_string')->fetch, "foo bar",
  'check result');


$step = 'a_string="foo bar baz" lista=a,b,c,d,e';
ok( $root->load( step => $step, ), "load : '$step'");
is( $root->fetch_element('a_string')->fetch, "foo bar baz",
  'check result' );

@expect = qw/a b c d e/;
map {
    is($lista->fetch_with_id($_)->fetch, $expect[$_], 
       "check lista element $_ content") ;
    } (0 .. 4) ;

# set the value of the previous object
$step = 'std_id:f/o/o:b.ar X=Bv' ;
ok( $root->load( step => $step, ), "load : '$step'");
is_deeply( [sort $root->fetch_element('std_id')->get_all_indexes ],
	   [' b  c ', 'a b',qw!ab bc f/o/o:b.ar!],
	   "check result after load '$step'" );

$step = 'hash_a:a=z hash_a:b=z2 hash_a:"a b "="z 1"' ;
ok( $root->load( step => $step, ), "load : '$step'");
is_deeply( [sort $root->fetch_element('hash_a')->get_all_indexes ],
	   ['a','a b ','b'],
	   "check result after load '$step'" );
is($root->fetch_element('hash_a')->fetch_with_id('a')->fetch,'z',
   'check result');

my $elt = $root->fetch_element('hash_a')->fetch_with_id('a b ');
is($elt->fetch,'z 1', 'check result with white spaces');

is ($elt->location,'hash_a:"a b "', 'check location') ;

$step = 'my_check_list=a,"a b "' ;
ok( $root->load( step => $step, ), "load : '$step'");

$step = 'a_string="a \"b\" "' ;
ok( $root->load( step => $step, ), "load : '$step'");
is($root->fetch_element('a_string')->fetch , 'a "b" ',
  "test value loaded by '$step'");

$step = 'lista=a,"a \"b\" "' ;
ok( $root->load( step => $step, ), "load : '$step'");
is($root->fetch_element('lista')->fetch_with_id(1)->fetch ,
   'a "b" ',
   "test value loaded by '$step'");

$step = 'lista~1 hash_a~"a b "' ;
ok( $root->load( step => $step, ), "load : '$step'");
is($root->fetch_element('lista')->fetch_with_id(1)->fetch ,
   undef,
   "test list value loaded by '$step'");
my $elt = $root->fetch_element('hash_a')->fetch_with_id('a b ');
is($elt->fetch,undef, "test hash value loaded by '$step'");

