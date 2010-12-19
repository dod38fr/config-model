[
    [
        name    => 'MasterModel::WarpedIdSlave',
        element => [
            [qw/X Y Z/] => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/Av Bv Cv/],
            }
        ]
    ],

    [
        name      => 'MasterModel::WarpedId',
        'element' => [
            macro => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/A B C/],
            },
            version => {
                type       => 'leaf',
                value_type => 'integer',
                default    => 1
            },
            warped_hash => {
                type       => 'hash',
                index_type => 'integer',
                max_nb     => 3,
                warp       => {
                    follow => '- macro',
                    rules  => {
                        A => { max_nb => 1 },
                        B => { max_nb => 2 }
                    }
                },
                cargo_type        => 'node',
                config_class_name => 'MasterModel::WarpedIdSlave'
            },
            'multi_warp' => {
                type       => 'hash',
                index_type => 'integer',
                min_index  => 0,
                max_index  => 3,
                default    => [ 0 .. 3 ],
                warp       => {
                    follow  => [ '- version', '- macro' ],
                    'rules' => [
                        [ '2', 'C' ] => { max => 7, default => [ 0 .. 7 ] },
                        [ '2', 'A' ] => { max => 7, default => [ 0 .. 7 ] }
                    ]
                },
                cargo_type        => 'node',
                config_class_name => 'MasterModel::WarpedIdSlave'
            },

            'hash_with_warped_value' => {
                type       => 'hash',
                index_type => 'string',
                cargo_type => 'leaf',
                level      => 'hidden'
                ,    # must also accept level permission and description here
                warp => {
                    follow  => '- macro',
                    'rules' => { 'A' => { level => 'normal', }, }
                },
                cargo_args => {
                    value_type => 'string',
                    warp       => {
                        follow  => '- macro',
                        'rules' => { 'A' => { default => 'dumb string' }, }
                    }
                }
            },
            'multi_auto_create' => {
                type        => 'hash',
                index_type  => 'integer',
                min_index   => 0,
                max_index   => 3,
                auto_create => [ 0 .. 3 ],
                'warp'      => {
                    follow  => [ '- version', '- macro' ],
                    'rules' => [
                        [ '2', 'C' ] =>
                          { max => 7, auto_create_keys => [ 0 .. 7 ] },
                        [ '2', 'A' ] =>
                          { max => 7, auto_create_keys => [ 0 .. 7 ] }
                    ],
                },
                cargo_type        => 'node',
                config_class_name => 'MasterModel::WarpedIdSlave'
            }
        ]
    ]
];
