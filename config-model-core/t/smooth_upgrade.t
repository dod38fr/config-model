# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 22;
use Test::Exception ;
use Test::Warn ;
use Test::Memory::Cycle;
use Config::Model ;
use Config::Model::Value;

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
   name => "Master",
   'element'
   => [
       # obsolete element cannot be used at all
       'obsolete_p'  
       => { type => 'leaf',
	    value_type => 'enum',
	    choice => [qw/cds perl ini custom/],
	    status => 'obsolete',
	    description => 'obsolete_p is replaced by non_obso',
	  },

       'deprecated_p'
       => { type => 'leaf',
	    value_type => 'enum',
	    choice => [qw/cds perl ini custom/],
	    status => 'deprecated',
	    description => 'deprecated_p is replaced by new_from_deprecated',
	  },

       'new_from_deprecated'
       => { type => 'leaf',
	    value_type => 'enum',
	    choice => [qw/cds_file perl_file ini_file augeas custom/],
	    migrate_from => { formula => '$replace{$old}' , 
			      variables => { old => '- deprecated_p' } ,
			      replace => { 
					  perl => 'perl_file',
					  ini  => 'ini_file',
					  cds  => 'cds_file',
					 },
			    },
	  },

       'hidden_p'
       => { type => 'leaf',
	    value_type => 'enum',
	    choice => [qw/cds perl ini custom/],
	    level => 'hidden',
	    description => 'hidden_p is replaced by new_from_hidden',
	  },
      ]
   );


$model ->create_config_class 
  (
   name => "UrlMigration",
   'element'
   => [
       'old_url' => { type => 'leaf',
		      value_type => 'uniline',
		      status => 'deprecated',
		    },
       'host' 
       => { type => 'leaf',
	    value_type => 'uniline',
	    mandatory => 1,
	    migrate_from => { formula => '$old =~ m!http://([\w\.]+)!; $1 ;' , 
			      variables => { old => '- old_url' } ,
			      use_eval => 1 ,
			    },
			},
       'port' 
       => { type => 'leaf',
	    value_type => 'uniline',
	    migrate_from => { formula => '$old =~ m!http://[\w\.]+:(\d+)!; $1 ;' , 
			      variables => { old => '- old_url' } ,
			      use_eval => 1 ,
			    },
			},
       'path' => { type => 'leaf',
		   value_type => 'uniline',
		   migrate_from => { formula => '$old =~ m!http://[\w\.]+(?::\d+)?(/.*)!; $1 ;', 
				     variables => { old => '- old_url' } ,
				     use_eval => 1 ,
				   },
		 },

      ] ,
  ) ;

my $inst = $model->instance (root_class_name => 'Master', 
				 instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

# emulate start of file read
$inst->initial_load_start ;

throws_ok { $root->fetch_element('obsolete_p') ;} 
  'Config::Model::Exception::ObsoleteElement' ,
  'tried to fetch obsolete element' ;

my $dp ;
warning_like {$dp = $root->fetch_element('deprecated_p') ;}
  qr/Element 'deprecated_p' of node 'Master' is deprecated/ ,
  "check warning when fetching deprecated element" ;

my $nfd = $root->fetch_element('new_from_deprecated') ;

is( $nfd->fetch, undef, "undef old and undef new");

# does not generate a warning
$dp -> store ('ini') ;

$inst->initial_load_stop ;

is( $nfd->fetch, 'ini_file', "old is 'ini' and new is 'ini_file'");

is( $nfd->fetch_custom, 'ini_file', "likewise for custom_value");

is( $nfd->fetch('non_upstream_default'), 'ini_file', "likewise for non_builtin_default");

is( $nfd->fetch_standard, undef, "but standard value is undef");

# check element list
is_deeply( [$root->get_element_name ],
	   [qw/new_from_deprecated/],
	   "check that deprecated and obsolete parameters are hidden"
	 ) ;

is ($root->dump_tree,"new_from_deprecated=ini_file -\n","check dump tree") ;

# now override the migrated value
$nfd->store('perl_file') ;

is( $nfd->fetch, 'perl_file', "overridden value is 'perl_file'");

is( $nfd->fetch_custom, 'perl_file', "likewise for custom_value");

is( $nfd->fetch('non_upstream_default'), 'perl_file', "likewise for non_builtin_default");

is( $nfd->fetch_standard, undef, "but standard value is undef");

# test migration with regexp value
my $uinst = $model->instance (root_class_name => 'UrlMigration', 
			      instance_name => 'urltest');
ok($uinst,"created url test instance") ;

my $uroot = $uinst -> config_root ;

# emulate start of file read
$uinst->initial_load_start ;

my $host = 'foo.gre.hp.com';
my $port = 2345 ;
my $path = '/bar/baz.html';
my $url = "http://$host:$port$path" ;

# check element list
is_deeply( [$uroot->get_element_name ],
	   [qw/host port path/],
	   "check that url deprecated and obsolete parameters are hidden"
	 ) ;

warning_like {$dp = $uroot->fetch_element('old_url')->store($url) ;}
  qr/Element 'old_url' of node 'UrlMigration' is deprecated/ ,
  "check warning when fetching deprecated element" ;

$uinst->initial_load_stop ;

my $h = $uroot->fetch_element('host');

is($h->fetch,$host,"check extracted host") ;

is($uroot->fetch_element('port')->fetch,$port,"check extracted port") ;
is($uroot->fetch_element('path')->fetch,$path,"check extracted path") ;

memory_cycle_ok($model,"test memory cycles");
