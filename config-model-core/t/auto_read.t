# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 56;
use Config::Model;
use File::Path;
use File::Copy ;
use Test::Warn ;
use Test::Exception ;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model -> new (legacy => 'ignore',) ;

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

ok(1,"compiled");


# pseudo root for config files 
my $wr_root = 'wr_root' ;
my $root1 = "$wr_root/test1/";
my $root2 = "$wr_root/test2/";
my $root3 = "$wr_root/test3/";

my $conf_dir  = '/etc/test/'; 

# cleanup before tests
rmtree($wr_root);

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
   read_config  => [ { backend => 'cds_file'}, 
		     { backend => 'custom', 
		       class => 'Level1Read', 
		       function => 'read_it' } ],
   write_config => [ { backend => 'cds_file', config_dir => $conf_dir},
		     { backend => 'perl_file', config_dir => $conf_dir,
		       auto_create => 1},
		     { backend => 'ini_file' , config_dir => $conf_dir}],

   read_config_dir  => $conf_dir,

   element => [
	       bar => { type => 'node',
			config_class_name => 'Level2',
		      } 
	      ]
   );

$model->create_config_class 
  (
   name => 'SameReadWriteSpec',

   # try first to read with cds string and then custom class
   read_config  => [ { backend => 'cds_file', config_dir => $conf_dir }, 
		     { backend => 'custom', class => 'SameRWSpec', config_dir => $conf_dir },
		     { backend => 'ini_file', config_dir => $conf_dir,
		       auto_create => 1} 
		   ],

   element => [
	       bar => { type => 'node',
			config_class_name => 'Level2',
		      } 
	      ]
   );


$model->create_config_class 
  (
   name => 'Master',

   read_config  => [ { backend => 'cds_file', config_dir => $conf_dir},
		     { backend => 'perl_file', config_dir => $conf_dir},
		     { backend => 'ini_file', config_dir => $conf_dir } ,
		     { backend => 'custom', class => 'MasterRead', 
		       config_dir => $conf_dir, function => 'read_it' }
		   ],
   write_config => [ { backend => 'cds_file', config_dir => $conf_dir},
		     { backend => 'perl_file', config_dir => $conf_dir},
		     { backend => 'ini_file', config_dir => $conf_dir } ,
		     { class => 'MasterRead', function => 'wr_stuff', 
		       config_dir => $conf_dir, auto_create => 1}
		   ],

   element => [
	       aa => { type => 'leaf',value_type => 'string'} ,
	       level1 => { type => 'node',
			   config_class_name => 'Level1',
			 },
	       samerw => { type => 'node',
			   config_class_name => 'SameReadWriteSpec',
			 },
	      ]
   );

$model->create_config_class 
  (
   name => 'FromScratch',

   read_config  => [ { backend => 'cds_file', config_dir => $conf_dir,
		       auto_create => 1},
		   ],

   element => [
	       aa => { type => 'leaf',value_type => 'string'} ,
	      ]
   );

$model->create_config_class 
  (
   name => 'CdsWithFile',

   read_config  => [ { backend => 'cds_file', config_dir => $conf_dir,
		       file => 'scratch_inst.cds'},
		   ],

   element => [
	       aa => { type => 'leaf',value_type => 'string'} ,
	      ]
   );

$model->create_config_class 
  (
   name => 'SimpleRW',

   read_config  => [ { backend => 'custom', config_dir => $conf_dir,
		       class => 'SimpleRW',
		       file => 'toto.conf'
		     },
		   ],

   element => [
	       aa => { type => 'leaf',value_type => 'string'} ,
	      ]
   );

#global variable to snoop on read config action
my %result;

package MasterRead;

my $custom_aa = 'aa was set (custom mode)' ;

sub read_it {
    my %args = @_;
    $result{master_read} = $args{config_dir};
    $args{object}->store_element_value('aa', $custom_aa);
}

sub wr_stuff {
    my %args = @_;
    $result{wr_stuff} = $args{config_dir};
    $result{wr_root_name} = $args{object}->name ;
}

package Level1Read;

sub read_it {
    my %args = @_;
    $result{level1_read} = $args{config_dir};
    $args{object}->load('bar X=Cv');
}

package SameRWSpec;

sub read {
    my %args = @_;
    $result{same_rw_read} = $args{config_dir};
    $args{object}->load('bar Y=Cv');
}

