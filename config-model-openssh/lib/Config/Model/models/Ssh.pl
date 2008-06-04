[
          {
            'class_description' => 'Model of /etc/ssh/ssh_config or ~/.ssh/config',
            'name' => 'Ssh',
            'element' => [
                           'Host',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Ssh::HostBlock'
                                        },
                             'type' => 'list',
                             'description' => "The declarations make in 'parameters' are applied only to the hosts that match one of the patterns given in pattern elements. A single \x{2018}*\x{2019} as a pattern can be used to provide global defaults for all hosts. The host is the hostname argument given on the command line (i.e. the name is not converted to a canonicalized host name before matching)."
                           }
                         ]
          }
        ]
;
