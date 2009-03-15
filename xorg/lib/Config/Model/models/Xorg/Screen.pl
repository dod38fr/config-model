[
          {
            'name' => 'Xorg::Screen',
            'element' => [
                           'Device',
                           {
                             'value_type' => 'reference',
                             'type' => 'leaf',
                             'description' => 'specifies the Device section to be used for this
       screen. This is what ties a specific graphics card to a
       screen.',
                             'refer_to' => '! Device'
                           },
                           'Monitor',
                           {
                             'value_type' => 'reference',
                             'type' => 'leaf',
                             'description' => 'specifies which monitor description is to be used
              for this screen. If a Monitor name is not specified, a
              default configuration is used. Currently the default
              configuration may not function as expected on all plat-
              forms.',
                             'refer_to' => '! Monitor'
                           },
                           'VideoAdaptor',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'specifies an optional Xv video adaptor
              description to be used with this screen.'
                           },
                           'DefaultDepth',
                           {
                             'value_type' => 'reference',
                             'type' => 'leaf',
                             'description' => 'specifies which color depth the server should
              use by default.  The -depth command line option can be
              used to override this. If neither is specified, the
              default depth is driver-specific, but in most cases is
              8.',
                             'refer_to' => '- Display'
                           },
                           'DefaultFbBpp',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'specifies which framebuffer layout to use by
              default.  The -fbbpp command line option can be used to
              override this.  In most cases the driver will chose the
              best default value for this.  The only case where there
              is even a choice in this value is for depth 24, where
              some hardware supports both a packed 24 bit framebuffer
              layout and a sparse 32 bit framebuffer layout.'
                           },
                           'Option',
                           {
                             'type' => 'node',
                             'config_class_name' => 'Xorg::Screen::Option'
                           },
                           'Display',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Xorg::Screen::Display'
                                        },
                             'min' => 1,
                             'max' => 32,
                             'type' => 'hash',
                             'description' => 'Each Screen section may have multiple Display
              subsections. The "active" Display subsection is the
              first that matches the depth and/or fbbpp values being
              used, or failing that, the first that has neither a
              depth or fbbpp value specified. The Display subsections
              are optional. When there isn\'t one that matches the
              depth and/or fbbpp values being used, all the parameters
              that can be specified here fall back to their
              defaults.',
                             'index_type' => 'integer'
                           }
                         ]
          }
        ]
;
