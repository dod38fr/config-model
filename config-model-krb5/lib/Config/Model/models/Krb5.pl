[
          {
            'class_description' => 'Copyright (c) 2008 Peter Knowles\\nReleased under LGPLv2+',
            'read_config' => [
                               {
                                 'function' => 'krb5_read',
                                 'backend' => 'custom',
                                 'class' => 'Config::Model::Krb5',
                                 'config_dir' => '/etc'
                               }
                             ],
            'name' => 'Krb5',
            'write_config' => [
                                {
                                  'function' => 'krb5_write',
                                  'backend' => 'custom',
                                  'class' => 'Config::Model::Krb5',
                                  'config_dir' => '/etc'
                                }
                              ],
            'element' => [
                           'libdefaults',
                           {
                             'type' => 'node',
                             'description' => 'Contains various default values used by the Kerberos V5 library.',
                             'config_class_name' => 'Krb5::LibDefaults'
                           },
                           'login',
                           {
                             'experience' => 'advanced',
                             'type' => 'node',
                             'description' => 'Contains default values used by the Kerberos V5 login program, login.krb5(8).',
                             'config_class_name' => 'Krb5::Login'
                           },
                           'appdefaults',
                           {
                             'experience' => 'advanced',
                             'type' => 'node',
                             'config_class_name' => 'Krb5::AppDefaults'
                           },
                           'realms',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Krb5::Realms'
                                        },
                             'type' => 'hash',
                             'description' => 'Contains subsections keyed by Kerberos realm names which describe where to find the Kerberos servers for a particular realm, and other realm-specific information.',
                             'index_type' => 'string'
                           },
                           'domain_realm',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'hash',
                             'description' => 'A mapping between a hostname or a domain name (where domain names are indicated by a prefix of a period () character) and a Kerberos realm.',
                             'index_type' => 'string'
                           },
                           'logging',
                           {
                             'experience' => 'advanced',
                             'type' => 'node',
                             'description' => 'Contains relations which determine how Kerberos entities are to perform their logging.',
                             'config_class_name' => 'Krb5::Logging'
                           },
                           'capaths',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Krb5::CAPaths::Realm'
                                        },
                             'experience' => 'advanced',
                             'type' => 'hash',
                             'description' => 'Realm participating in cross-realm authentication.',
                             'index_type' => 'string'
                           },
                           'dbdefaults',
                           {
                             'experience' => 'advanced',
                             'type' => 'node',
                             'description' => 'Contains default values for database specific parameters.',
                             'config_class_name' => 'Krb5::DBDefaults'
                           },
                           'dbmodules',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Krb5::DBModules::ConfigSection'
                                        },
                             'experience' => 'advanced',
                             'type' => 'hash',
                             'description' => 'Configuration section for database specific parameters that can be referred to by a realm.',
                             'index_type' => 'string'
                           }
                         ]
          }
        ]
;
