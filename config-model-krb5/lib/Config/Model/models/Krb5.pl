# $Author:$
# $Date: $
# $Name: $
# $Revision: $

#    Copyright (c) 2008 Peter Knowles
#
#    This file is part of Config::Model::Krb5.
#
#    Config::Model::Krb5 is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config::Model::Krb5 is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

# This model was created from krb5.conf(5) man page.

# Top level class feature krb5.conf sections

[
    {
        name => "Krb5",

        read_config => [ { class => 'Config::Model::Krb5', function => 'krb5_read', syntax => 'custom' } ],

        # config file location is now inherited from a model generated at build time
        #inherit => 'Krb5::ConfigDir',

        write_config => [ { class => 'Config::Model::Krb5', function => 'krb5_write', syntax => 'custom' } ],

        'read_config_dir'  => '/etc',
        'write_config_dir' => '/etc',

        'element' => [
            'libdefaults',
            {
                type              => 'node',
                config_class_name => 'Krb5::LibDefaults',
                description       => 'Contains various default values used by the Kerberos V5 library.',
            },

            'login',
            {
                type              => 'node',
                config_class_name => 'Krb5::Login',
                description       => 'Contains default values used by the Kerberos V5 login program, login.krb5(8).',
                'experience'      => 'advanced',
            },
            'appdefaults' => {
                type              => 'node',
                config_class_name => 'Krb5::AppDefaults',
                'experience'      => 'advanced',
            },

            'realms' => {
                'cargo' => {
                    type              => 'node',
                    config_class_name => 'Krb5::Realms',
                },
                'experience'  => 'beginner',
                'type'        => 'hash',
                'index_type'  => 'string',
                'description' => 'Contains subsections keyed by Kerberos realm names which describe where to find the Kerberos servers for a particular realm, and other realm-specific information.',
            },

            'domain_realm',
            {
                'cargo' => {
                    'type'       => 'leaf',
                    'value_type' => 'uniline',
                },
                'experience'  => 'beginner',
                'type'        => 'hash',
                'index_type'  => 'string',
                'description' => 'A mapping between a hostname or a domain name (where domain names are indicated by a prefix of a period (' . ') character) and a Kerberos realm.',
            },

            'logging' => {
                type              => 'node',
                config_class_name => 'Krb5::Logging',
                'description'     => 'Contains relations which determine how Kerberos entities are to perform their logging.',
                'experience'      => 'advanced',
            },

            'capaths' => {
                'cargo' => {
                    'type'              => 'node',
                    'config_class_name' => 'Krb5::CAPaths::Realm'
                },
                'experience'  => 'advanced',
                'type'        => 'hash',
                'index_type'  => 'string',
                'description' => 'Realm participating in cross-realm authentication.'
            },

            'dbdefaults',
            {
                type              => 'node',
                config_class_name => 'Krb5::DBDefaults',
                description       => 'Contains default values for database specific parameters.',
                'experience'      => 'advanced',
            },
            'dbmodules' => {
                'experience' => 'advanced',
                'cargo'      => {
                    'type'              => 'node',
                    'config_class_name' => 'Krb5::DBModules::ConfigSection'
                },
                'experience'  => 'advanced',
                'type'        => 'hash',
                'index_type'  => 'string',
                'description' => 'Configuration section for database specific parameters that can be referred to by a realm.'
            },

        ],

    },
];

