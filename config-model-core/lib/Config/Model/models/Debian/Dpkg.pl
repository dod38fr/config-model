[
  {
    'class_description' => 'Model of Debian source package files (e.g debian/control, debian/copyright...)',
    'read_config' => [
      {
        'auto_create' => '1',
        'file' => 'clean',
        'backend' => 'Debian::Dpkg',
        'config_dir' => 'debian'
      }
    ],
    'name' => 'Debian::Dpkg',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
    'element' => [
      'my_config',
      {
        'type' => 'node',
        'description' => 'This element contains a set of parameters to tune the behavior of this dpkg editor. You can for instance specify e-mail replacements. These parameters are stored in ~/.dpkg-meta.yml or ~/.local/share/.dpkg-meta.yml. These parameters can be applied to all Debian packages you maintain in this unix account.',
        'config_class_name' => 'Debian::Dpkg::Meta'
      },
      'control',
      {
        'type' => 'node',
        'description' => 'Package control file. Specifies the most vital (and version-independent) information about the source package and about the binary packages it creates.',
        'config_class_name' => 'Debian::Dpkg::Control'
      },
      'rules',
      {
        'value_type' => 'string',
        'summary' => 'package build rules',
        'type' => 'leaf',
        'description' => 'debian/rules is a makefile containing all intructions required to build a debian package.'
      },
      'copyright',
      {
        'summary' => 'copyright and license information',
        'type' => 'node',
        'description' => 'copyright and license information of all files contained in this package',
        'config_class_name' => 'Debian::Dpkg::Copyright'
      },
      'source',
      {
        'type' => 'node',
        'config_class_name' => 'Debian::Dpkg::Source'
      },
      'clean',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'summary' => 'list of files to clean',
        'type' => 'list',
        'description' => 'list of files to remove when dh_clean is run. Files names can include wild cards. For instance:

 build.log
 Makefile.in
 */Makefile.in
 */*/Makefile.in

'
      },
      'patches',
      {
        'cargo' => {
          'type' => 'node',
          'config_class_name' => 'Debian::Dpkg::Patch'
        },
        'ordered' => '1',
        'type' => 'hash',
        'index_type' => 'string'
      },
      'compat',
      {
        'value_type' => 'integer',
        'default' => '8',
        'type' => 'leaf',
        'description' => 'compat file defines the debhelper compatibility level'
      },
      'dirs',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'warn' => 'Make sure that this directory is actually needed. See L<http://www.debian.org/doc/manuals/maint-guide/dother.en.html#dirs> for details',
          'type' => 'leaf'
        },
        'summary' => 'Extra directories',
        'type' => 'list',
        'description' => 'This file specifies any directories which we need but which are not created by the normal installation procedure (make install DESTDIR=... invoked by dh_auto_install). This generally means there is a problem with the Makefile.

Files listed in an install file don\'t need their directories created first. 

It is best to try to run the installation first and only use this if you run into trouble. There is no preceding slash on the directory names listed in the dirs file. '
      },
      'docs',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'type' => 'list',
        'description' => 'This file specifies the file names of documentation files we can have dh_installdocs(1) install into the temporary directory for us.

By default, it will include all existing files in the top-level source directory that are called BUGS, README*, TODO etc. '
      }
    ]
  }
]
;

