[
          {
            'name' => 'Sshd::MatchBlock',
            'element' => [
                           'User',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Define the User criteria of a conditional block. The value of this field is a pattern that is tested against user name.'
                           },
                           'Group',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Define the Group criteria of a conditional block. The value of this field is a pattern that is tested against group name.'
                           },
                           'Host',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Define the Host criteria of a conditional block. The value of this field is a pattern that is tested against host name.'
                           },
                           'Address',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Define the Address criteria of a conditional block. The value of this field is a pattern that is tested against the address of the incoming connection.'
                           },
                           'Elements',
                           {
                             'type' => 'node',
                             'description' => 'Defines the sshd_config parameters that will override general settings when all defined User, Group, Host and Address patterns match.',
                             'config_class_name' => 'Sshd::MatchElement'
                           }
                         ]
          }
        ]
;
