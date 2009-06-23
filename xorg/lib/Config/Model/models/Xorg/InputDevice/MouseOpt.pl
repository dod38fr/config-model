[
          {
            'name' => 'Xorg::InputDevice::MouseOpt',
            'element' => [
                           'Device',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf'
                           },
                           'Protocol',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'choice' => [
                                           'auto',
                                           'PS/2',
                                           'ImPS/2',
                                           'IntelliMouse'
                                         ]
                           },
                           'Emulate3Buttons',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf'
                           },
                           'ZAxisMapping',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf'
                           },
                           'SendCoreEvents',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           },
                           'Buttons',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
