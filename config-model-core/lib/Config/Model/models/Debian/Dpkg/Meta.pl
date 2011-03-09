[
  {
    'read_config' => [
      {
        'auto_create' => '1',
        'file' => '.dpkg-meta.yml',
        'backend' => 'Yaml',
        'config_dir' => '~/'
      }
    ],
    'name' => 'Debian::Dpkg::Meta',
    'element' => [
      'email-updates',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'summary' => 'email update hash',
        'type' => 'hash',
        'description' => 'Specify old email as key. The value is the new e-mail address that will be substituted',
        'index_type' => 'string'
      }
    ]
  }
]
;
