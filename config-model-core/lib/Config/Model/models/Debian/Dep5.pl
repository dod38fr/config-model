[
          {
            'class_description' => 'Machine-readable debian/copyright
',
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
                                 'file' => 'license',
                                 'backend' => 'Debian::Dep5',
                                 'config_dir' => '/'
                               }
                             ],
            'name' => 'Debian::Dep5',
            'element' => [
                           'Disclaimer',
                           {
                             'value_type' => 'string',
                             'type' => 'leaf',
                             'description' => 'Free-form text. On Debian systems, this field can be used in the case of non-free and contrib packages (see Policy_12.5)
'
                           },
                           'Files',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Debian::Dep5::Content'
                                        },
                             'ordered' => '1',
                             'type' => 'hash',
                             'description' => 'o Required for all but the first stanza. If omitted from the first
  stanza, this is equivalent to a value of \'*\'.
o Syntax: List of patterns indicating files having the same license
  and sharing copyright holders. See "File patterns" below',
                             'index_type' => 'string'
                           },
                           'Format-Specification',
                           {
                             'value_type' => 'uniline',
                             'mandatory' => '1',
                             'type' => 'leaf',
                             'description' => 'URI of the format specification, such as: http://svn.debian.org/wsvn/dep/web/deps/dep5.mdwn?op=file&amp;rev=REVISION'
                           },
                           'Maintainer',
                           {
                             'value_type' => 'string',
                             'type' => 'leaf',
                             'description' => 'Line(s) containing the preferred address(es) to reach current upstream maintainer(s). May be free-form text, but by convention will usually be written as a list of RFC2822 addresses or URIs.
'
                           },
                       'Copyright',
                           {
                             'value_type' => 'string',
                             'type' => 'leaf',
                           },
                           'Name',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Single line (in most cases a single word), containing the name of the software.
'
                           },
                           'Source',
                           {
                             'value_type' => 'string',
                             'type' => 'leaf',
                             'description' => 'One or more URIs, one per line, indicating the primary point of distribution of the software.
'
                           },
                           'License',
                           {
                             'cargo' => {
                                          'value_type' => 'string',
                                          'type' => 'leaf'
                                        },
                             'allow_keys_matching' => '^(?i:Apache|Artistic|BSD|FreeBSD|ISC|CC-BY|CC-BY-SA|CC-BY-ND|CC-BY-NC|CC-BY-NC-SA|CC-BY-NC-ND|CC0|CDDL|CPL|Eiffel|Expat|GPL|LGPL|GFDL|GFDL-NIV|LPPL|MIT|MPL|Perl|PSF|QPL|W3C-Software|ZLIB|Zope|other)[\d\.\-]*\+?$',
                             'type' => 'hash',
                             'index_type' => 'string'
                           }
                         ]
          }
        ]
;
