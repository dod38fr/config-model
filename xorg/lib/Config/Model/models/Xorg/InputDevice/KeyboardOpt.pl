[
          {
            'name' => 'Xorg::InputDevice::KeyboardOpt::AutoRepeat',
            'element' => [
                           'delay',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '500',
                             'type' => 'leaf',
                             'description' => 'time in milliseconds before a key starts repeating'
                           },
                           'rate',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '30',
                             'type' => 'leaf',
                             'description' => 'number of times a key repeats per second'
                           }
                         ]
          },
          {
            'name' => 'Xorg::InputDevice::KeyboardOpt',
            'include' => [
                           'Xorg::InputDevice::KeyboardOptRules'
                         ],
            'element' => [
                           'Protocol',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 'Standard',
                             'type' => 'leaf',
                             'description' => 'Specify the keyboard protocol. Not all protocols are supported on all platforms.',
                             'choice' => [
                                           'Standard',
                                           'Xqueue'
                                         ]
                           },
                           'AutoRepeat',
                           {
                             'type' => 'node',
                             'description' => 'sets the auto repeat behaviour for the keyboard. This is not implemented on all platforms.',
                             'config_class_name' => 'Xorg::InputDevice::KeyboardOpt::AutoRepeat'
                           },
                           'XLeds',
                           {
                             'cargo' => {
                                          'value_type' => 'integer',
                                          'min' => 1,
                                          'max' => 3,
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
                             'description' => 'makes the keyboard LEDs specified available for client  use instead of their traditional function (Scroll Lock, Caps Lock and Num Lock). The numbers are in the range 1 to 3.'
                           },
                           'XkbDisable',
                           {
                             'value_type' => 'boolean',
                             'status' => 'deprecated',
                             'upstream_default' => 0,
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
