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
    'name' => 'LCDd::glcd',
    'element' => [
      'ConnectionType',
      {
        'value_type' => 'uniline',
        'default' => 't6963',
        'type' => 'leaf',
        'description' => 'Select what type of connection. See documentation for types.'
      },
      'Size',
      {
        'value_type' => 'uniline',
        'upstream_default' => '128x64',
        'type' => 'leaf',
        'description' => 'Width and height of the display in pixel. The supported sizes may depend on
the ConnectionType. '
      },
      'Port',
      {
        'value_type' => 'uniline',
        'upstream_default' => '0x378',
        'type' => 'leaf',
        'description' => 't6963: Parallel port to use '
      },
      'bidirectional',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 't6963: Use LPT port in bi-directional mode. This should work on most LPT port
and is required for proper timing! ',
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
        'description' => 't6963: Insert additional delays into reads / writes. ',
        'choice' => [
          'yes',
          'no'
        ]
      },
      'useFT2',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'If LCDproc has been compiled with FreeType 2 support this option can be used
to turn if off intentionally. ',
        'choice' => [
          'yes',
          'no'
        ]
      },
      'normal_font',
      {
        'value_type' => 'uniline',
        'default' => '/usr/local/lib/X11/fonts/TTF/andalemo.ttf',
        'type' => 'leaf',
        'description' => 'Path to font file to use for FreeType rendering. This font must be monospace
and should contain some special Unicode characters like arrows (Andale Mono
is recommended and can be fetched at http://corefonts.sf.net).'
      },
      'fontHasIcons',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'Some fonts miss the Unicode characters used to represent icons. In this case
the built-in 5x8 font can used if this option is turned off. ',
        'choice' => [
          'yes',
          'no'
        ]
      }
    ]
  }
]
;

