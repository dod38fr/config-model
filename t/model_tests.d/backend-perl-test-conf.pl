use Config::Model::BackendMgr;

$conf_dir = '/etc';
$conf_file_name = 'hosts.pl';

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

    read_config => [
        {
            backend     => 'perl_file',
            config_dir  => '/etc/',
            file        => 'hosts.pl',
        },
    ],

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
