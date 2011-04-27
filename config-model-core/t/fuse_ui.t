# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Path::Class ;

use Config::Model;
use Config;

if ($Config{osname} ne 'linux') {
    plan skip_all => "Not a Linux system" ;
}

my @lsmod = eval { `lsmod` ;} ;

if ($@) {
      plan skip_all => "Cannot check is fuse module is loaded: $@" ;
}

if (not grep (/fuse/, @lsmod)) {
      plan skip_all => "fuse module is not loaded" ;
}

if (not grep (/is/ , `bash -c 'type fusermount'`) ) {
      plan skip_all => "fusermount not found" ;
}

eval { require Config::Model::FuseUI ;} ;
if ( $@ ) {
    plan skip_all => "Config::Model::FuseUI or Fuse is not installed";
}
else {
    plan tests => 12;
}

use warnings FATAL => qw(all);
use strict;

# required to handle warnings in forked process
local $SIG{__WARN__} = sub { die $_[0] };

use Data::Dumper;
use POSIX ":sys_wait_h";

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
my $fuse_debug = $arg =~ /f/ ? 1 : 0 ;
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
ok(1,"Compilation done");

# pseudo root where config files are written by config-model
my $wr_root = dir('wr_root');

# cleanup before tests
$wr_root->rmtree;
$wr_root->mkpath( { mode => 0755 }) ;

my $fused = $wr_root->subdir('fused') ;
$fused->mkpath( { mode => 0755 }) ;

my $model = Config::Model -> new(legacy => 'ignore')  ;

$model->load(Master => 't/big_model.pm') ;


$model->augment_config_class(
    name => 'Master',
    element => [ 
        'a_boolean' => { type => 'leaf', value_type => 'boolean', default => 0  } ,
    ],
);

my $inst = $model->instance (root_class_name => 'Master');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata"';
ok( $root->load( step => $step, experience => 'advanced' ),
  "set up data in tree with '$step'");

my $ui = Config::Model::FuseUI->new(
    root => $root , 
    mountpoint => "$fused",
);

ok($ui,"Created ui") ;

# now fork 
my $pid = fork ;

if (defined $pid and $pid == 0) {
    # child process, just run fuse and wait for exit
    $ui->run_loop(debug => $fuse_debug) ;
    exit ;
}

# WARNING: the child process has its own copy of the config tree
# there's no use in modifying the tree on the parent process.

# wait for fuse to do its job
sleep 1;

# child process, continue tests
my @content = sort map { $_->relative($fused) ; } $fused->children ;
is_deeply( \@content ,[sort $root->get_element_name() ],"check $fused content");

my $std_id = $fused->subdir('std_id') ;
@content = sort map { $_->relative($std_id) ; } $std_id-> children ;
my @std_id_elements = sort $root->fetch_element('std_id')->get_all_indexes() ;
is_deeply( \@content , \@std_id_elements ,"check $std_id content (@content)");

is( $fused->file('a_string')->slurp , $root->grab_value('a_string')."\n",
    "check a_string content");
my $a_string_fhw = $fused->file('a_string')->openw ;
$a_string_fhw -> print("foo bar") ;
$a_string_fhw->close ;

is( $fused->file('a_string')->slurp , "foo bar\n", "check new a_string content");

$std_id->subdir('cd')->mkpath() ;
@content = sort map { $_->relative($std_id) ; } $std_id-> children ;
is_deeply( \@content ,  [ @std_id_elements, 'cd' ] ,"check $std_id new content (@content)");

$std_id->subdir('cd')->rmtree() ;
@content = sort map { $_->relative($std_id) ; } $std_id-> children ;
is_deeply( \@content ,  \@std_id_elements ,"check $std_id content after rmdir (@content)");

is( $fused->file('a_boolean')->slurp , "0\n", "check new a_boolean content");
my $a_boolean_fhw = $fused->file('a_boolean')->openw ;
$a_boolean_fhw -> print("1") ;
$a_boolean_fhw->close ;

END {
    if ($pid) {
        # run this only in parent process
        # umount so child process will exit 
        system("fusermount -u $fused")  ;
    
        # inspired from perlipc man page
        my $child;
        while ( ($child = wait) > 0) {
            ok (1,"Process pid $child done");
        }
    }
    exit ;
}




