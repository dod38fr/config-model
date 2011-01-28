# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Config::Model;
use File::Path;
use File::Copy ;
use Data::Dumper ;
use IO::File ;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model -> new () ;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;

if (-e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($arg =~ /l/ ? $DEBUG: $WARN);
}

plan tests => 8 ;

ok(1,"compiled");
my $subdir= 'plain/';

$model->create_config_class(
    name => "WithPlainFile",
    element => [ 
        [qw/source new/] => { qw/type leaf value_type uniline/ },
    ],
    read_config  => [ 
        { 
            backend => 'plain_file', 
            config_dir => $subdir,
        },
    ],
 );

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root/';

# cleanup before tests
rmtree($wr_root);
mkpath($wr_root.$subdir, { mode => 0755 }) ;
my $fh = IO::File->new ;
$fh ->open($wr_root.$subdir.'source', ">") ;
$fh->print("2.0\n");
$fh ->close ;
ok(1,"wrote source file");

my $inst = $model->instance(
    root_class_name  => 'WithPlainFile',
    root_dir    => $wr_root ,
);

ok( $inst, "Created instance" );

my $root = $inst->config_root ;

is($root->grab_value("source"),"2.0","got correct source value");

my $load = qq[source="3.0 (quilt)"\nnew="new stuff" -\n] ;

$root->load($load) ;

$inst->write_back ;
ok(1,"plain file write back done") ;

my $new_file      = $wr_root.'plain/new';
ok(-e $new_file, "check that config file $new_file was written");

# create another instance to read the yaml that was just written
my $i2_plain = $model->instance(instance_name    => 'inst2',
				root_class_name  => 'WithPlainFile',
				root_dir    => $wr_root ,
			       );

ok( $i2_plain, "Created 2nd instance" );


my $i2_root = $i2_plain->config_root ;

my $p2_dump = $i2_root->dump_tree ;

is($p2_dump,$load,"compare original data with 2nd instance data") ;
