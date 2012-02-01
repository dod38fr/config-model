[
  {
    'name' => 'Debian::Dpkg::Control::Source',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
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
        'mandatory' => '1',
        'type' => 'leaf',
        'description' => 'The package maintainer\'s name and email address. The name must come first, then the email address inside angle brackets <> (in RFC822 format).

If the maintainer\'s name contains a full stop then the whole field will not work directly as an email address due to a misfeature in the syntax specified in RFC822; a program using this field as an address must check for this and correct the problem if necessary (for example by putting the name in round brackets and moving it to the end, and bringing the email address forward). '
      },
      'Uploaders',
      {
        'cargo' => {
          'replace_follow' => '!Debian::Dpkg meta email-updates',
          'value_type' => 'uniline',
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
          'class' => 'Config::Model::Debian::Dependency',
          'type' => 'leaf'
        },
        'duplicates' => 'warn',
        'type' => 'list'
      },
      'Build-Depends-Indep',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'class' => 'Config::Model::Debian::Dependency',
          'type' => 'leaf'
        },
        'duplicates' => 'warn',
        'type' => 'list'
      },
      'Build-Conflicts',
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
        'summary' => 'Debian policy version number this package complies to',
        'warn_unless_match' => {
          '3\\.9\\.2' => {
            'msg' => 'Current standards version is 3.9.2',
            'fix' => '$_ = undef; # restore default value'
          }
        },
        'match' => '\\d+\\.\\d+\\.\\d+(\\.\\d+)?',
        'default' => '3.9.2',
        'type' => 'leaf',
        'description' => 'This field indicates the debian policy version number this package complies to'
      },
      'Vcs-Browser',
      {
        'compute' => {
          'use_eval' => '1',
          'formula' => '$maintainer =~ /pkg-perl/ ? "http://anonscm.debian.org/gitweb/?p=pkg-perl/packages/$pkgname.git" : undef ;',
          'variables' => {
            'maintainer' => '- Maintainer',
            'pkgname' => '- Source'
          },
          'allow_override' => '1'
        },
        'value_type' => 'uniline',
        'summary' => 'web-browsable URL of the VCS repository',
        'match' => '^https?://',
        'type' => 'leaf',
        'description' => 'Value of this field should be a http:// URL pointing to a web-browsable copy of the Version Control System repository used to maintain the given package, if available.

The information is meant to be useful for the final user, willing to browse the latest work done on the package (e.g. when looking for the patch fixing a bug tagged as pending in the bug tracking system). '
      },
      'Vcs-Arch',
      {
        'value_type' => 'uniline',
        'summary' => 'URL of the VCS repository',
        'type' => 'leaf',
        'description' => 'Value of this field should be a string identifying unequivocally the location of the Version Control System repository used to maintain the given package, if available. * identify the Version Control System; currently the following systems are supported by the package tracking system: arch, bzr (Bazaar), cvs, darcs, git, hg (Mercurial), mtn (Monotone), svn (Subversion). It is allowed to specify different VCS fields for the same package: they will all be shown in the PTS web interface.

The information is meant to be useful for a user knowledgeable in the given Version Control System and willing to build the current version of a package from the VCS sources. Other uses of this information might include automatic building of the latest VCS version of the given package. To this end the location pointed to by the field should better be version agnostic and point to the main branch (for VCSs supporting such a concept). Also, the location pointed to should be accessible to the final user; fulfilling this requirement might imply pointing to an anonymous access of the repository instead of pointing to an SSH-accessible version of the same. '
      },
      'Vcs-Bzr',
      {
        'value_type' => 'uniline',
        'summary' => 'URL of the VCS repository',
        'type' => 'leaf',
        'description' => 'Value of this field should be a string identifying unequivocally the location of the Version Control System repository used to maintain the given package, if available. * identify the Version Control System; currently the following systems are supported by the package tracking system: arch, bzr (Bazaar), cvs, darcs, git, hg (Mercurial), mtn (Monotone), svn (Subversion). It is allowed to specify different VCS fields for the same package: they will all be shown in the PTS web interface.

The information is meant to be useful for a user knowledgeable in the given Version Control System and willing to build the current version of a package from the VCS sources. Other uses of this information might include automatic building of the latest VCS version of the given package. To this end the location pointed to by the field should better be version agnostic and point to the main branch (for VCSs supporting such a concept). Also, the location pointed to should be accessible to the final user; fulfilling this requirement might imply pointing to an anonymous access of the repository instead of pointing to an SSH-accessible version of the same. '
      },
      'Vcs-Cvs',
      {
        'value_type' => 'uniline',
        'summary' => 'URL of the VCS repository',
        'type' => 'leaf',
        'description' => 'Value of this field should be a string identifying unequivocally the location of the Version Control System repository used to maintain the given package, if available. * identify the Version Control System; currently the following systems are supported by the package tracking system: arch, bzr (Bazaar), cvs, darcs, git, hg (Mercurial), mtn (Monotone), svn (Subversion). It is allowed to specify different VCS fields for the same package: they will all be shown in the PTS web interface.

The information is meant to be useful for a user knowledgeable in the given Version Control System and willing to build the current version of a package from the VCS sources. Other uses of this information might include automatic building of the latest VCS version of the given package. To this end the location pointed to by the field should better be version agnostic and point to the main branch (for VCSs supporting such a concept). Also, the location pointed to should be accessible to the final user; fulfilling this requirement might imply pointing to an anonymous access of the repository instead of pointing to an SSH-accessible version of the same. '
      },
      'Vcs-Darcs',
      {
        'value_type' => 'uniline',
        'summary' => 'URL of the VCS repository',
        'type' => 'leaf',
        'description' => 'Value of this field should be a string identifying unequivocally the location of the Version Control System repository used to maintain the given package, if available. * identify the Version Control System; currently the following systems are supported by the package tracking system: arch, bzr (Bazaar), cvs, darcs, git, hg (Mercurial), mtn (Monotone), svn (Subversion). It is allowed to specify different VCS fields for the same package: they will all be shown in the PTS web interface.

The information is meant to be useful for a user knowledgeable in the given Version Control System and willing to build the current version of a package from the VCS sources. Other uses of this information might include automatic building of the latest VCS version of the given package. To this end the location pointed to by the field should better be version agnostic and point to the main branch (for VCSs supporting such a concept). Also, the location pointed to should be accessible to the final user; fulfilling this requirement might imply pointing to an anonymous access of the repository instead of pointing to an SSH-accessible version of the same. '
      },
      'Vcs-Git',
      {
        'compute' => {
          'use_eval' => '1',
          'formula' => '$maintainer =~ /pkg-perl/ ? "git://git.debian.org/git/pkg-perl/packages/$pkgname.git" : \'\' ;',
          'variables' => {
            'maintainer' => '- Maintainer',
            'pkgname' => '- Source'
          },
          'allow_override' => '1'
        },
        'value_type' => 'uniline',
        'summary' => 'URL of the VCS repository',
        'type' => 'leaf',
        'description' => 'Value of this field should be a string identifying unequivocally the location of the Version Control System repository used to maintain the given package, if available. * identify the Version Control System; currently the following systems are supported by the package tracking system: arch, bzr (Bazaar), cvs, darcs, git, hg (Mercurial), mtn (Monotone), svn (Subversion). It is allowed to specify different VCS fields for the same package: they will all be shown in the PTS web interface.

The information is meant to be useful for a user knowledgeable in the given Version Control System and willing to build the current version of a package from the VCS sources. Other uses of this information might include automatic building of the latest VCS version of the given package. To this end the location pointed to by the field should better be version agnostic and point to the main branch (for VCSs supporting such a concept). Also, the location pointed to should be accessible to the final user; fulfilling this requirement might imply pointing to an anonymous access of the repository instead of pointing to an SSH-accessible version of the same. '
      },
      'Vcs-Hg',
      {
        'value_type' => 'uniline',
        'summary' => 'URL of the VCS repository',
        'type' => 'leaf',
        'description' => 'Value of this field should be a string identifying unequivocally the location of the Version Control System repository used to maintain the given package, if available. * identify the Version Control System; currently the following systems are supported by the package tracking system: arch, bzr (Bazaar), cvs, darcs, git, hg (Mercurial), mtn (Monotone), svn (Subversion). It is allowed to specify different VCS fields for the same package: they will all be shown in the PTS web interface.

The information is meant to be useful for a user knowledgeable in the given Version Control System and willing to build the current version of a package from the VCS sources. Other uses of this information might include automatic building of the latest VCS version of the given package. To this end the location pointed to by the field should better be version agnostic and point to the main branch (for VCSs supporting such a concept). Also, the location pointed to should be accessible to the final user; fulfilling this requirement might imply pointing to an anonymous access of the repository instead of pointing to an SSH-accessible version of the same. '
      },
      'Vcs-Mtn',
      {
        'value_type' => 'uniline',
        'summary' => 'URL of the VCS repository',
        'type' => 'leaf',
        'description' => 'Value of this field should be a string identifying unequivocally the location of the Version Control System repository used to maintain the given package, if available. * identify the Version Control System; currently the following systems are supported by the package tracking system: arch, bzr (Bazaar), cvs, darcs, git, hg (Mercurial), mtn (Monotone), svn (Subversion). It is allowed to specify different VCS fields for the same package: they will all be shown in the PTS web interface.

The information is meant to be useful for a user knowledgeable in the given Version Control System and willing to build the current version of a package from the VCS sources. Other uses of this information might include automatic building of the latest VCS version of the given package. To this end the location pointed to by the field should better be version agnostic and point to the main branch (for VCSs supporting such a concept). Also, the location pointed to should be accessible to the final user; fulfilling this requirement might imply pointing to an anonymous access of the repository instead of pointing to an SSH-accessible version of the same. '
      },
      'Vcs-Svn',
      {
        'value_type' => 'uniline',
        'summary' => 'URL of the VCS repository',
        'type' => 'leaf',
        'description' => 'Value of this field should be a string identifying unequivocally the location of the Version Control System repository used to maintain the given package, if available. * identify the Version Control System; currently the following systems are supported by the package tracking system: arch, bzr (Bazaar), cvs, darcs, git, hg (Mercurial), mtn (Monotone), svn (Subversion). It is allowed to specify different VCS fields for the same package: they will all be shown in the PTS web interface.

The information is meant to be useful for a user knowledgeable in the given Version Control System and willing to build the current version of a package from the VCS sources. Other uses of this information might include automatic building of the latest VCS version of the given package. To this end the location pointed to by the field should better be version agnostic and point to the main branch (for VCSs supporting such a concept). Also, the location pointed to should be accessible to the final user; fulfilling this requirement might imply pointing to an anonymous access of the repository instead of pointing to an SSH-accessible version of the same. '
      },
      'DM-Upload-Allowed',
      {
        'value_type' => 'uniline',
        'summary' => 'The package may be uploaded by a Debian Maintainer',
        'match' => 'yes',
        'type' => 'leaf',
        'description' => 'If this field is present, then any Debian Maintainers listed in the Maintainer or Uploaders fields may upload the package directly to the Debian archive.  For more information see the "Debian Maintainer" page at the Debian Wiki - http://wiki.debian.org/DebianMaintainer'
      },
      'Homepage',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'XS-Python-Version',
      {
        'value_type' => 'uniline',
        'status' => 'deprecated',
        'experience' => 'advanced',
        'type' => 'leaf'
      },
      'X-Python-Version',
      {
        'value_type' => 'uniline',
        'summary' => 'supported versions of Python ',
        'upstream_default' => 'all',
        'experience' => 'advanced',
        'migrate_from' => {
          'use_eval' => '1',
          'formula' => 'my $old = $xspython ;
my $new ;
if ($old =~ /,/) {
   # list of versions
   my @list = sort split /\\s*,\\s*/, $old ; 
   $new = ">= ". (shift @list) . ", << " .  (pop @list) ;
}
elsif ($old =~ /-/) {
   my @list = sort grep { $_ ;} split /\\s*-\\s*/, $old ; 
   $new = ">= ". shift @list ;
   $new .= ", << ". pop @list if @list ;
}
else {
   $new = $old ;
}
$new ;',
          'variables' => {
            'xspython' => '- XS-Python-Version'
          }
        },
        'type' => 'leaf',
        'description' => 'This field specifies the versions of Python (not versions of Python 3) supported by the source package.  When not specified, they default to all currently supported Python (or Python 3) versions. For more detail, See L<python policy|http://www.debian.org/doc/packaging-manuals/python-policy/ch-module_packages.html#s-specifying_versions>'
      },
      'X-Python3-Version',
      {
        'value_type' => 'uniline',
        'summary' => 'supported versions of Python3 ',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'This field specifies the versions of Python 3 supported by the package. For more detail, See L<python policy|http://www.debian.org/doc/packaging-manuals/python-policy/ch-module_packages.html#s-specifying_versions>'
      }
    ]
  }
]
;

