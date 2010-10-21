[
          {
            'name' => 'Xorg::Monitor::Option',
            'element' => [
                           'DPMS',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           },
                           'SyncOnGreen',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           },
                           'PreferredMode',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'This optional entry specifies a mode to be marked as the preferred initial mode of the monitor. (RandR 1.2-supporting drivers only).

FIXME: use available Modes + vesa standard'
                           },
                           'LeftOf',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'This optional entry specifies that the monitor should be positioned to the left of the output (not monitor) of the given name. (RandR 1.2-supporting drivers only)'
                           },
                           'RightOf',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'This optional entry specifies that the monitor should be positioned to the right of the output (not monitor) of the given name. (RandR 1.2-supporting drivers only)'
                           },
                           'Above',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'This optional entry specifies that the monitor should be positioned above the output (not monitor) of the given name. (RandR 1.2-supporting drivers only)'
                           },
                           'Below',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'This optional entry specifies that the monitor should be positioned below the output (not monitor) of the given name. (RandR 1.2-supporting drivers only)'
                           },
                           'Ignore',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 'false',
                             'type' => 'leaf',
                             'description' => 'This optional entry specifies whether the monitor should be turned on at startup. By default, the server will attempt to enable all connected monitors. (RandR 1.2-supporting drivers only)',
                             'choice' => [
                                           'false',
                                           'true'
                                         ]
                           }
                         ]
          }
        ]
;
