[
          {
            'name' => 'Xorg::InputDevice',
            'element' => [
                           'Driver',
                           {
                             'value_type' => 'enum',
                             'replace' => {
                                            'keyboard' => 'kbd'
                                          },
                             'mandatory' => 1,
                             'type' => 'leaf',
                             'description' => 'name of the driver to use for this input device',
                             'choice' => [
                                           'kbd',
                                           'mouse'
                                         ]
                           },
                           'SendCoreEvents',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf',
                             'description' => 'when enabled cause the input  device  to  always report core events.  This can be used, for example, to allow an additional pointer device  to  generate core pointer events (like moving the cursor, etc).'
                           },
                           'HistorySize',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf',
                             'description' => 'when enabled cause the input  device  to  always report core events.  This can be used, for example, to allow an additional pointer device  to  generate core pointer events (like moving the cursor, etc).'
                           },
                           'Option',
                           {
                             'follow' => {
                                           'f1' => '- Driver'
                                         },
                             'type' => 'warped_node',
                             'rules' => [
                                          '$f1 eq \'kbd\'',
                                          {
                                            'config_class_name' => 'Xorg::InputDevice::KeyboardOpt'
                                          },
                                          '$f1 eq \'mouse\'',
                                          {
                                            'config_class_name' => 'Xorg::InputDevice::MouseOpt'
                                          }
                                        ]
                           }
                         ]
          }
        ]
;
