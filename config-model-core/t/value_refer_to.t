# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-01-20 17:46:58 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 13 ;
use Config::Model ;

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
   name => 'Host',
   'element' => [ 
		 if => { type => 'hash',
			 index_type => 'string',
			 element_type => 'node',
			 element_args => { config_class_name  => 'If'},
		       },
		 trap => { type => 'leaf',
			   value_type => 'string'
			 }
		]
  );

$model ->create_config_class 
  (
   name => 'If',
   element => [
	       ip => { type => 'leaf',
		       value_type => 'string'
		     }
	      ]
   ) ;

$model ->create_config_class 
  (
   name => 'Lan',
   element => [
	       node => { type => 'hash',
			 index_type => 'string',
			 element_type => 'node',
			 element_args => { config_class_name  => 'Node'},
		       },
	      ]
  );

$model ->create_config_class 
  (
   name => 'Node',
   element => [
	       host => { type => 'leaf',
			 refer_to => '! host'
		       },
	       if   => { type => 'leaf',
			 refer_to => [ '  ! host:$h if ', h => '- host' ]
		       },
	       ip => { type => 'leaf',
		       value_type => 'string',
		       compute    => [
				      '$ip',
				      ip   => '! host:$h if:$card ip',
				      h    => '- host',
				      card => '- if'
				     ]
		     }
	      ]
  );

$model ->create_config_class 
  (
   name => 'Master',
   element => [
	       host => { type => 'hash',
			 index_type => 'string',
			 element_type => 'node',
			 element_args => { config_class_name  => 'Host' }
		       },
	       lan => { type => 'hash',
			 index_type => 'string',
			 element_type => 'node',
			 element_args => { config_class_name  => 'Lan'}
		      }
	      ]
  );


my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

ok( $root, "Created Root" );

$root -> load(
' host:A if:eth0 ip=10.0.0.1 -
        if:eth1 ip=10.0.1.1 - -
 host:B if:eth0 ip=10.0.0.2 -
        if:eth1 ip=10.0.1.2 - - '
);

ok( 1, "host setup done" );

my $node = $root->grab('lan:A node:1');
ok( $node, "got lan:A node:1".$node->name );

$node->load('host=A');

is( $node->grab_value('host'), 'A', "setup host=A" );

$node->load('if=eth0');

is( $node->grab_value('if'), 'eth0', "set up if=eth0 " );

# magic

is( $node->grab_value('ip'), '10.0.0.1', "got ip 10.0.0.1" );

$root->load(
' lan:A node:2 host=B if=eth0  - -
  lan:B node:1 host=A if=eth1  -
           node:2 host=B if=eth1  - -

'
);

ok( 1, "lan setup done" );

is( $root->grab_value('lan:A node:1 ip'), '10.0.0.1', "got ip 10.0.0.1" );
is( $root->grab_value('lan:A node:2 ip'), '10.0.0.2', "got ip 10.0.0.2" );
is( $root->grab_value('lan:B node:1 ip'), '10.0.1.1', "got ip 10.0.1.1" );
is( $root->grab_value('lan:B node:2 ip'), '10.0.1.2', "got ip 10.0.1.2" );

#print distill_root( object => $root );
#print dump_root( object => $root );
