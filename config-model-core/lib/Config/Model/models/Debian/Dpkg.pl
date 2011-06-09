[
  {
    'class_description' => 'Model of Debian source package files (e.g debian/control, debian/copyright...)',
    'read_config' => [
      {
        'auto_create' => '1',
        'file' => 'clean',
        'backend' => 'PlainFile',
        'config_dir' => 'debian'
      }
    ],
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
        'description' => 'copyright and license information of all files contained in this package',
        'config_class_name' => 'Debian::Dpkg::Copyright'
      },
      'source',
      {
        'type' => 'node',
        'config_class_name' => 'Debian::Dpkg::Source'
      },
      'clean',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'summary' => 'list of files to clean',
        'type' => 'list',
        'description' => 'list of files to remove when dh_clean is run. Files names can include wild cards. For instance:

 build.log
 Makefile.in
 */Makefile.in
 */*/Makefile.in

'
      }
    ]
  }
]
;

