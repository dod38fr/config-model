[
  {
    'class_description' => 'generated from LCDd.conf',
    'name' => 'LCDd::sli',
    'element' => [
      'Device',
      {
        'value_type' => 'uniline',
        'upstream_default' => '/dev/lcd',
        'type' => 'leaf',
        'description' => 'Select the output device to use '
      },
      'Speed',
      {
        'value_type' => 'enum',
        'upstream_default' => '19200',
        'type' => 'leaf',
        'description' => 'Set the communication speed ',
        'choice' => [
          '1200',
          '2400',
          '9600',
          '19200',
          '38400',
          '57600',
          '115200'
        ]
      }
    ]
  }
]
;

