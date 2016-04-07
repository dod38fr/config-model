use Config::Model::BackendMgr;

# test shellvar backend
$conf_file_name = 'test.ini';
$conf_dir = '/etc';

$model->create_config_class(
    name    => 'IniTest::Class',
    element => [
        [qw/lista listb/] => {
            type  => 'list',
            cargo => {
                type       => 'leaf',
                value_type => 'uniline',
            },
        },
    ]
);

$model->create_config_class(
    name => 'MiniIni',
        element => [
            [qw/foo bar/] => {
                type  => 'list',
                cargo => {
                    type       => 'leaf',
                    value_type => 'uniline',
                }
            },

            [qw/baz/] => {
                qw/type leaf value_type uniline/,
            },
            [qw/class1 class2/] => {
                type              => 'node',
                config_class_name => 'IniTest::Class'
            }
        ],
    read_config => [{
        backend     => 'IniFile',
        config_dir  => '/etc/',
        file        => 'test.ini',
        auto_create => 1,
    }],
);

$model_to_test = "MiniIni";

@tests = (
    {   # test complex parameters
        name  => 'complex',
        check => [
            baz => q!/bin/sh -c '[ "$(cat /etc/X11/default-display-manager 2>/dev/null)" = "/usr/bin/sddm" ]''!
        ]
    },
);

1;
