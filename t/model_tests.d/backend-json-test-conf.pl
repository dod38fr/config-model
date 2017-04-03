use Config::Model::BackendMgr;

$conf_dir = '/etc';
$conf_file_name = 'hosts.json';

$model->create_config_class(
    name => 'Host',

    element => [
        [qw/ipaddr canonical alias/] => {
            type       => 'leaf',
            value_type => 'uniline',
        },
        dummy => {qw/type leaf value_type uniline default toto/},
    ]
);
$model->create_config_class(
    name => 'Hosts',

    read_config => [
        {
            backend     => 'json',
            config_dir  => '/etc/',
            file        => 'hosts.json',
        },
    ],

    element => [
        record => {
            type  => 'list',
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
            'record:0 ipaddr' => '127.0.0.1',
            'record:1 canonical' => 'bilbo'
        ]
    },
);

1;
