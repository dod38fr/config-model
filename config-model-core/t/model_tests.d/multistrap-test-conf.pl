
$model_to_test = "Multistrap";

@tests = (
    {
        name        => 'arm',
        config_file => '/home/foo/my_arm.conf',
        check       => {
                'sections:Toolchains packages:0' ,'g++-4.2-arm-linux-gnu',
                'sections:Toolchains packages:1', 'linux-libc-dev-arm-cross',
            },
    },
    {
        name => 'from_scratch',
        config_file => '/home/foo/my_arm.conf',
        load => "include=/usr/share/multistrap/arm.conf" ,
        file_check_sub => sub { 
            my $r = shift ; 
            # this file was created after the load instructions above
            unshift @$r, "/home/foo/my_arm.conf";
        }
    },
    {
        name => 'igep0020',
        config_file => '/home/foo/strap-igep0020.conf',
    },
);

1;
