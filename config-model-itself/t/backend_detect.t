# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Config::Model;
use Log::Log4perl qw(:easy) ;
use Data::Dumper ;

use warnings;
no warnings qw(once);

use strict;

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

Log::Log4perl->easy_init($arg =~ /l/ ? $DEBUG: $ERROR);

my $model = Config::Model->new() ;

$model ->create_config_class
  (
   name => "Master",
   'element'
   => [ 
       'backend' => { type => 'leaf',
		      class => 'Config::Model::Itself::Backend' ,
		      value_type => 'enum',
		      choice => [qw/cds_file perl_file ini_file augeas custom/],

		      # TBD fill help from POD ?
		       help => {
			       cds_file => "file ...",
			       ini_file => "Ini file ...",
			       perl_file => "file  perl",
			       custom => "Custom format",
			       augeas => "Experimental backend",
			      }
		    }
      ],
  );

my $root = $model->instance(root_class_name => 'Master') -> config_root ;

my $backend = $root->fetch_element('backend') ;

my @choices = $backend->get_choice ;

print "@choices\n";
