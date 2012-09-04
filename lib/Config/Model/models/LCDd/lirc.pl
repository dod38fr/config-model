[
  {
    'class_description' => 'generated from LCDd.conf',
    'name' => 'LCDd::lirc',
    'element' => [
      'lircrc',
      {
        'value_type' => 'uniline',
        'upstream_default' => '~/.lircrc',
        'type' => 'leaf',
        'description' => 'Specify an alternative location of the lircrc file '
      },
      'prog',
      {
        'value_type' => 'uniline',
        'default' => 'lcdd',
        'type' => 'leaf',
        'description' => 'Must be the same as in your lircrc'
      }
    ]
  }
]
;

