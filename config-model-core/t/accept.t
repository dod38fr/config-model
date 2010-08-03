# -*- cperl -*-
# $Author: ddumont, random_nick $

use ExtUtils::testlib;
use Test::More ;
use Test::Exception ;
use Config::Model;
use File::Path;
use File::Copy ;
use Data::Dumper ;

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
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $ERROR);

plan tests => 8 ;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root/';

# cleanup before tests
rmtree($wr_root);
mkpath($wr_root.'cini/', { mode => 0755 }) ;

# set_up data

my $i_hosts = $model->instance(instance_name    => 'hosts_inst',
                   root_class_name  => 'Host',
                   root_dir    => $wr_root ,
                   model_file       => 't/test_accept.pl',
                  );

ok( $i_hosts, "Created instance" );


my $i_root = $i_hosts->config_root ;

my $load = "listA=one,two,three,four
listB=1,2,3,4
listC=a,b,c,d
str1=test
str2=of
str3=accept
str4=parameter -
";

$i_root->load($load) ;
ok(1,"Data loaded") ;

$i_hosts->write_back ;
ok(1,"ComplexIni write back done") ;



my $cini_file      = $wr_root.'cini/hosts.ini';
ok(-e $cini_file, "check that config file $cini_file was written");

# create another instance to read the ComplexIni that was just written
my $i2_hosts = $model->instance(instance_name    => 'hosts_inst2',
                root_class_name  => 'Host',
                root_dir    => $wr_root ,
                   );

ok( $i2_hosts, "Created instance" );


my $i2_root = $i2_hosts->config_root ;

my $p2_dump = $i2_root->dump_tree ;

#Line order is not preserved...
my $spload = join(' ',sort(split(/\s/,$load)));
my $spdump = join(' ',sort(split(/\s/,$p2_dump)));


is($spdump,$spload,"compare original data with 2nd instance data") ;

throws_ok { $i_root->load("foo=bar"); } "Config::Model::Exception::UnknownElement", 'caught unacceptable parameter';

