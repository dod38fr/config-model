[
          {
            'name' => 'Ssh::HostBlock',
            'element' => [
                           'patterns',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
                             'description' => 'Specify a pattern that will be compared to the hostname argument given on the command line (i.e. the name is not converted to a canonicalized host name before matching). A single `*\' as a pattern can be used to provide global defaults for all hosts. All parameters specifed in the sub-tree will apply only to the hosts that match this pattern.
'
                           },
                           'block',
                           {
                             'type' => 'node',
                             'description' => 'Specifies the parameters that apply to the host that match one of the pattern given above',
                             'config_class_name' => 'Ssh::HostElement'
                           }
                         ]
          }
        ]
;
