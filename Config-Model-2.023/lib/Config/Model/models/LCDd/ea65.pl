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
    'name' => 'LCDd::ea65',
    'element' => [
      'Brightness',
      {
        'value_type' => 'uniline',
        'default' => '500',
        'type' => 'leaf',
        'description' => 'Device is fixed /dev/ttyS1
Width and Height are fixed 9x1
As the VFD is self luminescent we don\'t have a backlight
But we can use the backlight functions to control the front LEDs
Brightness 0 to 299 -> LEDs off
Brightness 300 to 699 -> LEDs half bright
Brightness 700 to 1000 -> LEDs full bright'
      },
      'OffBrightness',
      {
        'value_type' => 'uniline',
        'default' => '0',
        'type' => 'leaf',
        'description' => 'OffBrightness is the the value used for the \'backlight off\' state'
      }
    ]
  }
]
;

