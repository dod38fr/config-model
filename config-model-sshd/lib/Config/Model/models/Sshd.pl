[
          {
            'name' => 'Sshd',
            'description' => [
                               'AuthorizedKeysFile',
                               'Specifies the file that contains the public keys that can be used for user authentication. AuthorizedKeysFile may contain tokens of the form %T which are substituted during connection setup.
',
                               'AcceptEnv',
                               "Specifies what environment variables sent by the client will be copied into the session\x{2019}s environ(7).
"
                             ],
            'element' => [
                           'AuthorizedKeysFile',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf'
                           },
                           'AcceptEnv',
                           {
                             'value_type' => 'uniline',
                             'type' => 'list',
                             'cargo_type' => 'leaf'
                           }
                         ]
          }
        ]
;
