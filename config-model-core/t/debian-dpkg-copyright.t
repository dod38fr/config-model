# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Config::Model ;
use Log::Log4perl qw(:easy) ;
use File::Path ;
use File::Copy ;
use Test::Warn ;
use Test::Exception ;

use warnings;

use strict;

if ( -r '/etc/debian_version' ) {
    plan tests => 163;
}
else {
    plan skip_all => "Not a Debian system";
}

my $arg = shift ;
$arg = '' unless defined $arg ;

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
        warnings => [ (qr/deprecated/) x 3, qr/Missing/ ],

        check => {
            'Files:"*" License full_license' => "[PSF LICENSE TEXT]",
            'Files:"*" Copyright:0' => "2008, John Doe <john.doe\@example.com>",
            'Files:"*" Copyright:1' =>
              "2007, Jane Smith <jane.smith\@example.com>",
            'Files:"*" License short_name' => "PsF",
            '"Xtest"'                     => "yada yada\n\nyada",
            '"Upstream-Name"'              => "xyz",
            '"Upstream-Contact:0"' => "Jane Smith <jane.smith\@example.com>",
        },
    },

    { #t1
        warnings => [ (qr/deprecated/) x 3 ],

        check => {
            'License:MPL-1.1'     => "[MPL-1.1 LICENSE TEXT]",
            'License:"GPL-2+"'    => "[GPL-2 LICENSE TEXT]",
            'License:"LGPL-2.1+"' => "[LGPL-2.1 plus LICENSE TEXT]",
            'Files:"src/js/editline/*" License short_name' =>
              "MPL-1.1 or GPL-2+ or LGPL-2.1+"
        },

    },
    { # t2
        warnings => [ (qr/deprecated/) x 1 ],

        check => {
            'License:MPL-1.1' => "[MPL-1.1 LICENSE TEXT]",
            'Files:"src/js/editline/*" License short_name' => "MPL-1.1",
            'Files:"src/js/fdlibm/*" License short_name'   => "MPL-1.1",
        },
    },

    # the empty license will default to 'other'
    { # t3
        warnings => [ (qr/deprecated/) x 3 ],

        check => {
            'Comment' => "\nHeader comment 1/2\nHeader comment 2/2",
            'Files:"*" Comment' => "\n Files * comment 1/2\nFiles * comment 2/2",
            'Files:"planet/vendor/compat_logging/*" Comment' 
                => "\nFiles logging * comment 1/2\n Files logging * comment 2/2",
            'Files:"planet/vendor/compat_logging/*" License short_name' => "MIT",
        },
    },
    { # t4
        warnings => [ (qr/deprecated/) x 1 ],

        check => {
            'Source'                       => "http:/some.where.com",
            'Files:"*" License short_name' => "GPL-2+",
            'Files:"*" License exception'  => "OpenSSL",
            'Files:"*" License full_license' =>
              "This program is free software; you can redistribute it\n"
              . " and/or modify it under the terms of the [snip]",
        },
    },
    { #t5

        warnings => [ (qr/deprecated/) x 3 ],
        check => {
            'Files:"*" License short_name' => "LGPL-2+",
            'Source' => 'http://search.cpan.org/dist/Config-Model-CursesUI/',
            'License:"LGPL-2+"' =>
"   [snip]either version 2.1 of\n   the License, or (at your option) any later version.\n"
              . "   [snip again]",
        },
    },
    { # t6

        warnings => [ (qr/deprecated/) x 3 ],

        check => {
            'Upstream-Contact:0' => 'Ignace Mouzannar <mouzannar at gmail.com>',
            'Files:"Embedded_Display/remoteview.cpp Embedded_Display/remoteview.h" License short_name'
              => "GPL-2",
        },
    },
    { # t7
        # example from CANDIDATE DEP-5 spec (nb 7)
        warnings => [ (qr/Adding/) x 1 ],
        check => { 
            Format => "http://dep.debian.net/deps/dep5/", 
            'Files:"*" Copyright:0' => 'Copyright 1998 John Doe <jdoe@example.com>',
            'Files:"debian/*" License short_name' => 'other',
            },
    },
    {
        # test nb 8
        check => { 
            Format => "http://dep.debian.net/deps/dep5/", 
            'Files:"*" Copyright:0' => '2008, John Doe <jdoe@example.com>',
            'Files:"*" Copyright:1' =>          '2007, Jane Smith <jsmith@example.org>',
            'Files:"*" Copyright:2' =>          '2007, Joe Average <joe@example.org>',
            'Files:"*" Copyright:3' =>          '2007, J. Random User <jr@users.example.com>',
            },
        },
    {
        check => {
            'Files:"*" Copyright:0' => 'foo',
            'Files:"*" License short_name' => 'BSD',
            'Files:"*" License full_license' => ' foo bar',
        },
    },
    { # t10
        warnings => [ (qr/deprecated/) x 2 ],

        check => { 
            Format => "http://dep.debian.net/deps/dep5/", 
            # something's wrong with utf8 string checks
            #'Debianized-By' => 'Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>',
            Source => 'http://tango-controls.org/download',
            #'Files:"*" Copyright:0' => '© 2010, The Tango team <tango@esrf.fr>',
            'Files:"debian/*" License short_name' => 'GPL-3+',
        },
    },

    { # t11 Debian bug #610231
        errors =>  [ 
            qr/mandatory/ => 'Files:"*" Copyright:0="(c) foobar"',
            qr/mandatory/ => ' License:FOO="foo bar" ! Files:"*" License short_name="FOO" '
        ],
    },
    
    { # t12
        warnings => [ (qr/deprecated/) x 3, qr/Adding/ ],
        load_check => 'no',
        errors =>  [ 
            qr/not declared/ => 'License:Expat="Expat license foobar"',
        ],
   }
);

