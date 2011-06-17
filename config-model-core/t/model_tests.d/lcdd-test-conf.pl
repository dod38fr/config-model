
$conf_file_name = "LCDd.conf" ;
$model_to_test = "LCDd" ;

@tests = (
    { # t0
     check => { 
       #'fs:/proc fs_spec',           "proc" ,
     },
     errors => [ 
            # qr/value 2 > max limit 0/ => 'fs:"/var/chroot/lenny-i386/dev" fs_passno=0' ,
        ],
    },
);

1;
