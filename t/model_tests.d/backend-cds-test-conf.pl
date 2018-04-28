use Config::Model::BackendMgr;

$conf_dir = '/etc';
$conf_file_name = 'hosts.cds';

$model->create_config_class(
    name => 'Host',

    element => [
        [qw/ipaddr alias/] => {
            type       => 'leaf',
            value_type => 'uniline',
        },
        dummy => {qw/type leaf value_type uniline/},
    ]
);
$model->create_config_class(
    name => 'Hosts',

    rw_config => {
        backend     => 'cds_file',
        config_dir  => '/etc/',
        file        => 'hosts.cds',
    },

    element => [
        record => {
            type  => 'hash',
            index_type => 'string',
            write_empty_value => 1,
            cargo => {
                type              => 'node',
                config_class_name => 'Host',
            },
        },
    ]
);

$model_to_test = "Hosts";

@tests = (
    {
        name  => 'basic',
        check => [
            'record:localhost ipaddr' => '127.0.0.1',
            'record:bilbo ipaddr' => '192.168.0.1'
        ]
    },
);

1;
