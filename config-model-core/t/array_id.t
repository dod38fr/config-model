# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Test::Exception ;
use Config::Model;

BEGIN { plan tests => 68; }

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"Compilation done");

my @element = ( 
	       # Value constructor args are passed in their specific array ref
	       cargo => { type => 'leaf',
			  value_type => 'string'
			},
	      ) ;

# minimal set up to get things working
my $model = Config::Model->new(legacy => 'ignore',) ;
$model ->create_config_class 
  (
   name => "Master",
   element 
   => [ 
       bounded_list 
       => { type => 'list',
	    # hash_class constructor args are all keys of this hash
	    # except type and class
	    list_class => 'Config::Model::ListId', # default

	    max => 123, 
	    cargo_type => 'leaf',
	    cargo_args => {value_type => 'string'},
	  },
       plain_list => { type => 'list' , @element } ,
       list_with_auto_created_id
       => {
	   type => 'list',
	   auto_create => 4,
	   @element
	  },
       [qw/list_with_default_id list_with_default_id_2/]
       => {
	   type => 'list',
	   default    => 1 ,
	   @element
	  },
       list_with_several_default_keys
       => {
	   type => 'list',
	   default    => [2..5],
	   @element
	  },
       olist => {
		 type => 'list',
		 cargo => { type=>'node',
			    config_class_name => 'Slave'} ,
		}
       ]
   ) ;

$model ->create_config_class 
  (
   name => "Bogus",
   element 
   => [ 
       list_with_wrong_auto_create
       => {
	   type => 'list',
	   auto_create => [ 'foo' ],
	   @element
	  },
       ]
  ) ;

$model -> create_config_class 
  (
   name => "Slave",
   element 
   =>  [
	[qw/X Y Z/] => {
			type => 'leaf',
			value_type => 'enum',
			choice     => [qw/Av Bv Cv/]
		       },
       ]
  );

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $b = $root->fetch_element('bounded_list');
ok($b,"bounded list created") ;


is($b->fetch_with_id(1)->store('foo'),'foo',"stored in 1") ;
is($b->fetch_with_id(0)->store('baz'),'baz',"stored in 0") ;
is($b->fetch_with_id(2)->store('bar'),'bar',"stored in 2") ;

throws_ok { $b->fetch_with_id(124)->store('baz') ;} 
  qr/Index 124 > max_index limit 123/,'max error caught';

my $bogus_root = $model->instance(root_class_name =>'Bogus')->config_root;
throws_ok { $bogus_root->fetch_element('list_with_wrong_auto_create') ;} 
  qr/Wrong auto_create argument for list/,'wrong auto_create caught';

is_deeply([$b->get_all_indexes],[0,1,2],"check ids") ;

$b->delete(1) ;
is($b->fetch_with_id(1)->fetch, undef,"check deleted id") ;

is($b->index_type,'integer','check list index_type') ;
is($b->max_index,123,'check list max boundary') ;

$b->push('toto','titi') ;
is($b->fetch_with_id(2)->fetch, 'bar', "check last item of table") ;
is($b->fetch_with_id(3)->fetch, 'toto',"check pushed item") ;
is($b->fetch_with_id(4)->fetch, 'titi',"check pushed item") ;

my @all = $b->fetch_all_values ;
is_deeply(\@all,[qw/baz bar toto titi/],"check fetch_all_values") ;

my $ld1 = $root->fetch_element('list_with_default_id');
is_deeply([$ld1->get_all_indexes],[0,1],"check list_with_default_id ids") ;

my $lds = $root->fetch_element('list_with_several_default_keys');
is_deeply([$lds->get_all_indexes],[0 .. 5],"check list_with_several_default_keys") ;

my $lac = $root->fetch_element('list_with_auto_created_id');
is_deeply([$lac->get_all_indexes],[0 .. 3],"check list_with_auto_created_id") ;

map{ is($b->fetch_with_id($_)->index_value, $_, 
	"Check index value $_" ); } (0 .. 4) ;

