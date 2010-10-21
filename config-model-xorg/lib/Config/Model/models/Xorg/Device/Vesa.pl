[
          {
            'name' => 'Xorg::Device::Vesa',
            'element' => [
                           'ShadowFB',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 1,
                             'type' => 'leaf',
                             'description' => 'Enable or disable use of the shadow framebuffer layer. This option is recommended for performance reasons.'
                           },
                           'ModeSetClearScreen',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 1,
                             'type' => 'leaf',
                             'description' => 'Enable or disable use of the shadow framebuffer layer. This option is recommended for performance reasons.'
                           }
                         ]
          }
        ]
;
