[
          {
            'name' => 'Debian::Dpkg::Source',
            'element' => [
                           'format',
                           {
                             'value_type' => 'uniline',
                             'warn_unless_match' => {
                                                      '/\\w/' => {
                                                                'msg' => 'Empty source/format file. ',
                                                                'fix' => '$_ = "3.0 (quilt)" ;'
                                                              }
                                                    },
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
