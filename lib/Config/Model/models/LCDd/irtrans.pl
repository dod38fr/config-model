[
  {
    'class_description' => 'generated from LCDd.conf',
    'name' => 'LCDd::irtrans',
    'element' => [
      'Backlight',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'Does the device have a backlight? ',
        'choice' => [
          'yes',
          'no'
        ]
      },
      'Hostname',
      {
        'value_type' => 'uniline',
        'upstream_default' => 'localhost',
        'type' => 'leaf',
        'description' => 'IRTrans device to connect to '
      },
      'Size',
      {
        'value_type' => 'uniline',
        'default' => '16x2',
        'type' => 'leaf',
        'description' => 'display dimensions'
      }
    ]
  }
]
;

