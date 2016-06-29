[
  {
    'accept' => [
      '.*',
      {
        'description' => 'unknown parameter',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'element' => [
      'acl',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'user_xattr',
      {
        'description' => 'Support "user." extended attributes ',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'statfs_behavior',
      {
        'choice' => [
          'bsddf',
          'minixdf'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'errors',
      {
        'choice' => [
          'continue',
          'remount-ro',
          'panic'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      }
    ],
    'include' => [
      'Fstab::CommonOptions'
    ],
    'license' => 'LGPL2',
    'name' => 'Fstab::Ext2FsOpt'
  }
]
;

