[
          {
            'name' => 'Debian::Dpkg::Control::Binary',
            'element' => [
                           'Architecture',
                           {
                             'value_type' => 'string',
                             'mandatory' => '1',
                             'type' => 'leaf'
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
                             'type' => 'list'
                           },
                           'Recommends',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list'
                           },
                           'Suggests',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list'
                           },
                           'Enhances',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf'
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
                                          'type' => 'leaf'
                                        },
                             'type' => 'list'
                           },
                           'Conflicts',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
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
                                          'type' => 'leaf'
                                        },
                             'type' => 'list'
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
                                                                   }
                                                },
                             'mandatory' => '1',
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
