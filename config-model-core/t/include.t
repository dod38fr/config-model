# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-04-08 18:22:52 +0200 (Tue, 08 Apr 2008) $
# $Revision: 595 $

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Config::Model;
use Data::Dumper ;

BEGIN { plan tests => 3; }

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"Compilation done");

# minimal set up to get things working
my $model = Config::Model->new() ;

$model ->create_config_class 
  (
   name => "Two",

   element 
   => [
       two => { type => 'leaf',
		value_type => 'string',
	      },

       ]
   ) ;

$model ->create_config_class 
  (
   name => "Three",

   element 
   => [
       three => { type => 'leaf',
		  value_type => 'string',
		},

       ]
   ) ;

$model ->create_config_class 
  (
   name => "Four",

   include => [qw/Three/] ,
   element 
   => [
       four => { type => 'leaf',
		  value_type => 'string',
		},

       ]
  ) ;


$model ->create_config_class 
  (
   name => "Master",

   include => [qw/Two Four/] ,
   include_after => 'one',

   element 
   => [
       one => { type => 'leaf',
		value_type => 'string',
	      },

       ]
   ) ;

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my @elt = $root->get_element_name() ;
is_deeply(\@elt,[qw/one two three four/],"check multiple include order") ;
