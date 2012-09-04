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
    'name' => 'LCDd::t6963',
    'element' => [
      'Size',
      {
        'value_type' => 'uniline',
        'upstream_default' => '128x64',
        'type' => 'leaf',
        'description' => 'set display size in pixels '
      },
      'Port',
      {
        'value_type' => 'uniline',
        'upstream_default' => '0x378',
        'type' => 'leaf',
        'description' => 'port to use '
      },
      'bidirectional',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'Use LPT port in bi-directional mode. This should work on most LPT port and
is required for proper timing! ',
        'choice' => [
          'yes',
          'no'
        ]
      },
      'delayBus',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'Insert additional delays into reads / writes. ',
        'choice' => [
          'yes',
          'no'
        ]
      },
      'ClearGraphic',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'Clear graphic memory on start-up. ',
        'choice' => [
          'yes',
          'no'
        ]
      }
    ]
  }
]
;

