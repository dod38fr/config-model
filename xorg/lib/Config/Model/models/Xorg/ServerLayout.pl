[
          {
            'name' => 'Xorg::ServerLayout',
            'element' => [
                           'Screen',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Xorg::ServerLayout::Screen'
                                        },
                             'type' => 'list',
                             'description' => 'One of these entries must be given for each screen
              being used in a session.  The screen-id field is
              mandatory, and specifies the Screen section being
              referenced. ',
                             'auto_create_ids' => 1
                           },
                           'InputDevice',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Xorg::ServerLayout::InputDevice'
                                        },
                             'allow_keys_from' => '! InputDevice',
                             'default_keys' => [
                                                 'kbd',
                                                 'mouse'
                                               ],
                             'type' => 'hash',
                             'description' => 'One of these entries should be given for each
      input device being used in a session.  Normally at least two are
      required, one each for the core pointer and keyboard devices.',
                             'index_type' => 'string'
                           }
                         ]
          },
          {
            'name' => 'Xorg::ServerLayout::Screen',
            'element' => [
                           'screen_id',
                           {
                             'value_type' => 'reference',
                             'type' => 'leaf',
                             'refer_to' => '! Screen'
                           },
                           'position',
                           {
                             'type' => 'node',
                             'config_class_name' => 'Xorg::ServerLayout::ScreenPosition'
                           }
                         ]
          },
          {
            'name' => 'Xorg::ServerLayout::ScreenPosition',
            'element' => [
                           'relative_screen_location',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'choice' => [
                                           'Absolute',
                                           'RightOf',
                                           'LeftOf',
                                           'Above',
                                           'Below',
                                           'Relative'
                                         ]
                           },
                           'screen_id',
                           {
                             'value_type' => 'reference',
                             'level' => 'hidden',
                             'warp' => {
                                         'follow' => {
                                                       'f1' => '- relative_screen_location'
                                                     },
                                         'rules' => [
                                                      '$f1 eq \'RightOf\' or $f1 eq \'LeftOf\' or $f1 eq \'Above\' or $f1 eq \'Below\' or $f1 eq \'Relative\'',
                                                      {
                                                        'level' => 'normal',
                                                        'mandatory' => 1
                                                      }
                                                    ]
                                       },
                             'type' => 'leaf',
                             'refer_to' => '! Screen'
                           },
                           'x',
                           {
                             'value_type' => 'integer',
                             'level' => 'hidden',
                             'warp' => {
                                         'follow' => {
                                                       'f1' => '- relative_screen_location'
                                                     },
                                         'rules' => [
                                                      '$f1 eq \'Absolute\' or $f1 eq \'Relative\'',
                                                      {
                                                        'level' => 'normal',
                                                        'mandatory' => 1
                                                      }
                                                    ]
                                       },
                             'type' => 'leaf'
                           },
                           'y',
                           {
                             'value_type' => 'integer',
                             'level' => 'hidden',
                             'warp' => {
                                         'follow' => {
                                                       'f1' => '- relative_screen_location'
                                                     },
                                         'rules' => [
                                                      '$f1 eq \'Absolute\' or $f1 eq \'Relative\'',
                                                      {
                                                        'level' => 'normal',
                                                        'mandatory' => 1
                                                      }
                                                    ]
                                       },
                             'type' => 'leaf'
                           }
                         ]
          },
          {
            'class_description' => 'Specifies InputDevice options',
            'name' => 'Xorg::ServerLayout::InputDevice',
            'element' => [
                           'SendCoreEvents',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
