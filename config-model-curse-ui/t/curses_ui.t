# -*- cperl -*-
# $Author$
# $Date$
# $Name: not supported by cvs2svn $
# $Revision$

use warnings FATAL => qw(all);
use ExtUtils::testlib;
use Test::More ;
#use Struct::Compare ;
use Data::Dumper;
use Config::Model ;
use Config::Model::CursesUI ;
use Log::Log4perl qw(:easy) ;

use strict ;

BEGIN { plan tests => 3;} 

use vars qw/$hw/;
use Curses::UI ;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;

my $log             = 1 if $arg =~ /l/;
Log::Log4perl->easy_init($log ? $TRACE: $WARN);

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

warn "You can run the GUI with 'i' argument. E.g. 'perl t/curses_ui.t i'\n";

ok(1,"Config::Model::CursesUI loaded") ;

my $model = Config::Model -> new ( );

my $inst = $model->instance (root_class_name => 'Master',
		  model_file      => 't/test_model.pm',
		  instance_name   => 'test1');
ok($inst,"created dummy instance") ;


# re-direct errors
open (FH,">>stderr.log") || die $! ;
open STDERR, ">&FH";

warn "----\n";

$inst->config_root->load("hash_a:foo=bar") ;

if ($arg =~ /i/ ) {
    my $dialog = Config::Model::CursesUI-> new
      (
       permission => 'advanced',
       debug => 1,
      ) ;
    $dialog->start( $model )  ;
}

close FH ;

ok(1,"done") ;
