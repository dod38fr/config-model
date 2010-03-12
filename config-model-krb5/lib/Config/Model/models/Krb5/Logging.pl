[
          {
            'name' => 'Krb5::Logging',
            'element' => [
                           'kdc',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Krb5::Logging::LoggingConfig'
                                        },
                             'experience' => 'advanced',
                             'type' => 'list',
                             'description' => 'Specifies how the KDC is to perform its logging.'
                           },
                           'admin_server',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Krb5::Logging::LoggingConfig'
                                        },
                             'experience' => 'advanced',
                             'type' => 'list',
                             'description' => 'Specifies how the administrative server is to perform its logging.'
                           },
                           'default',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Krb5::Logging::LoggingConfig'
                                        },
                             'experience' => 'advanced',
                             'type' => 'list',
                             'description' => 'Specifies how to perform logging in the absence of explicit specifications otherwise.'
                           }
                         ]
          }
        ]
;
