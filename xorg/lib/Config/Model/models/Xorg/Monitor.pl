[
          {
            'name' => 'Xorg::Monitor',
            'element' => [
                           'VendorName',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'optional entry for the monitor\'s manufacturer'
                           },
                           'ModelName',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'optional entry for the monitor\'s manufacturer'
                           },
                           'HorizSync',
                           {
                             'value_type' => 'uniline',
                             'upstream_default' => '28-33kHz',
                             'type' => 'leaf',
                             'description' => 'gives the range(s) of horizontal sync
              frequencies supported by the monitor.  horizsync-range
              may be a comma separated list of either discrete values
              or ranges of values.  A range of values is two values
              separated by a dash.  By default the values are in units
              of kHz.  They may be specified in MHz or Hz if MHz or Hz
              is added to the end of the line.  The data given here is
              used by the Xorg server to determine if video modes are
              within the spec- ifications of the monitor.  This
              information should be available in the monitor\'s
              handbook.  If this entry is omitted, a default range of
              28-33kHz is used.'
                           },
                           'VertRefresh',
                           {
                             'value_type' => 'uniline',
                             'upstream_default' => '43-72Hz',
                             'type' => 'leaf',
                             'description' => 'gives the range(s) of vertical refresh
              frequencies supported by the monitor.  vertrefresh-range
              may be a comma separated list of either discrete values
              or ranges of values.  A range of values is two values
              separated by a dash.  By default the values are in units
              of Hz.  They may be specified in MHz or kHz if MHz or
              kHz is added to the end of the line.  The data given
              here is used by the Xorg server to determine if video
              modes are within the spec- ifications of the monitor.
              This information should be available in the monitor\'s
              handbook.  If this entry is omitted, a default range of
              43-72Hz is used.'
                           },
                           'DisplaySize',
                           {
                             'type' => 'node',
                             'description' => 'This optional entry gives the width and
              height, in millimetres, of the picture area of the
              monitor.  If given, this is used to calculate the
              horizontal and vertical pitch (DPI) of the screen.',
                             'config_class_name' => 'Xorg::Monitor::DisplaySize'
                           },
                           'Gamma',
                           {
                             'type' => 'node',
                             'config_class_name' => 'Xorg::Monitor::Gamma'
                           },
                           'UseModes',
                           {
                             'value_type' => 'reference',
                             'type' => 'leaf',
                             'description' => 'Include the set of modes listed in the Modes
              section.  This make all of the modes defined in that
              section available for use by this monitor.',
                             'refer_to' => '! Modes '
                           },
                           'Mode',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Xorg::Monitor::Mode'
                                        },
                             'type' => 'hash',
                             'index_type' => 'string'
                           },
                           'Option',
                           {
                             'type' => 'node',
                             'config_class_name' => 'Xorg::Monitor::Option'
                           }
                         ]
          },
          {
            'name' => 'Xorg::Monitor::DisplaySize',
            'element' => [
                           'width',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf',
                             'description' => 'in millimeters'
                           },
                           'height',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf',
                             'description' => 'in millimeters'
                           }
                         ]
          },
          {
            'name' => 'Xorg::Monitor::Gamma',
            'element' => [
                           'use_global_gamma',
                           {
                             'value_type' => 'boolean',
                             'default' => 1,
                             'type' => 'leaf'
                           },
                           'gamma',
                           {
                             'value_type' => 'number',
                             'level' => 'hidden',
                             'warp' => {
                                         'follow' => {
                                                       'f1' => '- use_global_gamma'
                                                     },
                                         'rules' => [
                                                      '$f1 eq \'1\'',
                                                      {
                                                        'level' => 'normal'
                                                      }
                                                    ]
                                       },
                             'upstream_default' => 1,
                             'type' => 'leaf'
                           },
                           'red_gamma',
                           {
                             'value_type' => 'number',
                             'level' => 'hidden',
                             'warp' => {
                                         'follow' => {
                                                       'f1' => '- use_global_gamma'
                                                     },
                                         'rules' => [
                                                      '$f1 eq \'0\'',
                                                      {
                                                        'level' => 'normal',
                                                        'mandatory' => 1
                                                      }
                                                    ]
                                       },
                             'upstream_default' => 1,
                             'type' => 'leaf'
                           },
                           'green_gamma',
                           {
                             'value_type' => 'number',
                             'level' => 'hidden',
                             'warp' => {
                                         'follow' => {
                                                       'f1' => '- use_global_gamma'
                                                     },
                                         'rules' => [
                                                      '$f1 eq \'0\'',
                                                      {
                                                        'level' => 'normal',
                                                        'mandatory' => 1
                                                      }
                                                    ]
                                       },
                             'upstream_default' => 1,
                             'type' => 'leaf'
                           },
                           'blue_gamma',
                           {
                             'value_type' => 'number',
                             'level' => 'hidden',
                             'warp' => {
                                         'follow' => {
                                                       'f1' => '- use_global_gamma'
                                                     },
                                         'rules' => [
                                                      '$f1 eq \'0\'',
                                                      {
                                                        'level' => 'normal',
                                                        'mandatory' => 1
                                                      }
                                                    ]
                                       },
                             'upstream_default' => 1,
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
