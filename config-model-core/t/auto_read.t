# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-12-06 12:51:59 $
# $Name: not supported by cvs2svn $
# $Revision: 1.2 $

use ExtUtils::testlib;
use Test::More tests => 14;
use Config::Model;
use File::Path;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model -> new ;

my $trace = shift || 0;
$::verbose          = 1 if $trace =~ /v/;
$::debug            = 1 if $trace =~ /d/;
Config::Model::Exception::Any->Trace(1) if $trace =~ /e/;

ok(1,"compiled");

# directory were input config file are read
my $zdir = 'zero_test';

# setup input config file dir
mkdir( $zdir, 0755 ) unless -d $zdir;

my %cds = (
    Master => 'aa="aa was set" level1 bar X=Av Y=Bv - - ',
    Level1   => 'bar X=Av Y=Bv - '
);

# write input config files
foreach my $f ( keys %cds ) {
    my $fout = "$zdir/$f.cds";
    next if -r $fout;

    open( FOUT, ">$fout" ) or die "can't open $fout:$!";
    print FOUT $cds{$f};
    close FOUT;
}

# directory where config files are written by config-model
my $wr_dir = 'wr_test';

# cleanup before tests
rmtree($wr_dir);

# model declaration
$model->create_config_class 
  (
   name   => 'Level2',
   element => [
	       [qw/X Y Z/] => {
			       type => 'leaf',
			       value_type => 'enum',
			       choice     => [qw/Av Bv Cv/]
			      }
	      ]
  );

$model->create_config_class 
  (
   name => 'Level1',

   # try first to read with cds string and then custom class
   read_config  => [ 'cds', { class => 'Level1Read', function => 'read_it' } ],
   write_config => 'cds',

   read_config_dir  => $zdir,
   write_config_dir => $wr_dir,

   element => [
	       bar => { type => 'node',
			config_class_name => 'Level2',
			init_step => [ Y => 'Bv' ]
		      } 
	      ]
   );


$model->create_config_class 
  (
   name => 'Master',

   read_config  => [ 'cds', { class => 'MasterRead', function => 'read_it' }],
   write_config => [ 'cds', { class => 'MasterRead', function => 'wr_stuff'}],

   read_config_dir  => $zdir,
   write_config_dir => $wr_dir,

   element => [
	       aa => { type => 'leaf',value_type => 'string'} ,
	       level1 => { type => 'node',
			   config_class_name => 'Level1',
			   init_step => [ 'bar X' => 'Av' ]
			 }
	      ]
   );

# global variable to snoop on read config action
my %result;

package MasterRead;

sub read_it {
    my %args = @_;
    $result{master_read} = $args{conf_dir};
    $args{object}->store_element_value('aa','aa was set');
}

sub wr_stuff {
    my %args = @_;
    $result{wr_stuff} = $args{conf_dir};
    $result{wr_root_name} = $args{object}->name ;
}

package Level1Read;

sub read_it {
    my %args = @_;
    $result{level1_read} = $args{conf_dir};
    $args{object}->load('bar X=Cv');
}

package main;

my $i_zero = $model->instance(instance_name    => 'zero_test',
			      root_class_name  => 'Master');

ok( $i_zero, "Created instance (from scratch)" );

# check that conf dir was read when instance was created
is( $result{master_read}, $zdir, "Master read conf dir" );

my $master = $i_zero->config_root;

ok( $master, "Master node created" );

is( $master->fetch_element_value('aa'), 'aa was set', 
    "Master legacy read" );

my $level1 = $master->fetch_element('level1');

ok( $level1, "Level1 created" );
is( $level1->grab_value('bar X'), 'Cv', "Level1 legacy read" );

is( $result{level1_read}, $zdir, "Level1 read conf dir" );

is( scalar @{ $i_zero->{write_back} }, 3, "write call back are stored" );

# perform write back of dodu tree dump string
$i_zero->write_back;

# check written files
map { ok( -e "$wr_dir/$_.cds", "file $_.cds" ); } 
  ('zero_test','zero_test/level1') ;

# check called write routine
is($result{wr_stuff},'wr_test','check write dir') ;
is($result{wr_root_name},'Master','check conf root to write') ;

my $dump = $master->dump_tree( );
print "Master dump:\n$dump\n" if $trace;

# create another instance
my $i_one = $model->instance(root_class_name  => 'Master',
			     instance_name => 'one_test' );

# access level1 to autoread it
my $root_2   = $i_one  -> config_root ;
my $level1_2 = $root_2 -> fetch_element('level1');

my $dump2 = $root_2->dump_tree( );
print "Read Master dump:\n$dump2\n" if $trace;

is( $dump, $dump2, "compare original and re-loaded instance" );
