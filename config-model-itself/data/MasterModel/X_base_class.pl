# -*- cperl -*-

# this file is used by test script

[

    [
        name    => 'MasterModel::X_base_class2',
        element => [
            X => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/Av Bv Cv/]
            },
        ],
        class_description => 'rather dummy class to check include',
    ],

    [
        name    => 'MasterModel::X_base_class',
        include => 'MasterModel::X_base_class2',
    ],

];

# do not put 1; at the end or Model-> load will not work
