#
# This file is part of Config-Model
#
# This software is Copyright (c) 2012 by Dominique Dumont, Krzysztof Tyszecki.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

$conf_file_name = "LCDd.conf" ;
$conf_dir = "etc" ;
$model_to_test = "LCDd" ;

my @fix_warnings ;

push @fix_warnings,
    ( 
        #load_warnings => [ qr/code check returned false/ ],
        load => "server DriverPath=/tmp/" , # just a work-around
    ) 
    unless -d '/usr/lib/lcdproc/' ;

@tests = (
    { # t0
     check => { 
       'server Hello:0',           qq!"  Bienvenue"! ,
       'server Hello:1',           qq("   LCDproc et Config::Model!") ,
       'server GoodBye:0',           qq!"    GoodBye"! ,
       'server GoodBye:1',           qq("    LCDproc!") ,
       'server Driver', 'curses',
       'curses Size', '20x2',
     },
     @fix_warnings ,
     errors => [ 
            # qr/value 2 > max limit 0/ => 'fs:"/var/chroot/lenny-i386/dev" fs_passno=0' ,
        ],
    },
);

1;
