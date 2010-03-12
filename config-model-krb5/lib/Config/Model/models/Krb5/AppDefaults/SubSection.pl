[
          {
            'name' => 'Krb5::AppDefaults::SubSection',
            'element' => [
                           'subsection',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Krb5::AppDefaults::SecondLevelSubSection'
                                        },
                             'experience' => 'advanced',
                             'type' => 'hash',
                             'description' => 'Kerberos V5 application or realm.',
                             'index_type' => 'string'
                           },
                           'option',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Krb5::AppDefaults::Option'
                                        },
                             'experience' => 'advanced',
                             'type' => 'list',
                             'description' => 'Option that is used by some Kerberos V5 application[s].'
                           }
                         ]
          }
        ]
;
