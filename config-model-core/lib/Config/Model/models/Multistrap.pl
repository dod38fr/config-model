[
  {
    'accept' => [
      '\\w+',
      {
        'value_type' => 'uniline',
        'warn' => 'Handling unknown parameter as unlinie value.',
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
        'split_list_value' => '\\s+',
        'store_class_in_hash' => 'sections'
      }
    ],
    'name' => 'Multistrap',
    'element' => [
      'include',
      {
        'value_type' => 'uniline',
        'class' => 'Config::Model::Value::PresetFromInclude',
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
        'type' => 'list'
      },
      'bootstrap',
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

