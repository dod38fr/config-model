# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-12-06 12:51:59 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Config::Model;

BEGIN { plan tests => 13; }

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"Compilation done");

# minimal set up to get things working
my $model = Config::Model->new() ;
$model ->create_config_class 
  (
   name => "Master",
   element 
   => [
       [qw/my_hash my_hash2 my_hash3/] 
       => { type => 'hash',
	    index_type => 'string',
	    cargo_type => 'leaf',
	    cargo_args => { value_type => 'string' },
	  },
       choice_list 
       => { type => 'check_list',
	    choice     => ['A' .. 'Z'],
	  },

       refer_to_list 
       => { type => 'check_list',
            refer_to => '- my_hash'
          },

       refer_to_2_list 
       => { type => 'check_list',
            refer_to => '- my_hash + - my_hash2   + - my_hash3'
          },

       ]
   ) ;

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $cl = $root->fetch_element('choice_list') ;

$cl->fetch_with_id(0)->store('A') ;
is($cl->fetch_with_id(0)->fetch , 'A', "check 0 A " ) ;

$cl->fetch_with_id(0)->store('C') ;
is($cl->fetch_with_id(0)->fetch , 'C', "check 0 C" ) ;

$cl->fetch_with_id(0)->store('A') ;
is($cl->fetch_with_id(0)->fetch , 'A', "check 0 A (stored again value)" ) ;

$cl->fetch_with_id(1)->store('C') ;
is($cl->fetch_with_id(1)->fetch , 'C', "check 1 C" ) ;

eval {$cl->fetch_with_id(3)->store('A') ;} ;
ok( $@ ,"store 3 A: which is an error" );
print "normal error:\n", $@, "\n" if $trace;

# now test with a refer_to parameter

$root->load("my_hash:X=x my_hash:Y=y my_hash:Z=z") ;
my $rflist = $root->fetch_element('refer_to_list') ;

is_deeply([$rflist->fetch_with_id(0)->get_choice] ,
	  [qw/X Y Z/], 'check simple refer choices') ;

$rflist->fetch_with_id(0)->store('X') ;
is($rflist->fetch_with_id(0)->fetch , 'X', "check 0 X " ) ;

eval {$rflist->fetch_with_id(3)->store('A') ;} ;
ok( $@ ,"store 3 A: which is an error" );
print "normal error:\n", $@, "\n" if $trace;

$rflist->fetch_with_id(3)->store('Z') ;
is($rflist->fetch_with_id(3)->fetch , 'Z', "check 0 Z " ) ;

eval {$rflist->fetch_with_id(2)->store('Z') ;} ;
ok( $@ ,"store 2 Z: which is an error" );
print "normal error:\n", $@, "\n" if $trace;

# now test with a refer_to parameter with 3 references

$root->load("my_hash2:X2=x my_hash2:X=xy my_hash3:Y2=y") ;

my $rf2list = $root->fetch_element('refer_to_2_list') ;
is_deeply([sort $rf2list->fetch_with_id(0)->get_choice] ,
	  [qw/X X2 Y Y2 Z/], 'check refer_to_2_list choices') ;
