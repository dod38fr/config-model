my @element = (
    # Value constructor args are passed in their specific array ref
    cargo_type => 'leaf',
    cargo_args => { value_type => 'string' },
);

[
    [
        name    => "MasterModel::HashIdOfValues",
        element => [
            plain_hash => {
                type => 'hash',

                # hash_class constructor args are all keys of this hash
                # except type and class
                index_type => 'integer',

                @element
            },
            hash_with_auto_created_id => {
                type        => 'hash',
                index_type  => 'string',
                auto_create => 'yada',
                @element
            },
            hash_with_several_auto_created_id => {
                type        => 'hash',
                index_type  => 'string',
                auto_create => [qw/x y z/],
                @element
            },
            [qw/hash_with_default_id hash_with_default_id_2/] => {
                type       => 'hash',
                index_type => 'string',
                default    => 'yada',
                @element
            },
            hash_with_several_default_keys => {
                type       => 'hash',
                index_type => 'string',
                default    => [qw/x y z/],
                @element
            },
            hash_follower => {
                type       => 'hash',
                index_type => 'string',
                @element,
                follow => '- hash_with_several_auto_created_id',
            },
            hash_with_allow => {
                type       => 'hash',
                index_type => 'string',
                @element,
                allow => [qw/foo bar baz/],
            },
            hash_with_allow_from => {
                type       => 'hash',
                index_type => 'string',
                @element,
                allow_from => '- hash_with_several_auto_created_id',
            },
            ordered_hash => {
                type       => 'hash',
                index_type => 'string',
                @element,
                ordered => 1,
            },
        ],
    ]
];
