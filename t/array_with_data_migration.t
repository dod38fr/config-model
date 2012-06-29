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
        plain_list                => { 
            type => 'list', 
            status => 'deprecated' ,
            cargo => {
                type       => 'leaf',
                value_type => 'string'
            },
        },
        list_with_data_migration => {
            type => 'list',
            migrate_values_from => '- plain_list',
            cargo => {
                type       => 'leaf',
                value_type => 'string' ,
            },
        },
        list2_with_data_migration => {
            type => 'list',
            migrate_values_from => '- list_with_data_migration',
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
my $pl = $root->fetch_element(name => 'plain_list', check =>'no');
$pl->push(qw/foo bar/) ;
my @old = $pl->fetch_all_values ;
ok(1,"set up plain list") ;

my $lwdm = $root->fetch_element('list_with_data_migration') ;
ok($lwdm, "create list_with_data_migration element") ;
$lwdm->fetch_with_id(0)->store('baz0') ;

# check data prior to migration
eq_or_diff([$lwdm->fetch_all_values], ['baz0'],"list data before migration") ;

# emulate end of file read
$inst->initial_load_stop ;

# test data migration stuff

eq_or_diff([$lwdm->fetch_all_indexes],[ 0 ..2 ],"list size after migration") ;
eq_or_diff([$lwdm->fetch_all_values], [ baz0 => @old],"list data migration (@old)") ;

my $lwdm2 = $root->fetch_element('list2_with_data_migration') ;
ok($lwdm2, "create list2_with_data_migration element") ;
eq_or_diff([$lwdm2->fetch_all_values], [ baz0 => @old ],"list2 data migration (@old)") ;

memory_cycle_ok($model,"test memory cycles");
