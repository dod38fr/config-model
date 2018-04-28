# test model used by t/*.t

my @backend_config = (
    rw_config => {
        backend     => 'yaml',
        config_dir  => '/yaml/',
        file        => 'hosts.yml',
        auto_create => 1,
        full_dump => 0,
        auto_delete => 1,
    }
);

[
    {
        name => 'Host',

        element => [
            [qw/ipaddr canonical alias/] => {
                type       => 'leaf',
                value_type => 'uniline',
            },
            dummy => {qw/type leaf value_type uniline default toto/},
        ]
    },
    {
        name => 'Hosts',

        @backend_config,
        element => [
            record => {
                type  => 'list',
                cargo => {
                    type              => 'node',
                    config_class_name => 'Host',
                },
            },
        ]
    },
    {
        name => 'SingleHashElement',

        @backend_config,

        element => [
            record => {
                type  => 'hash',
                index_type => 'string',
                cargo => {
                    type              => 'node',
                    config_class_name => 'Host',
                },
            },
        ]
    },
    {
        name => 'TwoElements',
        include => 'SingleHashElement',
        @backend_config,
        element => [
            foo => {
                type => 'leaf',
                value_type => 'uniline',
            }
        ]
    }
];
