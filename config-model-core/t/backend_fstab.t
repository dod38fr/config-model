# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 17 ;
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
$do                 = $1 if $arg =~ /(\d)/;

Log::Log4perl->easy_init($log ? $TRACE: $WARN);

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root';

# cleanup before tests
rmtree($wr_root);
mkpath($wr_root, { mode => 0755 }) ;

my @tests ;
my $i = 0;
$tests[$i]{text} = <<'EOD0' ;
# /etc/fstab: static file system information.
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
proc            /proc           proc    defaults        0       0
# /dev/sda2       /               ext3    errors=remount-ro 0       1
UUID=e255dac7-9cfb-42c8-ad1e-4dd1a8b962cb       /               ext3    errors=remount-ro 0       1
# /dev/sda4       /home           ext3    defaults        0       2
UUID=18e71d5c-436a-4b88-aa16-308ebfa2eef8       /home           ext3    defaults        0       2
# /dev/sda3       none            swap    sw              0       0
UUID=9988aeba-6937-4da3-8fd3-0fa696266137       none            swap    sw              0       0

gandalf:/home/  /mnt/gandalf-home nfs  user,noauto,rw    0    2
gandalf:/mnt/video/   /mnt/video  nfs  user,noauto,rw    0    2
gandalf:/mnt/video3/  /mnt/video3 nfs  user,noauto,rw    0    2
gandalf:/mnt/video4/  /mnt/video4 nfs  user,noauto,rw    0    2

/dev  /var/chroot/lenny-i386/dev  none bind 0 2
/home /var/chroot/lenny-i386/home none bind 0 2
/tmp  /var/chroot/lenny-i386/tmp  none bind 0 2
/proc /var/chroot/lenny-i386/proc none bind 0 2

EOD0

$tests[$i++]{check} 
   = [ 'fs:/proc fs_spec',           "proc" ,
       'fs:/proc fs_file',           "/proc" ,
       'fs:/home fs_file',          "/home",
       'fs:/home fs_spec',          "UUID=18e71d5c-436a-4b88-aa16-308ebfa2eef8",
     ];

$tests[$i]{text} = <<'EOD1' ;
# /etc/fstab: static file system information.
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
LABEL=root      /               ext3    defaults,relatime,errors=remount-ro 0 1
LABEL=home       /home           ext3    defaults,relatime        0       2
LABEL=video1       /mnt/video      ext3    defaults,relatime        0       2
LABEL=video2       /mnt/video2     ext3    defaults,relatime        0 2
LABEL=video3       /mnt/video3     ext3    defaults,relatime        0 2
LABEL=video4       /mnt/video4     ext3    defaults,relatime        0 2

proc            /proc           proc    defaults        0       0
# /dev/sdd2       none            swap    sw              0       0
UUID=5333e0e6-11d0-47a5-97af-44880a732e19  none swap sw 0 0

# 320GB usb disk (maxtor) 
LABEL=USB320 /mnt/usb-320gb ext3 rw,user,relatime,noauto 0 0

# 200GB Maxtor disk IEEE1394 through USB 
LABEL=Maxtor120 /mnt/maxtor120  ext3 rw,user,relatime,noauto 0 0

# 2To external disk (USB or e-sata)
LABEL=ext-2To /mnt/ext-2To ext4 rw,user,relatime,noauto 0 0

# sysfs entry for powernowd (and others)
#sysfs /sys sysfs defaults 0 0

# to enable usbmon
debugfs /sys/kernel/debug debugfs defaults 0 2
                                                                                                              
/dev  /var/chroot/testing-i386/dev  none bind 0 0                                                          
/home /var/chroot/testing-i386/home none bind 0 0                                                          
/proc /var/chroot/testing-i386/proc none bind 0 0                                                          
/tmp  /var/chroot/testing-i386/tmp  none bind 0 0

EOD1

$tests[$i++]{check} = [ 
                        'fs:root fs_spec',           "LABEL=root" ,
                        'fs:root fs_file',           "/" ,
                      ];


if (0) {

$tests[$i]{text} = <<'EOD2' ;

EOD2

$tests[$i++]{check} = [ 'License:MPL-1.1',"[MPL-1.1 LICENSE TEXT]" ,
                      'Files:"src/js/editline/*" License abbrev',"MPL-1.1",
                      'Files:"src/js/fdlibm/*" License abbrev',"MPL-1.1",
                    ];

# the empty license will default to 'other'
$tests[$i]{text} = <<'EOD3' ;

EOD3

$tests[$i++]{check} = [ 
                      'Files:"planet/vendor/compat_logging/*" License abbrev',"MIT",
                    ];

$tests[$i]{text} = <<'EOD4' ;

EOD4

$tests[$i++]{check} = [ 
                      'Files:"*" License abbrev',"GPL-2+",
                      'Files:"*" License exception',"OpenSSL",
                      'Files:"*" License full_license',
                      "This program is free software; you can redistribute it\n"
                      ." and/or modify it under the terms of the [snip]\n",
                   ];

$tests[$i]{text} = <<'EOD5' ;
EOD5

$tests[$i++]{check} = [ 
                      'Files:"*" License abbrev',"LGPL-2+",
                      'License:"LGPL-2+"',
                      "   [snip]either version 2.1 of\n   the License, or (at your option) any later version.\n"
                     ."   [snip again]",
                   ];
}

my $idx = 0 ;
foreach my $t (@tests) {
    if (defined $do and $do ne $idx) { $idx ++; next; }
   
    my $wr_dir = $wr_root.'/test-'.$idx ;
    mkpath($wr_dir."/etc/", { mode => 0755 }) ;
    my $fstab_file = "$wr_dir/etc/fstab" ;

    open(FILE,"> $fstab_file" ) || die "can't open $fstab_file: $!";
    print FILE $t->{text} ;
    close FILE ;

    my $warns = $idx == 5 ? [ ( qr/Upstream/ ) x 3 ] : []; 
    my $inst;
    warnings_like {
         $inst  = $model->instance (root_class_name   => 'Fstab',
                                    root_dir          => $wr_dir,
                                    instance_name => "fstabtest".$idx,
                                   ); 
     } $warns , "Read $fstab_file and created instance" ;

    my $root = $inst -> config_root ;

    my $dump =  $root->dump_tree ();
    print $dump if $trace ;
   
    while (@{$t->{check}}) { 
       my ($path,$v) = splice @{$t->{check}},0,2 ;
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

    my $p2_dump = $i2_root->dump_tree ;

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

