
$conf_file_name = "fstab" ;
$conf_dir = "etc" ;
$model_to_test = "Fstab" ;

@tests = (
    { # t0
     check => { 
       'fs:/proc fs_spec',           "proc" ,
      'fs:/proc fs_file',           "/proc" ,
       'fs:/home fs_file',          "/home",
       'fs:/home fs_spec',          "UUID=18e71d5c-436a-4b88-aa16-308ebfa2eef8",
     },
     dump_errors => [ 
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

1;
