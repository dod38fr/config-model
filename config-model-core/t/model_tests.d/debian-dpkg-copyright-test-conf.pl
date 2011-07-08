use Data::Dumper;
use IO::File;

$conf_file_name = "copyright";
$conf_dir       = 'debian';
$model_to_test  = "Debian::Dpkg::Copyright";

eval { require AptPkg::Config ;} ;
$skip = ( $@ or not -r '/etc/debian_version') ? 1 : 0 ;

@tests = (
    { # t0
        load_warnings => [ (qr/deprecated/) x 3, qr/Missing/ ],

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
        load_warnings => [ (qr/deprecated/) x 3 ],

        check => {
            'License:MPL-1.1'     => "[MPL-1.1 LICENSE TEXT]",
            'License:"GPL-2+"'    => "[GPL-2 LICENSE TEXT]",
            'License:"LGPL-2.1+"' => "[LGPL-2.1 plus LICENSE TEXT]",
            'Files:"src/js/editline/*" License short_name' =>
              "MPL-1.1 or GPL-2+ or LGPL-2.1+"
        },

    },
    { # t2
        load_warnings => [ (qr/deprecated/) x 1 ],

        check => {
            'License:MPL-1.1' => "[MPL-1.1 LICENSE TEXT]",
            'Files:"src/js/editline/*" License short_name' => "MPL-1.1",
            'Files:"src/js/fdlibm/*" License short_name'   => "MPL-1.1",
        },
    },

    # the empty license will default to 'other'
    { # t3
        load_warnings => [ (qr/deprecated/) x 3 ],

        check => {
            'Comment' => "\nHeader comment 1/2\nHeader comment 2/2",
            'Files:"*" Comment' => "\n Files * comment 1/2\nFiles * comment 2/2",
            'Files:"planet/vendor/compat_logging/*" Comment' 
                => "\nFiles logging * comment 1/2\n Files logging * comment 2/2",
            'Files:"planet/vendor/compat_logging/*" License short_name' => "MIT",
        },
    },
    { # t4
        load_warnings => [ (qr/deprecated/) x 1 ],

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

        load_warnings => [ (qr/deprecated/) x 3 ],
        check => {
            'Files:"*" License short_name' => "LGPL-2+",
            'Source' => 'http://search.cpan.org/dist/Config-Model-CursesUI/',
            'License:"LGPL-2+"' =>
"   [snip]either version 2.1 of\n   the License, or (at your option) any later version.\n"
              . "   [snip again]",
        },
    },
    { # t6

        load_warnings => [ (qr/deprecated/) x 3 ],

        check => {
            'Upstream-Contact:0' => 'Ignace Mouzannar <mouzannar at gmail.com>',
            'Files:"Embedded_Display/remoteview.cpp Embedded_Display/remoteview.h" License short_name'
              => "GPL-2",
        },
    },
    { # t7
        # example from CANDIDATE DEP-5 spec (nb 7)
        load_warnings => [ (qr/Adding/) x 1 ],
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
        load_warnings => [ (qr/deprecated/) x 2 ],

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
        dump_errors =>  [ 
            qr/mandatory/ => 'Files:"*" Copyright:0="(c) foobar"',
            qr/mandatory/ => ' License:FOO="foo bar" ! Files:"*" License short_name="FOO" '
        ],
    },
    
    { # t12
        load_warnings => [ (qr/deprecated/) x 3, qr/Adding/ ],
        load_check => 'no',
        dump_errors =>  [ 
            qr/not declared/ => 'License:Expat="Expat license foobar"',
        ],
    },

    { # t13 Debian bug #624305
   }

);

1;
