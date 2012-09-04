[
          {
            'name' => 'MyFstab::Iso9660_Opt',
            'include' => [
                           'MyFstab::CommonOptions'
                         ],
            'element' => [
                           'rock',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           },
                           'joliet',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
