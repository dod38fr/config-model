# test model used by t/*.t

[
    {
        read_config => [
            {
                backend     => 'IniFile',
                config_dir  => '/etc/',
                file        => 'test.ini',
                auto_create => 1,
            },
        ],

        name => 'IniTest',

        element => [
            [qw/foo bar/] => {
                type  => 'list',
                cargo => {
                    type       => 'leaf',
                    value_type => 'uniline',
                }
            },

            [qw/baz/] => {
                qw/type leaf value_type uniline/,
            },
            [qw/class1 class2/] => {
                type              => 'node',
                config_class_name => 'IniTest::Class'
            }
        ]
    },
    {
        read_config => [
            {
                backend           => 'IniFile',
                config_dir        => '/etc/',
                file              => 'test.ini',
                auto_create       => 1,
                comment_delimiter => ';',
            },
        ],

        name => 'IniTest2',

        element => [
            [qw/foo bar/] => {
                type  => 'list',
                cargo => {
                    type       => 'leaf',
                    value_type => 'uniline',
                }
            },

            [qw/baz/] => {
                qw/type leaf value_type uniline/,
            },
            [qw/class1 class2/] => {
                type              => 'node',
                config_class_name => 'IniTest::Class'
            }
        ]
    },
    {
        name    => 'IniTest::Class',
        element => [
            [qw/lista listb/] => {
                type  => 'list',
                cargo => {
                    type       => 'leaf',
                    value_type => 'uniline',
                },
            },
        ]
    },
    {
        name        => 'AutoIni',
        read_config => [
            {
                backend     => 'IniFile',
                config_dir  => '/etc/',
                file        => 'test.ini',
                auto_create => 1,
            },
        ],
        accept => [
            'class.*' => {
                'type'              => 'node',
                'config_class_name' => 'AutoIniClass'
            },
            '.*' => {
                'type' => 'list',
                cargo  => {qw/type leaf value_type uniline/},
            }
        ],
    },
    {
        name   => 'AutoIniClass',
        accept => [
            '.*' => {
                'type' => 'list',
                cargo  => {qw/type leaf value_type uniline/},
            }
        ],
    },
    {
        name => "MyClass",

        element => [
            [qw/foo bar/] => {
                'type' => 'list',
                cargo  => {qw/type leaf value_type uniline/},
            },
            [qw/baz/] => {
                qw/type leaf value_type uniline/,
            },
            'any_ini_class' => {
                type       => 'hash',
                index_type => 'string',
                cargo      => {
                    type              => 'node',
                    config_class_name => 'AutoIniClass'
                },
            },
        ],

        read_config => [
            {
                backend     => 'IniFile',
                config_dir        => '/etc/',
                file              => 'test.ini',
                store_class_in_hash => 'any_ini_class',
                auto_create => 1,
            }
        ],
    }
];
