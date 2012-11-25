# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Test::Exception ;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Value ;
use Data::Dumper ;
use Log::Log4perl qw(:easy) ;

BEGIN { plan tests => 9; }

use strict;

my $arg = shift || '';
my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

my $home = $ENV{HOME} || "";
my $log4perl_user_conf_file = "$home/.log4config-model";

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($log ? $WARN: $ERROR);
}

ok(1,"Compilation done");

$Config::Model::Value::nowarning = 1 unless $trace ;

# minimal set up to get things working
my $model = Config::Model->new() ;

$model->create_config_class(
    name    => "NodeFix",
    element => [
        'fix-gnu' => {
            type            => 'leaf',
            value_type      => 'uniline',
            'warn_if_match' => {
                'Debian GNU/Linux' => {
                    'msg' => 'deprecated in favor of Debian GNU',
                    'fix' => 's!Debian GNU/Linux!Debian GNU!g;'
                },
            },
        },
        'fix-long' => {
            type            => 'leaf',
            value_type      => 'uniline',
            'warn_if_match' => {
                '[^\\n]{10,}' => {
                    'msg' => 'Line too long',
                    'fix' => '$_ = substr $_,0,10;'
                },
            },
        }
      ]

);

$model->create_config_class(
    name => "Master",

    element => [
        [ map { "my_broken_node_$_" } (qw/a b c/) ] => {
            type              => 'node',
            config_class_name => 'NodeFix',
        }
    ]
);


my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

foreach my $w (qw/a b c/) {
    $root->load(qq!my_broken_node_$w fix-gnu="Debian GNU/Linux for $w" fix-long="$w is way too long"!) ;
}

print $root->dump_tree if $trace ;

$root->apply_fixes('long') ;
map {
    is( 
        $root->grab_value("my_broken_node_$_ fix-long"),
        "$_ is way t",
        "check that $_ long stuff was fixed"
    ) ;
    is(
        $root->grab_value("my_broken_node_$_ fix-gnu"),
        "Debian GNU/Linux for $_",
        "check that $_ gnu stuff was NOT fixed"
    ) ;
    } qw/a b c/ ;

print $root->dump_tree if $trace ;


memory_cycle_ok($model);
