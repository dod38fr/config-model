[
          {
            'name' => 'Krb5::Logging::LoggingConfig::Syslog',
            'element' => [
                           'severity',
                           {
                             'value_type' => 'enum',
                             'experience' => 'advanced',
                             'default' => 'ERR',
                             'type' => 'leaf',
                             'description' => 'Specifies the default severity of system log messages.',
                             'choice' => [
                                           'EMERG',
                                           'ALERT',
                                           'CRIT',
                                           'ERR',
                                           'WARNING',
                                           'NOTICE',
                                           'INFO',
                                           'DEBUG'
                                         ]
                           },
                           'facility',
                           {
                             'value_type' => 'enum',
                             'experience' => 'advanced',
                             'default' => 'AUTH',
                             'type' => 'leaf',
                             'description' => 'Specifies the facility under which the messages are logged.',
                             'choice' => [
                                           'KERN',
                                           'USER',
                                           'MAIL',
                                           'DAEMON',
                                           'AUTH',
                                           'LPR',
                                           'NEWS',
                                           'UUCP',
                                           'CRON',
                                           'LOCAL0',
                                           'LOCAL1',
                                           'LOCAL2',
                                           'LOCAL3',
                                           'LOCAL4',
                                           'LOCAL5',
                                           'LOCAL6',
                                           'LOCAL7'
                                         ]
                           }
                         ]
          }
        ]
;
