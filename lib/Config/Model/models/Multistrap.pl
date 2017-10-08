[
  {
    'accept' => [
      '\\w+',
      {
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'Handling unknown parameter as uniline value.'
      }
    ],
    'class_description' => 'Class for multistrap configuration files. Note that multistrap is based on INI where section and keys are case insensitive. Hence all sections and keys are converted to lower case and written back as lower case. Most values (but not all) are also case-insensitive. These values will also be written back as lowercase.',
    'element' => [
      'include',
      {
        'class' => 'Config::Model::Value::LayeredInclude',
        'convert' => 'lc',
        'description' => 'To support multiple variants of a basic (common) configuration, "multistrap" allows configuration files to include other (more general) configuration files. i.e. the most detailed / specific configuration file is specified on the command line and that file includes another file which is shared by other configurations.',
        'summary' => 'Include file for cascaded configuration',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'arch',
      {
        'choice' => [
          'alpha',
          'arm',
          'armel',
          'powerpc'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'directory',
      {
        'description' => 'top level directory where the bootstrap will be created',
        'summary' => 'target directory',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'aptsources',
      {
        'cargo' => {
          'convert' => 'lc',
          'refer_to' => '- sections',
          'type' => 'leaf',
          'value_type' => 'reference'
        },
        'description' => 'aptsources is a list of sections to be used in the /etc/apt/sources.list.d/multistrap.sources.list of the target. Order is not important.',
        'duplicates' => 'forbid',
        'type' => 'list'
      },
      'bootstrap',
      {
        'cargo' => {
          'convert' => 'lc',
          'refer_to' => '- sections',
          'type' => 'leaf',
          'value_type' => 'reference'
        },
        'description' => 'the bootstrap option determines which repository is used to calculate the list of Priority: required packages and which packages go into the rootfs. The order of sections is not important.',
        'duplicates' => 'forbid',
        'type' => 'list'
      },
      'debootstrap',
      {
        'cargo' => {
          'convert' => 'lc',
          'refer_to' => '- sections',
          'type' => 'leaf',
          'value_type' => 'reference'
        },
        'description' => 'Replaced by bootstrap parameter',
        'duplicates' => 'forbid',
        'status' => 'deprecated',
        'type' => 'list'
      },
      'omitrequired',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'addimportant',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'configscript',
      {
        'convert' => 'lc',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'setupscript',
      {
        'convert' => 'lc',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'cleanup',
      {
        'description' => 'remove apt cache data, downloaded Packages files and the apt package cache.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'noauth',
      {
        'description' => 'allow the use of unauthenticated repositories',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'explicitsuite',
      {
        'description' => 'whether to add the /suite to be explicit about where apt needs to look for packages.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'unpack',
      {
        'convert' => 'lc',
        'migrate_from' => {
          'formula' => '$old',
          'variables' => {
            'old' => '- forceunpack'
          }
        },
        'summary' => 'extract all downloaded archives',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean'
      },
      'sections',
      {
        'cargo' => {
          'config_class_name' => 'Multistrap::Section',
          'type' => 'node'
        },
        'convert' => 'lc',
        'index_type' => 'string',
        'type' => 'hash'
      },
      'forceunpack',
      {
        'convert' => 'lc',
        'description' => 'deprecated. Replaced by unpack',
        'status' => 'deprecated',
        'summary' => 'extract all downloaded archives',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean'
      }
    ],
    'name' => 'Multistrap',
    'rw_config' => {
      'auto_create' => '1',
      'backend' => 'IniFile',
      'force_lc_key' => '1',
      'force_lc_section' => '1',
      'join_list_value' => ' ',
      'section_map' => {
        'general' => '!'
      },
      'split_list_value' => '\\s+',
      'store_class_in_hash' => 'sections',
      'write_boolean_as' => [
        'false',
        'true'
      ]
    }
  }
]
;

