use ExtUtils::testlib;
use Test::More;
use Test::Exception;
use Test::Memory::Cycle;
use Test::Differences;
use Data::Dumper;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;

use strict;
use warnings;

use lib 'wr_root/load_model_snippets';

my ($model, $trace) = init_test();

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir();

my $model_dir = $wr_root->child('Config/Model/models');
$model_dir->mkpath;

my $str = << 'EOF' ;
---
- name: Master
  element:
  - name: one
    type: leaf
    value_type: string
  - name: fs_vfstype
    type: leaf
    value_type: enum
    choice: [auto, ext2, ext3]
  - name: fs_mntopts
    type: warped_node
    warp:
      follow:
        f1: '- fs_vfstype'
      rules:
      - when: $f1 eq 'auto'
        apply:
          config_class_name: Fstab::CommonOptions
      - when: $f1 eq 'ext2'
        apply:
          config_class_name: Fstab::Ext2FsOpt
      - when: $f1 eq 'ext3'
        apply:
          config_class_name: Fstab::Ext3FsOpt
  accept:
  - .*
  - type: leaf
    value_type: uniline
EOF

$model_dir->child('Master.yml')->spew($str);

$str = << 'EOF' ;
---
- name: Two
  element:
  - name: two
    type: leaf
    value_type: string
EOF

$model_dir->child('Two.yml')->spew($str);


$str = << 'EOF' ;
---
name: Master
include: Two
include_after: fs_mntopts
element:
- name: three
  type: leaf
  value_type: string
- name: fs_vfstype
  choice: [ext4]
- name: fs_mntopts
  warp:
    rules:
    - when: $f1 eq 'ext4'
      apply:
        config_class_name: Fstab::Ext4FsOpt
accept:
- pattern: .*
  description: catchall
- pattern: ip.*
  type: leaf
  value_type: uniline
EOF

my $snippet_dir = $model_dir->child('Master.d');
$snippet_dir->mkpath();

$snippet_dir->child('Three.yml')->spew($str);

# use Tk::ObjScanner; Tk::ObjScanner::scan_object($model) ;

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);

ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

my $augmented_model = $model->get_model_clone('Master');
print Dumper ($augmented_model) if $trace;

my @elt = $root->get_element_name();
print "element list: @elt\n" if $trace;
eq_or_diff( \@elt, [qw/one fs_vfstype two three/], "check augmented class" );

my $fstype     = $root->fetch_element('fs_vfstype');
my @fs_choices = $fstype->get_choice;
eq_or_diff( \@fs_choices, [qw/auto ext2 ext3 ext4/], "check augmented choices" );

eq_or_diff(
    $augmented_model->{element}{fs_mntopts}{warp}{rules},
    [
        {
            when => q!$f1 eq 'auto'!,
            apply => { config_class_name => 'Fstab::CommonOptions' }
        },
        {
            when => q!$f1 eq 'ext2'!,
            apply => { config_class_name => 'Fstab::Ext2FsOpt' }
        },
        {
            when => q!$f1 eq 'ext3'!,
            apply => { config_class_name => 'Fstab::Ext3FsOpt' }
        },
        {
            when => q!$f1 eq 'ext4'!,
            apply => { config_class_name => 'Fstab::Ext4FsOpt' }
        }
    ],
    "test augmented rules"
);

eq_or_diff( $augmented_model->{accept_list}, [ '.*', 'ip.*' ], "test accept_list" );
is( $augmented_model->{accept}{'.*'}{description}, 'catchall', "test augmented rules" );

memory_cycle_ok($model, "memory cycles");

done_testing;
