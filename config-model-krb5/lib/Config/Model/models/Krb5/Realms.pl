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

[
    [
        name => "Krb5::Realms",

        'element' => [
            'kdc' => {
                'cargo' => {
                    'type'       => 'leaf',
                    'value_type' => 'uniline',
                },
                'experience'  => 'beginner',
                'type'        => 'list',
                'description' => 'The value of this relation is the name of a host running a KDC for that realm. An optional port number (preceded by a colon) may be appended to the hostname. This tag should generally be used only if the realm administrator has not made the information available through DNS.',
            },

            'admin_server' => {
                'cargo' => {
                    'type'       => 'leaf',
                    'value_type' => 'uniline',
                },
                'experience'  => 'beginner',
                'type'        => 'list',
                'description' => 'This relation identifies the host where the administration server is running. Typically this is the Master Kerberos server.',
            },

            'database_module' => {
                'type'        => 'leaf',
                'value_type'  => 'uniline',
                'experience'  => 'advanced',
                'description' => 'This relation indicates the name of the configuration section under dbmodules for database specific parameters used by the loadable database library.',
            },
            'default_domain' => {
                'type'        => 'leaf',
                'value_type'  => 'uniline',
                'experience'  => 'beginner',
                'description' => 'This relation identifies the default domain for which hosts in this realm are assumed to be in. This is needed for translating V4 principal names (which do not contain a domain name) to V5 principal names (which do).',
            },

            'v4_instance_convert' => {
                'cargo' => {
                    'type'       => 'leaf',
                    'value_type' => 'uniline',
                },
                'experience'  => 'advanced',
                'type'        => 'hash',
                'index_type'  => 'string',
                'description' => 'This subsection allows the administrator to configure exceptions to the default_domain mapping rule. It contains V4 instances (the tag name) which should be translated to some specific hostname (the tag value) as the second component in a Kerberos V5 principal name.',
            },

            'v4_realm' => {
                'type'        => 'leaf',
                'value_type'  => 'uniline',
                'experience'  => 'advanced',
                'description' => 'This relation is used by the krb524 library routines when converting a V5 principal name to a V4 principal name. It is used when V4 realm name and the V5 realm are not the same, but still share the same principal names and passwords. The tag value is the Kerberos V4 realm name.',
            },

            'auth_to_local_names' => {
                'cargo' => {
                    'type'       => 'leaf',
                    'value_type' => 'uniline',
                },
                'experience'  => 'advanced',
                'type'        => 'hash',
                'index_type'  => 'string',
                'description' => 'This subsection allows you to set explicit mappings from principal names to local user names. The tag is the mapping name, and the value is the corresponding local user name.',
            },

            'auth_to_local' => {
                'type'        => 'leaf',
                'value_type'  => 'uniline',
                'experience'  => 'advanced',
                'description' => 'This tag allows you to set a general rule for mapping principal names to local user names. It will be used if there is not an explicit mapping for the principal name that is being translated.',
            },

        ],
    ],
];

