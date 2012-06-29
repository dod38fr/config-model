[
  {
    'class_description' => 'options valid for all types of file systems.',
    'name' => 'Fstab::CommonOptions',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
    'element' => [
      'async',
      {
        'value_type' => 'boolean',
        'type' => 'leaf'
      },
      'atime',
      {
        'value_type' => 'boolean',
        'type' => 'leaf'
      },
      'auto',
      {
        'value_type' => 'boolean',
        'type' => 'leaf'
      },
      'dev',
      {
        'value_type' => 'boolean',
        'type' => 'leaf'
      },
      'exec',
      {
        'value_type' => 'boolean',
        'type' => 'leaf'
      },
      'group',
      {
        'value_type' => 'boolean',
        'type' => 'leaf'
      },
      'mand',
      {
        'value_type' => 'boolean',
        'type' => 'leaf'
      },
      'user',
      {
        'value_type' => 'boolean',
        'help' => {
          '1' => 'user can mount the file system',
          '0' => 'Only root can mount the file system'
        },
        'type' => 'leaf'
      },
      'defaults',
      {
        'value_type' => 'boolean',
        'help' => {
          '1' => 'option equivalent to rw, suid, dev, exec, auto, nouser, and async'
        },
        'type' => 'leaf'
      },
      'rw',
      {
        'value_type' => 'boolean',
        'help' => {
          '0' => 'read-only file system'
        },
        'type' => 'leaf'
      }
    ]
  }
]
;

