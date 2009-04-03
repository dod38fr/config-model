# -*- cperl -*-
# $Author$
# $Date$
# $Revision$

use ExtUtils::testlib;
use Test::More tests => 4;
use Config::Model;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model -> new(legacy => 'ignore',)  ;

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file => 't/big_model.pm',
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;
ok($root,"Config root created") ;

my $dot_file = "wr_root/config-test.dot";

my $res =  $model->get_dot ;
ok($res,"got dot data, written in $dot_file") ;

print $res if $trace ;

open(TMP,">$dot_file") || die "Cannot open $dot_file:$!";
print TMP $res;
close TMP ;

