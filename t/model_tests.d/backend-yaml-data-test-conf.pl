use Config::Model::BackendMgr;

$conf_dir = '/etc';
$conf_file_name = 'test.yaml';

$model->create_config_class(
    name => 'Master',

    rw_config => {
        backend     => 'yaml',
        config_dir  => '/etc/',
        file        => 'test.yaml',
        # as of 2017, YAML is the only parser that writes back boolean value as unquoted true/false
        yaml_class  => 'YAML',
    },

    element => [
        true_bool  => { qw/type leaf value_type boolean/, write_as => [qw/false true/]},
        false_bool => { qw/type leaf value_type boolean/, write_as => [qw/false true/]},
        null_value => { qw/type leaf value_type uniline/},
    ]
);

$model_to_test = "Master";

@tests = (
    {
        name  => 'basic',
        check => [
            # values are translated from whatever YAML lib returns to true and false
            'true_bool' => 'true',
            'false_bool' => 'false',
            null_value => undef
        ]
    },
);

1;
