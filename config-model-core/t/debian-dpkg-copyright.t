# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 99 ;
use Config::Model ;
use Log::Log4perl qw(:easy) ;
use File::Path ;
use File::Copy ;
use Test::Warn ;
use Test::Exception ;

use warnings;

use strict;

my $arg = shift ;
$arg = '' unless defined $arg ;

my ($log,$show) = (0) x 2 ;
my $do ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;
$do                 = $1 if $arg =~ /(\d+)/;

Log::Log4perl->easy_init($log ? $TRACE: $WARN);

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root';

# cleanup before tests
rmtree($wr_root);
mkpath($wr_root, { mode => 0755 }) ;

my @tests = (
    {
        warnings => [ (qr/deprecated/) x 3, qr/Missing/ ],

        check => {
            'Files:"*" License full_license' => "[PSF LICENSE TEXT]\n",
            'Files:"*" Copyright:0' => "2008, John Doe <john.doe\@example.com>",
            'Files:"*" Copyright:1' =>
              "2007, Jane Smith <jane.smith\@example.com>",
            'Files:"*" License short_name' => "PsF",
            '"X-test"'                     => "yada yada\n\nyada",
            '"Upstream-Name"'              => "xyz",
            '"Upstream-Contact"' => "Jane Smith <jane.smith\@example.com>",
        },
    },

    {
        warnings => [ (qr/deprecated/) x 3 ],

        check => {
            'License:MPL-1.1'     => "[MPL-1.1 LICENSE TEXT]",
            'License:"GPL-2+"'    => "[GPL-2 LICENSE TEXT]",
            'License:"LGPL-2.1+"' => "[LGPL-2.1 plus LICENSE TEXT]",
            'Files:"src/js/editline/*" License short_name' =>
              "MPL-1.1 or GPL-2+ or LGPL-2.1+"
        },

    },
    {
        warnings => [ (qr/deprecated/) x 1 ],

        check => {
            'License:MPL-1.1' => "[MPL-1.1 LICENSE TEXT]",
            'Files:"src/js/editline/*" License short_name' => "MPL-1.1",
            'Files:"src/js/fdlibm/*" License short_name'   => "MPL-1.1",
        },
    },

    # the empty license will default to 'other'
    {
        warnings => [ (qr/deprecated/) x 3 ],

        check => {
            'Files:"planet/vendor/compat_logging/*" License short_name' =>
              "MIT",
        },
    },
    {
        warnings => [ (qr/deprecated/) x 1 ],

        check => {
            'Source'                       => "http:/some.where.com",
            'Files:"*" License short_name' => "GPL-2+",
            'Files:"*" License exception'  => "OpenSSL",
            'Files:"*" License full_license' =>
              "This program is free software; you can redistribute it\n"
              . " and/or modify it under the terms of the [snip]\n",
        },
    },
    {

        warnings => [ (qr/deprecated/) x 3 ],
        check => {
            'Files:"*" License short_name' => "LGPL-2+",
            'Source' => 'http://search.cpan.org/dist/Config-Model-CursesUI/',
            'License:"LGPL-2+"' =>
"   [snip]either version 2.1 of\n   the License, or (at your option) any later version.\n"
              . "   [snip again]",
        },
    },
    {

        warnings => [ (qr/deprecated/) x 3 ],

        check => {
            'Upstream-Contact' => 'Ignace Mouzannar <mouzannar at gmail.com>',
'Files:"Embedded_Display/remoteview.cpp Embedded_Display/remoteview.h" License short_name'
              => "GPL-2",
        },
    },
    {
        # example from CANDIDATE DEP-5 spec (nb 7)
        warnings => [ (qr/Adding/) x 1 ],
        check => { Format => "http://dep.debian.net/deps/dep5/", },
    },
    {
        # test nb 8
        check => { Format => "http://dep.debian.net/deps/dep5/", },
    },
    {},
    {}

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

    my $inst;
    warnings_like {
         $inst  = $model->instance (root_class_name   => 'Debian::Dpkg::Copyright',
                                    root_dir          => $wr_dir,
                                    instance_name => "deptest".$idx,
                                    force_load => 1 ,
                                   ); 
     } $t->{warnings} , "Read $license_file and created instance" ;

    my $lic = $inst -> config_root ;

    my $dump =  $lic->dump_tree (full_dump => 1);
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
   
    # test license warnings
    warning_like { $i2_root->load('License:YADA="yada license"') ; }
       qr/should match/, "test license warning" ;
   
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

