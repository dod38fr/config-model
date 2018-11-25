use Config::Model::BackendMgr;

$conf_dir = '/etc';
$conf_file_name = 'test.yaml';

$model->create_config_class(
    name => 'Master',

    rw_config => {
        backend     => 'yaml',
        config_dir  => '/etc/',
        file        => 'test.yaml',
    },

    element => [
        true_bool  => { qw/type leaf value_type boolean/},
        false_bool => { qw/type leaf value_type boolean/},
        new_bool => { qw/type leaf value_type boolean/},
        null_value => { qw/type leaf value_type uniline/},
    ]
);

$model_to_test = "Master";

@tests = (
    {
        name  => 'basic',
        check => [
            # values are translated from whatever YAML lib returns to true and false
            true_bool => 1,
            false_bool => 0,
            null_value => undef
        ],
        load => 'new_bool=1',
        file_contents => {
            # test that file contains real booleans
            "/etc/test.yaml" => "---\nfalse_bool: false\nnew_bool: true\ntrue_bool: true\n",
        }
    },
);

1;
