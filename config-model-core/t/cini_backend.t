# -*- cperl -*-
# $Author: ddumont, random_nick $
# $Date: 2008-07-04 16:14:06 +0200 (Fri, 04 Jul 2008) $
# $Revision: 971 $

use ExtUtils::testlib;
use Test::More ;
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

plan tests => 6 ;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root/';


# cleanup before tests
rmtree($wr_root);
mkpath($wr_root.'cini/', { mode => 0755 }) ;

# set_up data
do "t/test_model.pl" ;

my $i_hosts = $model->instance(instance_name    => 'hosts_inst',
                   root_class_name  => 'Host',
                   root_dir    => $wr_root ,
                   model_file       => 't/test_cini_model.pl',
                  );

ok( $i_hosts, "Created instance" );


my $i_root = $i_hosts->config_root ;

my $load = "ipaddr=127.0.0.1
id=this_machine
aliases=localhost,home,this -
";

$i_root->load($load) ;

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

is($p2_dump,$load,"compare original data with 2nd instance data") ;
