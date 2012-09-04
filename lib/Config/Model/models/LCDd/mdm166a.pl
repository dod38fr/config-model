[
  {
    'class_description' => 'generated from LCDd.conf',
    'name' => 'LCDd::mdm166a',
    'element' => [
      'Clock',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'Show self-running clock after LCDd shutdown
Possible values: ',
        'choice' => [
          'no',
          'small',
          'big'
        ]
      },
      'Dimming',
      {
        'value_type' => 'uniline',
        'upstream_default' => 'no,legal:yes,no',
        'type' => 'leaf',
        'description' => 'Dim display, no dimming gives full brightness '
      },
      'OffDimming',
      {
        'value_type' => 'uniline',
        'upstream_default' => 'no,legal:yes,no',
        'type' => 'leaf',
        'description' => 'Dim display in case LCDd is inactive '
      }
    ]
  }
]
;

