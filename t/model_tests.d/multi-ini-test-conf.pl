
# test inifile backend with multiple ini files

# specify the name of the class to test
$model_to_test = "MultiMiniIni";

# create minimal model to test ini file backend.

# this class is used by MultiMiniIni class below
$model->create_config_class(
    name    => 'MultiIniTest::Class',
    element => [
        int_with_max => {qw/type leaf value_type integer max 10/},
    ],
    read_config => [{
        backend     => 'IniFile',
        config_dir  => '/etc/',
        file        => '&index.conf',
        auto_create => 1,
    }],
);

$model->create_config_class(
    name => 'MultiMiniIni',
    element => [
        service => {
            type  => 'hash',
            index_type => 'string',
            # require to trigger load of bar.conf
            default_keys => 'bar',
            cargo => {
                type       => 'node',
                config_class_name => 'MultiIniTest::Class'
            }
        },
    ],
    read_config => [{
        backend     => 'Yaml',
        config_dir  => '/etc/',
        file        => 'service.yml',
        auto_create => 1,
    }],
);


# the test suite
@tests = (
    {
        name  => 'max-overflow',
        # work only with Config::Model > 2.094 because of an obscure
        # initialisation bug occuring while loading a bad value in
        # a sub-node (thanks systemd)
        load => 'service:bar int_with_max=9',
        file_check_sub => sub {
            my $list_ref = shift ;
            # file added because of default bar key
            push @$list_ref, "/etc/service.yml" ;
        },
    },
);

1;
