# -*- cperl -*-
# $Author$
# $Date$
# $Revision$

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Config::Model;

BEGIN { plan tests => 22; }

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"Compilation done");

my @element = ( 
	       # Value constructor args are passed in their specific array ref
	       cargo => { type => 'leaf',
			  value_type => 'string'
			},
	      ) ;

# minimal set up to get things working
my $model = Config::Model->new() ;
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
       ]
   ) ;

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $b = $root->fetch_element('bounded_list');
ok($b,"bounded list created") ;

is($b->fetch_with_id(1)->store('foo'),'foo',"stored in 1") ;
is($b->fetch_with_id(0)->store('baz'),'baz',"stored in 0") ;
is($b->fetch_with_id(2)->store('bar'),'bar',"stored in 2") ;

eval { $b->fetch_with_id(124)->store('baz') ;} ;
ok($@,"max error") ;
print "normal error:", $@, "\n" if $trace;

is_deeply([$b->get_all_indexes],[0,1,2],"check ids") ;

$b->delete(1) ;
is($b->fetch_with_id(1)->fetch, undef,"check deleted id") ;

is($b->index_type,'integer','check list index_type') ;
is($b->max,123,'check list max boundary') ;

$b->push('toto','titi') ;
is($b->fetch_with_id(2)->fetch, 'bar', "check last item of table") ;
is($b->fetch_with_id(3)->fetch, 'toto',"check pushed item") ;
is($b->fetch_with_id(4)->fetch, 'titi',"check pushed item") ;

my $ld1 = $root->fetch_element('list_with_default_id');
is_deeply([$ld1->get_all_indexes],[0,1],"check list_with_default_id ids") ;

my $lds = $root->fetch_element('list_with_several_default_keys');
is_deeply([$lds->get_all_indexes],[0 .. 5],"check list_with_several_default_keys") ;

my $lac = $root->fetch_element('list_with_auto_created_id');
is_deeply([$lac->get_all_indexes],[0 .. 3],"check list_with_auto_created_id") ;

$b->move(3,4) ;
is($b->fetch_with_id(3)->fetch, undef ,"check after move") ;
is($b->fetch_with_id(4)->fetch, 'toto',"check after move") ;

$b->fetch_with_id(3)->store('titi');
$b->swap(3,4) ;

is($b->fetch_with_id(3)->fetch, 'toto',"check after swap") ;
is($b->fetch_with_id(4)->fetch, 'titi',"check after swap") ;

$b->remove(3) ;
is($b->fetch_with_id(3)->fetch, 'titi',"check after remove") ;
