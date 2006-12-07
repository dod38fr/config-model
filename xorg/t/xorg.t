# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-12-07 13:13:24 $
# $Name: not supported by cvs2svn $
# $Revision: 1.3 $

use ExtUtils::testlib;
use Test::More tests => 33;
use Config::Model;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model -> new ( ) ;# model_dir => '.' );

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

mkdir('wr_test') unless -d 'wr_test' ;

my $inst = $model->instance (root_class_name  => 'Xorg', 
			     instance_name    => 'xorg_instance',
			     'read_directory' => 'data',
			     'write_directory' => 'wr_test',
			    );
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

$inst->push_no_value_check('fetch') ;
my $res = $root->describe ;
$inst->pop_no_value_check;

#print $root->dump_tree ;

$inst->write_back ;
