[
          {
            'name' => 'Xorg::Device',
            'element' => [
                           'Driver',
                           {
                             'value_type' => 'enum',
                             'mandatory' => 1,
                             'type' => 'leaf',
                             'description' => 'name of the driver to use for this graphics device',
                             'choice' => [
                                           'radeon',
                                           'nvidia',
                                           'vesa'
                                         ]
                           },
                           'BusID',
                           {
                             'value_type' => 'uniline',
                             'warp' => {
                                         'follow' => {
                                                       'f1' => '! MultiHead'
                                                     },
                                         'rules' => [
                                                      '$f1 eq \'1\'',
                                                      {
                                                        'mandatory' => 1
                                                      }
                                                    ]
                                       },
                             'type' => 'leaf'
                           },
                           'Screen',
                           {
                             'value_type' => 'integer',
                             'warp' => {
                                         'follow' => {
                                                       'f1' => '! MultiHead'
                                                     },
                                         'rules' => [
                                                      '$f1 eq \'1\'',
                                                      {
                                                        'mandatory' => 1
                                                      }
                                                    ]
                                       },
                             'type' => 'leaf'
                           },
                           'Option',
                           {
                             'follow' => {
                                           'f1' => '- Driver'
                                         },
                             'type' => 'warped_node',
                             'rules' => [
                                          '$f1 eq \'radeon\'',
                                          {
                                            'config_class_name' => 'Xorg::Device::Radeon'
                                          },
                                          '$f1 eq \'vesa\'',
                                          {
                                            'config_class_name' => 'Xorg::Device::Vesa'
                                          },
                                          '$f1 eq \'nvidia\'',
                                          {
                                            'config_class_name' => 'Xorg::Device::Nvidia'
                                          }
                                        ]
                           },
                           'Chipset',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf'
                           },
                           'Ramdac',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf'
                           },
                           'DacSpeed',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
