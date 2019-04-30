use Config::Model::BackendMgr;
use strict;
use warnings;

my @config_classes = ({
    name => 'Host',

    element => [
        [qw/ipaddr canonical alias/] => {
            type       => 'leaf',
            value_type => 'uniline',
        },
        dummy => {qw/type leaf value_type uniline default toto/},
    ]
});

push @config_classes, {
    name => 'Hosts',

    rw_config => {
        backend     => 'json',
        config_dir  => '/etc/',
        file        => 'hosts.json',
    },

    element => [
        record => {
            type  => 'list',
            cargo => {
                type              => 'node',
                config_class_name => 'Host',
            },
        },
    ]
};


my @tests = (
    {
        name  => 'basic',
        check => [
            'record:0 ipaddr' => '127.0.0.1',
            'record:1 canonical' => 'bilbo'
        ]
    },
);

return {
    model_to_test => "Hosts",
    conf_dir => '/etc',
    conf_file_name => 'hosts.json',
    config_classes => \@config_classes,
    tests => \@tests
};
