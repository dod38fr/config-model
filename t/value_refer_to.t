# -*- cperl -*-

use warnings;

use ExtUtils::testlib;
use Test::Warn;
use Test::More ;
use Test::Memory::Cycle;
use Test::Exception;
use Config::Model;
use Log::Log4perl qw(:easy :levels);

use strict;

my $arg = shift || '';
my ( $log, $show ) = (0) x 2;

my $trace = $arg =~ /t/ ? 1 : 0;
$log  = 1 if $arg =~ /l/;
$show = 1 if $arg =~ /s/;

my $home = $ENV{HOME} || "";
my $log4perl_user_conf_file = "$home/.log4config-model";

if ( $log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init( $log ? $WARN : $ERROR );
}

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok( 1, "Compilation done" );

# minimal set up to get things working
my $model = Config::Model->new( legacy => 'ignore', );
$model->create_config_class(
    name      => 'Host',
    'element' => [
        if => {
            type              => 'hash',
            index_type        => 'string',
            cargo => {
                type        => 'node',
                config_class_name => 'If'
            },
        },
        trap => {
            type       => 'leaf',
            value_type => 'string'
        }
    ]
);

$model->create_config_class(
    name    => 'If',
    element => [
        ip => {
            type       => 'leaf',
            value_type => 'string'
        }
    ]
);

$model->create_config_class(
    name    => 'Lan',
    element => [
        node => {
            type              => 'hash',
            index_type        => 'string',
            cargo => {
                type        => 'node',
                config_class_name => 'Node',
            },
        }
    ]
);

$model->create_config_class(
    name    => 'Node',
    element => [
        host => {
            type       => 'leaf',
            value_type => 'reference',
            refer_to   => '! host'
        },
        if => {
            type       => 'leaf',
            value_type => 'reference',
            computed_refer_to   => {
                formula => '  ! host:$h if ',
                variables => { h => '- host' }
            }
        },
        ip => {
            type       => 'leaf',
            value_type => 'string',
            compute    => {
                formula => '$ip',
                variables => {
                    ip   => '! host:$h if:$card ip',
                    h    => '- host',
                    card => '- if'
                }
            }
        }
    ]
);

$model->create_config_class(
    name    => 'Master',
    element => [
        host => {
            type              => 'hash',
            index_type        => 'string',
            cargo => {
                type        => 'node',
                config_class_name => 'Host'
            }
        },
        lan => {
            type              => 'hash',
            index_type        => 'string',
            cargo => {
                type        => 'node',
                config_class_name => 'Lan'
            }
        },
        host_reference => {
            type       => 'leaf',
            value_type => 'reference',
            refer_to   => '! host ',
        },
        host_and_choice => {
            type       => 'leaf',
            value_type => 'reference',
            refer_to   => '! host ',
            choice     => [qw/foo bar/]
        },
        host_and_replace => {
            type       => 'leaf',
            value_type => 'reference',
            refer_to   => '! host ',
            replace => { 'fou' => 'Foo', 'barre' => 'Bar' },
        },
        dumb_list => {
            type       => 'list',
            cargo => {
                type => 'leaf',
                value_type => 'string'
            }
        },
        refer_to_list_enum => {
            type       => 'leaf',
            value_type => 'reference',
            refer_to   => '- dumb_list',
        },

        refer_to_wrong_path => {
            type       => 'leaf',
            value_type => 'reference',
            refer_to   => '! unknown_class unknown_elt',
        },

        refer_to_unknown_elt => {
            type       => 'leaf',
            value_type => 'reference',
            refer_to   => '! unknown_elt',
        },
    ] );

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

ok( $root, "Created Root" );

$root->load(
    ' host:A if:eth0 ip=10.0.0.1 -
        if:eth1 ip=10.0.1.1 - -
 host:B if:eth0 ip=10.0.0.2 -
        if:eth1 ip=10.0.1.2 - - '
);

ok( 1, "host setup done" );

my $node = $root->grab('lan:A node:1');
ok( $node, "got lan:A node:1" . $node->name );

$node->load('host=A');

is( $node->grab_value('host'), 'A', "setup host=A" );

$node->load('if=eth0');

is( $node->grab_value('if'), 'eth0', "set up if=eth0 " );

# magic

is( $node->grab_value('ip'), '10.0.0.1', "got ip 10.0.0.1" );

$root->load(
    ' lan:A node:2 host=B if=eth0  - -
  lan:B node:1 host=A if=eth1  -
           node:2 host=B if=eth1  - -

'
);

ok( 1, "lan setup done" );

is( $root->grab_value('lan:A node:1 ip'), '10.0.0.1', "got ip 10.0.0.1" );
is( $root->grab_value('lan:A node:2 ip'), '10.0.0.2', "got ip 10.0.0.2" );
is( $root->grab_value('lan:B node:1 ip'), '10.0.1.1', "got ip 10.0.1.1" );
is( $root->grab_value('lan:B node:2 ip'), '10.0.1.2', "got ip 10.0.1.2" );

#print distill_root( object => $root );
#print dump_root( object => $root );

my $hac = $root->fetch_element('host_and_choice');
is_deeply(
    [ $hac->get_choice ],
    [ 'A', 'B', 'bar', 'foo' ],
    "check that default choice and refer_to add up"
);

# choice needs to be recomputed for references
$root->load("host~B");
is_deeply(
    [ $hac->get_choice ],
    [ 'A', 'bar', 'foo' ],
    "check that default choice and refer_to follow removed elements"
);

# test reference to list values
$root->load("dumb_list=a,b,c,d,e");

my $rtle = $root->fetch_element("refer_to_list_enum");
is_deeply( [ $rtle->get_choice ], [qw/a b c d e/], "check choice of refer_to_list_enum" );

throws_ok { $root->fetch_element("refer_to_wrong_path"); } 'Config::Model::Exception::Model',"fetching refer_to_wrong_path" ;

throws_ok { $root->fetch_element("refer_to_unknown_elt") } 'Config::Model::Exception::Model',"fetching refer_to_unknown_elt" ;

warning_like { $root->fetch_element("host_reference")->store(value => 'Foo', check => 'skip') } qr/skipping value/,"store unknown host (skip mode)";

throws_ok { $root->fetch_element("host_reference")->store('Foo') } "Config::Model::Exception::WrongValue","store unknown host (failure mode)";

$root->load("host:Foo - host:Bar");
$root->fetch_element("host_reference")->store('Foo');
ok(scalar $root->fetch_element("host_reference")->check, "check reference to Foo host");

$root->load("host_and_replace=fou");
is($root->grab_value("host_and_replace"),'Foo',"check replaced host fou->Foo");

$root->load("host~Foo");
ok( !$root->fetch_element("host_reference")->check, "check reference to removed Foo host");

# todo: need an exclude parameter (to avoid cycle in config_class_name)

memory_cycle_ok($model,"test memory cycle");

done_testing;
