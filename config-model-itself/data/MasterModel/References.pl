[
    [
        name      => 'MasterModel::References::Host',
        'element' => [
            if => {
                type              => 'hash',
                index_type        => 'string',
                cargo_type        => 'node',
                config_class_name => 'MasterModel::References::If',
            },
            trap => {
                type       => 'leaf',
                value_type => 'string'
            }
        ]
    ],
    [
        name    => 'MasterModel::References::If',
        element => [
            ip => {
                type       => 'leaf',
                value_type => 'string'
            }
        ]
    ],
    [
        name    => 'MasterModel::References::Lan',
        element => [
            node => {
                type              => 'hash',
                index_type        => 'string',
                cargo_type        => 'node',
                config_class_name => 'MasterModel::References::Node',
            },
        ]
    ],
    [
        name    => 'MasterModel::References::Node',
        element => [
            host => {
                type       => 'leaf',
                value_type => 'reference',
                refer_to   => '- host'
            },
            if => {
                type       => 'leaf',
                value_type => 'reference',
                refer_to   => [ '  - host:$h if ', h => '- host' ]
            },
            ip => {
                type       => 'leaf',
                value_type => 'string',
                compute    => [
                    '$ip',
                    ip   => '- host:$h if:$card ip',
                    h    => '- host',
                    card => '- if'
                ]
            }
        ]
    ],
    [
        name    => 'MasterModel::References',
        element => [
            host => {
                type              => 'hash',
                index_type        => 'string',
                cargo_type        => 'node',
                config_class_name => 'MasterModel::References::Host'
            },
            lan => {
                type              => 'hash',
                index_type        => 'string',
                cargo_type        => 'node',
                config_class_name => 'MasterModel::References::Lan'
            },
            host_and_choice => {
                type       => 'leaf',
                value_type => 'reference',
                refer_to   => ['- host '],
                choice     => [qw/foo bar/]
            },
            dumb_list => {
                type       => 'list',
                cargo_type => 'leaf',
                cargo_args => { value_type => 'string' }
            },
            refer_to_list_enum => {
                type       => 'leaf',
                value_type => 'reference',
                refer_to   => '- dumb_list',
            },

        ]
    ]
];
