# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 6 ;
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
		      class => 'Config::Model::Itself::BackendDetector' ,
		      value_type => 'enum',
		      choice => [qw/cds_file perl_file ini_file augeas custom/],

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

ok(1,"test class created") ;

my $root = $model->instance(root_class_name => 'Master') -> config_root ;

my $backend = $root->fetch_element('backend') ;

my @choices = $backend->get_choice ;

ok( (scalar grep { $_ eq 'Yaml'} @choices), "Yaml plugin backend was found") ;
ok( (scalar grep { $_ eq 'Debian::Dpkg::Copyright'} @choices), "Debian::Dpkg::Copyright plugin backend was found") ;


my $help = $backend->get_help('Yaml') ;
like($help,qr/provided by Config::Model::Backend::Yaml/,
   "Found Yaml NAME section from pod") ;

$help = $backend->get_help('Debian::Dpkg::Copyright') ;
like($help,qr/provided by Config::Model::Backend::Debian::Dpkg::Copyright/,
   "Found Debian::Dpkg::Copyright NAME section from pod") ;

$help = $backend->get_help('cds_file') ;
is($help,"file ...", "cds_file help was kept") ;
