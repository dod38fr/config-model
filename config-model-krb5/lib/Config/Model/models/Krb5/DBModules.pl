[
          {
            'name' => 'Krb5::DBModules',
            'element' => [
                           'configurations',
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
