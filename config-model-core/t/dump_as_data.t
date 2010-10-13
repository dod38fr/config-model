# -*- cperl -*-
# $Author$
# $Date$
# $Revision$

use ExtUtils::testlib;
use Test::More tests => 29;
use Config::Model;

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
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $ERROR);

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file => 't/dump_load_model.pm',
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;
ok($root,"Config root created") ;

my $step = '
std_id:ab X=Bv -
std_id:bc X=Av -
tree_macro=mXY
a_string="toto tata"
hash_a:toto=toto_value 
hash_a:titi=titi_value
ordered_hash:z=1 
ordered_hash:y=2
ordered_hash:x=3 
lista=a,b,c,d
olist:0 X=Av -
olist:1 X=Bv -
my_check_list=toto my_reference="titi"
warp warp2 aa2="foo bar"
';

$step =~ s/\n/ /g;

ok( $root->load( step => $step, experience => 'advanced' ),
  "set up data in tree with '$step'");

# load some values with undef
$root->fetch_element('hash_a')->fetch_with_id('undef_val') ;
$root->fetch_element('lista' )->fetch_with_id(6)->store('g');

$root->load_data({ listb => 'bb'}) ;
ok (1, "loaded single array element as listb => 'bb'") ;

my $data = $root->dump_as_data(full_dump => 0) ;

my $expect = {
	      'olist' => [{'X' => 'Av'}, {'X' => 'Bv'}],
	      'my_check_list' => ['toto'],
	      'tree_macro' => 'mXY',
	      'ordered_hash' => ['z', '1', 'y', '2', 'x', '3'],
	      'a_string' => 'toto tata',
	      'listb' => ['bb'],
	      'my_reference' => 'titi',
	      'hash_a' => {
			   'toto' => 'toto_value',
			   'titi' => 'titi_value',
			   undef_val => undef ,
			  },
	      'std_id' => {
			   'ab' => {'X' => 'Bv'},
			   'bc' => {'X' => 'Av'}
			  },
	      'lista' => [qw/a b c d g/],
	      'warp' => {
			 'warp2' => {
				     'aa2' => 'foo bar'
				    }
			},
       };

#use Data::Dumper; print Dumper $data ;

is_deeply($data, $expect, "check data dump") ;

# add default information provided by model to check full dump
$expect->{string_with_def} = 'yada yada';
$expect->{int_v} = 10 ;
$expect->{olist}[0]{DX} = 'Dv' ;
$expect->{olist}[1]{DX} = 'Dv' ;
$expect->{std_id}{ab}{DX} = 'Dv' ;
$expect->{std_id}{bc}{DX} = 'Dv' ;
$expect->{a_uniline} = 'yada yada';
my $full_data = $root->dump_as_data() ;

is_deeply($full_data, $expect, "check full data dump") ;


my $inst2 = $model->instance (root_class_name => 'Master', 
			      instance_name => 'test2');
ok($inst,"created 2nd dummy instance") ;

my $root2 = $inst2 -> config_root ;
ok($root2,"Config root2  created") ;

$root2->load_data($data) ;

ok(1,"loaded perl data structure in 2nd instance") ;

my $dump1 = $root ->dump_tree ;
my $dump2 = $root2->dump_tree ;

is($dump2, $dump1, 
   "check that dump of 2nd tree is identical to dump of the first tree") ;

# try partial dumps

my @tries = ( [ 'olist' => $expect->{olist}  ],
	      [ 'olist:0' => $expect->{olist}[0] ],
	      [ 'olist:0 DX' => $expect->{olist}[0]{DX} ],
	      [ 'string_with_def' => $expect->{string_with_def} ],
	      [ 'ordered_hash' => $expect->{ordered_hash} ],
	      [ 'hash_a' => $expect->{hash_a} ],
	      [ 'std_id:ab' => $expect->{std_id}{ab} ],
	      [ 'my_check_list' => $expect->{my_check_list} ],
	    );

foreach my $test ( @tries ) {
    my ($path, $expect) = @$test ;
    my $obj = $root->grab($path) ;
    my $dump = $obj->dump_as_data();
    is_deeply($dump, $expect, "check data dump for '$path'") ; 
}

# try dump of ordered hash as hash
my $ohah_dump = $root->grab('ordered_hash')
  -> dump_as_data(ordered_hash_as_list => 0);
is_deeply($ohah_dump, { __order => [qw/z y x/],'z', '1', 'y', '2', 'x', '3'},
	  "check dump of ordered hash as hash") ; 


# test ordered hash load with hash ref instead of array ref
my $inst3 = $model->instance (root_class_name => 'Master', 
			      instance_name => 'test3');
ok($inst,"created 3rd dummy instance") ;
my $root3= $inst3->config_root ;
$data->{ordered_hash} = { @{$expect->{ordered_hash}}} ;
$root3->load_data($data); 

@tries    = ( [ 'olist' => $expect->{olist}  ],
	      [ 'olist:0' => $expect->{olist}[0] ],
	      [ 'olist:0 DX' => $expect->{olist}[0]{DX} ],
	      [ 'string_with_def' => $expect->{string_with_def} ],
	      [ 'ordered_hash' =>  [qw/x 3 y 2 z 1/] ],
	      [ 'hash_a' => $expect->{hash_a} ],
	      [ 'std_id:ab' => $expect->{std_id}{ab} ],
	      [ 'my_check_list' => $expect->{my_check_list} ],
	    );

foreach my $test ( @tries ) {
    my ($path, $expect) = @$test ;
    my $obj = $root3->grab($path) ;
    my $dump = $obj->dump_as_data();
    is_deeply($dump, $expect, "check data dump for '$path'") ; 
}

