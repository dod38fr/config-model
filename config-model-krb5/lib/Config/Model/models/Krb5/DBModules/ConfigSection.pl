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
        name => "Krb5::DBModules::ConfigSection",

        'element' => [
            'db_library' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'This tag indicates the name of the loadable database library. The value should be db2 for db2 database and kldap for LDAP database.',
                'experience' => 'advanced',
            },

            'ldap_kerberos_container_dn' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'This LDAP specific tag indicates the DN of the container object where the realm objects will be located.',
                'experience' => 'advanced',
            },

            'ldap_kdc_dn' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'This LDAP specific tag indicates the bind DN for the KDC server. The KDC does a login to the directory as this object.',
                'experience' => 'advanced',
            },
            'ldap_kadmind_dn' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'This LDAP specific tag indicates the bind DN for the Administration server. The Administration server does a login to the directory as this object.',
                'experience' => 'advanced',
            },

            'ldap_service_password_file' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'This LDAP specific tag indicates the file containing the stashed passwords for the objects used for starting the Kerberos servers.',
                'experience' => 'advanced',
            },

            'ldap_servers' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'This LDAP specific tag indicates the list of LDAP servers. The list of LDAP servers is whitespace-separated. The LDAP server is specified by a LDAP URI.',
                'experience' => 'advanced',
            },
            'ldap_conns_per_server' => {
                type         => 'leaf',
                value_type   => 'integer',
                description  => 'This LDAP specific tag indicates the number of connections to be maintained per LDAP server.',
                'experience' => 'advanced',
            },

        ],
    ],
];

