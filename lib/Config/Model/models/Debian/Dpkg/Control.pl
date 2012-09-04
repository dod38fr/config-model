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

