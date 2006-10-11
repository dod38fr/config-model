# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-10-11 11:42:18 $
# $Name: not supported by cvs2svn $
# $Revision: 1.6 $

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Config::Model;

BEGIN { plan tests => 14; }

use strict;

my $trace = shift || 0;

ok(1,"Compilation done");

my @element = ( 
	       # Value constructor args are passed in their specific array ref
	       cargo_type => 'leaf',
	       cargo_args => {value_type => 'string'},
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
