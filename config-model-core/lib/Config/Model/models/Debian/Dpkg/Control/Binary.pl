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
      'Section',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'Priority',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'Essential',
      {
        'value_type' => 'boolean',
        'type' => 'leaf'
      },
      'Depends',
      {
        'cargo' => {
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
          '^[A-Z]' => {
            'msg' => 'short description should start with a small letter',
            'fix' => '$_ = lcfirst($_) ;'
          },
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

