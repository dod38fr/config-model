[
  {
    'author' => [
      'Dominique Dumont'
    ],
    'class_description' => 'options valid for all types of file systems.',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'element' => [
      'async',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'atime',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'auto',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'dev',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'exec',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'group',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'mand',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'user',
      {
        'help' => {
          '0' => 'Only root can mount the file system',
          '1' => 'user can mount the file system'
        },
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'defaults',
      {
        'help' => {
          '1' => 'option equivalent to rw, suid, dev, exec, auto, nouser, and async'
        },
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'rw',
      {
        'help' => {
          '0' => 'read-only file system'
        },
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'relatime',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      }
    ],
    'license' => 'LGPL2',
    'name' => 'Fstab::CommonOptions'
  }
]
;

