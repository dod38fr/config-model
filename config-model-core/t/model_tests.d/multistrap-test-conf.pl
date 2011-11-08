
#$conf_file_name = "multi-test.conf" ;
$conf_dir      = "";
$model_to_test = "Multistrap";

@tests = (
    {
        name        => 'arm',
        config_file => '/home/foo/my_arm.conf',
        check       => {},
    },
);

1;
