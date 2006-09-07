# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-09-07 12:11:05 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1.1.1 $

use ExtUtils::testlib;
use Test::More tests => 33;
use Config::Model;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model -> new ( model_dir => '.' );

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Xorg', 
			     instance_name => 'xorg_instance');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

$inst->push_no_value_check('fetch') ;
my $res = $root->describe ;
$inst->pop_no_value_check;
