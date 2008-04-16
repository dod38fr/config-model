[
          {
            'name' => 'Sshd',
            'include' => [
                           'Sshd::MatchElement'
                         ],
            'element' => [
                           'AcceptEnv',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
                             'description' => "Specifies what environment variables sent by the client will be copied into the session\x{2019}s environ(7).
"
                           },
                           'AddressFamily',
                           {
                             'value_type' => 'enum',
                             'built_in' => 'any',
                             'type' => 'leaf',
                             'description' => 'Specifies which address family should be used by sshd(8).
',
                             'choice' => [
                                           'any',
                                           'inet',
                                           'inet6'
                                         ]
                           },
                           'AllowGroups',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
                             'description' => 'Login is allowed only for users whose primary group or supplementary group list matches one of the patterns. Only group names are valid; a numerical group ID is not recognized. By default, login is allowed for all groups. The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.
'
                           },
                           'AllowUsers',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
                             'description' => 'Login is allowed only for users whose primary group or supplementary group list matches one of the patterns. Only group names are valid; a numerical group ID is not recognized. By default, login is allowed for all groups. The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.
'
                           },
                           'AuthorizedKeysFile',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Specifies the file that contains the public keys that can be used for user authentication. AuthorizedKeysFile may contain tokens of the form %T which are substituted during connection setup.
'
                           },
                           'ChallengeResponseAuthentication',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '1',
                             'type' => 'leaf',
                             'description' => 'Specifies whether challenge-response authentication is allowed. All authentication styles from login.conf(5) are supported.
'
                           },
                           'Ciphers',
                           {
                             'type' => 'check_list',
                             'description' => 'Specifies the ciphers allowed for protocol version 2. By default, all ciphers are allowed.

',
                             'choice' => [
                                           '3des-cbc',
                                           'aes128-cbc',
                                           'aes192-cbc',
                                           'aes256-cbc',
                                           'aes128-ctr',
                                           'aes192-ctr',
                                           'aes256-ctr',
                                           'arcfour128',
                                           'arcfour256',
                                           'arcfour',
                                           'blowfish-cbc',
                                           'cast128-cbc'
                                         ]
                           },
                           'ClientAliveCheck',
                           {
                             'value_type' => 'boolean',
                             'default' => '0',
                             'type' => 'leaf',
                             'description' => 'Check if client is alive by sending client alive messages
'
                           },
                           'ClientAliveInterval',
                           {
                             'value_type' => 'integer',
                             'level' => 'hidden',
                             'min' => '1',
                             'warp' => {
                                         'follow' => {
                                                       'c_a_check' => '- ClientAliveCheck'
                                                     },
                                         'rules' => [
                                                      '$c_a_check == 1',
                                                      {
                                                        'level' => 'normal'
                                                      }
                                                    ]
                                       },
                             'type' => 'leaf'
                           },
                           'Match',
                           {
                             'type' => 'node',
                             'config_class_name' => 'Sshd::MatchBlock'
                           }
                         ]
          }
        ]
;
