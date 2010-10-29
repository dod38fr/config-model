# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 18 ;
use Config::Model ;

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"Compilation done");

# minimal set up to get things working
my $model = Config::Model->new(legacy => 'ignore',) ;
$model ->create_config_class 
  (
   name => 'Host',
   'element' => [ 
		 if => { type => 'hash',
			 index_type => 'string',
			 cargo_type => 'node',
			 config_class_name  => 'If',
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
			 cargo_type => 'node',
			 config_class_name  => 'Node',
		       },
	      ]
  );

$model ->create_config_class 
  (
   name => 'Node',
   element => [
	       host => { type => 'leaf',
			 value_type => 'reference' ,
			 refer_to => '! host'
		       },
	       if   => { type => 'leaf',
			 value_type => 'reference' ,
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
			 cargo_type => 'node',
			 config_class_name  => 'Host'
		       },
	       lan => { type => 'hash',
			index_type => 'string',
			cargo_type => 'node',
			config_class_name  => 'Lan'
		      },
	       host_and_choice => { type => 'leaf',
				    value_type => 'reference' ,
				    refer_to => [ '! host ' ],
				    choice => [qw/foo bar/]
				  },
	       dumb_list => { type => 'list',
			      cargo_type => 'leaf',
			      cargo_args => {value_type => 'string'}
			    },
	       refer_to_list_enum 
	       => {
		   type => 'leaf',
		   value_type => 'reference',
		   refer_to => '- dumb_list',
		  },

	       refer_to_wrong_path
	       => {
		   type => 'leaf',
		   value_type => 'reference',
		   refer_to => '! unknown_class unknown_elt',
		  },

	       refer_to_unknown_elt
	       => {
		   type => 'leaf',
		   value_type => 'reference',
		   refer_to => '! unknown_elt',
		  },
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

my $hac = $root->fetch_element('host_and_choice') ;
is_deeply([$hac->get_choice],['A','B','bar','foo'],
	 "check that default choice and refer_to add up");

# choice needs to be recomputed for references
$root->load("host~B") ;
is_deeply([$hac->get_choice],['A','bar','foo'],
	 "check that default choice and refer_to follow removed elements");

# test reference to list values
$root->load("dumb_list=a,b,c,d,e") ;

my $rtle = $root->fetch_element("refer_to_list_enum") ;
is_deeply( [$rtle -> get_choice ], [qw/a b c d e/],
	   "check choice of refer_to_list_enum"
	 ) ;

eval { $root->fetch_element("refer_to_wrong_path") ; } ;
ok($@,"fetching refer_to_wrong_path") ;
print "normal error: $@" if $trace;

eval { $root->fetch_element("refer_to_unknown_elt") } ;
ok($@,"fetching refer_to_unknown_elt") ;
print "normal error: $@" if $trace;
