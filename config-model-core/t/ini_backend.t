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

plan tests => 23 ;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root/';

# set_up data
my @with_semi_column_comment = my @with_hash_comment = <DATA> ;
# change delimiter comments
map {s/#/;/;} @with_semi_column_comment ;
my %test_setup = ( IniTest  => \@with_hash_comment, 
                   IniTest2 => \@with_semi_column_comment);

foreach my $test_class (sort keys %test_setup) {
   my @orig = @{$test_setup{$test_class}} ;

   # cleanup before tests
   rmtree($wr_root);

   my $test1 = 'ini1' ;
   my $wr_dir = $wr_root.'/'.$test1 ;
   my $conf_file = "$wr_dir/etc/test.ini" ;

   mkpath($wr_dir.'/etc', { mode => 0755 }) 
      || die "can't mkpath: $!";
   open(CONF,"> $conf_file" ) || die "can't open $conf_file: $!";
   print CONF @orig ;
   close CONF ;

   my $i_test = $model->instance(instance_name    => 'test_inst',
                                 root_class_name  => $test_class,
                                 root_dir    => $wr_dir ,
                                 model_file       => 't/test_ini_backend_model.pl',
                                 );

   ok( $i_test, "Created $test_class instance" );


   my $i_root = $i_test->config_root ;

   is($i_root->annotation,"some global comment","check global comment");
   is($i_root->fetch_element("class1")->annotation,"class1 comment",
      "check class1 comment");

   my $lista_obj = $i_root->fetch_element("class1")->fetch_element('lista');
   is($lista_obj->annotation, undef,"check lista comment"); 

   foreach my $i (1 .. 3) {
      my $elt = $lista_obj->fetch_with_id($i - 1) ;
      is($elt->annotation,
         "lista$i comment","check lista[$i] comment");
      } 

   my $orig = $i_root->dump_tree ;
   print $orig if $trace ;

   $i_test->write_back ;
   ok(1,"IniFile write back done") ;

   my $ini_file      = $wr_dir.'/etc/test.ini';
   ok(-e $ini_file, "check that config file $ini_file was written");

   # create another instance to read the IniFile that was just written
   my $wr_dir2 = $wr_root.'/ini2' ;
   mkpath($wr_dir2.'/etc',{ mode => 0755 })   || die "can't mkpath: $!";
   copy($wr_dir.'/etc/test.ini',$wr_dir2.'/etc/') 
      or die "can't copy from test1 to test2: $!";

   my $i2_test = $model->instance(instance_name    => 'test_inst2',
                                  root_class_name  => $test_class,
                                  root_dir    => $wr_dir2 ,
                                 );

   ok( $i2_test, "Created instance" );


   my $i2_root = $i2_test->config_root ;

   my $p2_dump = $i2_root->dump_tree ;

   is($p2_dump,$orig,"compare original data with 2nd instance data") ;

}

__DATA__
#some global comment


# foo1 comment
foo = foo1

foo = foo2 # foo2 comment

bar = bar1 

# class1 comment
[class1]
lista=lista1 #lista1 comment
# lista2 comment
lista    =    lista2 
# lista3 comment
lista    =    lista3 
