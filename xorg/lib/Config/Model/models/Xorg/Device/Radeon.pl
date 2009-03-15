[
          {
            'name' => 'Xorg::Device::Radeon',
            'element' => [
                           'MergedFB',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf',
                             'description' => 'This enables merged framebuffer mode.  In this mode you have a single  shared  framebuffer  with  two  viewports looking into it.  It is similar to Xinerama, but has some advantages.  It is faster than Xinerama, the DRI works on both heads, and it supports clone modes.'
                           },
                           'SWcursor',
                           {
                             'value_type' => 'enum',
                             'built_in' => 'off',
                             'type' => 'leaf',
                             'description' => 'Selects software cursor.',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'NoAccel',
                           {
                             'value_type' => 'enum',
                             'built_in' => 'on',
                             'type' => 'leaf',
                             'description' => 'Enables or disables all hardware acceleration.',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'Dac6Bit',
                           {
                             'value_type' => 'enum',
                             'built_in' => 'off',
                             'type' => 'leaf',
                             'description' => '
           Enables or disables the use of 6 bits per color component when in 8
           bpp mode (emulates VGA mode). By default, all 8 bits per color
           component are used. The default is: "off".',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'VideoKey',
                           {
                             'value_type' => 'uniline',
                             'built_in' => '0x1E',
                             'type' => 'leaf',
                             'description' => 'This overrides the default pixel value for the YUV video overlay key.
              The default value is 0x1E.
'
                           },
                           'ScalerWidth',
                           {
                             'value_type' => 'integer',
                             'min' => '1024',
                             'max' => '2048',
                             'type' => 'leaf',
                             'description' => "This  sets the overlay scaler buffer width. Accepted values range from 1024 to 2048, divisible
              by 64, values other than 1536 and 1920 may not make sense though. Should be set automatically,
              but  noone  has  a  clue what the limit is for which chip. If you think quality is not optimal
              when playing back HD video (with horizontal resolution larger  than  this  setting),  increase
              this  value, if you get an empty area at the right (usually pink), decrease it. Note this only
              affects the \"true\" overlay via xv, it won\x{2019}t affect things like textured video.
              The default value is either 1536 (for most chips) or 1920.
"
                           },
                           'AccelMethod',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'choice' => [
                                           'EXA',
                                           'XAA'
                                         ]
                           },
                           'Monitor-DVI-0',
                           {
                             'value_type' => 'reference',
                             'type' => 'leaf',
                             'refer_to' => '! Monitor'
                           },
                           'Monitor-LVDS',
                           {
                             'value_type' => 'reference',
                             'type' => 'leaf',
                             'refer_to' => '! Monitor'
                           },
                           'IgnoreEDID',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Do not use EDID data for mode validation, but DDC is still used for monitor detection. This is different from Option "NoDDC". The default is: "off". If the server is ignoring your modlines, set this option to "on" and try again.',
                             'choice' => [
                                           'off',
                                           'on'
                                         ]
                           },
                           'PanelSize',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
