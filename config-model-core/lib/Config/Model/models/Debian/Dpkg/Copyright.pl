[
  {
    'class_description' => 'Machine-readable debian/copyright. Parameters from former version 
of DEP-5 are flagged as deprecated. The idea is to enable migration from older 
specs to CANDIDATE spec.

To edit a copyright file, go into your package development directory and run:

  config-edit -application dpkg-copyright
   
To check you file run:

  config-edit -application dpkg-copyright -ui none
    
To upgrade your file from an old spec, run:

  config-edit -application dpkg-copyright -ui none -save
',
    'accept' => [
      '.*',
      {
        'value_type' => 'string',
        'type' => 'leaf'
      }
    ],
    'name' => 'Debian::Dpkg::Copyright',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
    'element' => [
      'Format',
      {
        'value_type' => 'uniline',
        'warn_unless_match' => {
          '^http://www.debian.org/doc/packaging-manuals/copyright-format/1\\.0/?$' => {
            'msg' => 'Format does not match the recommended URL for DEP-5',
            'fix' => '$_ = \'http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/\';'
          }
        },
        'match' => '^http://',
        'default' => 'http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/',
        'mandatory' => '1',
        'type' => 'leaf',
        'description' => 'URI of the format specification.'
      },
      'Upstream-Name',
      {
        'value_type' => 'uniline',
        'migrate_from' => {
          'formula' => '$name',
          'variables' => {
            'name' => '- Name'
          }
        },
        'type' => 'leaf',
        'description' => 'The name upstream uses for the software.'
      },
      'Upstream-Contact',
      {
        'migrate_keys_from' => '- Upstream-Maintainer',
        'cargo' => {
          'value_type' => 'uniline',
          'migrate_from' => {
            'formula' => '$maintainer',
            'variables' => {
              'maintainer' => '- Upstream-Maintainer:&index'
            }
          },
          'type' => 'leaf'
        },
        'type' => 'list',
        'description' => 'The preferred address(es) to reach the upstream project. May be free-form text, but by convention will usually be written as a list of RFC5822 addresses or URIs.'
      },
      'Source',
      {
        'value_type' => 'string',
        'migrate_from' => {
          'undef_is' => '\'\'',
          'use_eval' => '1',
          'formula' => '$old || $older ;',
          'variables' => {
            'older' => '- Original-Source-Location',
            'old' => '- Upstream-Source'
          }
        },
        'type' => 'leaf',
        'description' => 'An explanation from where the upstream source came from. Typically this would be a URL, but it might be a free-form explanation. The Debian Policy, 12.5 requires this information unless there are no upstream sources, which is mainly the case for native Debian packages. If the upstream source has been modified to remove non-free parts, that should be explained in this field.'
      },
      'Disclaimer',
      {
        'value_type' => 'string',
        'warn_if_match' => {
          'dh-make-perl' => {
            'msg' => 'Disclaimer contains dh-make-perl boilerplate',
            'fix' => '$_ = undef ;'
          }
        },
        'type' => 'leaf',
        'description' => 'This field can be used in the case of non-free and contrib packages (see [Policy 12.5]( http://www.debian.org/doc/debian-policy/ch-docs.html#s-copyrightfile))'
      },
      'Comment',
      {
        'value_type' => 'string',
        'migrate_from' => {
          'formula' => '$old',
          'variables' => {
            'old' => '- X-Comment'
          }
        },
        'type' => 'leaf',
        'description' => 'This field can provide additional information. For example, it might quote an e-mail from upstream justifying why the license is acceptable to the main archive, or an explanation of how this version of the package has been forked from a version known to be DFSG-free, even though the current upstream version is not.'
      },
      'Copyright',
      {
        'value_type' => 'string',
        'type' => 'leaf',
        'description' => 'Copyright information for the package as a whole, which may be different or simplified from a combination of all the per-file copyright information. See also Copyright below in the Files paragraph section.'
      },
      'Files',
      {
        'cargo' => {
          'type' => 'node',
          'config_class_name' => 'Debian::Dpkg::Copyright::Content'
        },
        'ordered' => '1',
        'type' => 'hash',
        'description' => 'Patterns indicating files having the same license and sharing copyright holders. See "File patterns" below',
        'index_type' => 'string'
      },
      'Global-License',
      {
        'type' => 'node',
        'config_class_name' => 'Debian::Dpkg::Copyright::GlobalLicense'
      },
      'Format-Specification',
      {
        'value_type' => 'uniline',
        'status' => 'deprecated',
        'type' => 'leaf'
      },
      'Name',
      {
        'value_type' => 'uniline',
        'status' => 'deprecated',
        'type' => 'leaf'
      },
      'Maintainer',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'status' => 'deprecated',
        'type' => 'list',
        'description' => 'Line(s) containing the preferred address(es) to reach current upstream maintainer(s). May be free-form text, but by convention will usually be written as a list of RFC2822 addresses or URIs.'
      },
      'Upstream-Maintainer',
      {
        'migrate_keys_from' => '- Maintainer',
        'cargo' => {
          'value_type' => 'uniline',
          'migrate_from' => {
            'formula' => '$maintainer',
            'variables' => {
              'maintainer' => '- Maintainer:&index'
            }
          },
          'type' => 'leaf'
        },
        'status' => 'deprecated',
        'type' => 'list'
      },
      'Upstream-Source',
      {
        'value_type' => 'string',
        'status' => 'deprecated',
        'type' => 'leaf'
      },
      'Original-Source-Location',
      {
        'value_type' => 'string',
        'status' => 'deprecated',
        'type' => 'leaf'
      },
      'License',
      {
        'cargo' => {
          'type' => 'node',
          'config_class_name' => 'Debian::Dpkg::Copyright::LicenseSpec'
        },
        'allow_keys_matching' => '^[\\w\\-\\.+]+$',
        'type' => 'hash',
        'index_type' => 'string'
      },
      'X-Comment',
      {
        'value_type' => 'string',
        'status' => 'deprecated',
        'type' => 'leaf'
      }
    ],
    'read_config' => [
      {
        'auto_create' => '1',
        'file' => 'copyright',
        'backend' => 'Debian::Dpkg::Copyright',
        'config_dir' => 'debian'
      }
    ]
  }
]
;

