# Generated file. Do not edit

[
          [
            'name',
            'Xorg::InputDevice::KeyboardOptModel::Sun',
            'generated_by',
            'Config::Model Build.PL',
            'element',
            [
              'lock',
              {
                'value_type' => 'enum',
                'help' => {
                            'group' => 'Key is group lock',
                            'shift' => 'Key is shift lock',
                            'caps' => 'Key is captals lock'
                          },
                'type' => 'leaf',
                'choice' => [
                              'shift',
                              'caps',
                              'group'
                            ]
              },
              'grp',
              {
                'value_type' => 'enum',
                'help' => {
                            'ctrl_alt_toggle' => 'Pressing alt and control together toggles group',
                            'caps_toggle' => 'Caps Lock key toggles group',
                            'ctrl_shift_toggle' => 'Pressing shift and control together toggles group',
                            'toggle' => 'Pressing Right Alt key toggles group',
                            'shift_toggle' => 'Pressing both shift keys together toggles group',
                            'switch' => 'Right Alt key switches group while held down'
                          },
                'type' => 'leaf',
                'choice' => [
                              'switch',
                              'toggle',
                              'shift_toggle',
                              'ctrl_shift_toggle',
                              'ctrl_alt_toggle',
                              'caps_toggle'
                            ]
              },
              'ctrl',
              {
                'value_type' => 'enum',
                'help' => {
                            'ctrl_aa' => 'Control key is at the left of the bottom row',
                            'nocaps' => 'Replace Caps Lock with another control key',
                            'swapcaps' => 'Swap positions of control and Caps Lock',
                            'ctrl_ac' => 'Control key is left of the \'A\' key'
                          },
                'type' => 'leaf',
                'choice' => [
                              'nocaps',
                              'swapcaps',
                              'ctrl_ac',
                              'ctrl_aa'
                            ]
              }
            ],
            'description',
            []
          ]
        ]
