[
          {
            'level' => [
                         'AcceptEnv',
                         'normal',
                         'AddressFamily',
                         'normal',
                         'AuthorizedKeysFile',
                         'normal'
                       ],
            'status' => [
                          'AcceptEnv',
                          'standard',
                          'AddressFamily',
                          'standard',
                          'AuthorizedKeysFile',
                          'standard'
                        ],
            'name' => 'Sshd',
            'permission' => [
                              'AcceptEnv',
                              'intermediate',
                              'AddressFamily',
                              'intermediate',
                              'AuthorizedKeysFile',
                              'intermediate'
                            ],
            'include' => 'Sshd::MatchElement',
            'description' => [
                               'AcceptEnv',
                               "Specifies what environment variables sent by the client will be copied into the session\x{2019}s environ(7).
",
                               'AddressFamily',
                               '',
                               'AuthorizedKeysFile',
                               'Specifies the file that contains the public keys that can be used for user authentication. AuthorizedKeysFile may contain tokens of the form %T which are substituted during connection setup.
'
                             ],
            'element' => [
                           'AcceptEnv',
                           {
                             'type' => 'list',
                             'cargo_type' => 'leaf'
                           },
                           'AddressFamily',
                           {
                             'value_type' => 'enum',
                             'built_in' => 'any',
                             'type' => 'leaf',
                             'choice' => [
                                           'any',
                                           'inet',
                                           'inet6'
                                         ]
                           },
                           'AuthorizedKeysFile',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
