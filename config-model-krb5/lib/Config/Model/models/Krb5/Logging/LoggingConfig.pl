[
          {
            'name' => 'Krb5::Logging::LoggingConfig',
            'element' => [
                           'logging_type',
                           {
                             'value_type' => 'enum',
                             'help' => {
                                         'FILE' => 'This value causes the entity\'s logging messages to go to the specified file',
                                         'STDERR' => 'This value causes the entity\'s logging messages to go to its standard error stream.',
                                         'CONSOLE' => 'This value causes the entity\'s logging messages to go to the console, if the system supports it.',
                                         'DEVICE' => 'This causes the entity\'s logging messages to go to the specified device.',
                                         'SYSLOG' => 'This causes the entity\'s logging messages to go to the system log.'
                                       },
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies whether remote hosts are allowed to connect to ports forwarded for the client. By default, sshd(8) binds remote port forwardings to the loopback address. This prevents other remote hosts from connecting to forwarded ports. GatewayPorts can be used to specify that sshd should allow remote port forwardings to bind to non-loopback addresses, thus allowing other hosts to connect.',
                             'choice' => [
                                           'FILE',
                                           'STDERR',
                                           'CONSOLE',
                                           'DEVICE',
                                           'SYSLOG'
                                         ]
                           },
                           'logging_config',
                           {
                             'follow' => {
                                           'f1' => '- logging_type'
                                         },
                             'experience' => 'advanced',
                             'type' => 'warped_node',
                             'rules' => [
                                          '$f1 eq \'FILE\'',
                                          {
                                            'config_class_name' => 'Krb5::Logging::LoggingConfig::File'
                                          },
                                          '$f1 eq \'STDERR\'',
                                          {
                                            'config_class_name' => 'Krb5::Logging::LoggingConfig::StdErr'
                                          },
                                          '$f1 eq \'CONSOLE\'',
                                          {
                                            'config_class_name' => 'Krb5::Logging::LoggingConfig::Console'
                                          },
                                          '$f1 eq \'DEVICE\'',
                                          {
                                            'config_class_name' => 'Krb5::Logging::LoggingConfig::Device'
                                          },
                                          '$f1 eq \'SYSLOG\'',
                                          {
                                            'config_class_name' => 'Krb5::Logging::LoggingConfig::Syslog'
                                          }
                                        ]
                           }
                         ]
          }
        ]
;
