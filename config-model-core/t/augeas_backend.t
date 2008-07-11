# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-07-04 16:14:06 +0200 (Fri, 04 Jul 2008) $
# $Revision: 707 $

# test augeas backend if Config::Augeas is installed

use ExtUtils::testlib;
use Test::More tests => 35;
use Config::Model;
use File::Path;
use File::Copy ;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model -> new (legacy => 'ignore',) ;

my $trace = shift || 0;
$::verbose          = 1 if $trace =~ /v/;
$::debug            = 1 if $trace =~ /d/;
Config::Model::Exception::Any->Trace(1) if $trace =~ /e/;

ok(1,"compiled");

# pseudo root were input config file are read
my $r_root = 'augeas-box/';

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root/';

# cleanup before tests
rmtree($wr_root);

$model->create_config_class 
  (
   name => 'Host',

   element => [
	       [qw/ipaddr canonical alias/] 
	       => { type => 'leaf',
		    value_type => 'uniline',
		  } 
	      ]
   );


$model->create_config_class 
  (
   name => 'Hosts',

   read_config  => [ { backend => 'augeas', 
		       config_file => '/etc/hosts',
		       set_in => 'top',
		     },
		   ],

   element => [
	       top => { type => 'list',
			cargo => { type => 'node',
				   config_class_name => 'Host',
				 } ,
		      },
	      ]
   );


my $i_hosts = $model->instance(instance_name    => 'hosts_inst',
			       root_class_name  => 'Hosts',
			       write_root_dir   => $wr_root ,
			       read_root_dir    => $r_root ,
			      );

ok( $i_hosts, "Created instance (from scratch)" );

__END__

# check that conf dir was read when instance was created
is( $result{master_read}, $r_dir, "Master read conf dir" );

my $master = $i_hosts->config_root;

ok( $master, "Master node created" );

is( $master->fetch_element_value('aa'), $custom_aa, "Master custom read" );

my $level1 = $master->fetch_element('level1');

ok( $level1, "Level1 object created" );
is( $level1->grab_value('bar X'), 'Cv', "Check level1 custom read" );

is( $result{level1_read} , $r_dir, "check level1 custom read conf dir" );

my $same_rw = $master->fetch_element('samerw');

ok( $same_rw, "SameRWSpec object created" );
is( $same_rw->grab_value('bar Y'), 'Cv', "Check samerw custom read" );

is( $result{same_rw_read}, $r_dir, "check same_rw_spec custom read conf dir" );

is( scalar @{ $i_hosts->{write_back} }, 10, 
    "check that write call back are present" );

# perform write back of dodu tree dump string
$i_hosts->write_back;

# check written files
foreach my $suffix (qw/cds ini/) {
    map { 
	my $f = "$wr_root$w_dir/$_.$suffix" ;
	ok( -e $f, "check written file $f" ); 
    } 
      ('zero_inst','zero_inst/level1','zero_inst/samerw') ;
}

foreach my $suffix (qw/pl/) {
    map { 
	my $f = "$wr_root$w_dir/$_.$suffix" ;
	ok( -e "$f", "check written file $f" );
    } 
      ('zero_inst','zero_inst/level1') ;
}

__END__ 

# check called write routine
is($result{wr_stuff},$wr_root,'check custom write dir') ;
is($result{wr_root_name},'Master','check custom conf root to write') ;

# perform write back of dodu tree dump string in an overridden dir
$i_hosts->write_back($wr_root.'wr_2');

# check written files
foreach my $suffix (qw/cds ini/) {
    map { ok( -e $wr_root."wr_2/$_.$suffix", 
	      "check written file $ {wr_dir}wr_2/$_.$suffix" ); } 
      ('zero_inst','zero_inst/level1','zero_inst/samerw' ) ;
}
foreach my $suffix (qw/pl/) {
    map { ok( -e $wr_root."wr_2/$_.$suffix", 
	      "check written file $ {wr_dir}wr_2/$_.$suffix" ); } 
      ('zero_inst','zero_inst/level1') ;
}

is($result{wr_stuff},'wr_test/wr_2/','check custom overridden write dir') ;

my $dump = $master->dump_tree( skip_auto_write => 'cds_file' );
print "Master dump:\n$dump\n" if $trace;

is($dump,qq!aa="$custom_aa" -\n!,"check master dump") ;

$dump = $level1->dump_tree( skip_auto_write => 'cds_file' );
print "Level1 dump:\n$dump\n" if $trace;
is($dump,qq!  bar\n    X=Cv - -\n!,"check level1 dump") ;


# setup input config file dir that will be used in 2nd part of test
mkdir( $r_root, 0755 ) unless -d $r_root;

my %cds = (
    test2 => 'aa="aa was set by file" - ',
    'test2/level1'   => 'bar X=Av Y=Bv - '
);

mkpath("$r_root/test2",0,0755) || die "Can't mkpath $r_root/test2:$!";

# write input config files
foreach my $f ( keys %cds ) {
    my $fout = "$r_root/$f.cds";
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
    Y=Bv - -
samerw
  bar
    Y=Cv - - -
' ;
is( $dump2, $expect2, "test2: check dump" );

# test loading with ini files
map { my $o = $_; s!$wr_root/zero!ini!; 
      copy($o,"$r_root/$_") or die "can't copy $o $_:$!" } 
  glob("$wr_root/*.ini") ;

# create another instance to load ini files
my $ini_inst = $model->instance(root_class_name  => 'Master',
				instance_name => 'ini_inst' );
ok($ini_inst,"Created instance to load ini files") ;

my $expect_custom = 'aa="aa was set (custom mode)"
level1
  bar
    X=Cv - -
samerw
  bar
    Y=Cv - - -
' ;

$dump = $ini_inst ->config_root->dump_tree ;
is( $dump, $expect_custom, "ini_test: check dump" );


unlink(glob("$r_root/*.ini")) ;

# test loading with pl files
map { my $o = $_; s!$wr_root/zero!pl!; 
      copy($o,"$r_root/$_") or die "can't copy $o $_:$!" 
  } glob("$wr_root/*.pl") ;

# create another instance to load pl files
my $pl_inst = $model->instance(root_class_name  => 'Master',
				instance_name => 'pl_inst' );
ok($pl_inst,"Created instance to load pl files") ;

$dump = $pl_inst ->config_root->dump_tree ;
is( $dump, $expect_custom, "pl_test: check dump" );