sub write {
    my %args = @_;
    $result{same_rw_write} = $args{config_dir};
}

package SimpleRW ;

sub read {
    my %args = @_;
    $result{simple_rw}{rfile} = $args{file_path};
    my $io = $args{io_handle} ;
    return 0 unless defined $io ;
    $args{object}->load($io->getlines);
    return 1 ;
}

sub write {
    my %args = @_;
    $result{simple_rw}{wfile} = $args{file_path};

    my $io = $args{io_handle} ;
    return 0 unless defined $io ;
    my $dump = $args{object}->dump_tree() ;
    $io->print($dump);
}



package main;

throws_ok {
    my $i_fail = $model->instance(instance_name    => 'zero_inst',
			       root_class_name  => 'Master',
			       root_dir   => $root1 ,
			       backend => 'perl_file',
			      );
    } qr/'perl_file' backend/,  "read with forced perl_file backend fails (normal: no perl file)"  ;

my $i_no_read = $model->instance(instance_name    => 'no_read_inst',
				 root_class_name  => 'Master',
				 root_dir   => $root1 ,
				 skip_read => 1,
				);
ok( $i_no_read, "Created instance (from scratch without read)-> no warning" );

# check that conf dir was NOT read when instance was created
is( $result{master_read}, undef, "Master read conf dir" );

my $i_zero = $model->instance(instance_name    => 'zero_inst',
			      root_class_name  => 'Master',
			      root_dir   => $root1 ,
			     );

ok( $i_zero, "Created instance (from scratch)" );

# check that conf dir was read when instance was created
is( $result{master_read}, $conf_dir, "Master read conf dir" );

my $master = $i_zero->config_root;

ok( $master, "Master node created" );

is( $master->fetch_element_value('aa'), $custom_aa, "Master custom read" );

my $level1;

warnings_like {
    $level1 = $master->fetch_element('level1');
} qr/read_config_dir is obsolete/ , "obsolete warning" ;

ok( $level1, "Level1 object created" );

is( $level1->grab_value('bar X'), 'Cv', "Check level1 custom read" );

is( $result{level1_read} , $conf_dir, "check level1 custom read conf dir" );

my $same_rw = $master->fetch_element('samerw');

ok( $same_rw, "SameRWSpec object created" );
is( $same_rw->grab_value('bar Y'), 'Cv', "Check samerw custom read" );

is( $result{same_rw_read}, $conf_dir, "check same_rw_spec custom read conf dir" );

is( scalar @{ $i_zero->{write_back} }, 10, 
    "check that write call back are present" );

# perform write back of dodu tree dump string
$i_zero->write_back(backend => 'all');

# check written files
foreach my $suffix (qw/cds ini/) {
    map { 
	my $f = "$root1$conf_dir/$_.$suffix" ;
	ok( -e $f, "check written file $f" ); 
    } 
      ('zero_inst','zero_inst/level1','zero_inst/samerw') ;
}

foreach my $suffix (qw/pl/) {
    map { 
	my $f = "$root1$conf_dir/$_.$suffix" ;
	ok( -e "$f", "check written file $f" );
    } 
      ('zero_inst','zero_inst/level1') ;
}

# check called write routine
is($result{wr_stuff},$conf_dir,'check custom write dir') ;
is($result{wr_root_name},'Master','check custom conf root to write') ;

# perform write back of dodu tree dump string in an overridden dir
my $override = 'etc/wr_2/';
$i_zero->write_back(backend => 'all', config_dir => $override);

# check written files
foreach my $suffix (qw/cds ini/) {
    map { ok( -e "$root1$override$_.$suffix", 
	      "check written file $root1$override$_.$suffix" ); } 
      ('zero_inst','zero_inst/level1','zero_inst/samerw' ) ;
}
foreach my $suffix (qw/pl/) {
    map { ok( -e "$root1$override$_.$suffix", 
	      "check written file $root1$override$_.$suffix" ); } 
      ('zero_inst','zero_inst/level1') ;
}

is($result{wr_stuff},$override,'check custom overridden write dir') ;

my $dump = $master->dump_tree( skip_auto_write => 'cds_file' );
print "Master dump:\n$dump\n" if $trace;

is($dump,qq!aa="$custom_aa" -\n!,"check master dump") ;

$dump = $level1->dump_tree( skip_auto_write => 'cds_file' );
print "Level1 dump:\n$dump\n" if $trace;
is($dump,qq!  bar\n    X=Cv - -\n!,"check level1 dump") ;


