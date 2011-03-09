[
  {
    'read_config' => [
      {
        'auto_create' => '1',
        'backend' => 'PlainFile',
        'config_dir' => 'debian/source'
      }
    ],
    'name' => 'Debian::Dpkg::Source',
    'element' => [
      'format',
      {
        'value_type' => 'enum',
        'mandatory' => '1',
        'type' => 'leaf',
        'choice' => [
          '1.0',
          '2.0',
          '3.0 (native)',
          '3.0 (quilt)',
          '3.0 (custom)',
          '3.0 (git)',
          '3.0 (bzr)'
        ]
      }
    ]
  }
]
;
