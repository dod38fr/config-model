[
  {
    'class_description' => 'generated from LCDd.conf',
    'name' => 'LCDd::xosd',
    'element' => [
      'Size',
      {
        'value_type' => 'uniline',
        'upstream_default' => '20x4',
        'type' => 'leaf',
        'description' => 'set display size '
      },
      'Offset',
      {
        'value_type' => 'uniline',
        'upstream_default' => '0x0',
        'type' => 'leaf',
        'description' => 'Offset in pixels from the top-left corner of the monitor '
      },
      'Font',
      {
        'value_type' => 'uniline',
        'default' => '-*-terminus-*-r-*-*-*-320-*-*-*-*-*',
        'type' => 'leaf',
        'description' => 'X font to use, in XLFD format, as given by "xfontsel"'
      }
    ]
  }
]
;

