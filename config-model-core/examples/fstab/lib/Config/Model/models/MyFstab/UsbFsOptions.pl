[
          {
            'class_description' => 'usbfs options',
            'name' => 'Fstab::UsbFsOptions',
            'include' => [
                           'Fstab::CommonOptions'
                         ],
            'element' => [
                           'devuid',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0',
                             'type' => 'leaf'
                           },
                           'devgid',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0',
                             'type' => 'leaf'
                           },
                           'busuid',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0',
                             'type' => 'leaf'
                           },
                           'budgid',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0',
                             'type' => 'leaf'
                           },
                           'listuid',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0',
                             'type' => 'leaf'
                           },
                           'listgid',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0',
                             'type' => 'leaf'
                           },
                           'devmode',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0644',
                             'type' => 'leaf'
                           },
                           'busmode',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0555',
                             'type' => 'leaf'
                           },
                           'listmode',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0444',
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
