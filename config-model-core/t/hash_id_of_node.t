# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-02-06 12:34:35 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 6 ;
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
	       element_type => 'node',
	       config_class_name => 'Slave' ,
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
			choice     => [qw/Av Bv Cv/],
			warp       => [
				       '- - macro',
				       A => { default => 'Av' },
				       B => { default => 'Bv' }
				      ]
		       },
       ]
  );

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $b = $root->get_element_for('bounded_hash') ;
ok($b,"bounded hash created") ;

is($b->name,'Master bounded_hash id',"check hash id name");

my $b1 = $b->fetch(1) ;
isa_ok($b1,'Config::Model::Node',"fetched element id 1") ;

is($b1->config_class_name,'Slave', 'check config_class_name') ;

