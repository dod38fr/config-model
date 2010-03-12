[
          {
            'name' => 'Krb5::DBModules::ConfigSection',
            'element' => [
                           'db_library',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'This tag indicates the name of the loadable database library. The value should be db2 for db2 database and kldap for LDAP database.'
                           },
                           'ldap_kerberos_container_dn',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'This LDAP specific tag indicates the DN of the container object where the realm objects will be located.'
                           },
                           'ldap_kdc_dn',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'This LDAP specific tag indicates the bind DN for the KDC server. The KDC does a login to the directory as this object.'
                           },
                           'ldap_kadmind_dn',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'This LDAP specific tag indicates the bind DN for the Administration server. The Administration server does a login to the directory as this object.'
                           },
                           'ldap_service_password_file',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'This LDAP specific tag indicates the file containing the stashed passwords for the objects used for starting the Kerberos servers.'
                           },
                           'ldap_servers',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'This LDAP specific tag indicates the list of LDAP servers. The list of LDAP servers is whitespace-separated. The LDAP server is specified by a LDAP URI.'
                           },
                           'ldap_conns_per_server',
                           {
                             'value_type' => 'integer',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'This LDAP specific tag indicates the number of connections to be maintained per LDAP server.'
                           }
                         ]
          }
        ]
;
