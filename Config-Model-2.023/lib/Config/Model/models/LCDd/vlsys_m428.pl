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
    'name' => 'LCDd::vlsys_m428',
    'element' => [
      'Device',
      {
        'value_type' => 'uniline',
        'upstream_default' => '/dev/ttyUSB0',
        'type' => 'leaf',
        'description' => 'Select the output device to use '
      }
    ]
  }
]
;

