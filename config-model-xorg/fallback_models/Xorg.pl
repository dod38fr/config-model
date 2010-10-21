# Generated file. Do not edit

[
          [
            'name',
            'Xorg::InputDevice::KeyboardOptModel::Xorg',
            'generated_by',
            'Config::Model Build.PL',
            'element',
            [
              'eurosign',
              {
                'value_type' => 'enum',
                'help' => {
                            'e' => 'Add the EuroSign to the E key.',
                            '2' => 'Add the EuroSign to the 2 key.',
                            '5' => 'Add the EuroSign to the 5 key.'
                          },
                'type' => 'leaf',
                'choice' => [
                              'e',
                              '5',
                              '2'
                            ]
              },
              'numpad',
              {
                'value_type' => 'enum',
                'help' => {
                            'microsoft' => 'Shift with numpad keys works as in MS Windows.'
                          },
                'type' => 'leaf',
                'choice' => [
                              'microsoft'
                            ]
              },
              'grp_led',
              {
                'value_type' => 'enum',
                'help' => {
                            'scroll' => 'ScrollLock LED shows alternative group.',
                            'num' => 'NumLock LED shows alternative group.',
                            'caps' => 'CapsLock LED shows alternative group.'
                          },
                'type' => 'leaf',
                'choice' => [
                              'num',
                              'caps',
                              'scroll'
                            ]
              },
              'altwin',
              {
                'value_type' => 'enum',
                'help' => {
                            'alt_super_win' => 'Alt is mapped to the right Win-key and Super to Menu.',
                            'meta_alt' => 'Alt and Meta are on the Alt keys (default).',
                            'super_win' => 'Super is mapped to the Win-keys (default).',
                            'left_meta_win' => 'Meta is mapped to the left Win-key.',
                            'menu' => 'Add the standard behavior to Menu key.',
                            'hyper_win' => 'Hyper is mapped to the Win-keys.',
                            'meta_win' => 'Meta is mapped to the Win-keys.'
                          },
                'type' => 'leaf',
                'choice' => [
                              'menu',
                              'meta_alt',
                              'meta_win',
                              'left_meta_win',
                              'super_win',
                              'hyper_win',
                              'alt_super_win'
                            ]
              },
              'caps',
              {
                'value_type' => 'enum',
                'help' => {
                            'shiftlock' => 'CapsLock toggles Shift so all keys are affected.',
                            'shift_lock' => 'CapsLock just locks the Shift modifier.',
                            'shift_nocancel' => 'CapsLock acts as Shift with locking. Shift doesn\'t cancel CapsLock.',
                            'capslock' => 'CapsLock toggles normal capitalization of alphabetic characters.',
                            'shift' => 'CapsLock acts as Shift with locking. Shift cancels CapsLock.',
                            'internal_nocancel' => 'CapsLock uses internal capitalization. Shift doesn\'t cancel CapsLock.',
                            'internal' => 'CapsLock uses internal capitalization. Shift cancels CapsLock.'
                          },
                'type' => 'leaf',
                'choice' => [
                              'internal',
                              'internal_nocancel',
                              'shift',
                              'shift_nocancel',
                              'shift_lock',
                              'capslock',
                              'shiftlock'
                            ]
              },
              'ctrl',
              {
                'value_type' => 'enum',
                'help' => {
                            'ctrl_aa' => 'Control key at bottom left',
                            'nocaps' => 'Make CapsLock an additional Control.',
                            'ctrl_ra' => 'Right Control key works as Right Alt.',
                            'swapcaps' => 'Swap Control and CapsLock.',
                            'ctrl_ac' => 'Control key at left of \'A\''
                          },
                'type' => 'leaf',
                'choice' => [
                              'nocaps',
                              'swapcaps',
                              'ctrl_ac',
                              'ctrl_aa',
                              'ctrl_ra'
                            ]
              },
              'srvrkeys',
              {
                'value_type' => 'enum',
                'help' => {
                            'none' => 'Special keys (Ctrl+Alt+&lt;key&gt;) handled in a server.'
                          },
                'type' => 'leaf',
                'choice' => [
                              'none'
                            ]
              },
              'grp',
              {
                'value_type' => 'enum',
                'help' => {
                            'sclk_toggle' => 'Scroll Lock changes group',
                            'ctrl_shift_toggle' => 'Control+Shift changes group.',
                            'win_switch' => 'Both Win-keys switch group while pressed.',
                            'menu_toggle' => 'Menu key changes group.',
                            'rwin_switch' => 'Right Win-key switches group while pressed.',
                            'rwin_toggle' => 'Right Win-key changes group.',
                            'ctrl_alt_toggle' => 'Alt+Control changes group.',
                            'lwin_toggle' => 'Left Win-key changes group.',
                            'rctrl_switch' => 'Right Ctrl key switches group while pressed.',
                            'lshift_toggle' => 'Left Shift key changes group.',
                            'lctrl_toggle' => 'Left Ctrl key changes group.',
                            'lwin_switch' => 'Left Win-key switches group while pressed.',
                            'shift_caps_toggle' => 'Shift+CapsLock changes group.',
                            'ctrls_toggle' => 'Both Ctrl keys together change group.',
                            'rshift_toggle' => 'Right Shift key changes group.',
                            'toggle' => 'Right Alt key changes group.',
                            'caps_toggle' => 'CapsLock key changes group.',
                            'switch' => 'R-Alt switches group while pressed.',
                            'alt_shift_toggle' => 'Alt+Shift changes group.',
                            'lalt_toggle' => 'Left Alt key changes group.',
                            'alts_toggle' => 'Both Alt keys together change group.',
                            'rctrl_toggle' => 'Right Ctrl key changes group.',
                            'lswitch' => 'Left Alt key switches group while pressed.',
                            'shifts_toggle' => 'Both Shift keys together change group.'
                          },
                'type' => 'leaf',
                'choice' => [
                              'switch',
                              'lswitch',
                              'lwin_switch',
                              'rwin_switch',
                              'win_switch',
                              'rctrl_switch',
                              'toggle',
                              'lalt_toggle',
                              'caps_toggle',
                              'shift_caps_toggle',
                              'shifts_toggle',
                              'alts_toggle',
                              'ctrls_toggle',
                              'ctrl_shift_toggle',
                              'ctrl_alt_toggle',
                              'alt_shift_toggle',
                              'menu_toggle',
                              'lwin_toggle',
                              'rwin_toggle',
                              'sclk_toggle',
                              'lshift_toggle',
                              'rshift_toggle',
                              'lctrl_toggle',
                              'rctrl_toggle'
                            ]
              },
              'lv3',
              {
                'value_type' => 'enum',
                'help' => {
                            'ralt_switch' => 'Press Right Alt key to choose 3rd level.',
                            'win_switch' => 'Press any of Win-keys to choose 3rd level.',
                            'lwin_switch' => 'Press Left Win-key to choose 3rd level.',
                            'rwin_switch' => 'Press Right Win-key to choose 3rd level.',
                            'ralt_switch_multikey' => 'Press Right Alt key to choose 3rd level, Shift+Right Alt key is Multi_Key',
                            'lalt_switch' => 'Press Left Alt key to choose 3rd level.',
                            'menu_switch' => 'Press Menu key to choose 3rd level.',
                            'switch' => 'Press Right Control to choose 3rd level.',
                            'alt_switch' => 'Press any of Alt keys to choose 3rd level.'
                          },
                'type' => 'leaf',
                'choice' => [
                              'switch',
                              'menu_switch',
                              'win_switch',
                              'lwin_switch',
                              'rwin_switch',
                              'alt_switch',
                              'lalt_switch',
                              'ralt_switch',
                              'ralt_switch_multikey'
                            ]
              },
              'compose',
              {
                'value_type' => 'enum',
                'help' => {
                            'rwin' => 'Right Win-key is Compose.',
                            'ralt' => 'Right Alt is Compose.',
                            'caps' => 'Caps Lock is Compose',
                            'menu' => 'Menu is Compose.',
                            'rctrl' => 'Right Ctrl is Compose.'
                          },
                'type' => 'leaf',
                'choice' => [
                              'ralt',
                              'rwin',
                              'menu',
                              'rctrl',
                              'caps'
                            ]
              }
            ],
            'description',
            []
          ]
        ]
