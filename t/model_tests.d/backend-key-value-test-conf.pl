
# test inifile backend

# specify where is the example file
$conf_file_name = 'test.kv';
$conf_dir = '/etc';

# specify the name of the class to test
$model_to_test = "IniKeyValue";

# create minimal model to test ini file backend.


$model->create_config_class(
    name => 'IniKeyValue',
    element => [
        [qw/package-status report-with/] => {
            qw/type leaf value_type uniline/,
        },
    ],
    rw_config => {
        backend     => 'IniFile',
        # specify where is the config file. this must match
        # the $conf_file_name and $conf_dir variable above
        assign_char => ':',
        assign_with => ' : ',
        config_dir  => '/etc/',
        file        => 'test.kv',
    },
);


# the test suite
@tests = (
    {   # test complex parameters
        name  => 'bts-control',
    },
);

1;
