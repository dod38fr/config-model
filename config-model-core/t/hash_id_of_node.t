# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-09-07 11:50:06 $
# $Name: not supported by cvs2svn $
# $Revision: 1.4 $

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 10 ;
use Config::Model ;
use Data::Dumper ;

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"Compilation done");

my @element = ( 
	       # Value constructor args are passed in their specific array ref
	       collected_type => 'node',
	       config_class_name => 'Slave' ,
	      ) ;

# minimal set up to get things working
my $model = Config::Model->new() ;
$model ->create_config_class 
  (
   name => "Master",
   element 
   => [ 
       'bounded_hash'
       => { type => 'hash',
	    # hash_class constructor args are all keys of this hash
	    # except type and class
	    hash_class => 'Config::Model::HashId', # default
	    index_type  => 'integer',

	    # hash boundaries
	    min => 1, max => 123, max_nb => 2 ,
	    @element
	  },
       'hash_with_default_and_init'
       => { type => 'hash',
	    index_type  => 'string',
	    default => { 'def_1' => 'X=Av Y=Bv'  ,
			 'def_2' => 'Y=Av Z=Cv' } ,
	    @element
	  },
      ],
   );

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

my $b = $root->fetch_element('bounded_hash') ;
ok($b,"bounded hash created") ;

is($b->name,'Master bounded_hash id',"check hash id name");

my $b1 = $b->fetch_with_id(1) ;
isa_ok($b1,'Config::Model::Node',"fetched element id 1") ;

is($b1->config_class_name,'Slave', 'check config_class_name') ;

my $h_with_def = $root->fetch_element('hash_with_default_and_init') ;
my $res = [$h_with_def->get_all_indexes] ;

#print Dumper( $res ) ;

is_deeply($res , [qw/def_1 def_2/], 'check default items') ;

#print $root->dump_tree ;
is ($root->dump_tree ,
   'bounded_hash:1 -
hash_with_default_and_init:def_1
  X=Av
  Y=Bv -
hash_with_default_and_init:def_2
  Y=Av
  Z=Cv - -
', "check default items with children setup") ;

$h_with_def->move('def_1', 'moved_1') ;

$res = [$h_with_def->get_all_indexes] ;
is_deeply($res , [qw/def_2 moved_1/], 'check moved items keys') ;

#print $root->dump_tree ;
is ($root->dump_tree ,
   'bounded_hash:1 -
hash_with_default_and_init:def_2
  Y=Av
  Z=Cv -
hash_with_default_and_init:moved_1
  X=Av
  Y=Bv - -
', "check moved items with children setup") ;

