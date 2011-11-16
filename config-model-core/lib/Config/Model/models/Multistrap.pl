[
  {
    'accept' => [
      '\\w+',
      {
        'value_type' => 'uniline',
        'warn' => 'Handling unknown parameter as uniline value.',
        'type' => 'leaf'
      }
    ],
    'read_config' => [
      {
        'auto_create' => '1',
        'join_list_value' => ' ',
        'section_map' => {
          'General' => '!'
        },
        'backend' => 'ini_file',
        'write_boolean_as' => [
          'false',
          'true'
        ],
        'split_list_value' => '\\s+',
        'store_class_in_hash' => 'sections'
      }
    ],
    'name' => 'Multistrap',
    'element' => [
      'include',
      {
        'value_type' => 'uniline',
        'class' => 'Config::Model::Value::LayeredInclude',
        'type' => 'leaf'
      },
      'arch',
      {
        'value_type' => 'enum',
        'type' => 'leaf',
        'choice' => [
          'alpha',
          'arm',
          'armel',
          'powerpc'
        ]
      },
      'directory',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'aptsources',
      {
        'cargo' => {
          'value_type' => 'reference',
          'type' => 'leaf',
          'refer_to' => '- sections'
        },
        'duplicates' => 'forbid',
        'type' => 'list',
        'description' => 'aptsources is a list of sections to be used in the /etc/apt/sources.list.d/multistrap.sources.list of the target. Order is not important.'
      },
      'bootstrap',
      {
        'cargo' => {
          'value_type' => 'reference',
          'type' => 'leaf',
          'refer_to' => '- sections'
        },
        'duplicates' => 'forbid',
        'type' => 'list',
        'description' => 'the bootstrap option determines which repository is used to calculate the list of Priority: required packages and which packages go into the rootfs. The order of sections is not important.'
      },
      'debootstrap',
      {
        'cargo' => {
          'value_type' => 'reference',
          'type' => 'leaf',
          'refer_to' => '- sections'
        },
        'duplicates' => 'forbid',
        'type' => 'list'
      },
      'omitrequired',
      {
        'value_type' => 'boolean',
        'type' => 'leaf'
      },
      'addimportant',
      {
        'value_type' => 'boolean',
        'type' => 'leaf'
      },
      'configscript',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'setupscript',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'cleanup',
      {
        'value_type' => 'boolean',
        'type' => 'leaf',
        'description' => 'remove apt cache data, downloaded Packages files and the apt package cache.'
      },
      'noauth',
      {
        'value_type' => 'boolean',
        'type' => 'leaf',
        'description' => 'allow the use of unauthenticated repositories'
      },
      'explicitsuite',
      {
        'value_type' => 'boolean',
        'upstream_default' => '0',
        'type' => 'leaf',
        'description' => 'whether to add the /suite to be explicit about where apt needs to look for packages.'
      },
      'unpack',
      {
        'value_type' => 'boolean',
        'summary' => 'extract all downloaded archives',
        'upstream_default' => '1',
        'type' => 'leaf'
      },
      'sections',
      {
        'cargo' => {
          'type' => 'node',
          'config_class_name' => 'Multistrap::Section'
        },
        'type' => 'hash',
        'index_type' => 'string'
      }
    ]
  }
]
;

