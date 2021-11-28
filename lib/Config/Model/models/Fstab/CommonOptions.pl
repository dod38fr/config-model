use strict;
use warnings;

return [
  {
    'author' => [
      'Dominique Dumont'
    ],
    'class_description' => 'options valid for all types of file systems.',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'element' => [
      'async',
      {
        'description' => 'All I/O to the filesystem should be done asynchronously. (See also the sync option.)
',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'atime',
      {
        'description' => 'Do not use the noatime feature, so the inode access time is controlled by kernel defaults. See also the descriptions of the relatime and strictatime mount options.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'auto',
      {
        'description' => 'Can be mounted with the -a option of C<mount> command',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'dev',
      {
        'description' => 'Interpret character or block special devices on the filesystem.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'exec',
      {
        'description' => 'Permit execution of binaries.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'suid',
      {
        'description' => 'Honor set-user-ID and set-group-ID bits or file capabilities when executing programs from this filesystem.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'group',
      {
        'description' => "Allow an ordinary user to mount the filesystem if one of that user\x{2019}s groups matches the group of the device. This option implies the options nosuid and nodev (unless overridden by subsequent options, as in the option line group,dev,suid).",
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'mand',
      {
        'description' => 'Allow mandatory locks on this filesystem. See L<fcntl(2)>.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'user',
      {
        'description' => 'Allow an ordinary user to mount the filesystem. The name of the mounting user is written to the mtab file (or to the private libmount file in /run/mount on systems without a regular mtab) so that this same user can unmount the filesystem again. This option implies the options noexec, nosuid, and nodev (unless overridden by subsequent options, as in the option line user,exec,dev,suid).',
        'help' => {
          '0' => 'Only root can mount the file system',
          '1' => 'user can mount the file system'
        },
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'defaults',
      {
        'description' => 'Use the default options: rw, suid, dev, exec, auto, nouser, and async.

Note that the real set of all default mount options depends on the kernel and filesystem type. See the beginning of this section for more details.',
        'help' => {
          '1' => 'option equivalent to rw, suid, dev, exec, auto, nouser, and async'
        },
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'rw',
      {
        'description' => 'Mount the filesystem read-write.',
        'help' => {
          '0' => 'read-only file system'
        },
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'relatime',
      {
        'description' => "Update inode access times relative to modify or change time. Access time is only updated if the previous access time was earlier than the current modify or change time. (Similar to noatime, but it doesn\x{2019}t break mutt(1) or other applications that need to know if a file has been read since the last time it was modified.)",
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'umask',
      {
        'description' => 'Set the umask (the bitmask of the permissions that are not present). The default is the umask of the current process. The value is given in octal.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'license' => 'LGPL2',
    'name' => 'Fstab::CommonOptions'
  }
]
;

