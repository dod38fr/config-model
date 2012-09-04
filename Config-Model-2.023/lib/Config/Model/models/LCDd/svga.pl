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
    'name' => 'LCDd::svga',
    'element' => [
      'Mode',
      {
        'value_type' => 'uniline',
        'upstream_default' => 'G320x240x256',
        'type' => 'leaf',
        'description' => 'svgalib mode to use 
legal values are supported svgalib modes'
      },
      'Size',
      {
        'value_type' => 'uniline',
        'upstream_default' => '20x4',
        'type' => 'leaf',
        'description' => 'set display size '
      },
      'Contrast',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '500',
        'max' => '1000',
        'type' => 'leaf',
        'description' => 'Set the initial contrast 
Can be set but does not change anything internally'
      },
      'Brightness',
      {
        'value_type' => 'integer',
        'min' => '1',
        'upstream_default' => '1000',
        'max' => '1000',
        'type' => 'leaf',
        'description' => 'Set the initial brightness '
      },
      'OffBrightness',
      {
        'value_type' => 'integer',
        'min' => '1',
        'upstream_default' => '500',
        'max' => '1000',
        'type' => 'leaf',
        'description' => 'Set the initial off-brightness 
This value is used when the display is normally
switched off in case LCDd is inactive'
      }
    ]
  }
]
;

