[
          {
            'name' => 'Ssh::HostBlock',
            'element' => [
                           'pattern',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Ssh::HostElement'
                                        },
                             'type' => 'hash',
                             'description' => 'Specify a pattern that will be compared to the hostname argument given on the command line (i.e. the name is not converted to a canonicalized host name before matching). A single `*\' as a pattern can be used to provide global defaults for all hosts. All parameters specifed in the sub-tree will apply only to the hosts that match this pattern.
',
                             'index_type' => 'string'
                           }
                         ]
          }
        ]
;
