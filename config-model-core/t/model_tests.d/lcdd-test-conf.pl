
$conf_file_name = "LCDd.conf" ;
$conf_dir = "etc" ;
$model_to_test = "LCDd" ;

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
     errors => [ 
            # qr/value 2 > max limit 0/ => 'fs:"/var/chroot/lenny-i386/dev" fs_passno=0' ,
        ],
    },
);

1;
