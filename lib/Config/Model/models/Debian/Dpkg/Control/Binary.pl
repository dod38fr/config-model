[
  {
    'name' => 'Debian::Dpkg::Control::Binary',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
    'element' => [
      'Architecture',
      {
        'value_type' => 'string',
        'mandatory' => '1',
        'type' => 'leaf',
        'description' => 'If a program needs to specify an architecture specification string in some place, it should select one of the strings provided by dpkg-architecture -L. The strings are in the format os-arch, though the OS part is sometimes elided, as when the OS is Linux. 
A package may specify an architecture wildcard. Architecture wildcards are in the format any (which matches every architecture), os-any, or any-cpu. For more details, see L<http://www.debian.org/doc/debian-policy/ch-customized-programs.html#s-arch-spec| Debian policy>'
      },
      'Multi-Arch',
      {
        'value_type' => 'enum',
        'help' => {
          'foreign' => 'the package is not co-installable with itself, but should be allowed to satisfy the dependency of a package of a different arch from itself.',
          'allowed' => 'allows reverse-dependencies to indicate in their Depends field that they need a package from a foreign architecture, but has no effect otherwise.',
          'same' => 'the package is co-installable with itself, but it must not be used to satisfy the dependency of any package of a different architecture from itself.'
        },
        'type' => 'leaf',
        'description' => 'This field is used to indicate how this package should behave on a multi-arch installations. This field should not be present in packages with the Architecture: all field.',
        'choice' => [
          'same',
          'foreign',
          'allowed'
        ]
      },
      'Section',
      {
        'warn_unless' => {
          'area' => {
            'msg' => 'Bad area. Should be \'non-free\' or \'contrib\'',
            'code' => '(not defined) or m!^((contrib|non-free)/)?\\w+$!;'
          },
          'section' => {
            'msg' => 'Bad section.',
            'code' => '(not defined) or m!^([-\\w]+/)?(admin|cli-mono|comm|database|devel|debug|doc|editors|education|electronics|embedded|fonts|games|gnome|graphics|gnu-r|gnustep|hamradio|haskell|httpd|interpreters|introspection|java|kde|kernel|libs|libdevel|lisp|localization|mail|math|metapackages|misc|net|news|ocaml|oldlibs|otherosfs|perl|php|python|ruby|science|shells|sound|tex|text|utils|vcs|video|web|x11|xfce|zope)$!;'
          }
        },
        'compute' => {
          'use_as_upstream_default' => '1',
          'formula' => '$source',
          'variables' => {
            'source' => '- - source Section'
          }
        },
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'Priority',
      {
        'compute' => {
          'use_as_upstream_default' => '1',
          'formula' => '$source',
          'variables' => {
            'source' => '- - source Priority'
          }
        },
        'value_type' => 'enum',
        'type' => 'leaf',
        'choice' => [
          'required',
          'important',
          'standard',
          'optional',
          'extra'
        ]
      },
      'Essential',
      {
        'value_type' => 'boolean',
        'type' => 'leaf'
      },
      'Depends',
      {
        'cargo' => {
          'warn_unless' => {
            'libtiff4 transition' => {
              'msg' => 'libtiff4 is transtioning to versioned symbols. New packages should build-depend on libtiff4 (>= 3.9.5-2).',
              'fix' => '$_ = \'libtiff4 (>= 3.9.5-2)\';',
              'code' => 'not /libtiff4/ or /libtiff4\\s*\\(>=\\s*3.9.5-2\\s*\\)/'
            }
          },
          'value_type' => 'uniline',
          'class' => 'Config::Model::Debian::Dependency',
          'type' => 'leaf'
        },
        'duplicates' => 'warn',
        'type' => 'list'
      },
      'Recommends',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'class' => 'Config::Model::Debian::Dependency',
          'type' => 'leaf'
        },
        'duplicates' => 'warn',
        'type' => 'list'
      },
      'Suggests',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'class' => 'Config::Model::Debian::Dependency',
          'type' => 'leaf'
        },
        'duplicates' => 'warn',
        'type' => 'list'
      },
      'Enhances',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'class' => 'Config::Model::Debian::Dependency',
          'type' => 'leaf'
        },
        'type' => 'list'
      },
      'Pre-Depends',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'class' => 'Config::Model::Debian::Dependency',
          'type' => 'leaf'
        },
        'type' => 'list'
      },
      'Breaks',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'class' => 'Config::Model::Debian::Dependency',
          'type' => 'leaf'
        },
        'type' => 'list'
      },
      'Conflicts',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'class' => 'Config::Model::Debian::Dependency',
          'type' => 'leaf'
        },
        'type' => 'list'
      },
      'Provides',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'type' => 'list'
      },
      'Replaces',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'class' => 'Config::Model::Debian::Dependency',
          'type' => 'leaf'
        },
        'type' => 'list'
      },
      'Package-Type',
      {
        'value_type' => 'enum',
        'summary' => 'The type of the package, if not a regular Debian one',
        'experience' => 'advanced',
        'migrate_from' => {
          'formula' => '$xc',
          'variables' => {
            'xc' => '- XC-Package-Type'
          }
        },
        'type' => 'leaf',
        'description' => 'If this field is present, the package is not a regular Debian package, but either a udeb generated for the Debian installer or a tdeb containing translated debconf strings.',
        'choice' => [
          'tdeb',
          'udeb'
        ]
      },
      'XC-Package-Type',
      {
        'value_type' => 'enum',
        'summary' => 'The type of the package, if not a regular Debian one',
        'status' => 'deprecated',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'If this field is present, the package is not a regular Debian package, but either a udeb generated for the Debian installer or a tdeb containing translated debconf strings.',
        'choice' => [
          'tdeb',
          'udeb'
        ]
      },
      'Synopsis',
      {
        'value_type' => 'uniline',
        'warn_if_match' => {
          '.{60,}' => {
            'msg' => 'Synopsis is too long. '
          }
        },
        'mandatory' => '1',
        'type' => 'leaf'
      },
      'Description',
      {
        'value_type' => 'string',
        'warn_if_match' => {
          'Debian GNU/Linux' => {
            'msg' => 'deprecated in favor of Debian GNU',
            'fix' => 's!Debian GNU/Linux!Debian GNU!g;'
          },
          '[^\\n]{80,}' => {
            'msg' => 'Line too long in description',
            'fix' => 'eval { require Text::Autoformat   ; } ;
if ($@) { CORE::warn "cannot fix without Text::Autoformat"}
else {
        import Text::Autoformat ;
        $_ = autoformat($_) ;
	chomp;
}'
          },
          '\\n[\\-\\*]' => {
            'msg' => 'lintian like possible-unindented-list-in-extended-description. i.e. "-" or "*" without leading white space',
            'fix' => 's/\\n([\\-\\*])/\\n $1/g; $_ ;'
          },
          'automagically.*dh-make-perl' => {
            'msg' => 'Description contains dh-make-perl boilerplate'
          },
          '^\\s*\\n' => {
            'msg' => 'Description must not start with an empty line',
            'fix' => 's/[\\s\\s]+// ;'
          }
        },
        'mandatory' => '1',
        'type' => 'leaf'
      }
    ]
  }
]
;

