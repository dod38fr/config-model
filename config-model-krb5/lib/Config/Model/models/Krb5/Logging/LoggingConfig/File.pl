[
          {
            'name' => 'Krb5::Logging::LoggingConfig::File',
            'element' => [
                           'append',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf',
                             'description' => 'Append to log file.'
                           },
                           'filename',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Filename for logging messages.'
                           }
                         ]
          }
        ]
;
