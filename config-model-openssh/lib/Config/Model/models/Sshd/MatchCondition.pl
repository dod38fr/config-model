[
          {
            'name' => 'Sshd::MatchCondition',
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
                           }
                         ]
          }
        ]
;
