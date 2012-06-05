[
  {
    'name' => 'Debian::Dpkg::Copyright::GlobalLicense',
    'copyright' => [
      '2010',
      '2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
    'element' => [
      'short_name',
      {
        'value_type' => 'uniline',
        'warp' => {
          'rules' => [
            '&location !~ /Global/',
            {
              'mandatory' => '1'
            }
          ]
        },
        'help' => {
          'Zope' => 'Zope Public License. For versions, consult Zope.org',
          'MPL' => 'Mozilla Public License. For versions, consult Mozilla.org',
          'LGPL' => 'GNU Lesser General Public License, (GNU Library General Public License for versions lower than 2.1)',
          'Perl' => 'Perl license (equates to "GPL-1+ or Artistic-1")',
          'Artistic' => 'Artistic license. For versions, consult the Perl_Foundation',
          'CC-BY' => 'Creative Commons Attribution license',
          'ZLIB' => 'zlib/libpng_license',
          'Expat' => 'The Expat license',
          'EFL' => 'The Eiffel Forum License. For versions, consult the Open_Source_Initiative',
          'BSD-3-clause' => 'Berkeley software distribution license, 3-clause version',
          'LPPL' => 'LaTeX Project Public License',
          'CC-BY-NC-SA' => 'Creative Commons Attribution Non-Commercial Share Alike',
          'BSD-4-clause' => 'Berkeley software distribution license, 4-clause version',
          'CC-BY-SA' => 'Creative Commons Attribution Share Alike license',
          'GPL' => 'GNU General Public License',
          'GFDL' => 'GNU Free Documentation License',
          'CC0' => 'Creative Commons Universal waiver',
          'Python-CNRI' => 'Python Software Foundation license. For versions, consult the Python_Software Foundation',
          'FreeBSD' => 'FreeBSD Project license',
          'CC-BY-NC' => 'Creative Commons Attribution Non-Commercial',
          'CDDL' => 'Common Development and Distribution License. For versions, consult Sun Microsystems.',
          'ISC' => "Internet_Software_Consortium's license, sometimes also known as the OpenBSD License",
          'CC-BY-NC-ND' => 'Creative Commons Attribution Non-Commercial No Derivatives',
          'GFDL-NIV' => 'GNU Free Documentation License, with no invariant sections',
          'CPL' => 'IBM Common Public License. For versions, consult the IBM_Common_Public License_(CPL)_Frequently_asked_questions.',
          'CC-BY-ND' => 'Creative Commons Attribution No Derivatives',
          'BSD-2-clause' => 'Berkeley software distribution license, 2-clause version',
          'W3C' => 'W3C Software License. For more information, consult the W3C IntellectualRights FAQ and the 20021231 W3C_Software_notice_and_license',
          'QPL' => 'Q Public License',
          'Apache' => 'Apache license. For versions, consult the Apache_Software_Foundation.'
        },
        'type' => 'leaf',
        'description' => 'The Copyright and License fields in the header paragraph may complement but do not replace the files paragraphs. They can be used to summarise the contributions and redistribution terms for the whole package, for instance when a work combines a permissive and a copyleft license, or to document a compilation copyright and license. It is possible to use only License in the header paragraph, but Copyright alone makes no sense.'
      },
      'full_license',
      {
        'value_type' => 'string',
        'type' => 'leaf',
        'description' => 'if left blank here, the file must include a stand-alone License section matching each license short name listed on the first line (see the Standalone License Section section). Otherwise, this field should either include the full text of the license(s) or include a pointer to the license file under /usr/share/common-licenses. This field should include all text needed in order to fulfill both Debian Policy requirement for including a copy of the software distribution license, and any license requirements to include warranty disclaimers or other notices with the binary package.
'
      }
    ]
  }
]
;

