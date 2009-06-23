[
          {
            'name' => 'Xorg::Monitor::Mode::Timing',
            'element' => [
                           'disp',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf'
                           },
                           'syncstart',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf'
                           },
                           'syncend',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf'
                           },
                           'total',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf'
                           }
                         ]
          },
          {
            'name' => 'Xorg::Monitor::Mode::Flags',
            'element' => [
                           'Interlace',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'be used to specify composite sync on hardware
      where this is supported.'
                           },
                           'DoubleScan',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'be used to specify composite sync on hardware
      where this is supported.'
                           },
                           'Composite',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'be used to specify composite sync on hardware
      where this is supported.'
                           },
                           'HSyncPolarity',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'used to select the polarity of the VSync signal.',
                             'choice' => [
                                           'positive',
                                           'negative'
                                         ]
                           },
                           'VSyncPolarity',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'used to select the polarity of the VSync signal.',
                             'choice' => [
                                           'positive',
                                           'negative'
                                         ]
                           },
                           'CSyncPolarity',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'used to select the polarity of the VSync signal.',
                             'choice' => [
                                           'positive',
                                           'negative'
                                         ]
                           }
                         ]
          },
          {
            'name' => 'Xorg::Monitor::Mode',
            'element' => [
                           'DotClock',
                           {
                             'value_type' => 'number',
                             'type' => 'leaf',
                             'description' => 'is the dot (pixel) clock rate to be used for the
      mode.'
                           },
                           'HTimings',
                           {
                             'type' => 'node',
                             'config_class_name' => 'Xorg::Monitor::Mode::Timing'
                           },
                           'VTimings',
                           {
                             'type' => 'node',
                             'config_class_name' => 'Xorg::Monitor::Mode::Timing'
                           },
                           'Flags',
                           {
                             'type' => 'node',
                             'config_class_name' => 'Xorg::Monitor::Mode::Flags'
                           },
                           'HSkew',
                           {
                             'value_type' => 'number',
                             'type' => 'leaf',
                             'description' => 'specifies the number of pixels (towards the right
      edge of the screen) by which the display enable signal is to be
      skewed.  Not all drivers use this information.  This option
      might become necessary to override the default value supplied by
      the server (if any).  "Roving" horizontal lines indicate this
      value needs to be increased.  If the last few pixels on a scan
      line appear on the left of the screen, this value should be
      decreased.'
                           },
                           'VScan',
                           {
                             'value_type' => 'number',
                             'type' => 'leaf',
                             'description' => 'specifies the number of pixels (towards the right
      edge of the screen) by which the display enable signal is to be
      skewed.  Not all drivers use this information.  This option
      might become necessary to override the default value supplied by
      the server (if any).  "Roving" horizontal lines indicate this
      value needs to be increased.  If the last few pixels on a scan
      line appear on the left of the screen, this value should be
      decreased.'
                           }
                         ]
          }
        ]
;
