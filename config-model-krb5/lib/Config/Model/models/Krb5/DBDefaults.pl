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

[
    [
        name => "Krb5::DBDefaults",

        'element' => [
            'database_module' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'This relation indicates the name of the configuration section under dbmodules for database specific parameters used by the loadable database library.',
                'experience' => 'advanced',
            },

            'ldap_kerberos_container_dn' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'This LDAP specific tag indicates the DN of the container object where the realm objects will be located. This value is used if no object DN is mentioned in the configuration section under dbmodules.',
                'experience' => 'advanced',
            },

            'ldap_kdc_dn' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'This LDAP specific tag indicates the default bind DN for the KDC server. The KDC server does a login to the directory as this object. This value is used if no object DN is mentioned in the configuration section under dbmodules.',
                'experience' => 'advanced',
            },
            'ldap_kadmind_dn' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'This LDAP specific tag indicates the default bind DN for the Administration server. The Administration server does a login to the directory as this object. This value is used if no object DN is mentioned in the configuration section under dbmodules.',
                'experience' => 'advanced',
            },

            'ldap_service_password_file' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'This LDAP specific tag indicates the file containing the stashed passwords for the objects used for starting the Kerberos servers. This value is used if no service password file is mentioned in the configuration section under dbmodules.',
                'experience' => 'advanced',
            },

            'ldap_servers' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'This LDAP specific tag indicates the list of LDAP servers. The list of LDAP servers is whitespace-separated. The LDAP server is specified by a LDAP URI. This value is used if no LDAP servers are mentioned in the configuration section under dbmodules.',
                'experience' => 'advanced',
            },
            'ldap_conns_per_server' => {
                type         => 'leaf',
                value_type   => 'integer',
                default      => '5',
                description  => 'This LDAP specific tag indicates the number of connections to be maintained per LDAP server. This value is used if the number of connections per LDAP server are not mentioned in the configuration section under dbmodules. The default value is 5.',
                'experience' => 'advanced',
            },

        ],
    ],
];

