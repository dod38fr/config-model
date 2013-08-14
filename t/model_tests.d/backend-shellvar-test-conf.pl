use Config::Model::BackendMgr;

# test shellvar backend
$home_for_test = '/home/joe';
$conf_file_name = 'foo.conf';
$conf_dir = '/etc';

$model->create_config_class(
    name    => "Shelly",
    element => [
        [qw/foo bar/],
        {
            'value_type' => 'uniline',
            'type'       => 'leaf',
        },
    ],
    'read_config' => [
        {
            backend    => 'ShellVar',
            config_dir => '/etc',
            file       => 'foo.conf',
        }
    ]
);

$model_to_test = "Shelly";

@tests = (
    {    # mini (test for Debian #719256)
        name  => 'debian-719256',
        check => [
            foo => 'ok',
            bar => "with space"
        ]
    },
);

1;
