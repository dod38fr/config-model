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
      },
      'dependency-filter',
      {
        'value_type' => 'enum',
        'warp' => {
          'follow' => {
            'maintainer' => '! control source Maintainer'
          },
          'rules' => [
            '$maintainer =~ /Debian Perl/',
            {
              'default' => 'squeeze'
            }
          ]
        },
        'type' => 'leaf',
        'description' => 'Specifies the depedency filter to be used. The release specified mentions the most recent release to be filterd out. Oldser release will also be filtered.

For instance, if the dependency filter is \'lenny\', all \'lenny\' and \'etch\' dependencies are filtered out.',
        'choice' => [
          'etch',
          'lenny',
          'squeeze',
          'wheezy'
        ]
      }
    ]
  }
]
;
