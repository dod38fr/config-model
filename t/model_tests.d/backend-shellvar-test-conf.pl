# test shellvar backend

use Config::Model::BackendMgr;
use strict;
use warnings;


my @config_classes = ({
    name    => "Shelly",
    element => [
        [qw/foo bar/],
        {
            'value_type' => 'uniline',
            'type'       => 'leaf',
        },
    ],
    'rw_config' => {
        backend    => 'ShellVar',
        config_dir => '/etc',
        file       => 'foo.conf',
    }
});

my @tests = (
    {    # mini (test for Debian #719256)
        name  => 'debian-719256',
        check => [
            foo => 'ok',
            bar => "with space"
        ],
    },
    {
        # data is written in file not using canonical order
        name => 'keep-order',
        file_contents_like => {
            "/etc/foo.conf" => [ qr/bar="with space"\nfoo="ok"/m ] ,
        }
    }
);

return {
    model_to_test => "Shelly",
    home_for_test => '/home/joe',
    conf_file_name => 'foo.conf',
    conf_dir => '/etc',
    config_classes => \@config_classes,
    tests => \@tests
};
