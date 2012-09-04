[
  {
    'class_description' => 'generated from LCDd.conf',
    'name' => 'LCDd::mx5000',
    'element' => [
      'Device',
      {
        'value_type' => 'uniline',
        'upstream_default' => '/dev/hiddev0',
        'type' => 'leaf',
        'description' => 'Select the output device to use '
      },
      'WaitAfterRefresh',
      {
        'value_type' => 'uniline',
        'upstream_default' => '1000',
        'type' => 'leaf',
        'description' => 'Time to wait in ms after the refresh screen has been sent '
      }
    ]
  }
]
;

