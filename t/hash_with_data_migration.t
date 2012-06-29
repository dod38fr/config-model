# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Test::Exception;
use Test::Warn ;
use Test::Differences ;
use Test::Memory::Cycle;
use Config::Model;
use Log::Log4perl qw(:easy :levels) ;

BEGIN { plan tests => 11; }

use strict;

my $arg = shift || '';

my $log = 0 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$log                = 1 if $arg =~ /l/;

my $home = $ENV{HOME} || "";
my $log4perl_user_conf_file = "$home/.log4config-model";

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($log ? $WARN: $ERROR);
}

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

# minimal set up to get things working
$model->create_config_class(
    name    => "Master",
    element => [
        plain_hash                => { 
            type => 'hash', 
            status => 'deprecated' ,
            index_type => 'string',
            ordered => 1,
            cargo => {
                type       => 'leaf',
                value_type => 'string'
            },
        },
        hash_with_data_migration => {
            type => 'hash',
            index_type => 'string',
            migrate_values_from => '- plain_hash',
            ordered => 1,
            cargo => {
                type       => 'leaf',
                value_type => 'string' ,
            },
        },
        hash2_with_data_migration => {
            type => 'hash',
            index_type => 'string',
            migrate_values_from => '- hash_with_data_migration',
            ordered => 1,
            cargo => {
                type       => 'leaf',
                value_type => 'string' ,
            },
        },
    ]
);

ok(1,"config classes created") ;

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

# emulate start of file read
$inst->initial_load_start ;

# emulate config file load
$root->load(step => "plain_hash:k1=foo plain_hash:k2=bar", check => 'no') ;
ok(1,"set up plain hash") ;

my $hwdm = $root->fetch_element('hash_with_data_migration') ;
ok($hwdm, "create hash_with_data_migration element") ;
$hwdm->fetch_with_id('new')->store('baz0') ;

# check data prior to migration
eq_or_diff([$hwdm->fetch_all_values], ['baz0'],"hash data before migration") ;

# emulate end of file read
$inst->initial_load_stop ;

# test data migration stuff

eq_or_diff([$hwdm->fetch_all_indexes],[ qw/new k1 k2/ ],"hash keys after migration") ;
eq_or_diff([$hwdm->fetch_all_values], [ qw/baz0 foo bar/],"hash data after migration ") ;

my $hwdm2 = $root->fetch_element('hash2_with_data_migration') ;
ok($hwdm2, "create hash2_with_data_migration element") ;
eq_or_diff([$hwdm2->fetch_all_values], [ qw/baz0 foo bar/],"hash data after 2nd migration ") ;

memory_cycle_ok($model,"test memory cycles");
