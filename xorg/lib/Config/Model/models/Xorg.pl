[
          {
            'class_description' => 'Top level Xorg configuration.',
            'name' => 'Xorg',
            'include' => [
                           'Xorg::ConfigDir'
                         ],
            'element' => [
                           'Files',
                           {
                             'type' => 'node',
                             'description' => 'File pathnames',
                             'config_class_name' => 'Xorg::Files'
                           },
                           'Module',
                           {
                             'type' => 'node',
                             'description' => 'Dynamic module loading',
                             'config_class_name' => 'Xorg::Module'
                           },
                           'CorePointer',
                           {
                             'value_type' => 'reference',
                             'type' => 'leaf',
                             'description' => 'name of the core (primary) keyboard device',
                             'refer_to' => '! InputDevice'
                           },
                           'CoreKeyboard',
                           {
                             'value_type' => 'reference',
                             'type' => 'leaf',
                             'description' => 'name of the core (primary) keyboard device',
                             'refer_to' => '! InputDevice'
                           },
                           'InputDevice',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Xorg::InputDevice'
                                        },
                             'default_with_init' => {
                                                      'mouse' => 'Driver=mouse',
                                                      'kbd' => 'Driver=keyboard'
                                                    },
                             'type' => 'hash',
                             'description' => 'Input device(s) description',
                             'index_type' => 'string'
                           },
                           'MultiHead',
                           {
                             'value_type' => 'boolean',
                             'level' => 'important',
                             'default' => 0,
                             'type' => 'leaf',
                             'description' => 'Set this to one if you plan to use more than 1 display'
                           },
                           'Monitor',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Xorg::Monitor'
                                        },
                             'type' => 'hash',
                             'description' => 'Monitor description',
                             'index_type' => 'string'
                           },
                           'Device',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Xorg::Device'
                                        },
                             'type' => 'hash',
                             'description' => 'Graphics device description',
                             'index_type' => 'string'
                           },
                           'Modes',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Xorg::Monitor::Mode'
                                        },
                             'type' => 'hash',
                             'description' => 'Video modes descriptions',
                             'index_type' => 'string'
                           },
                           'Screen',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Xorg::Screen'
                                        },
                             'type' => 'hash',
                             'description' => 'Screen configuration',
                             'index_type' => 'string'
                           },
                           'ServerLayout',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Xorg::ServerLayout'
                                        },
                             'type' => 'hash',
                             'description' => 'represents the binding of one or more screens
       (Screen sections) and one or more input devices (InputDevice
       sections) to form a complete configuration.',
                             'index_type' => 'string'
                           },
                           'ServerFlags',
                           {
                             'type' => 'node',
                             'description' => 'Server flags used to specify some global Xorg server options.',
                             'config_class_name' => 'Xorg::ServerFlags'
                           },
                           'DRI',
                           {
                             'type' => 'node',
                             'description' => 'DRI-specific configuration',
                             'config_class_name' => 'Xorg::DRI'
                           },
                           'Extensions',
                           {
                             'type' => 'node',
                             'description' => 'DRI-specific configuration',
                             'config_class_name' => 'Xorg::Extensions'
                           }
                         ]
          },
          {
            'name' => 'Xorg::DRI',
            'element' => [
                           'Mode',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'DRI mode, usually set to 0666'
                           }
                         ]
          }
        ]
;
