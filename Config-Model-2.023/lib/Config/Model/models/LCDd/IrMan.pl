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
    'name' => 'LCDd::IrMan',
    'element' => [
      'Device',
      {
        'value_type' => 'uniline',
        'default' => '/dev/irman',
        'type' => 'leaf',
        'description' => 'in case of trouble with IrMan, try the Lirc emulator for IrMan
Select the input device to use'
      },
      'Config',
      {
        'value_type' => 'uniline',
        'default' => '/etc/irman.cfg',
        'type' => 'leaf',
        'description' => 'Select the configuration file to use'
      }
    ]
  }
]
;

