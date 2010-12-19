#    Copyright (c) 2007-2010 Dominique Dumont.
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
        name => "Itself::CargoElement",

        include =>
          [ 'Itself::NonWarpableElement', 'Itself::WarpableCargoElement' ],
        include_after => 'type',

        'element' => [

            # structural information
            'type' => {
                type        => 'leaf',
                value_type  => 'enum',
                choice      => [qw/node warped_node leaf check_list/],
                mandatory   => 1,
                description => 'specify the type of the cargo.',
            },

            # node element (may be within a hash or list)

            # all but warped_node
            'warp' => {
                type   => 'warped_node',              # ?
                level  => 'hidden',
                follow => { elt_type => '- type' },

                rules => [
                    '$elt_type ne "warped_node"' => {
                        level             => 'normal',
                        config_class_name => 'Itself::CargoWarpValue',
                    }
                ],
                description =>
                    "change the properties (i.e. default value or its value_type) "
                  . "dynamically according to the value of another Value object locate "
                  . "elsewhere in the configuration tree. "

            },

            # warped_node: warp parameter for warped_node. They must be
            # warped out when type is not a warped_node

            'rules' => {
                type       => 'hash',
                ordered    => 1,
                level      => 'hidden',
                index_type => 'string',
                warp       => {
                    follow  => '- type',
                    'rules' => { 'warped_node' => { level => 'normal', } }
                },
                cargo => {
                    type    => 'warped_node',
                    follow  => '- type',
                    'rules' => {
                        'warped_node' => {
                            config_class_name => 'Itself::WarpableCargoElement',
                        }
                    }
                },
                description =>
                    "Each key of a hash is a boolean expression using variables declared "
                    . "in the 'follow' parameters. The value of the hash specifies the effects on the node",
            },

            # end warp elements for warped_node

            # leaf element

        ],

    ],

];
