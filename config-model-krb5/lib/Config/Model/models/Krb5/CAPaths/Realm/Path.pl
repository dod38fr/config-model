[
          {
            'name' => 'Krb5::CAPaths::Realm::Path',
            'element' => [
                           'realm',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Realm name.'
                           },
                           'intermediate',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Intermediate realm which may participate in the cross-realm authentication.'
                           }
                         ]
          }
        ]
;
