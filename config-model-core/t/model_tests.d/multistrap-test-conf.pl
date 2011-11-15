
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
);

1;
