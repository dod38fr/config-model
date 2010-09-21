[
          {
            'name' => 'Debian::Dpkg::Control::Binary',
            'element' => [
                           'Package',
                           {
                             'value_type' => 'uniline',
                             'summary' => 'binary package name',
                             'match' => '\\w[\\w+\\-\\.]{1,}',
                             'mandatory' => '1',
                             'type' => 'leaf'
                           },
                           'Architecture',
                           {
                             'value_type' => 'uniline',
                             'mandatory' => '1',
                             'type' => 'leaf'
                           },
                           'Section',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf'
                           },
                           'Priority',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf'
                           },
                           'Essential',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           },
                           'Depends',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list'
                           },
                           'Description',
                           {
                             'value_type' => 'string',
                             'mandatory' => '1',
                             'type' => 'leaf'
                           },
                           'Homepage',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
