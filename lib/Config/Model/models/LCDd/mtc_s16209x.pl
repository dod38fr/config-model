[
  {
    'class_description' => 'generated from LCDd.conf',
    'name' => 'LCDd::mtc_s16209x',
    'element' => [
      'Device',
      {
        'value_type' => 'uniline',
        'upstream_default' => '/dev/lcd',
        'type' => 'leaf',
        'description' => 'Select the output device to use '
      },
      'Brightness',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '255',
        'max' => '255',
        'type' => 'leaf',
        'description' => 'Set the initial brightness '
      },
      'Reboot',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'Reinitialize the LCD\'s BIOS ',
        'choice' => [
          'yes',
          'no'
        ]
      }
    ]
  }
]
;

