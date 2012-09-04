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

