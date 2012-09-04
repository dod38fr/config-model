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
    'accept' => [
      '\\w+',
      {
        'value_type' => 'uniline',
        'warn' => 'Handling unknown parameter as unlinie value.',
        'type' => 'leaf'
      }
    ],
    'name' => 'Multistrap::Section',
    'element' => [
      'packages',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'type' => 'list'
      },
      'components',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'type' => 'list'
      },
      'source',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'keyring',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'suite',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'omitdebsrc',
      {
        'value_type' => 'boolean',
        'type' => 'leaf'
      }
    ]
  }
]
;

