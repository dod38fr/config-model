# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Test::Exception ;
use Test::Memory::Cycle;
use Config::Model;
use Data::Dumper ;
use IO::File ;
use File::Path ;

BEGIN { plan tests => 7; }

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"Compilation done");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root';

# cleanup before tests
rmtree($wr_root);
mkpath($wr_root, { mode => 0755 }) ;

my $file = "$wr_root/Master.pl" ;
my $fh = IO::File->new($file ,'>') or die "can't open write $file:$!" ;

my $str = << 'EOF' ;
[
    {
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
            fs_vfstype => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/auto ext2 ext3/],
            },
            fs_mntopts => {
                type   => 'warped_node',
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
        ]
    }
];
EOF

$fh->print($str) ;

$fh->close ;

$file = "$wr_root/Two.pl" ;
$fh = IO::File->new($file ,'>') or die "can't open write $file:$!" ;

$str = << 'EOF' ;
[{
    name => "Two",
    element => [ two => { type => 'leaf', value_type => 'string', }, ]
}] ;
EOF

$fh->print($str) ;

$fh->close ;

my $snippet_dir = "$wr_root/Master.d" ;
mkpath($snippet_dir, { mode => 0755 }) ;
$file = "$snippet_dir/Three.pl" ;
$fh = IO::File->new($file ,'>') or die "can't open write $file:$!" ;

$str = << 'EOF' ;
{
    name    => "Master",
    include => 'Two',

    accept => [
        '.*'   => { description => "catchall" },
        'ip.*' => {
            type       => 'leaf',
            value_type => 'uniline',
        }
    ],

    element => [
        three => {
            type       => 'leaf',
            value_type => 'string',
        },
        fs_vfstype => { choice => [qw/ext4/], },
        fs_mntopts => {
            rules => [
                q!$f1 eq 'ext4'!,
                { 'config_class_name' => 'Fstab::Ext4FsOpt' },
            ],
        },
    ]
};
EOF

$fh->print($str) ;

$fh->close ;

# minimal set up to get things working
my $model = Config::Model->new(    
    model_dir => $wr_root,
) ;

my $inst = $model->instance (
    root_class_name => 'Master', 
    instance_name => 'test1'
);

ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $augmented_model = $model->get_model('Master') ;
print Dumper ($augmented_model) if $trace;

my @elt = $root->get_element_name() ;
print "element list: @elt\n" if $trace ;
is_deeply(\@elt,[qw/one fs_vfstype two three/],"check augmented class") ;

my $fstype = $root->fetch_element('fs_vfstype');
my @fs_choices = $fstype->get_choice ;
is_deeply(\@fs_choices, [qw/auto ext2 ext3 ext4/], "check augmented choices") ;

is_deeply($augmented_model->{element}{fs_mntopts}{rules}, 
    [
        '$f1 eq \'auto\'', { 'config_class_name' => 'Fstab::CommonOptions' },
        '$f1 eq \'ext2\'', { 'config_class_name' => 'Fstab::Ext2FsOpt' }, 
        '$f1 eq \'ext3\'', { 'config_class_name' => 'Fstab::Ext3FsOpt' }, 
        '$f1 eq \'ext4\'', { 'config_class_name' => 'Fstab::Ext4FsOpt' }
    ],   
    "test augmented rules"
);

is_deeply($augmented_model->{accept_list},['.*','ip.*'],"test accept_list");
is($augmented_model->{accept}{'.*'}{description},'catchall',"test augmented rules");
memory_cycle_ok($model);
