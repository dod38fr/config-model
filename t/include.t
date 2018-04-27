# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Exception;
use Test::Differences;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

use strict;
use warnings;

# minimal set up to get things working
my ($model, $trace) = init_test();

$model->create_config_class(
    name => "Two",

    element => [
        two => {
            type       => 'leaf',
            value_type => 'string',
        },

    ] );

$model->create_config_class(
    name => "Three",

    element => [
        three => {
            type       => 'leaf',
            value_type => 'string',
        },

    ] );

$model->create_config_class(
    name => "Four",

    include => [qw/Three/],
    element => [
        four => {
            type       => 'leaf',
            value_type => 'string',
        },

    ] );

$model->create_config_class(
    name => "Master",

    include       => [qw/Two Four/],
    include_after => 'one',

    element => [
        one => {
            type       => 'leaf',
            value_type => 'string',
        },

    ] );

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

my @elt = $root->get_element_name();
is_deeply( \@elt, [qw/one two three four/], "check multiple include order" );

my @bad_class = (
    name    => "EvilMaster",
    include => [qw/Master/],
    element => [ one => { type => 'leaf', value_type => 'string', }, ] );

# failure occurs later
$model->create_config_class(@bad_class);

throws_ok { $model->get_model('EvilMaster'); } qr/cannot clobber/i,
    "Check that include does not clobber elements";

# test include of read/write spec
$model->create_config_class(
    name => 'LikeXorg',
    'include_backend' => [
      'Xorg::ConfigDir'
    ],
    element => [
        one => {
            type       => 'leaf',
            value_type => 'string',
        },

    ],
);

my $read_config = [{
    'auto_create' => 1,
    'backend' => 'Xorg',
    'config_dir' => '/etc/X11',
    'file' => 'xorg.conf'
}] ;

$model->create_config_class(
    'name' => 'Xorg::ConfigDir',
    'read_config' => $read_config
);

my $xorg_model = $model->get_model('LikeXorg');

# use $read_config->[0] because of legacy translation from read_config array to rw_config
eq_or_diff($xorg_model->{rw_config}, $read_config->[0],"check included read specification");

memory_cycle_ok($model, "memory cycles");

done_testing;