$b->move(3,4) ;
is($b->fetch_with_id(3)->fetch, undef ,"check after move idx 3 in 4") ;
is($b->fetch_with_id(4)->fetch, 'toto',"check after move idx 3 in 4") ;
map{ is($b->fetch_with_id($_)->index_value, $_, 
	"Check moved index value $_" ); } (0 .. 4) ;

$b->fetch_with_id(3)->store('titi');
$b->swap(3,4) ;

map{ is($b->fetch_with_id($_)->index_value, $_, 
	"Check swapped index value $_" ); } (0 .. 4) ;

is($b->fetch_with_id(3)->fetch, 'toto',"check value after swap") ;
is($b->fetch_with_id(4)->fetch, 'titi',"check value after swap") ;

$b->remove(3) ;
is($b->fetch_with_id(3)->fetch, 'titi',"check after remove") ;

# test move swap with node list
my $ol = $root->fetch_element('olist') ;

my @set = ( [ qw/X Av/],
	    [ qw/X Bv/],
	    [ qw/Y Av/],
	    [ qw/Z Cv/],
	    [ qw/Z Av/],
	  );

my $i = 0;
foreach my $item (@set) {
    my ($e,$v) = @$item;
    $ol->fetch_with_id($i++)->fetch_element($e)->store($v)
}

$ol->move(3,4) ;
is($ol->fetch_with_id(3)->fetch_element('Z')->fetch, undef ,
   "check after move idx 3 in 4") ;
is($ol->fetch_with_id(4)->fetch_element('Z')->fetch, 'Cv',
   "check after move idx 3 in 4") ;
map{ is($ol->fetch_with_id($_)->index_value, $_, 
	"Check moved index value $_" ); } (0 .. 4) ;

$ol->swap(0,2) ;
is($ol->fetch_with_id(0)->fetch_element('X')->fetch, undef ,
   "check after move idx 0 in 2") ;
is($ol->fetch_with_id(0)->fetch_element('Y')->fetch, 'Av' ,
   "check after move") ;

is($ol->fetch_with_id(2)->fetch_element('Y')->fetch, undef ,
   "check after move") ;
is($ol->fetch_with_id(2)->fetch_element('X')->fetch, 'Av' ,
   "check after move") ;

map{ is($ol->fetch_with_id($_)->index_value, $_, 
	"Check moved index value $_" ); } (0 .. 4) ;
print $root->dump_tree(experience => 'beginner' ) if $trace;

is($ol->fetch_with_id(0)->fetch_element('X')->fetch, undef ,
   "check before move") ;
$ol->remove(0) ;
print $root->dump_tree(experience => 'beginner' ) if $trace;
is($ol->fetch_with_id(0)->fetch_element('X')->fetch, 'Bv' ,
   "check after move") ;

# test store 
my @test = ( [         a1 => ['a1']       ],
	     [ '"a","b"'  => [ qw/a b/  ] ],
	     [ 'a,b'      => [ qw/a b/  ] ],
	     [ '"a\"a",b' => [ qw/a"a b/] ],
	     [ '"a,a",b'  => [ 'a,a', 'b'] ],
	     [    '",a1"' => [ ',a1']     ],
	   ) ;
foreach my $l (@test) {
    $b->load($l->[0]) ;
    is_deeply( [$b->fetch_all_values], $l->[1], "test store $l->[0]");
}

throws_ok { $b->load('a,,b');} "Config::Model::Exception::Load",
  "fails load 'a,,b'" ;

# test preset mode
$inst->preset_start ;
my $pl = $root->fetch_element('plain_list') ;

$pl->fetch_with_id(0)->store('prefoo') ;
$pl->fetch_with_id(1)->store('prebar') ;
$inst->preset_stop ;
ok(1,"filled preset values");

is_deeply( [ $pl->fetch_all_values], ['prefoo','prebar'],"check that preset values are read") ;
$pl->fetch_with_id(2)->store('bar') ;

is_deeply( [ $pl->fetch_all_values], ['prefoo','prebar','bar'],"check that values are read") ;

is_deeply( [ $pl->fetch_all_values(mode => 'custom')], ['bar'],"check that custom values are read") ;
