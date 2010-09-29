[
          {
            'name' => 'Debian::Dpkg::Control::Source',
            'element' => [
                           'Source',
                           {
                             'value_type' => 'uniline',
                             'summary' => 'source package name',
                             'match' => '\\w[\\w+\\-\\.]{1,}',
                             'mandatory' => '1',
                             'type' => 'leaf'
                           },
                           'Maintainer',
                           {
                             'value_type' => 'uniline',
                             'summary' => 'package maintainer\'s name and email address',
                             'match' => '[\\w\\s\\-]+<[\\w\\.\\-\\@]+>',
                             'mandatory' => '1',
                             'type' => 'leaf',
                             'description' => 'The package maintainer\'s name and email address. The name must come first, then the email address inside angle brackets <> (in RFC822 format).

If the maintainer\'s name contains a full stop then the whole field will not work directly as an email address due to a misfeature in the syntax specified in RFC822; a program using this field as an address must check for this and correct the problem if necessary (for example by putting the name in round brackets and moving it to the end, and bringing the email address forward). '
                           },
                           'Uploaders',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'match' => '[\\w\\s\\-]+<[\\w\\.\\-\\@]+>',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list'
                           },
                           'Section',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'The packages in the archive areas main, contrib and non-free are grouped further into sections to simplify handling. 

The archive area and section for each package should be specified in the package\'s Section control record (see Section, Section 5.6.5). However, the maintainer of the Debian archive may override this selection to ensure the consistency of the Debian distribution. The Section field should be of the form:
 * section if the package is in the main archive area,
 * area/section if the package is in the contrib or non-free archive areas.'
                           },
                           'Priority',
                           {
                             'value_type' => 'enum',
                             'help' => {
                                         'standard' => 'These packages provide a reasonably small but not too limited character-mode system. This is what will be installed by default if the user doesn\'t select anything else. It doesn\'t include many large applications. ',
                                         'required' => 'Packages which are necessary for the proper functioning of the system (usually, this means that dpkg functionality depends on these packages). Removing a required package may cause your system to become totally broken and you may not even be able to use dpkg to put things back, so only do so if you know what you are doing. Systems with only the required packages are probably unusable, but they do have enough functionality to allow the sysadmin to boot and install more software. ',
                                         'optional' => '(In a sense everything that isn\'t required is optional, but that\'s not what is meant here.) This is all the software that you might reasonably want to install if you didn\'t know what it was and don\'t have specialized requirements. This is a much larger system and includes the X Window System, a full TeX distribution, and many applications. Note that optional packages should not conflict with each other. ',
                                         'extra' => 'This contains all packages that conflict with others with required, important, standard or optional priorities, or are only likely to be useful if you already know what they are or have specialized requirements (such as packages containing only detached debugging symbols).',
                                         'important' => 'Important programs, including those which one would expect to find on any Unix-like system. If the expectation is that an experienced Unix person who found it missing would say "What on earth is going on, where is foo?", it must be an important package.[5] Other packages without which the system will not run well or be usable must also have priority important. This does not include Emacs, the X Window System, TeX or any other large applications. The important packages are just a bare minimum of commonly-expected and necessary tools.'
                                       },
                             'type' => 'leaf',
                             'choice' => [
                                           'required',
                                           'important',
                                           'standard',
                                           'optional',
                                           'extra'
                                         ]
                           },
                           'Build-Depends',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list'
                           },
                           'Build-Depends-Indep',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list'
                           },
                           'Standards-Version',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf'
                           },
                           'Homepage',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
