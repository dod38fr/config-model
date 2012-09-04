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
    'name' => 'LCDd::serialVFD',
    'element' => [
      'Type',
      {
        'value_type' => 'uniline',
        'upstream_default' => '0',
        'type' => 'leaf',
        'description' => 'Specifies the displaytype.
0 NEC (FIPC8367 based) VFDs.
1 KD Rev 2.1.
2 Noritake VFDs (*).
3 Futaba VFDs
4 IEE S03601-95B
5 IEE S03601-96-080 (*)
6 Futaba NA202SD08FA (allmost IEE compatible)
7 Samsung 20S207DA4 and 20S207DA6
8 Nixdorf BA6x / VT100
(* most should work, not tested yet.)'
      },
      'use_parallel',
      {
        'value_type' => 'uniline',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => '"no" if display connected serial, "yes" if connected parallel. 
I.e. serial by default'
      },
      'Port',
      {
        'value_type' => 'uniline',
        'default' => '0x378',
        'type' => 'leaf',
        'description' => 'Number of Custom-Characters. default is display type dependent
Custom-Characters=0
Portaddress where the LPT is. Used in parallel mode only. Usual values are
0x278, 0x378 and 0x3BC.'
      },
      'PortWait',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '2',
        'max' => '255',
        'type' => 'leaf',
        'description' => 'Set parallel port timing delay (us). Used in parallel mode only.'
      },
      'Device',
      {
        'value_type' => 'uniline',
        'default' => '/dev/ttyS1',
        'type' => 'leaf',
        'description' => 'Device to use in serial mode. Usual values are /dev/ttyS0 and /dev/ttyS1'
      },
      'Size',
      {
        'value_type' => 'uniline',
        'default' => '20x2',
        'type' => 'leaf',
        'description' => 'Specifies the size of the VFD.'
      },
      'Brightness',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '1000',
        'max' => '1000',
        'type' => 'leaf',
        'description' => 'Set the initial brightness 
(4 steps 0-250, 251-500, 501-750, 751-1000)'
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
switched off in case LCDd is inactive
(4 steps 0-250, 251-500, 501-750, 751-1000)'
      },
      'Speed',
      {
        'value_type' => 'enum',
        'upstream_default' => '9600',
        'type' => 'leaf',
        'description' => 'set the serial port speed ',
        'choice' => [
          '1200',
          '2400',
          '9600',
          '19200',
          '115200'
        ]
      },
      'ISO_8859_1',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'enable ISO 8859 1 compatibility ',
        'choice' => [
          'yes',
          'no'
        ]
      }
    ]
  }
]
;

