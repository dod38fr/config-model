[
          {
            'class_description' => 'Machine-readable debian/copyright',
            'accept' => [
                          {
                            'value_type' => 'string',
                            'name_match' => 'X-.*',
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
                             ],
            'name' => 'Debian::Dpkg::Copyright',
            'element' => [
                           'Format-Specification',
                           {
                             'value_type' => 'uniline',
                             'default' => 'http://svn.debian.org/wsvn/dep/web/deps/dep5.mdwn?op=file&rev=135',
                             'mandatory' => '1',
                             'type' => 'leaf',
                             'description' => 'URI of the format specification, such as: http://svn.debian.org/wsvn/dep/web/deps/dep5.mdwn?op=file&amp;rev=REVISION'
                           },
                           'Name',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Single line (in most cases a single word), containing the name of the software.'
                           },
                           'Maintainer',
                           {
                             'value_type' => 'string',
                             'type' => 'leaf',
                             'description' => 'Line(s) containing the preferred address(es) to reach current upstream maintainer(s). May be free-form text, but by convention will usually be written as a list of RFC2822 addresses or URIs.'
                           },
                           'Source',
                           {
                             'value_type' => 'string',
                             'type' => 'leaf',
                             'description' => 'One or more URIs, one per line, indicating the primary point of distribution of the software.'
                           },
                           'Disclaimer',
                           {
                             'value_type' => 'string',
                             'type' => 'leaf',
                             'description' => 'Free-form text. On Debian systems, this field can be used in the case of non-free and contrib packages (see Policy_12.5)'
                           },
                           'Copyright',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'match' => '[\\d\\-\\,]+, .*',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list'
                           },
                           'Files',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Debian::Dpkg::Copyright::Content'
                                        },
                             'ordered' => '1',
                             'type' => 'hash',
                             'description' => 'Patterns indicating files having the same license
  and sharing copyright holders. See "File patterns" below',
                             'index_type' => 'string'
                           },
                           'License',
                           {
                             'cargo' => {
                                          'value_type' => 'string',
                                          'type' => 'leaf'
                                        },
                             'warn_unless_key_match' => '^(?i:Apache|Artistic|BSD|FreeBSD|ISC|CC-BY|CC-BY-SA|CC-BY-ND|CC-BY-NC|CC-BY-NC-SA|CC-BY-NC-ND|CC0|CDDL|CPL|Eiffel|Expat|GPL|LGPL|GFDL|GFDL-NIV|LPPL|MIT|MPL|Perl|PSF|QPL|W3C-Software|ZLIB|Zope)[\\d\\.\\-]*\\+?$',
                             'allow_keys_matching' => '^[\\w\\-\\.]+$',
                             'type' => 'hash',
                             'index_type' => 'string'
                           }
                         ]
          }
        ]
;
