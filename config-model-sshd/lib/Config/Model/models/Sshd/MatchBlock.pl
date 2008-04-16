[
          {
            'name' => 'Sshd::MatchBlock',
            'element' => [
                           'User',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Sshd::MatchElement'
                                        },
                             'type' => 'hash',
                             'description' => 'Define a conditional block. The key of this "hash" is a pattern that is tested against user name. If the pattern matches, the properties defined in the content of this hash will override the proerties defined in the main sshd_config part.
',
                             'index_type' => 'string'
                           }
                         ]
          }
        ]
;
