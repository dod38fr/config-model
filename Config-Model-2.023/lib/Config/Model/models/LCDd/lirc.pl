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
    'name' => 'LCDd::lirc',
    'element' => [
      'lircrc',
      {
        'value_type' => 'uniline',
        'upstream_default' => '~/.lircrc',
        'type' => 'leaf',
        'description' => 'Specify an alternative location of the lircrc file '
      },
      'prog',
      {
        'value_type' => 'uniline',
        'default' => 'lcdd',
        'type' => 'leaf',
        'description' => 'Must be the same as in your lircrc'
      }
    ]
  }
]
;

