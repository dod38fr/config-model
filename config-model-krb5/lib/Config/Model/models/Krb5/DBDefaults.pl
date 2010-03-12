[
          {
            'name' => 'Krb5::DBDefaults',
            'element' => [
                           'database_module',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'This relation indicates the name of the configuration section under dbmodules for database specific parameters used by the loadable database library.'
                           },
                           'ldap_kerberos_container_dn',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'This LDAP specific tag indicates the DN of the container object where the realm objects will be located. This value is used if no object DN is mentioned in the configuration section under dbmodules.'
                           },
                           'ldap_kdc_dn',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'This LDAP specific tag indicates the default bind DN for the KDC server. The KDC server does a login to the directory as this object. This value is used if no object DN is mentioned in the configuration section under dbmodules.'
                           },
                           'ldap_kadmind_dn',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'This LDAP specific tag indicates the default bind DN for the Administration server. The Administration server does a login to the directory as this object. This value is used if no object DN is mentioned in the configuration section under dbmodules.'
                           },
                           'ldap_service_password_file',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'This LDAP specific tag indicates the file containing the stashed passwords for the objects used for starting the Kerberos servers. This value is used if no service password file is mentioned in the configuration section under dbmodules.'
                           },
                           'ldap_servers',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'This LDAP specific tag indicates the list of LDAP servers. The list of LDAP servers is whitespace-separated. The LDAP server is specified by a LDAP URI. This value is used if no LDAP servers are mentioned in the configuration section under dbmodules.'
                           },
                           'ldap_conns_per_server',
                           {
                             'value_type' => 'integer',
                             'experience' => 'advanced',
                             'default' => '5',
                             'type' => 'leaf',
                             'description' => 'This LDAP specific tag indicates the number of connections to be maintained per LDAP server. This value is used if the number of connections per LDAP server are not mentioned in the configuration section under dbmodules. The default value is 5.'
                           }
                         ]
          }
        ]
;
