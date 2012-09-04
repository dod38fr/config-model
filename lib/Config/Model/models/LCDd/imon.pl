[
  {
    'class_description' => 'generated from LCDd.conf',
    'name' => 'LCDd::imon',
    'element' => [
      'Device',
      {
        'value_type' => 'uniline',
        'default' => '/dev/lcd0',
        'type' => 'leaf',
        'description' => 'select the device to use'
      },
      'Size',
      {
        'value_type' => 'uniline',
        'default' => '16x2',
        'type' => 'leaf',
        'description' => 'display dimensions'
      },
      'CharMap',
      {
        'value_type' => 'enum',
        'upstream_default' => 'none',
        'type' => 'leaf',
        'description' => 'Character map to to map ISO-8859-1 to the displays character set.
 (upd16314, hd44780_koi8_r,
hd44780_cp1251, hd44780_8859_5 are possible if compiled with additional
charmaps)',
        'choice' => [
          'none',
          'hd44780_euro',
          'upd16314',
          'hd44780_koi8_r',
          'hd44780_cp1251',
          'hd44780_8859_5'
        ]
      }
    ]
  }
]
;

