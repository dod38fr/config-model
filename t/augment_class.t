# -*- cperl -*-

use Test::More;
use Test::Memory::Cycle;
use Test::Differences;
use Config::Model;
use Data::Dumper;
use Config::Model::Tester::Setup qw/init_test/;

use strict;
use warnings;

my ($model, $trace) = init_test();

$model->create_config_class(
    name => "Master",

    accept => [
        '.*' => {
            type       => 'leaf',
            value_type => 'uniline',
        }
    ],

    element => [
        one => {
            type       => 'leaf',
            value_type => 'string',
        },
        override_vtype => {
            type       => 'leaf',
            value_type => 'uniline',
        },
        fs_vfstype => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/auto ext2 ext3/],
        },
        fs_mntopts => {
            type   => 'warped_node',
            warp => {
                follow => { 'f1' => '- fs_vfstype' },
                rules  => [
                    '$f1 eq \'auto\'',
                    { 'config_class_name' => 'Fstab::CommonOptions' },
                    '$f1 eq \'ext2\'',
                    { 'config_class_name' => 'Fstab::Ext2FsOpt' },
                    '$f1 eq \'ext3\'',
                    { 'config_class_name' => 'Fstab::Ext3FsOpt' },
                ],
            }
        }
    ]
);

$model->create_config_class(
    name    => "Two",
    element => [ two => { type => 'leaf', value_type => 'string', }, ]
);

$model->augment_config_class(
    name          => "Master",
    include       => 'Two',
    include_after => 'fs_mntopts',

    accept => [
        '.*'   => { description => "catchall" },
        'ip.*' => {
            type       => 'leaf',
            value_type => 'uniline',
        }
    ],

    element => [
        override_vtype => {
            type       => 'leaf',
            value_type => 'integer',
            min => 1,
        },
        three => {
            type       => 'leaf',
            value_type => 'string',
        },
        fs_vfstype => { choice => [qw/ext4/], },
        fs_mntopts => {
            warp => {
                rules => [ q!$f1 eq 'ext4'!, { 'config_class_name' => 'Fstab::Ext4FsOpt' }, ]
            }
        },
    ]
);

# augment a class which is inherited
$model->augment_config_class(
    name    => "Two",
    element => [ two_and_a_half => { type => 'leaf', value_type => 'string', }, ]
);

# use Tk::ObjScanner; Tk::ObjScanner::scan_object($model) ;

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

my $augmented_model = $model->get_model('Master');
print Dumper ($augmented_model) if $trace;

my @elt = $root->get_element_name();
print "element list: @elt\n" if $trace;
eq_or_diff( \@elt, [qw/one override_vtype fs_vfstype two two_and_a_half three/], "check augmented class" );

my $fstype     = $root->fetch_element('fs_vfstype');
my @fs_choices = $fstype->get_choice;
eq_or_diff( \@fs_choices, [qw/auto ext2 ext3 ext4/], "check augmented choices" );

eq_or_diff(
    $augmented_model->{element}{fs_mntopts}{warp}{rules},
    [
        '$f1 eq \'auto\'',
        { 'config_class_name' => 'Fstab::CommonOptions' },
        '$f1 eq \'ext2\'',
        { 'config_class_name' => 'Fstab::Ext2FsOpt' },
        '$f1 eq \'ext3\'',
        { 'config_class_name' => 'Fstab::Ext3FsOpt' },
        '$f1 eq \'ext4\'',
        { 'config_class_name' => 'Fstab::Ext4FsOpt' }
    ],
    "test augmented rules"
);

is( $augmented_model->{element}{override_vtype}{value_type}, 'integer', "test value type override" );
is( $augmented_model->{element}{override_vtype}{min}, 1, "test min setup" );

eq_or_diff( $augmented_model->{accept_list}, [ '.*', 'ip.*' ], "test accept_list" );
is( $augmented_model->{accept}{'.*'}{description}, 'catchall', "test augmented rules" );

memory_cycle_ok($model,"check memory cycles");

done_testing;
