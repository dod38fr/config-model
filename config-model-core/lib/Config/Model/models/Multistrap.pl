[
  {
    'class_description' => 'Class for multistrap configuration files. Note that multistrap is based on INI where section and keys are case insensitive. Hence all sections and keys are converted to lower case and written back as lower case. Most values (but not all) are also case-insensitive. These values will also be written back as lowercase.',
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
        'force_lc_section' => '1',
        'join_list_value' => ' ',
        'backend' => 'ini_file',
        'force_lc_key' => '1',
        'auto_create' => '1',
        'section_map' => {
          'general' => '!'
        },
        'split_list_value' => '\\s+',
        'write_boolean_as' => [
          'false',
          'true'
        ],
        'store_class_in_hash' => 'sections'
      }
    ],
    'name' => 'Multistrap',
    'element' => [
      'include',
      {
        'convert' => 'lc',
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
          'convert' => 'lc',
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
          'convert' => 'lc',
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
          'convert' => 'lc',
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
        'convert' => 'lc',
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'setupscript',
      {
        'convert' => 'lc',
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
        'convert' => 'lc',
        'value_type' => 'boolean',
        'summary' => 'extract all downloaded archives',
        'upstream_default' => '1',
        'migrate_from' => {
          'formula' => '$old',
          'variables' => {
            'old' => '- forceunpack'
          }
        },
        'type' => 'leaf'
      },
      'sections',
      {
        'convert' => 'lc',
        'cargo' => {
          'type' => 'node',
          'config_class_name' => 'Multistrap::Section'
        },
        'type' => 'hash',
        'index_type' => 'string'
      },
      'forceunpack',
      {
        'convert' => 'lc',
        'value_type' => 'boolean',
        'summary' => 'extract all downloaded archives',
        'status' => 'deprecated',
        'upstream_default' => '1',
        'type' => 'leaf',
        'description' => 'deprecated. Replaced by unpack'
      }
    ]
  }
]
;

