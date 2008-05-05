# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-04-15 13:57:49 +0200 (mar, 15 avr 2008) $
# $Revision: 608 $

use ExtUtils::testlib;
use Test::More tests => 54;
use Config::Model ;
use Log::Log4perl qw(:easy) ;

use warnings;
no warnings qw(once);

use strict;

my $arg = shift || '';

my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

Log::Log4perl->easy_init($log ? $TRACE: $WARN);

#$::RD_ERRORS = 1 ;  
#$::RD_WARN   = 1 ;  # unless undefined, also report non-fatal problems
#$::RD_HINT   = 1 ;  # if defined, also suggestion remedies
$::RD_TRACE  = 1 if $arg =~ /p/;

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

mkdir('wr_test') unless -d 'wr_test' ;

my $inst = $model->instance (root_class_name   => 'Sshd',
                             instance_name     => 'sshd_instance',
                             'read_directory'  => "data/example1",
                             'write_directory' => "wr_test",
                            );

ok($inst,"Read sshd.conf and created instance") ;

my $root = $inst -> config_root ;

#Config::Model::Sshd::read(conf_dir => 'data/example1', object => 1 ) ;
print $root->dump_tree (mode => 'full') if $trace ;
