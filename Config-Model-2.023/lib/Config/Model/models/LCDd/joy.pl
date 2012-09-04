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
    'name' => 'LCDd::joy',
    'element' => [
      'Device',
      {
        'value_type' => 'uniline',
        'upstream_default' => '/dev/js0',
        'type' => 'leaf',
        'description' => 'Select the input device to use '
      },
      'Map_Axis1neg',
      {
        'value_type' => 'uniline',
        'default' => 'Left',
        'type' => 'leaf',
        'description' => 'set the axis map'
      },
      'Map_Axis1pos',
      {
        'value_type' => 'uniline',
        'default' => 'Right',
        'type' => 'leaf'
      },
      'Map_Axis2neg',
      {
        'value_type' => 'uniline',
        'default' => 'Up',
        'type' => 'leaf'
      },
      'Map_Axis2pos',
      {
        'value_type' => 'uniline',
        'default' => 'Down',
        'type' => 'leaf'
      },
      'Map_Button1',
      {
        'value_type' => 'uniline',
        'default' => 'Enter',
        'type' => 'leaf',
        'description' => 'set the button map'
      },
      'Map_Button2',
      {
        'value_type' => 'uniline',
        'default' => 'Escape',
        'type' => 'leaf'
      }
    ]
  }
]
;

