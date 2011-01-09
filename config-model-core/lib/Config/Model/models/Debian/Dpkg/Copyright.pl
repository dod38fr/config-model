[
          {
            'class_description' => 'Machine-readable debian/copyright. Parameters from former version of DEP-5 are flagged as deprecated. The idea is to enable migration from older specs to CANDIDATE spec.',
            'accept' => [
                          'X-.*',
                          {
                            'value_type' => 'string',
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
                           'Format',
                           {
                             'value_type' => 'uniline',
                             'default' => 'http://svn.debian.org/wsvn/dep/web/deps/dep5.mdwn?op=file&rev=153',
                             'mandatory' => '1',
                             'type' => 'leaf',
                             'description' => 'URI of the format specification, such as: http://svn.debian.org/wsvn/dep/web/deps/dep5.mdwn?op=file&amp;rev=REVISION'
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
                             'value_type' => 'string',
                             'migrate_from' => {
                                                 'formula' => '$old_maintainer',
                                                 'variables' => {
                                                                  'old_maintainer' => '- Maintainer'
                                                                }
                                               },
                             'type' => 'leaf',
                             'description' => '* Syntax: line based list
* The preferred address(es) to reach the upstream project. May be free-form text, but by convention will usually be written as a list of RFC5822 addresses or URIs.'
                           },
                           'Source',
                           {
                             'value_type' => 'string',
                             'mandatory' => '1',
                             'migrate_from' => {
                                                 'formula' => '$old',
                                                 'variables' => {
                                                                  'old' => '- Upstream-Source'
                                                                }
                                               },
                             'type' => 'leaf',
                             'description' => '* Syntax: formatted text, no synopsis 
* An explanation from where the upstream source came from. Typically this would be a URL, but it might be a free-form explanation. If the upstream source has been modified to remove non-free parts, that should be explained in this field.'
                           },
                           'Disclaimer',
                           {
                             'value_type' => 'string',
                             'type' => 'leaf',
                             'description' => '* Syntax: formatted text, no synopsis 
* This field can be used in the case of non-free and contrib packages (see [Policy 12.5]( http://www.debian.org/doc/debian-policy/ch-docs.html#s-copyrightfile))'
                           },
                           'Comment',
                           {
                             'value_type' => 'string',
                             'type' => 'leaf',
                             'description' => '* Syntax: formatted text, no synopsis
* Description: This field can provide additional information. For example, it might quote an e-mail from upstream justifying why the license is acceptable to the main archive, or an explanation of how this version of the package has been forked from a version known to be DFSG-free, even though the current upstream version is not.'
                           },
                           'Copyright',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
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
                           'License',
                           {
                             'cargo' => {
                                          'value_type' => 'string',
                                          'type' => 'leaf'
                                        },
                             'warn_unless_key_match' => '^(?i:Apache|Artistic|BSD|FreeBSD|ISC|CC-BY|CC-BY-SA|CC-BY-ND|CC-BY-NC|CC-BY-NC-SA|CC-BY-NC-ND|CC0|CDDL|CPL|Eiffel|Expat|GPL|LGPL|GFDL|GFDL-NIV|LPPL|MIT|MPL|Perl|PSF|QPL|W3C-Software|ZLIB|Zope)[\\d\\.\\-]*\\+?$',
                             'allow_keys_matching' => '^[\\w\\-\\.+]+$',
                             'type' => 'hash',
                             'index_type' => 'string'
                           },
                           'Format-Specification',
                           {
                             'value_type' => 'uniline',
                             'status' => 'deprecated',
                             'default' => 'http://svn.debian.org/wsvn/dep/web/deps/dep5.mdwn?op=file&rev=153',
                             'mandatory' => '1',
                             'type' => 'leaf',
                             'description' => 'URI of the format specification, such as: http://svn.debian.org/wsvn/dep/web/deps/dep5.mdwn?op=file&amp;rev=REVISION'
                           },
                           'Name',
                           {
                             'value_type' => 'string',
                             'status' => 'deprecated',
                             'type' => 'leaf'
                           },
                           'Maintainer',
                           {
                             'value_type' => 'string',
                             'status' => 'deprecated',
                             'migrate_from' => {
                                                 'formula' => '$old_maintainer',
                                                 'variables' => {
                                                                  'old_maintainer' => '- Upstream-Maintainer'
                                                                }
                                               },
                             'type' => 'leaf',
                             'description' => 'Line(s) containing the preferred address(es) to reach current upstream maintainer(s). May be free-form text, but by convention will usually be written as a list of RFC2822 addresses or URIs.'
                           },
                           'Upstream-Maintainer',
                           {
                             'value_type' => 'string',
                             'status' => 'deprecated',
                             'type' => 'leaf'
                           },
                           'Upstream-Source',
                           {
                             'value_type' => 'string',
                             'status' => 'deprecated',
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
