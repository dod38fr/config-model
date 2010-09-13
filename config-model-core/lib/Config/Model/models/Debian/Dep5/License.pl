[
          {
            'name' => 'Debian::Dep5::License',
            'element' => [
                           'abbrev',
                           {
                             'value_type' => 'uniline',
                             'grammar' => 'license (oper license)(s?) 
oper: \'and\' | \'or\' 
license: /[\w\-\.\+]+/i
   { # PRD action to check if the license text is provided
     $return = $arg[0]->grab("! License")->defined($item[0]);
   } ',
                             'help' => {
                                         'Zope' => 'Zope Public License. For versions, consult Zope.org',
                                         'MPL' => 'Mozilla Public License. For versions, consult Mozilla.org',
                                         'LGPL' => 'GNU Lesser General Public License, (GNU Library General Public License for versions lower than 2.1)',
                                         'Eiffel' => 'The Eiffel Forum License. For versions, consult the Open_Source_Initiative',
                                         'Perl' => 'Perl license (equates to "GPL-1+ or Artistic-1")',
                                         'Artistic' => 'Artistic license. For versions, consult the Perl_Foundation',
                                         'CC-BY' => 'Creative Commons Attribution license',
                                         'ZLIB' => 'zlib/libpng_license',
                                         'W3C-Software' => 'W3C Software License. For more information, consult the W3C IntellectualRights FAQ and the 20021231 W3C_Software_notice_and_license',
                                         'PSF' => 'Python Software Foundation license. For versions, consult the Python_Software Foundation',
                                         'Expat' => 'The Expat license',
                                         'LPPL' => 'LaTeX Project Public License',
                                         'CC-BY-NC-SA' => 'Creative Commons Attribution Non-Commercial Share Alike',
                                         'CC-BY-SA' => 'Creative Commons Attribution Share Alike license',
                                         'GPL' => 'GNU General Public License',
                                         'GFDL' => 'GNU Free Documentation License',
                                         'CC0' => 'Creative Commons Universal waiver',
                                         'FreeBSD' => 'FreeBSD Project license',
                                         'BSD' => 'Berkeley software distribution license',
                                         'CC-BY-NC' => 'Creative Commons Attribution Non-Commercial',
                                         'CDDL' => 'Common Development and Distribution License. For versions, consult Sun Microsystems.',
                                         'ISC' => "Internet_Software_Consortium\x{2019}s license, sometimes also known as the OpenBSD License",
                                         'CC-BY-NC-ND' => 'Creative Commons Attribution Non-Commercial No Derivatives',
                                         'GFDL-NIV' => 'GNU Free Documentation License, with no invariant sections',
                                         'CPL' => 'IBM Common Public License. For versions, consult the IBM_Common_Public License_(CPL)_Frequently_asked_questions.',
                                         'CC-BY-ND' => 'Creative Commons Attribution No Derivatives',
                                         'other' => 'Any other custom license. License notice text must be copied verbatim.',
                                         'QPL' => 'Q Public License',
                                         'Apache' => 'Apache license. For versions, consult the Apache_Software_Foundation.'
                                       },
                             'default' => 'other',
                             'type' => 'leaf',
                             'description' => 'abbreviated name for the license. If empty, it is given the default value \'other\'. Only one license per file can use this default value; if there is more than one license present in the package without a standard short name, an arbitrary short name may be assigned for these licenses. These arbitrary names are only guaranteed to be unique within a single copyright file.
'
                           },
                           'exception',
                           {
                             'value_type' => 'enum',
                             'help' => {
                                         'Font' => 'The GPL "Font" exception refers to the text added to the license notice of each file as specified at How_does_the_GPL_apply_to_fonts?. The precise text corresponding to this exception is:
     As a special exception, if you create a document which uses this
     font, and embed this font or unaltered portions of this font into the
     document, this font does not by itself cause the resulting document
     to be covered by the GNU General Public License. This exception does
     not however invalidate any other reasons why the document might be
     covered by the GNU General Public License. If you modify this font,
     you may extend this exception to your version of the font, but you
     are not obligated to do so. If you do not wish to do so, delete this
     exception statement from your version.',
                                         'OpenSSL' => 'The GPL "OpenSSL" exception gives permission to link GPL-licensed code with the OpenSSL library, which contains GPL-incompatible clauses. For more information, see "The_-OpenSSL_License_and_The_GPL" by Mark McLoughlin and the message "middleman_software_license_conflicts_with_OpenSSL" by Mark McLoughlin on the debian-legal mailing list. The text corresponding to this exception is:
     In addition, as a special exception, the copyright holders give
     permission to link the code of portions of this program with the
     OpenSSL library under certain conditions as described in each
     individual source file, and distribute linked combinations including
     the two.
     You must obey the GNU General Public License in all respects for all
     of the code used other than OpenSSL. If you modify file(s) with this
     exception, you may extend this exception to your version of the file
     (s), but you are not obligated to do so. If you do not wish to do so,
     delete this exception statement from your version. If you delete this
     exception statement from all source files in the program, then also
     delete it here.'
                                       },
                             'type' => 'leaf',
                             'description' => 'License exception',
                             'choice' => [
                                           'Font',
                                           'OpenSSL'
                                         ]
                           },
                           'full_license',
                           {
                             'value_type' => 'string',
                             'type' => 'leaf',
                             'description' => "if left blank here, the file must include a stand-alone License section matching each license short name listed on the first line (see the Standalone License Section section). Otherwise, this field should either include the full text of the license(s) or include a pointer to the license file under /usr/share/common-licenses. This field should include all text needed in order to fulfill both Debian Policy\x{2019}s requirement for including a copy of the software\x{2019}s distribution license (\x{a7}12.5), and any license requirements to include warranty disclaimers or other notices with the binary package.
"
                           }
                         ]
          }
        ]
;
