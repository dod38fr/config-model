#    Copyright (c) 2007-2011 Dominique Dumont.
#
#    This file is part of Config-Model-Itself.
#
#    Config-Model-Itself is free software; you can redistribute it
#    and/or modify it under the terms of the GNU Lesser Public License
#    as published by the Free Software Foundation; either version 2.1
#    of the License, or (at your option) any later version.
#
#    Config-Model-Itself is distributed in the hope that it will be
#    useful, but WITHOUT ANY WARRANTY; without even the implied
#    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#    See the GNU Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model-Itself; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

[
    [
        name => 'Itself::NonWarpableElement',

        # warp often depend on this one, so list it first
        'element' => [
            'value_type' => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'enum',
                'warp'     => {
                    follow  => { 't' => '- type' },
                    'rules' => [
                        '$t eq "leaf"' => {
                            choice => [
                                qw/boolean enum integer reference
                                  number uniline string/
                            ],
                            level     => 'normal',
                            mandatory => 1,
                        }
                    ]
                }
            },

            'class' => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'uniline',
                summary    => "Override Config::Model::Value:",
                description =>
                  "Perl class name of a child of Config::Model::Value",
                experience => 'master',
                'warp'     => {
                    follow  => { 't'            => '- type' },
                    'rules' => [ '$t eq "leaf"' => { level => 'normal', } ]
                }
            },

            # node element (may be within a hash or list)

            # warped_node: warp parameter for warped_node. They must be
            # warped out when type is not a warped_node
            'follow' => {
                type       => 'hash',
                index_type => 'string',
                level      => 'hidden',
                'warp'     => {
                    follow  => '- type',
                    'rules' => { 'warped_node' => { level => 'normal', }, }
                },
                cargo => {
                    type       => 'leaf',
                    value_type => 'uniline'
                },
                description =>
                  "Specifies the path to the value elements that drive the "
                  . "change of this node. Each key of the has is a variable name used "
                  . "in the 'rules' parameter. The value of the hash is a path in the "
                  . "configuration tree",
            },

            'morph' => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'boolean',
                'warp'     => {
                    follow  => '- type',
                    'rules' => {
                        'warped_node' => {
                            level            => 'normal',
                            upstream_default => 0,
                        },
                    }
                },
                description =>
                  "When set, a recurse copy of the value from the old object "
                  . "to the new object will be attemped. When a copy is not possible, "
                  . "undef values will be assigned.",
            },

            # end warp elements for warped_node

            # leaf element

            'refer_to' => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'uniline',
                experience => 'advanced',
                warp       => {
                    follow => {
                        t  => '- type',
                        vt => '- value_type',
                    },
                    'rules' => [
                        '$t  eq "check_list" or $vt eq "reference"' =>
                          { level => 'important', },
                    ]
                },
                description =>
                  "points to an array or hash element in the configuration "
                  . "tree using the path syntax. The available choice of this "
                  . "reference value (or check list)is made from the available "
                  . "keys of the pointed hash element or the values of the pointed array element.",
            },

            'computed_refer_to' => {
                type   => 'warped_node',
                follow => {
                    t  => '- type',
                    vt => '- value_type',
                },
                level      => 'hidden',
                experience => 'master',
                'rules'    => [
                    '$t  eq "check_list" or $vt eq "reference"' => {
                        level             => 'normal',
                        config_class_name => 'Itself::ComputedValue',
                    },
                ],
                description =>
                  "points to an array or hash element in the configuration "
                  . "tree using a path computed with value from several other "
                  . "elements in the configuration tree. The available choice "
                  . "of this reference value (or check list) is made from the "
                  . "available keys of the pointed hash element or the values "
                  . "of the pointed array element.",
            },

            'replace_follow' => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'uniline',
                experience => 'advanced',
                warp       => {
                    follow  => { t               => '- type' },
                    'rules' => [ '$t  eq "leaf"' => { level => 'important', }, ]
                },
                description =>
                  "Path specifying a hash of value element in the configuration "
                  . "tree. The hash if used in a way similar to the replace "
                  . "parameter. In this case, the replacement is not coded "
                  . "in the model but specified by the configuration.",
            },

            'compute' => {
                type       => 'warped_node',
                level      => 'hidden',
                experience => 'advanced',

                follow  => { t => '- type', },
                'rules' => [
                    '$t  eq "leaf"' => {
                        level             => 'normal',
                        config_class_name => 'Itself::ComputedValue',
                    },
                ],
                description =>
                  "compute the default value according to a formula and value "
                  . "from other elements in the configuration tree.",
            },

            'migrate_from' => {
                type       => 'warped_node',
                level      => 'hidden',
                experience => 'advanced',

                follow  => { t => '- type', },
                'rules' => [
                    '$t  eq "leaf"' => {
                        level             => 'normal',
                        config_class_name => 'Itself::MigratedValue',
                    },
                ],
                description =>
                    "Specify an upgrade path from an old value and compute "
                  . "the value to store in the new element.",
            },

            'write_as' => {
                type       => 'list',
                level      => 'hidden',
                max_index  => 1,

                warp => {
                    follow  => { t => '- type', vt => '- value_type'},
                    rules   => [
                        '$t eq "leaf" and $vt eq "boolean"' => { level => 'normal', },
                    ]
                },
                cargo => {
                    type => 'leaf',
                    value_type => 'uniline',
                },
                description =>
                    "Specify how to write a boolean value. Example 'no' 'yes'.",
            },

            # hash element

            # list element

        ],
    ],
];
