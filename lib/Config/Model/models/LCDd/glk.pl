[
  {
    'class_description' => 'generated from LCDd.conf',
    'name' => 'LCDd::glk',
    'element' => [
      'Device',
      {
        'value_type' => 'uniline',
        'upstream_default' => '/dev/lcd',
        'type' => 'leaf',
        'description' => 'select the serial device to use '
      },
      'Contrast',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '560',
        'max' => '1000',
        'type' => 'leaf',
        'description' => 'set the initial contrast value '
      },
      'Speed',
      {
        'value_type' => 'enum',
        'upstream_default' => '19200',
        'type' => 'leaf',
        'description' => 'set the serial port speed ',
        'choice' => [
          '9600',
          '19200',
          '38400'
        ]
      }
    ]
  }
]
;

