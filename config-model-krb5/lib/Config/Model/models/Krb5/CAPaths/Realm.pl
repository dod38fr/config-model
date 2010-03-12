[
          {
            'name' => 'Krb5::CAPaths::Realm',
            'element' => [
                           'paths',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Krb5::CAPaths::Realm::Path'
                                        },
                             'experience' => 'advanced',
                             'type' => 'list',
                             'description' => 'Intermediate realm which may participate in the cross-realm authentication.'
                           }
                         ]
          }
        ]
;
