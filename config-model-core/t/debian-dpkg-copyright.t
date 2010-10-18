# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 56 ;
use Config::Model ;
use Log::Log4perl qw(:easy) ;
use File::Path ;
use File::Copy ;
use Test::Warn ;
use Test::Exception ;

use warnings;

use strict;

my $arg = shift || '';

my ($log,$show,$do) = (0) x 3 ;

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
Format-Specification: http://svn.debian.org/wsvn/dep/web/deps/dep5.mdwn?op=file&amp;rev=135
Name: xyz
Maintainer: Jane Smith <jane.smith@example.com>
Source: http://www.example.com/gitwww
X-test: yada yada
 .
 yada

Files: *
Copyright: 2008, John Doe <john.doe@example.com>
           2007, Jane Smith <jane.smith@example.com>
License: PsF
 [PSF LICENSE TEXT]

EOD0

$tests[$i++]{check} 
   = [ 'License:PsF',           "[PSF LICENSE TEXT]" ,
       'Files:"*" Copyright:0', "2008, John Doe <john.doe\@example.com>",
       'Files:"*" Copyright:1', "2007, Jane Smith <jane.smith\@example.com>",
       'Files:"*" License abbrev',"PsF",
       '"X-test"' ,                 "yada yada\n\nyada",
     ];

$tests[$i]{text} = <<'EOD1' ;
Format-specification: http://svn.debian.org/wsvn/dep/web/deps/dep5.mdwn?op=file&amp;rev=135
Name: SOFTware
Maintainer: John Doe <john.doe@example.com>
Source: http://www.example.com/software/project
Files: src/js/editline/*
Copyright: 1993, John Doe
           1993, Joe Average
License: MPL-1.1 or GPL-2+ or LGPL-2.1+

License: MPL-1.1
 [MPL-1.1 LICENSE TEXT]

License: GPL-2
 [GPL-2 LICENSE TEXT]

License: LGPL-2.1
 [LGPL-2.1 LICENSE TEXT]

EOD1

$tests[$i++]{check} = [ 'License:MPL-1.1',"[MPL-1.1 LICENSE TEXT]" ,
                        'License:GPL-2', "[GPL-2 LICENSE TEXT]",
                        'License:LGPL-2.1', "[LGPL-2.1 LICENSE TEXT]",
                      'Files:"src/js/editline/*" License abbrev',"MPL-1.1 or GPL-2+ or LGPL-2.1+"
                    ];


$tests[$i]{text} = <<'EOD2' ;
Format-Specification: http://svn.debian.org/wsvn/dep/web/deps/dep5.mdwn?op=file&amp;rev=135
Files: src/js/editline/*
Copyright: 1993, John Doe
           1993, Joe Average
License: MPL-1.1

Files: src/js/fdlibm/*
Copyright: 1993, J-Random Corporation
License: MPL-1.1

License: MPL-1.1
 [MPL-1.1 LICENSE TEXT]

EOD2

$tests[$i++]{check} = [ 'License:MPL-1.1',"[MPL-1.1 LICENSE TEXT]" ,
                      'Files:"src/js/editline/*" License abbrev',"MPL-1.1",
                      'Files:"src/js/fdlibm/*" License abbrev',"MPL-1.1",
                    ];

# the empty license will default to 'other'
$tests[$i]{text} = <<'EOD3' ;
Format-Specification: http://svn.debian.org/wsvn/dep/web/deps/dep5.mdwn?op=file&rev=135
Name: Planet Venus
Maintainer: John Doe <jdoe@example.com>
Source: http://www.example.com/code/venus

Copyright: 2008, John Doe <jdoe@example.com>
           2007, Jane Smith <jsmith@example.org>
           2007, Joe Average <joe@example.org>
           2007, J. Random User <jr@users.example.com>
License: PSF-2
 [LICENSE TEXT]

Files: debian/patches/theme-diveintomark.patch
Copyright: 2008, Joe Hacker <hack@example.org>
License: GPL-2+
 [LICENSE TEXT]

Files: planet/vendor/compat_logging/*
Copyright: 2002, Mark Smith <msmith@example.org>
License: MIT
 [LICENSE TEXT]

Files: planet/vendor/httplib2/*
Copyright: 2006, John Brown <brown@example.org>
License: MIT2
 Unspecified MIT style license.

Files: planet/vendor/feedparser.py
Copyright: 2007, Mike Smith <mike@example.org>
License: PSF-2
 [LICENSE TEXT]

Files: planet/vendor/htmltmpl.py
Copyright: 2004, Thomas Brown <coder@example.org>
License: GPL-2
 This program is free software; you can redistribute it
 and/or modify it under the terms of the GNU General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later
 version.
 .
 This program is distributed in the hope that it will be
 useful, but WITHOUT ANY WARRANTY; without even the implied
 warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.  See the GNU General Public License for more
 details.
 .
 You should have received a copy of the GNU General Public
 License along with this package; if not, write to the Free
 Software Foundation, Inc., 51 Franklin St, Fifth Floor,
 Boston, MA  02110-1301 USA
 .
 On Debian systems, the full text of the GNU General Public
 License version 2 can be found in the file
 ‘/usr/share/common-licenses/GPL-2’.

EOD3

$tests[$i++]{check} = [ 
                      'Files:"planet/vendor/compat_logging/*" License abbrev',"MIT",
                    ];

$tests[$i]{text} = <<'EOD4' ;
Format-Specification: http://svn.debian.org/wsvn/dep/web/deps/dep5.mdwn?op=file&amp;rev=135
Files: *
Copyright: 1993, John Doe
           1993, Joe Average
License: GPL-2+ with OpenSSL exception
  This program is free software; you can redistribute it
  and/or modify it under the terms of the [snip]

EOD4

$tests[$i++]{check} = [ 
                      'Files:"*" License abbrev',"GPL-2+",
                      'Files:"*" License exception',"OpenSSL",
                    ];

my $idx = 0 ;
foreach my $t (@tests) {
    if ($do and $do ne $idx) { $idx ++; next; }
   
    my $wr_dir = $wr_root.'/test-'.$idx ;
    mkpath($wr_dir."/debian/", { mode => 0755 }) ;
    my $license_file = "$wr_dir/debian/copyright" ;

    open(LIC,"> $license_file" ) || die "can't open $license_file: $!";
    print LIC $t->{text} ;
    close LIC ;

    my $inst = $model->instance (root_class_name   => 'Debian::Dpkg::Copyright',
                                 root_dir          => $wr_dir,
                                 instance_name => "deptest".$idx,
                                );  
    ok($inst,"Read $license_file and created instance") ;

    my $lic = $inst -> config_root ;

    my $dump =  $lic->dump_tree ();
    rint $dump if $trace ;
   
    while (@{$t->{check}}) { 
       my ($path,$v) = splice @{$t->{check}},0,2 ;
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

    my $p2_dump = $i2_root->dump_tree ;

    is($p2_dump,$dump,"compare original data with 2nd instance data") ;
   
    # test license warnings
    warning_like { $i2_root->load('License:YADA="yada license"') ; }
       qr/should match/, "test license warning" ;
   
    my $elt = $i2_root->grab("! License") ;
    is($elt->defined('foobar'),0,"test defined method");

    # test backups, load a wrong value
    $i2_root->load(step => qq!Files:foobar License abbrev="FOO or BAR"!, check => 'no');
    # then try to write backups
    throws_ok {$i2_test->write_back} 'Config::Model::Exception::WrongValue',
        "check that write back is aborted with bad values" ;

    ok( -s $wr_dir2.'/debian/copyright',"check that original file was not clobbered");
   
    $idx++ ;
}

