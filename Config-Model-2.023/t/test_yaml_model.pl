#
# This file is part of Config-Model
#
# This software is Copyright (c) 2012 by Dominique Dumont, Krzysztof Tyszecki.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# test model used by t/*.t

[
    {
        name => 'Host',

        element => [
            [qw/ipaddr canonical alias/] => {
                type       => 'leaf',
                value_type => 'uniline',
            },
            dummy => {qw/type leaf value_type uniline default toto/},
        ]
    },
    {
        name => 'Hosts',

        read_config => [
            {
                backend     => 'yaml',
                config_dir  => '/yaml/',
                file        => 'hosts.yml',
                auto_create => 1,
                full_dump => 0,
            },
        ],

        element => [
            record => {
                type  => 'list',
                cargo => {
                    type              => 'node',
                    config_class_name => 'Host',
                },
            },
        ]
    }
];
