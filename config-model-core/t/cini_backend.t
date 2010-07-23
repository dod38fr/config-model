# -*- cperl -*-
# $Author: ddumont, random_nick $

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

plan tests => 8 ;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root/';

# cleanup before tests
rmtree($wr_root);

# set_up data
my @orig = <DATA> ;

my $test1 = 'cini1' ;
my $wr_dir = $wr_root.'/'.$test1 ;
my $conf_file = "$wr_dir/etc/test.ini" ;

mkpath($wr_dir.'/etc', { mode => 0755 }) 
  || die "can't mkpath: $!";
open(CONF,"> $conf_file" ) || die "can't open $conf_file: $!";
print CONF @orig ;
close CONF ;

my $i_test = $model->instance(instance_name    => 'test_inst',
                   root_class_name  => 'Cini',
                   root_dir    => $wr_dir ,
                   model_file       => 't/test_cini_model.pl',
                  );

ok( $i_test, "Created instance" );


my $i_root = $i_test->config_root ;

is($i_root->annotation,"some global comment","check global comment");
is($i_root->fetch_element("class1")->annotation,"class1 comment",
   "check class1 comment");

my $orig = $i_root->dump_tree ;
print $orig if $trace ;

$i_test->write_back ;
ok(1,"ComplexIni write back done") ;

my $cini_file      = $wr_dir.'/etc/test.ini';
ok(-e $cini_file, "check that config file $cini_file was written");

# create another instance to read the ComplexIni that was just written
my $wr_dir2 = $wr_root.'/cini2' ;
mkpath($wr_dir2.'/etc',{ mode => 0755 })   || die "can't mkpath: $!";
copy($wr_dir.'/etc/test.ini',$wr_dir2.'/etc/') 
  or die "can't copy from test1 to test2: $!";

my $i2_test = $model->instance(instance_name    => 'test_inst2',
                               root_class_name  => 'Cini',
                               root_dir    => $wr_dir2 ,
                              );

ok( $i2_test, "Created instance" );


my $i2_root = $i2_test->config_root ;

my $p2_dump = $i2_root->dump_tree ;

is($p2_dump,$orig,"compare original data with 2nd instance data") ;

__DATA__
#some global comment


# foo1 comment
foo = foo1

foo = foo2 # foo2 comment

bar = bar1 

# class1 comment
[class1]
lista=lista1 #lista1 comment
lista    =    lista2
