# -*- cperl -*-

# this file is used by test script

[
    [
        name    => 'SubSlave2',
        element => [
            [qw/aa2 ab2 ac2 ad2 Z/] => {
                type       => 'leaf',
                value_type => 'string'
            }
        ]
    ],

    [
        name    => 'SubSlave',
        element => [
            [qw/aa ab ac ad/] => {
                type       => 'leaf',
                value_type => 'uniline'
            },
            sub_slave => {
                type              => 'node',
                config_class_name => 'SubSlave2',
            }
        ]
    ],

    [
        name    => 'X_base_class2',
        element => [
            X => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/Av Bv Cv/]
            },
        ],
        class_description => 'rather dummy class to check include feature',
    ],

    [
        name    => 'X_base_class',
        include => 'X_base_class2',
    ],

    [
        name    => 'SlaveZ',
        element => [
            [qw/Z/] => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/Av Bv Cv/]
            },
            [qw/DX/] => {
                type       => 'leaf',
                value_type => 'enum',
                default    => 'Dv',
                choice     => [qw/Av Bv Cv Dv/]
            },
        ],
        include       => 'X_base_class',
        include_after => 'Z',
    ],

    [
        name    => 'SlaveY',
        element => [
            std_id => {
                type       => 'hash',
                index_type => 'string',
                cargo      => {
                    type              => 'node',
                    config_class_name => 'SlaveZ'
                },
            },
            sub_slave => {
                type              => 'node',
                config_class_name => 'SubSlave',
            },
            [qw/a_string a_long_string another_string/] => {
                type       => 'leaf',
                mandatory  => 1,
                value_type => 'string'
            },
            warp2 => {
                type              => 'warped_node',
                follow            => '! tree_macro',
                config_class_name => 'SubSlave',
                morph             => 1,
                rules             => [
                    mXY => { config_class_name => 'SubSlave2' },
                    XZ  => { config_class_name => 'SubSlave2' }
                ]
            },
            Y => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/Av Bv Cv/]
            }, 
        ],
        include => 'X_base_class',
    ],

    [
        name              => 'Master',
        experience        => [ [qw/warp/] => 'advanced' ],
        class_description => "

=head1 coucou

Master description . Let's go for a very long description.

Big class to do:

=over 

=item * 

shiny

=item *

beautiful

=back

things.
",
        level        => [ [qw/lista hash_a tree_macro int_v/] => 'important' ],
        write_config => [
            {
                backend     => 'cds_file',
                config_dir  => '/foo',
                auto_create => 1
            },
        ],
        element => [
            tree_macro => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/XY XZ mXY/],
                help       => {
                    XY  => 'XY help',
                    XZ  => 'XZ help',
                    mXY => 'mXY help',
                }
            },
            pop_in_out => {
                type       => 'leaf',
                level => 'hidden',
                value_type => 'uniline',
                default    => 'yada yada',
                warp => {  
                    follow            => '! tree_macro',
                    rules             => [
                        XZ => { level => 'normal' },
                    ],
                },
            },

            std_id => {
                type       => 'hash',
                index_type => 'string',
                cargo      => {
                    type              => 'node',
                    config_class_name => 'SlaveZ'
                },
            },
            [qw/lista listb/] => {
                type  => 'list',
                cargo => {
                    type       => 'leaf',
                    value_type => 'uniline'
                },
                summary => 'lista and listb are used to yada yada ',
            },
            [qw/hash_a hash_b/] => {
                type       => 'hash',
                index_type => 'string',
                cargo      => {
                    type       => 'leaf',
                    value_type => 'uniline'
                },
            },
            ordered_hash => {
                type       => 'hash',
                index_type => 'string',
                ordered    => 1,
                cargo      => {
                    type       => 'leaf',
                    value_type => 'uniline'
                },
            },
            ordered_hash_of_mandatory => {
                type       => 'hash',
                index_type => 'string',
                ordered    => 1,
                cargo      => {
                    type       => 'leaf',
                    value_type => 'uniline',
                    mandatory  => 1,
                },
            },
            'ordered_hash_of_nodes' => {
                type       => 'hash',
                index_type => 'string',
                ordered    => 1,
                cargo      => {
                    type              => 'node',
                    config_class_name => 'SlaveZ'
                },
            },
            olist => {
                type  => 'list',
                cargo => {
                    type              => 'node',
                    config_class_name => 'SlaveZ',
                },
            },
            enum_list => {
                type  => 'list',
                cargo => {
                    type       => 'leaf',
                    value_type => 'enum',
                    choice     => [qw/A B C/],
                }
            },
            
            "list_with_warn_duplicates" => { 
                type => 'list', 
                duplicates => 'warn' , 
                cargo => { type => 'leaf', value_type => 'string' } 
            },
             "hash_with_warn_duplicates" => { 
                type => 'hash',
                index_type => 'string', 
                duplicates => 'warn' , 
                cargo => { type => 'leaf', value_type => 'string' } 
            },
           warp => {
                type              => 'warped_node',
                follow            => '! tree_macro',
                config_class_name => 'SlaveY',
                morph             => 1,
                rules             => [

                    #XY => { config_class_name => 'SlaveY'},
                    mXY => { config_class_name => 'SlaveY' },
                    XZ  => { config_class_name => 'SlaveZ' }
                ]
            },

            'slave_y' => {
                type              => 'node',
                config_class_name => 'SlaveY',
            },

            string_with_def => {
                type       => 'leaf',
                value_type => 'uniline',
                default    => 'yada yada'
            },
            a_uniline => {
                type       => 'leaf',
                value_type => 'uniline',
                default    => 'yada yada'
            },
            a_boolean => {
                type       => 'leaf',
                value_type => 'boolean',
            },
            [qw/a_string a_long_string another_string/] => {
                type       => 'leaf',
                value_type => 'string'
            },
            [qw/a_mandatory_string another_mandatory_string/] => {
                type       => 'leaf',
                mandatory  => 1,
                value_type => 'string'
            },
            int_v => {
                type       => 'leaf',
                value_type => 'integer',
                default    => '10',
                min        => 5,
                max        => 15
            },
            upstream_default => {
                type             => 'leaf',
                value_type       => 'integer',
                upstream_default => '10',
            },
            my_plain_check_list => {
                type   => 'check_list',
                choice => [ 'AA' .. 'AE' ],
                help   => {
                    AA => 'AA help',
                    AC => 'AC help',
                    AE => 'AE help',
                },
                description =>
                  'my_plain_check_list nto so helpfull description',
            },
            enum_with_help => {
                type   => 'leaf',
                value_type => 'enum' ,
                choice => [ 'AA' .. 'AE' ],
                help   => { map { ( $_ => "$_ help") ;} ('AA' .. 'AE') },
                description =>
                  'my_plain_check_list nto so helpfull description',
            },
           my_ref_check_list => {
                type     => 'check_list',
                refer_to => '- hash_a + ! hash_b',
            },
            'ordered_checklist' => {
                type    => 'check_list',
                choice  => [ 'A' .. 'Z' ],
                ordered => 1,
                help    => { A => 'A help', E => 'E help' },
                summary => 'will checklist be served ? ;-) ',
            },

            my_reference => {
                type       => 'leaf',
                value_type => 'reference',
                refer_to   => '- hash_a + ! hash_b',
                summary    => 'justify a long help ;-) ',
            },

            warn_unless => {
                type       => 'leaf',
                value_type => 'string',
                warn_unless_match =>
                  { foo => { msg => '', fix => '$_ = "foo".$_;' } },
            },
            always_warn => {
                type       => 'leaf',
                value_type => 'string',
                warn       => 'Always warn whenever used',
            },
            hash_with_warn_unless_key_match => {
                type       => 'hash',
                index_type => 'string',
                cargo      => { type => 'leaf', value_type => 'string' },
                warn_unless_key_match => 'foo',
            },

        ],
        description => [
            tree_macro    => 'controls behavior of other elements',
            a_long_string => "long string with \\n in it",
            my_reference  => "very long help:\n"
              . "Config::Model enables a project developer to provide an interactive configuration editor to his users. For this he must:
- describe the structure and constraint of his project's configuration
- if the configuration data is not stored in INI file or in Perl data
  file, he must provide some code to read and write configuration from
  configuration files.
"
        ]
    ],
];

# do not put 1; at the end or Model-> load will not work
