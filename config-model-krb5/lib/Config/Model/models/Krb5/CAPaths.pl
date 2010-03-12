[
          {
            'name' => 'Krb5::CAPaths',
            'element' => [
                           'realms',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Krb5::CAPaths::Realm'
                                        },
                             'experience' => 'advanced',
                             'type' => 'hash',
                             'description' => 'Realm participating in cross-realm authentication.',
                             'index_type' => 'string'
                           }
                         ]
          }
        ]
;
