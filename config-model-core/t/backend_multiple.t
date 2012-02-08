# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 7;
use Test::Memory::Cycle;
use Config::Model;
use File::Path;
use File::Copy ;
use Test::Warn ;
use Test::Exception ;

use warnings;
#no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model -> new (legacy => 'ignore',) ;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
my $home = $ENV{HOME} || "";
my $log4perl_user_conf_file = "$home/.log4config-model";

if (-e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($arg =~ /l/ ? $DEBUG: $WARN);
}

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root/';

# cleanup before tests
rmtree($wr_root);
mkpath($wr_root, { mode => 0755 }) ;

$model->create_config_class(
    'read_config' => [
        {
            'auto_create' => '1',
            'file'        => 'control.pl',
            'backend'     => 'perl_file',
            'config_dir'  => 'debian'
        }
    ],
    'name'    => 'Test::Control',
    'element' => [ 'source' => { 'type' => 'leaf', value_type => 'string', } ]
);

$model->create_config_class(
    'read_config' => [
        {
            'auto_create' => '1',
            'file'        => 'copyright.pl',
            'backend'     => 'perl_file',
            'config_dir'  => 'debian'
        }
    ],
    'name'    => 'Test::Copyright',
    'element' => [ 'Format', { 'value_type' => 'uniline', 'type' => 'leaf', }, ]
);

$model->create_config_class(
    'read_config' => [
        {
            'auto_create' => '1',
            'backend'     => 'PlainFile',
            'config_dir'  => 'debian/source'
        }
    ],
    'name'    => 'Test::Source',
    'element' => [ 'format', { 'value_type' => 'uniline', 'type' => 'leaf', } ]
);

$model->create_config_class(
    'name'    => 'Test::Dpkg',
    'element' => [
        'control',
        {
            'type'              => 'node',
            'config_class_name' => 'Test::Control'
        },
        'copyright',
        {
            'type'              => 'node',
            'config_class_name' => 'Test::Copyright'
        },
        'source',
        {
            'type'              => 'node',
            'config_class_name' => 'Test::Source'
        }
    ]
);

my $inst = $model->instance(root_class_name => 'Test::Dpkg', root_dir    => $wr_root , );
my $root = $inst->config_root;

$root->load("control source=ctrl-source -
             copyright Format=copyright-format -
             source format=source-format");
ok(1,"loaded data");

my $dump = $root ->dump_tree ;
print $dump if $trace ;

$inst->write_back ;

#check written files
foreach (qw!control.pl copyright.pl source/format!) { 
	my $f = $wr_root."debian/$_" ;
	ok( -e $f, "check written file $f" ); 
} 

my $inst2 = $model->instance(root_class_name => 'Test::Dpkg', 
    root_dir    => $wr_root , 
    instance_name => 'test2' );
my $root2 = $inst2->config_root;
my $dump2 = $root2 -> dump_tree ;
is($dump2, $dump,"check that inst2 is a copy of first instance");
memory_cycle_ok($model);