my $inst2 = 'second_inst' ;

my %cds = (
    $inst2 => 'aa="aa was set by file" - ',
    "$inst2/level1"   => 'bar X=Av Y=Bv - '
);

my $dir2 = "$root2/etc/test/" ;
mkpath($dir2.$inst2,0,0755) || die "Can't mkpath $dir2.$inst2:$!";

# write input config files
foreach my $f ( keys %cds ) {
    my $fout = "$dir2/$f.cds";
    next if -r $fout;

    open( FOUT, ">$fout" ) or die "can't open $fout:$!";
    print FOUT $cds{$f};
    close FOUT;
}

# create another instance
my $test2_inst = $model->instance(root_class_name  => 'Master',
				   instance_name    => $inst2 ,
				   root_dir         => $root2 ,);

ok($test2_inst,"created second instance") ;

# access level1 to autoread it
my $root_2   = $test2_inst  -> config_root ;

my $level1_2;
warnings_like {
    $level1_2 = $root_2 -> fetch_element('level1');
} qr/read_config_dir is obsolete/ , "obsolete warning" ;


is($root_2->grab_value('aa'),'aa was set by file',"$inst2: check that cds file was read") ;

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
is( $dump2, $expect2, "$inst2: check dump" );

# test loading with ini files
map { my $o = $_; s!$root1/zero!ini!; 
      copy($o,"$root2/$_") or die "can't copy $o $_:$!" } 
  glob("$root1/*.ini") ;

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

warnings_like {
    $dump = $ini_inst ->config_root->dump_tree ;
} qr/read_config_dir is obsolete/ , "obsolete warning" ;

is( $dump, $expect_custom, "ini_test: check dump" );


unlink(glob("$root2/*.ini")) ;

# test loading with pl files
map { my $o = $_; s!$root1/zero!pl!; 
      copy($o,"$root2/$_") or die "can't copy $o $_:$!" 
  } glob("$root1/*.pl") ;

# create another instance to load pl files
my $pl_inst = $model->instance(root_class_name  => 'Master',
				instance_name => 'pl_inst' );

ok($pl_inst,"Created instance to load pl files") ;

warnings_like {
    $dump = $pl_inst ->config_root->dump_tree ;
} qr/read_config_dir is obsolete/ , "obsolete warning" ;

is( $dump, $expect_custom, "pl_test: check dump" );

#create from scratch instance
my $scratch_i = $model->instance(root_class_name  => 'FromScratch',
				 instance_name => 'scratch_inst',
				 root_dir => $root3 ,
				);

ok($scratch_i,"Created instance from scratch to load cds files") ;

$scratch_i->config_root->load("aa=toto") ;
$scratch_i -> write_back ;
ok ( -e "$root3/$conf_dir/scratch_inst.cds", "wrote cds config file") ;

# create model for simple RW class

my $cdswf = $model->instance(root_class_name  => 'CdsWithFile',
			     instance_name => 'cds_with_file_inst',
			     root_dir => $root3 ,
			    );
ok($cdswf,"Created instance to load custom cds file") ;

$cdswf->config_root->load("aa=toto2") ;
my $expect = 'aa=toto2 -
' ;
is($cdswf->config_root->dump_tree, $expect, "check dump" );

$cdswf -> write_back ;

my $toto_conf  = "$root3/$conf_dir/toto.conf" ;
copy("$root3/$conf_dir/scratch_inst.cds", $toto_conf)
  or die "can't copy scratch_inst.cds to toto.conf:$!" ;

my $ctoto = $model->instance(root_class_name  => 'SimpleRW',
			     instance_name => 'custom_toto',
			     root_dir => $root3 ,
			    );
ok($ctoto,"Created instance to load custom custom toto file") ;

is($ctoto->config_root->dump_tree, $expect, "check dump" );
$ctoto->config_root->load("aa=toto3") ;



$ctoto -> write_back ;

map {is($result{simple_rw}{$_},'wr_root/test3//etc/test/toto.conf',
	"Check Simple_Rw cb file argument ($_)")} 
  qw/rfile wfile/ ;

open(TOTO,$toto_conf) || die "Can't open $toto_conf:$!" ;
my @totolines= <TOTO> ;
close TOTO;

is_deeply(\@totolines,["aa=toto3 -\n"],"checked file written by simpleRW") ;


