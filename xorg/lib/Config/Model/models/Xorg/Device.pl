[
          {
            'class_description' => 'Driver-independent entries and Options',
            'name' => 'Xorg::Device',
            'element' => [
                           'Driver',
                           {
                             'value_type' => 'enum',
                             'mandatory' => 1,
                             'type' => 'leaf',
                             'description' => 'name of the driver to use for this graphics device',
                             'choice' => [
                                           'vesa',
                                           'ati',
                                           'radeon',
                                           'fglrx',
                                           'nvidia'
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
                             'type' => 'leaf',
                             'description' => "This specifies the bus location of the graphics card. For PCI/AGP cards, the bus-id string has the form
PCI:bus:device:function (e.g., \x{201c}PCI:1:0:0\x{201d} might be appropriate for an AGP card). This field is usually optional in single-head configurations when using the primary graphics card. In multi-head configurations, or when using a secondary graphics card in a single-head configuration, this entry is mandatory. Its main purpose is to make an unambiguous connection between the device section and the hardware it is representing. This information can usually be found by running the Xorg server with the -scanpci command line option."
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
                             'type' => 'leaf',
                             'description' => 'his option is mandatory for cards where a single PCI entity can drive more than one display (i.e., multiple CRTCs sharing a single graphics accelerator and video memory). One Device section is required for each head, and this parameter determines which head each of the Device sections applies to. The legal values of number range from 0 to one less than the total number of heads per entity. Most drivers require that the primary screen (0) be present.'
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
                                          },
                                          '$f1 eq \'fglrx\'',
                                          {
                                            'config_class_name' => 'Xorg::Device::Fglrx'
                                          },
                                          '$f1 eq \'ati\'',
                                          {
                                            'config_class_name' => 'Xorg::Device::Ati'
                                          }
                                        ],
                             'description' => 'Option flags may be specified in the Device sections. These include driver-specific options and driver-independent options.'
                           }
                         ]
          }
        ]
;
