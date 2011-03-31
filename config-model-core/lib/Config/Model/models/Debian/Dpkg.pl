[
  {
    'class_description' => 'Model of Debian source package files (e.g control, oopyright...)',
    'name' => 'Debian::Dpkg',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
    'element' => [
      'meta',
      {
        'type' => 'node',
        'description' => 'Specify meta parameters that will tune the behavior of this dpkg model',
        'config_class_name' => 'Debian::Dpkg::Meta'
      },
      'control',
      {
        'type' => 'node',
        'description' => 'Package control file. Specifies the most vital (and version-independent) information about the source package and about the binary packages it creates.',
        'config_class_name' => 'Debian::Dpkg::Control'
      },
      'copyright',
      {
        'summary' => 'copyright and license information',
        'type' => 'node',
        'description' => 'copyrigth and license information of all files containted in this packge',
        'config_class_name' => 'Debian::Dpkg::Copyright'
      },
      'source',
      {
        'type' => 'node',
        'config_class_name' => 'Debian::Dpkg::Source'
      }
    ]
  }
]
;

