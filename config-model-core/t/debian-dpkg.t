# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Test::Memory::Cycle;
use Config::Model ;
use Log::Log4perl qw(:easy) ;
use File::Path ;
use File::Copy ;
use File::Slurp ;
use Test::Warn ;
use Test::Exception ;

use warnings;

use strict;

eval { require AptPkg::Config ;} ;
if ( $@ ) {
    plan skip_all => "AptPkg::Config is not installed";
}
elsif ( -r '/etc/debian_version' ) {
    plan tests => 15;
}
else {
    plan skip_all => "Not a Debian system";
}

my $arg = shift ;
$arg = '' unless defined $arg ;

my ($log,$show) = (0) x 2 ;
my $do ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;
$do                 = $1 if $arg =~ /(\d+)/;

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

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root';

# cleanup before tests
rmtree($wr_root);
mkpath($wr_root, { mode => 0755 }) ;

my $dpkg = $model->instance(
    root_class_name => 'Debian::Dpkg',
    root_dir        => $wr_root,
);

my $root = $dpkg->config_root ;

my $opt = 'config\..*|configure|.*Makefile.in|aclocal.m4|\.pc' ;

my @test = (
    [ "clean=foo,bar,baz",           'clean',         "foo\nbar\nbaz\n" ],
    [ 'source format="3.0 (quilt)"', 'source/format', "3.0 (quilt)\n" ],
    [
        qq!source options extend-diff-ignore="$opt"!, 'source/options',
        qq!extend-diff-ignore="$opt"\n!
    ],
);

my %files ;
foreach my $t (@test) {
    my ($load, $file, $content) = @$t ;
	$files{$file} = $content if $file;

	print "loading: $load\n" if $trace ;
	$root->load($load) ;

	$dpkg->write_back ;

	foreach my $f (keys %files) {
	    my $test_file = "$wr_root/debian/$f" ;
	    ok(-e $test_file ,"check that $f exists") ;
		my @lines = grep { ! /^#/ and /\w/ } read_file($test_file) ;
		is(join('',@lines),$files{$f},"check $f content") ;
	}
}

$root->load('control source Maintainer="foo <foo@bar>" ! meta dependency-filter=lenny') ;
is($root->grab_value("meta package-dependency-filter:foopkg"),
    'lenny', "check package-dependency-filter");
memory_cycle_ok($model);
