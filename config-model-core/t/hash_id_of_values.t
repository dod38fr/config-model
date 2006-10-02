# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-10-02 11:35:48 $
# $Name: not supported by cvs2svn $
# $Revision: 1.4 $

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 32 ;
use Config::Model ;

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"Compilation done");


my @element = ( 
	       # Value constructor args are passed in their specific array ref
	       cargo_type => 'leaf',
	       element_args => {value_type => 'string'},
	      ) ;

# minimal set up to get things working
my $model = Config::Model->new() ;
$model ->create_config_class 
  (
   name => "Master",
   element 
   => [ 
       bounded_hash 
       => { type => 'hash',
	    # hash_class constructor args are all keys of this hash
	    # except type and class
	    hash_class => 'Config::Model::HashId', # default
	    index_type  => 'integer',

	    # hash boundaries
	    min => 1, max => 123, max_nb => 2 ,
	    element_class => 'Config::Model::Value',
	    @element
	  },
       hash_with_auto_created_id
       => {
	   type => 'hash',
	   index_type  => 'string',
	   auto_create => 'yada',
	   @element
	  },
       hash_with_several_auto_created_id
       => {
	   type => 'hash',
	   index_type  => 'string',
	   auto_create => [qw/x y z/],
	   @element
	  },
       [qw/hash_with_default_id hash_with_default_id_2/]
       => {
	   type => 'hash',
	   index_type  => 'string',
	   default    => 'yada' ,
	   @element
	  },
       hash_with_several_default_keys
       => {
	   type => 'hash',
	   index_type  => 'string',
	   default    => [qw/x y z/],
	   @element
	  },
      ],
   );

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $b = $root->fetch_element('bounded_hash') ;
ok($b,"bounded hash created") ;

is($b->name,'Master bounded_hash id',"check hash id name");

my $b1 = $b->fetch_with_id(1) ;
isa_ok($b1,'Config::Model::Value',"fetched element id 1") ;

is($b1->store('foo'),'foo',"Storing in id 1" ) ;

is($b->fetch_with_id(2)->store('bar'),'bar',"Storing in id 2" ) ;

eval { $b->fetch_with_id('')->store('foo');} ;
ok($@,"empty index error") ;
print "normal error: ", $@ if $trace;

eval { $b->fetch_with_id(0)->store('foo');} ;
ok($@,"min error") ;
print "normal error: ", $@ if $trace;

eval { $b->fetch_with_id(124)->store('foo');} ;
ok($@,"max error") ;
print "normal error: ", $@ if $trace;

eval { $b->fetch_with_id(40)->store('foo');} ;
ok($@,"max nb error") ;
print "normal error: ", $@ if $trace;

ok( $b->delete(2), "delete id 2" );
is( $b->exists(2), '', "deleted id does not exist" );

is( $b->index_type, 'integer',"reading value_type" );
is( $b->max, 123,"reading max boundary" );

my $ac = $root->fetch_element('hash_with_auto_created_id') ;
ok($ac,"created hash_with_auto_created_id") ;

is_deeply([$ac->get_all_indexes], ['yada'],"check auto-created id") ;
ok($ac->exists('yada'), "...idem") ;

$ac->fetch_with_id('foo')->store(3) ;
ok($ac->exists('yada'), "...idem after creating another id") ;
is_deeply([$ac->get_all_indexes], ['foo','yada'],"check the 2 ids") ;

my $dk = $root->fetch_element('hash_with_default_id');
ok($dk,"created hash_with_default_id ...") ;

is_deeply([$dk->get_all_indexes], ['yada'],"check default id") ;
ok($dk->exists('yada'), "...and test default id on empty hash") ;

my $dk2 = $root->fetch_element('hash_with_default_id_2');
ok($dk2,"created hash_with_default_id_2 ...") ;
ok($dk2->fetch_with_id('foo')->store(3),"... store a value...") ;
is_deeply([$dk2->get_all_indexes], ['foo'],"...check existing id...") ;
is($dk2->exists('yada'),'', "...and test that default id is not provided") ;

my $dk3 = $root->fetch_element('hash_with_several_default_keys');
ok($dk3,"created hash_with_several_default_keys ...") ;
is_deeply([sort $dk3->get_all_indexes], [qw/x y z/],"...check default id") ;

my $ac2 = $root->fetch_element('hash_with_several_auto_created_id');
ok($ac2,"created hash_with_several_auto_created_id ...") ;
ok($ac2->fetch_with_id('foo')->store(3),"... store a value...") ;
is_deeply([sort $ac2->get_all_indexes], [qw/foo x y z/],"...check id...") ;

