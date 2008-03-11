# -*- cperl -*-
# $Author$
# $Date$
# $Revision$

use ExtUtils::testlib;
use Test::More tests => 32;
use Config::Model;
use File::Path;
use File::Copy ;

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


# directory where config files are written by config-model
my $wr_dir = 'wr_test';

# cleanup before tests
rmtree($wr_dir);
rmtree($zdir);

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
   write_config => ['cds', 'perl', 'ini' ],

   read_config_dir  => $zdir,
   write_config_dir => $wr_dir,

   element => [
	       bar => { type => 'node',
			config_class_name => 'Level2',
		      } 
	      ]
   );


$model->create_config_class 
  (
   name => 'Master',

   read_config  => [ 'cds', 'perl', 'ini' ,{ class => 'MasterRead', function => 'read_it' }],
   write_config => [ 'cds', 'perl', 'ini' ,{ class => 'MasterRead', function => 'wr_stuff'}],

   read_config_dir  => $zdir,
   write_config_dir => $wr_dir,

   element => [
	       aa => { type => 'leaf',value_type => 'string'} ,
	       level1 => { type => 'node',
			   config_class_name => 'Level1',
			 }
	      ]
   );

# global variable to snoop on read config action
my %result;

package MasterRead;

my $custom_aa = 'aa was set (custom mode)' ;

sub read_it {
    my %args = @_;
    $result{master_read} = $args{conf_dir};
    $args{object}->store_element_value('aa', $custom_aa);
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

my $i_zero = $model->instance(instance_name    => 'zero_inst',
			      root_class_name  => 'Master');

ok( $i_zero, "Created instance (from scratch)" );

# check that conf dir was read when instance was created
is( $result{master_read}, $zdir, "Master read conf dir" );

my $master = $i_zero->config_root;

ok( $master, "Master node created" );

is( $master->fetch_element_value('aa'), $custom_aa, "Master custom read" );

my $level1 = $master->fetch_element('level1');

ok( $level1, "Level1 object created" );
is( $level1->grab_value('bar X'), 'Cv', "Check level1 custom read" );

is( $result{level1_read}, $zdir, "check level1 custom read conf dir" );

is( scalar @{ $i_zero->{write_back} }, 7, "check that write call back are present" );

# perform write back of dodu tree dump string
$i_zero->write_back;

# check written cds files
foreach my $suffix (qw/cds ini pl/) {
    map { ok( -e "$wr_dir/$_.$suffix", "check written file $_.$suffix" ); } 
      ('zero_inst','zero_inst:level1') ;
}

# check called write routine
is($result{wr_stuff},'wr_test','check custom write dir') ;
is($result{wr_root_name},'Master','check custom conf root to write') ;

# perform write back of dodu tree dump string in an overridden dir
$i_zero->write_back("$wr_dir/$wr_dir");

# check written cds files
foreach my $suffix (qw/cds ini pl/) {
    map { ok( -e "$wr_dir/$wr_dir/$_.$suffix", "check written file $wr_dir/$_.$suffix" ); } 
      ('zero_inst','zero_inst:level1') ;
}

is($result{wr_stuff},'wr_test/wr_test','check custom overridden write dir') ;

my $dump = $master->dump_tree( skip_auto_write => 1 );
print "Master dump:\n$dump\n" if $trace;

is($dump,qq!aa="$custom_aa" -\n!,"check master dump") ;

$dump = $level1->dump_tree( skip_auto_write => 1 );
print "Level1 dump:\n$dump\n" if $trace;
is($dump,qq!  bar\n    X=Cv - -\n!,"check level1 dump") ;


# setup input config file dir that will be used in 2nd part of test
mkdir( $zdir, 0755 ) unless -d $zdir;

my %cds = (
    test2 => 'aa="aa was set by file" - ',
    'test2:level1'   => 'bar X=Av Y=Bv - '
);

# write input config files
foreach my $f ( keys %cds ) {
    my $fout = "$zdir/$f.cds";
    next if -r $fout;

    open( FOUT, ">$fout" ) or die "can't open $fout:$!";
    print FOUT $cds{$f};
    close FOUT;
}

# create another instance
my $test2_inst = $model->instance(root_class_name  => 'Master',
			     instance_name => 'test2' );

# access level1 to autoread it
my $root_2   = $test2_inst  -> config_root ;
my $level1_2 = $root_2 -> fetch_element('level1');

is($root_2->grab_value('aa'),'aa was set by file',"test2: check that cds file was read") ;

my $dump2 = $root_2->dump_tree( );
print "Read Master dump:\n$dump2\n" if $trace;

my $expect2 = 'aa="aa was set by file"
level1
  bar
    X=Av
    Y=Bv - - -
' ;
is( $dump2, $expect2, "test2: check dump" );

# test loading with ini files
map { my $o = $_; s!$wr_dir/zero!ini!; 
      copy($o,"$zdir/$_") or die "can't copy $o $_:$!" } 
  glob("$wr_dir/*.ini") ;

# create another instance to load ini files
my $ini_inst = $model->instance(root_class_name  => 'Master',
				instance_name => 'ini_inst' );
ok($ini_inst,"Created instance to load ini files") ;

my $expect_custom = 'aa="aa was set (custom mode)"
level1
  bar
    X=Cv - - -
' ;

$dump = $ini_inst ->config_root->dump_tree ;
is( $dump, $expect_custom, "ini_test: check dump" );


unlink(glob("$zdir/*.ini")) ;

# test loading with pl files
map { my $o = $_; s!$wr_dir/zero!pl!; 
      copy($o,"$zdir/$_") or die "can't copy $o $_:$!" 
  } glob("$wr_dir/*.pl") ;

# create another instance to load pl files
my $pl_inst = $model->instance(root_class_name  => 'Master',
				instance_name => 'pl_inst' );
ok($pl_inst,"Created instance to load pl files") ;

$dump = $pl_inst ->config_root->dump_tree ;
is( $dump, $expect_custom, "pl_test: check dump" );
