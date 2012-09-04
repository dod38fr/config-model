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
    'read_config' => [
      {
        'auto_create' => '1',
        'file' => 'control',
        'backend' => 'Debian::Dpkg::Control',
        'config_dir' => 'debian'
      }
    ],
    'name' => 'Debian::Dpkg::Control',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
    'element' => [
      'source',
      {
        'summary' => 'package source description',
        'type' => 'node',
        'config_class_name' => 'Debian::Dpkg::Control::Source'
      },
      'binary',
      {
        'cargo' => {
          'type' => 'node',
          'config_class_name' => 'Debian::Dpkg::Control::Binary'
        },
        'summary' => 'package binary description',
        'ordered' => '1',
        'type' => 'hash',
        'index_type' => 'string'
      }
    ]
  }
]
;

