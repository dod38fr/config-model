
# test inifile backend

# specify where is the example file
$conf_file_name = 'test.ini';
$conf_dir = '/etc';

# specify the name of the class to test
$model_to_test = "MiniIni";

# create minimal model to test ini file backend.

# this class is used by MiniIni class below
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

            baz => {
                qw/type leaf value_type uniline/,
            },
            [qw/class1 class2/] => {
                type              => 'node',
                config_class_name => 'IniTest::Class'
            }
        ],
    rw_config => {
        backend     => 'IniFile',
        # specify where is the config file. this must match
        # the $conf_file_name and $conf_dir variable above
        config_dir  => '/etc/',
        file        => 'test.ini',
        file_mode   => 'a=r,ug+w',
        auto_create => 1,
    },
);


# the test suite
@tests = (
    {   # test complex parameters
        name  => 'complex',
        check => [
            # check a specific value stored in example file
            baz => q!/bin/sh -c '[ "$(cat /etc/X11/default-display-manager 2>/dev/null)" = "/usr/bin/sddm" ]''!
        ],
        file_mode => {
            '/etc/test.ini' => 0664
        }
    },
);

1;