my $idx = 0 ;
foreach my $t (@tests) {
    if (defined $do and $do ne $idx) { $idx ++; next; }
   
    my $wr_dir = $wr_root.'/test-'.$idx ;
    mkpath($wr_dir."/debian/", { mode => 0755 }) ;
    my $license_file = "$wr_dir/debian/copyright" ;

    my $ex_file = "t/copyright-examples/t$idx" ;
    copy($ex_file , $license_file) 
        || die "copy $ex_file -> $license_file failed:$!";
    ok(1,"Copied copyright example $idx") ;

    my $inst = $model->instance(
        root_class_name => 'Debian::Dpkg::Copyright',
        root_dir        => $wr_dir,
        instance_name   => "deptest" . $idx,
        check           => $t->{load_check} || 'yes',
    );

    my $lic = $inst -> config_root ;
    warnings_like { $lic->init;   } $t->{warnings} , 
        "Read $license_file and created instance" ;


    print "dumping tree ...\n" if $trace ;
    my $dump = '';
    my $risky = sub {$dump = $lic->dump_tree (full_dump => 1); } ;
    
    if (defined $t->{errors} ) {
        my $nb = 0 ;
        my @tf = @{$t->{errors}} ;
        while (@tf) {
            my $qr = shift @tf ;
            throws_ok { &$risky }  $qr , "Failed dump $nb of copyright config tree" ;
            my $fix = shift @tf;
            $lic->load($fix);
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
       is($lic->grab_value($path),$v,"check $path value");
    }
   
    $inst->write_back ;
    ok(1,"Dep-5 write back done") ;

    # create another instance to read the IniFile that was just written
    my $wr_dir2 = $wr_dir.'-w' ;
    mkpath($wr_dir2.'/debian',{ mode => 0755 })   || die "can't mkpath: $!";
    copy($wr_dir.'/debian/copyright',$wr_dir2.'/debian/') 
        or die "can't copy from $wr_dir to $wr_dir2: $!";

    my $i2_test = $model->instance(root_class_name   => 'Debian::Dpkg::Copyright',
                                   root_dir    => $wr_dir2 ,
                                   instance_name => "deptest".$idx."-w",
                                  );

    ok( $i2_test, "Created instance $idx-w" );

    my $i2_root = $i2_test->config_root ;

    my $p2_dump = $i2_root->dump_tree(full_dump => 1) ;

    is($p2_dump,$dump,"compare original data with 2nd instance data") ;
   
    my $elt = $i2_root->grab("! License") ;
    is($elt->defined('foobar'),0,"test defined method");

    # test backups, load a wrong value
    $i2_root->load(step => qq!Files:foobar License short_name="FOO or BAR"!, check => 'no');
    # then try to write backups
    throws_ok {$i2_test->write_back} 'Config::Model::Exception::WrongValue',
        "check that write back is aborted with bad values" ;

    ok( -s $wr_dir2.'/debian/copyright',"check that original file was not clobbered");
   
    $idx++ ;
}



