[
          {
            'name' => 'Debian::Dpkg::Control',
            'element' => [
                           'source',
                           {
                             'summary' => 'package source description',
                             'type' => 'node',
                             'config_class_name' => 'Debian::Dpkg::Control::Source'
                           },
                           'binary',
                           {
                             'summary' => 'package binary description',
                             'type' => 'node',
                             'config_class_name' => 'Debian::Dpkg::Control::Binary'
                           }
                         ]
          }
        ]
;
