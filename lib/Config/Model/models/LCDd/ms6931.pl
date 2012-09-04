[
  {
    'class_description' => 'generated from LCDd.conf',
    'name' => 'LCDd::ms6931',
    'element' => [
      'Device',
      {
        'value_type' => 'uniline',
        'upstream_default' => '/dev/ttyS1',
        'type' => 'leaf',
        'description' => 'device to use '
      },
      'Size',
      {
        'value_type' => 'uniline',
        'upstream_default' => '16x2',
        'type' => 'leaf',
        'description' => 'display size '
      }
    ]
  }
]
;

