
$model_to_test = "Sshd" ;
$conf_file_name = 'sshd_config';
$conf_dir = '/etc/ssh' ;

@tests = (
    { 
        name => 'debian-671367' ,
        load_warnings => [ qr/deprecated/ ],
        check => { 
            'AuthorizedKeysFile:0' => '/etc/ssh/userkeys/%u',
            'AuthorizedKeysFile:1' => '/var/lib/misc/userkeys2/%u',
        },
    },
);

1;
