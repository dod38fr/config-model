#
# This file is part of Config-Model
#
# This software is Copyright (c) 2012 by Dominique Dumont, Krzysztof Tyszecki.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'class_description' => 'generated from LCDd.conf',
    'name' => 'LCDd::NoritakeVFD',
    'element' => [
      'Device',
      {
        'value_type' => 'uniline',
        'upstream_default' => '/dev/lcd',
        'type' => 'leaf',
        'description' => 'device where the VFD is. Usual values are /dev/ttyS0 and /dev/ttyS1'
      },
      'Size',
      {
        'value_type' => 'uniline',
        'default' => '20x4',
        'type' => 'leaf',
        'description' => 'Specifies the size of the LCD.'
      },
      'Brightness',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '1000',
        'max' => '1000',
        'type' => 'leaf',
        'description' => 'Set the initial brightness '
      },
      'OffBrightness',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '0',
        'max' => '1000',
        'type' => 'leaf',
        'description' => 'Set the initial off-brightness 
This value is used when the display is normally
switched off in case LCDd is inactive'
      },
      'Speed',
      {
        'value_type' => 'uniline',
        'upstream_default' => '9600,legal:1200,2400,9600,19200,115200',
        'type' => 'leaf',
        'description' => 'set the serial port speed '
      },
      'Parity',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '0',
        'max' => '2',
        'type' => 'leaf',
        'description' => 'Set serial data parity 
Meaning: 0(=none), 1(=odd), 2(=even)'
      },
      'Reboot',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 're-initialize the VFD ',
        'choice' => [
          'yes',
          'no'
        ]
      }
    ]
  }
]
;

