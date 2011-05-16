# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 22 ;
use Config::Model ;
use Log::Log4perl qw(:easy :levels) ;
use File::Path ;
use File::Copy ;
use Test::Warn ;
use Test::Exception ;

use warnings;

use strict;

my $arg = shift || '';

my ($log,$show) = (0) x 2 ;
my $do ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;
$do                 = $1 if $arg =~ /(\d+)/;

my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;

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

my @tests = (
    { # t0
     check => { 
       'fs:/proc fs_spec',           "proc" ,
      'fs:/proc fs_file',           "/proc" ,
       'fs:/home fs_file',          "/home",
       'fs:/home fs_spec',          "UUID=18e71d5c-436a-4b88-aa16-308ebfa2eef8",
     },
     errors => [ 
            qr/value 2 > max limit 0/ => 'fs:"/var/chroot/lenny-i386/dev" fs_passno=0' ,
        ],
    },
    { #t1
     check => { 
                        'fs:root fs_spec',           "LABEL=root" ,
                        'fs:root fs_file',           "/" ,
              },
     },
);

my $idx = 0 ;
foreach my $t (@tests) {
    if (defined $do and $do ne $idx) { $idx ++; next; }
   
    my $wr_dir = $wr_root.'/test-'.$idx ;
    mkpath($wr_dir."/etc/", { mode => 0755 }) ;
    my $fstab_file = "$wr_dir/etc/fstab" ;

    my $ex_file = "t/fstab-examples/t$idx" ;
    copy($ex_file , $fstab_file) 
        || die "copy $ex_file -> $fstab_file failed:$!";
    ok(1,"Copied fstab example $idx") ;

    my $inst = $model->instance (root_class_name   => 'Fstab',
                                    root_dir          => $wr_dir,
                                    instance_name => "fstabtest".$idx,
                                   ); 

    my $root = $inst -> config_root ;
    warnings_like { $root->init;   } $t->{warnings} , 
        "Read $fstab_file and created instance" ;

    print "dumping tree ...\n" if $trace ;
    my $dump = '';
    my $risky = sub {$dump = $root->dump_tree (full_dump => 1); } ;
    
    if (defined $t->{errors} ) {
        my $nb = 0 ;
        my @tf = @{$t->{errors}} ;
        while (@tf) {
            my $qr = shift @tf ;
            throws_ok { &$risky }  $qr , "Failed dump $nb of copyright config tree" ;
            my $fix = shift @tf;
            $root->load($fix);
            ok(1, "Fixed error nb ".$nb++);
        }
        &$risky; 
    }
    else {
        &$risky ;
        ok($dump, "Dumped copyright config tree" ) ;
    }
    
    print $dump if $trace ;

    foreach my $path (sort keys %{$t->{check} || {}}) { 
       my $v = $t->{check}{$path} ;
       is($root->grab_value($path),$v,"check $path value");
    }
   
    $inst->write_back ;
    ok(1,"fstab write back done") ;

    # create another instance to read the IniFile that was just written
    my $wr_dir2 = $wr_dir.'-w' ;
    mkpath($wr_dir2.'/etc',{ mode => 0755 })   || die "can't mkpath: $!";
    copy($wr_dir.'/etc/fstab',$wr_dir2.'/etc') 
        or die "can't copy from $wr_dir to $wr_dir2: $!";

    my $i2_test = $model->instance(root_class_name   => 'Fstab',
                                   root_dir    => $wr_dir2 ,
                                   instance_name => "fstabtest".$idx."-w",
                                  );

    ok( $i2_test, "Created instance $idx-w" );

    my $i2_root = $i2_test->config_root ;

    my $p2_dump = $i2_root->dump_tree(full_dump => 1) ;

    is($p2_dump,$dump,"compare original data with 2nd instance data") ;
   
    #my $elt = $i2_root->grab("! License") ;
    #is($elt->defined('foobar'),0,"test defined method");

    # test backups, load a wrong value
    #$i2_root->load(step => qq!Files:foobar License abbrev="FOO or BAR"!, check => 'no');
    # then try to write backups
    #throws_ok {$i2_test->write_back} 'Config::Model::Exception::WrongValue',
    #    "check that write back is aborted with bad values" ;

    ok( -s $wr_dir2.'/etc/fstab',"check that original file was not clobbered");
   
    $idx++ ;
}

