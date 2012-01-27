# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use File::Path;
use File::Copy;
use Data::Dumper;
use Log::Log4perl qw(:easy);
use Test::Differences;
use Test::File::Contents;

use warnings;
no warnings qw(once);

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0;
my $log   = $arg =~ /l/ ? 1 : 0;

my $log4perl_user_conf_file = $ENV{HOME} . '/.log4config-model';

if ( $log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init( $log ? $WARN : $ERROR );
}
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

plan tests => 15;

ok( 1, "compiled" );

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root/';

my $head = << 'EOH';
## This file was written by Config::Model
## You may modify the content of this file. Configuration 
## modifications will be preserved. Modifications in
## comments may be mangled.
EOH

my @below_data = split /\n/, << 'EOD2' ;
[Low]
foo=bar

[Section1]
source=1

[Section2]
source=2

[Empty]
EOD2

my $w_file_below = join("\n",$head,'', map {lc} @below_data[3..8,0..2]);

# set_up data
my @general_data = split /\n/, << 'EOD1' ;
[General]
foo=bar

[Section1]
source=1

[Section2]
source=2

[Empty]
EOD1

my $w_file_general = join("\n",$head, map {lc} @general_data[0..8]);

# change delimiter comments
my %test_setup = ( 
    SectionMapTop => [ \@general_data, 'general' , $w_file_general ], 
    SectionMap    => [ \@below_data,   'below' , $w_file_below], 
);

my $model = Config::Model->new();

$model->create_config_class(
    'name'    => 'Section',
    'element' => [
        'source',
        {
            'value_type' => 'uniline',
            'type'       => 'leaf'
        },
    ],
);

$model->create_config_class(
    'name'    => 'Below',
    'element' => [
         foo => { qw/type leaf value_type uniline/, },
    ],
);


$model->create_config_class(
    name          => 'SectionMapTop',
    'read_config' => [
        {
            'section_map'         => { 'general' => '!' },
            'backend'             => 'ini_file',
            'split_list_value'    => '\\s+',
            'store_class_in_hash' => 'sections',
            force_lc_section => 1,
        }
    ],

    element => [
        'sections',
        {
            'cargo' => {
                'type'              => 'node',
                'config_class_name' => 'Section'
            },
            'type'       => 'hash',
            'index_type' => 'string'
        },

        foo => { qw/type leaf value_type uniline/, },
    ]
);

$model->create_config_class(
    name          => 'SectionMap',
    'read_config' => [
        {
            'section_map'         => { 'low' => 'below' },
            'backend'             => 'ini_file',
            'split_list_value'    => '\\s+',
            'store_class_in_hash' => 'sections',
            force_lc_section => 1,
        }
    ],

    element => [
        'sections',
        {
            'cargo' => {
                'type'              => 'node',
                'config_class_name' => 'Section'
            },
            'type'       => 'hash',
            'index_type' => 'string'
        },

        below => { qw/type node config_class_name Below/, },
        foo => { qw/type leaf value_type uniline/, },
    ]
);

# cleanup before tests
rmtree($wr_root);

foreach my $test_class ( sort keys %test_setup ) {
    my @orig      = @{ $test_setup{$test_class}[0] };
    my $test_path = $test_setup{$test_class}[1];
    my $written_file = $test_setup{$test_class}[2];

    ok( 1, "Starting $test_class tests in $test_path dir" );

    my $test1     = 'ini1';
    my $wr_dir    = "$wr_root/$test_path/$test1";
    my $conf_file = "/etc/test.ini";
    my $abs_conf_file = "$wr_dir$conf_file";

    mkpath( $wr_dir . '/etc', { mode => 0755 } )
      || die "can't mkpath: $!";
    open( CONF, "> $abs_conf_file" ) || die "can't open $abs_conf_file: $!";
    print CONF map { "$_\n"} @orig;
    close CONF;

    my $i_test = $model->instance(
        instance_name   => $test_path,
        root_class_name => $test_class,
        root_dir        => $wr_dir,
        config_file     => $conf_file,
    );

    ok( $i_test, "Created $test_class instance" );

    my $i_root = $i_test->config_root;

    my $orig = $i_root->dump_tree;
    print $orig if $trace;

    $i_test->write_back(config_file     => $conf_file);
    ok( 1, "IniFile write back done" );

    my $ini_file = $wr_dir . '/etc/test.ini';
    ok( -e $ini_file, "check that config file $ini_file was written" );

    file_contents_eq_or_diff $ini_file,  $written_file, 
        "check file $ini_file content" ;


    # create another instance to read the IniFile that was just written
    my $wr_dir2 = "$wr_root/$test_path/ini2";
    mkpath( $wr_dir2 . '/etc', { mode => 0755 } ) || die "can't mkpath: $!";
    copy( $wr_dir . '/etc/test.ini', $wr_dir2 . '/etc/' )
      or die "can't copy from test1 to test2: $!";

    my $i2_test = $model->instance(
        instance_name   => $test_path.'2',
        root_class_name => $test_class,
        root_dir        => $wr_dir2,
        config_file     => $conf_file,
    );

    ok( $i2_test, "Created instance" );

    my $i2_root = $i2_test->config_root;

    my $p2_dump = $i2_root->dump_tree;
    
    $i_root->load('sections~empty');
    my $orig_fixed = $i_root->dump_tree ;

    eq_or_diff( 
        [ split /\n/, $p2_dump], 
        [ split /\n/ , $orig_fixed ],
         "compare original data with 2nd instance data" 
    );

}
memory_cycle_ok($model);
