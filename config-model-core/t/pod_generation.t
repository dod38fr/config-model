# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 8;
use Test::Memory::Cycle;
use Config::Model;
use Log::Log4perl qw(:easy) ;
use File::Path ;

use warnings;
no warnings qw(once);

use strict;

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root';

# cleanup before tests
rmtree($wr_root);
mkpath($wr_root, { mode => 0755 }) ;

my $model = Config::Model -> new (legacy => 'ignore',) ;

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
my $log             =  $arg =~ /l/ ? 1 : 0;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

my $home = $ENV{HOME} || "";
my $log4perl_user_conf_file = "$home/.log4config-model";

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($arg =~ /l/ ? $DEBUG: $WARN);
}

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file => 't/big_model.pm',
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

$model->generate_doc('Master') if $trace ;

$model->generate_doc('Master',$wr_root) ;

map { ok ( -r "wr_root/Config/Model/models/$_", "Found doc $_") ; }
    qw /Master.pod  SlaveY.pod  SlaveZ.pod  SubSlave2.pod  SubSlave.pod/;
memory_cycle_ok($model);
