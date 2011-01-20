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
        name => "Itself::WarpableElement",

        include => 'Itself::CommonElement',

        'element' => [

            [
                qw/allow_keys_from allow_keys_matching follow_keys_from
                  warn_if_key_match warn_unless_key_match/
            ] => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'uniline',
                experience => 'advanced',
                warp       => {
                    follow  => { 't'            => '?type' },
                    'rules' => [ '$t eq "hash"' => { level => 'normal', } ]
                }
            },

            [ qw/migrate_keys_from/ ] => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'uniline',
                experience => 'advanced',
                warp       => {
                    follow  => { 't'                            => '?type' },
                    'rules' => [ '$t eq "hash" or $t eq "list"' => { level => 'normal', } ]
                }
            },

            [qw/ordered/] => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'boolean',
                warp       => {
                    follow  => { 't' => '?type' },
                    'rules' => [
                        '$t eq "hash" or $t eq "check_list"' =>
                          { level => 'normal', }
                    ]
                }
            },

            [qw/default_keys auto_create_keys allow_keys/] => {
                type       => 'list',
                level      => 'hidden',
                cargo      => { type => 'leaf', value_type => 'string' },
                experience => 'advanced',
                warp       => {
                    follow  => { 't'            => '?type' },
                    'rules' => [ '$t eq "hash"' => { level => 'normal', } ]
                }
            },

            [qw/auto_create_ids/] => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'string',
                experience => 'advanced',
                warp       => {
                    follow  => { 't'            => '?type' },
                    'rules' => [ '$t eq "list"' => { level => 'normal', } ]
                }
            },

            [qw/default_with_init/] => {
                type       => 'hash',
                level      => 'hidden',
                index_type => 'string',
                cargo      => { type => 'leaf', value_type => 'string' },
                warp       => {
                    follow  => { 't'            => '?type' },
                    'rules' => [ '$t eq "hash"' => { level => 'normal', } ]
                }
            },

            'max_nb' => {
                type       => 'leaf',
                level      => 'hidden',
                value_type => 'integer',
                warp       => {
                    follow  => { 'type'            => '?type', },
                    'rules' => [ '$type eq "hash"' => { level => 'normal', } ]
                }
            },

            'replace' => {
                type       => 'hash',
                index_type => 'string',
                level      => 'hidden',
                experience => 'advanced',
                warp       => {
                    follow  => { 't' => '?type' },
                    'rules' => [
                        '$t eq "leaf" or $t eq "check_list"' =>
                          { level => 'normal', }
                    ]
                },

                # TBD this could be a reference if we restrict replace to
                # enum value...
                cargo => { type => 'leaf', value_type => 'string' },
            },

            help => {
                type       => 'hash',
                index_type => 'string',
                level      => 'hidden',
                warp       => {
                    follow  => { 't' => '?type' },
                    'rules' => [
                        '$t eq "leaf" or $t eq "check_list"' =>
                          { level => 'normal', }
                    ]
                },

                # TBD this could be a reference if we restrict replace to
                # enum value...
                cargo => { type => 'leaf', value_type => 'string' },
            },
        ],

        'description' => [
            follow_keys_from => 'this hash will contain the same keys as the hash pointed by the path string',
            allow_keys_from => 'this hash will allow keys from the keys of the hash pointed by the path string',
            ordered => 'keep track of the order of the elements of this hash',
            default_keys => 'default keys hashes.',
            auto_create_keys => 'always create a set of keys specified in this list',
            auto_create_ids => 'always create the number of id specified in this integer',
            allow_keys => 'specify a set of allowed keys',
            allow_keys_matching => 'Keys must match the specified regular expression.',
            default_with_init => 'specify a set of keys to create and initialization on some elements . E.g. \' foo => "X=Av Y=Bv", bar => "Y=Av Z=Cz"\' ',
            help => 'Specify help string specific to possible values. E.g for "light" value, you could write " red => \'stop\', green => \'walk\' ',
            replace => 'Used for enum to substitute one value with another. This parameter must be used to enable user to upgrade a configuration with obsolete values. The old value is the key of the hash, the new one is the value of the hash',
            warn_if_key_match => 'Warn user if a key is created matching this regular expression',
            warn_unless_key_match => 'Warn user if a key is created not matching this regular expression',
        ],
    ],

];
