use strict;
use warnings;
use v5.20;
use utf8;

return [
  {
    'accept' => [
      'X-[\w.-]*',
      {
        'description' => 'All options prefixed with "X-" are interpreted as comments or as userspace application-specific options. These options are not stored in user space (e.g., mtab file), nor sent to the mount.type helpers nor to the mount(2) system call. The suggested format is X-appname.option.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'x-[\w.-]*',
      {
        'description' => "=pod

The same as X-* options, but stored permanently in user space. This
means the options are also available for umount(8) or other
operations. Note that maintaining mount options in user space is
tricky, because it\x{2019}s necessary to use libmount-based tools and there
is no guarantee that the options will be always available (for example
after a move mount operation or in unshared namespace).

Note that before util-linux v2.30 the x-* options have not been
maintained by libmount and stored in user space (functionality was the
same as for X-* now), but due to the growing number of use-cases (in
initrd, systemd etc.) the functionality has been extended to keep
existing fstab configurations usable without a change.

",
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
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
      'context',
      {
        'description' => '=pod

The C<context=> option is useful when mounting filesystems that do not
support extended attributes, such as a floppy or hard disk formatted
with VFAT, or systems that are not normally running under SELinux,
such as an ext3 or ext4 formatted disk from a non-SELinux
workstation. You can also use C<context=> on filesystems you do not
trust, such as a floppy. It also helps in compatibility with
xattr-supporting filesystems on earlier 2.4.x kernel versions. Even
where xattrs are supported, you can save time not having to label
every file by assigning the entire disk one security context.

A commonly used option for removable media is C<context="system_u:object_r:removable_t>.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'fscontext',
      {
        'description' => '=pod

The C<fscontext=> option works for all filesystems, regardless of their
xattr support. The fscontext option sets the overarching filesystem
label to a specific security context. This filesystem label is
separate from the individual labels on the files. It represents the
entire filesystem for certain kinds of permission checks, such as
during mount or file creation. Individual file labels are still
obtained from the xattrs on the files themselves.  The context option
actually sets the aggregate context that fscontext provides, in
addition to supplying the same label for individual files.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'defcontext',
      {
        'description' => 'You can set the default security context for unlabeled files using C<defcontext=> option. This overrides the value set for unlabeled files in the policy and requires a filesystem that supports xattr labeling.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'rootcontext',
      {
        'description' => 'The C<rootcontext=> option allows you to explicitly label the root inode of a FS being mounted before that FS or inode becomes visible to userspace. This was found to be useful for things like stateless Linux. The special value C<@target> can be used to assign the current context of the target mountpoint location.',
        'type' => 'leaf',
        'value_type' => 'uniline'
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
      'dev',
      {
        'description' => 'Interpret character or block special devices on the filesystem.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'diratime',
      {
        'description' => 'Update directory inode access times on this filesystem. This is the default. (This option is ignored when noatime is set.)',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean'
      },
      'dirsync',
      {
        'description' => 'All  directory  updates within the filesystem should be done synchronously. This affects the following system calls: C<creat(2)>, C<link(2)>, C<unlink(2)>, C<symlink(2)>, C<mkdir(2)>, C<rmdir(2)>, C<mknod(2)> and C<rename(2)>.
',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean'
      },
      'exec',
      {
        'description' => 'Permit execution of binaries.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'group',
      {
        'description' => "Allow an ordinary user to mount the filesystem if one of that user\x{2019}s groups matches the group of the device. This option implies the options nosuid and nodev (unless overridden by subsequent options, as in the option line group,dev,suid).",
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'iversion',
      {
        'description' => 'Every time the inode is modified, the i_version field will be incremented.
',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'mand',
      {
        'description' => 'Allow mandatory locks on this filesystem. See L<fcntl(2)>.
This option was deprecated in Linux 5.15.
',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      '_netdev',
      {
        'description' => 'The filesystem resides on a device that requires network access (used to prevent the system from attempting to mount these filesystems until the network has been enabled on the system).',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'nofail',
      {
        'description' => 'Do not report errors for this device if it does not exist.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'relatime',
      {
        'description' => "=pod

Update inode access times relative to modify or change time. Access
time is only updated if the previous access time was earlier than the
current modify or change time. (Similar to noatime, but it doesn\x{2019}t
break mutt(1) or other applications that need to know if a file has
been read since the last time it was modified.)

Since Linux 2.6.30, the kernel defaults to the behavior provided by
this option (unless noatime was specified), and the strictatime option
is required to obtain traditional semantics. In addition, since Linux
2.6.30, the file\x{2019}s last access time is always updated if it is more
than 1 day old.
",
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'strictatime',
      {
        'description' => 'Allows to explicitly request full atime updates. This makes it possible for the kernel to default to relatime or noatime but still allow userspace to override it. For more details about the default system mount options see C</proc/mounts>.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'lazytime',
      {
        'description' => '=pod

Only update times (atime, mtime, ctime) on the in-memory version of
the file inode.

This mount option significantly reduces writes to the inode table for
workloads that perform frequent random writes to preallocated files.

The on-disk timestamps are updated only when:

'.'=over

'.'=item *

the inode needs to be updated for some change unrelated to file timestamps

'.'=item *

the application employs fsync(2), syncfs(2), or sync(2)

'.'=item *

an undeleted inode is evicted from memory

'.'=item *

more than 24 hours have passed since the inode was written to disk.

'.'=back
',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'suid',
      {
        'description' => 'Honor set-user-ID and set-group-ID bits or file capabilities when executing programs from this filesystem.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'silent',
      {
        'description' => 'Turn on the silent flag.
',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'loud',
      {
        'description' => 'Turn off the silent flag.

',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'owner',
      {
        'description' => 'Allow an ordinary user to mount the filesystem if that user is the owner of the device. This option implies the options nosuid and nodev (unless overridden by subsequent options, as in the option line owner,dev,suid).',
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
      'sync',
      {
        'description' => 'All I/O to the filesystem should be done synchronously. In the case of media with a limited number of write cycles (e.g. some flash drives), sync may cause life-cycle shortening.',
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
      'users',
      {
        'description' => 'Allow any user to mount and to unmount the filesystem, even when some other ordinary user mounted it. This option implies the options noexec, nosuid, and nodev (unless overridden by subsequent options, as in the option line users,exec,dev,suid).',
        'help' => {
          '0' => 'Only root can mount the file system',
          '1' => 'user can mount the file system'
        },
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'nosymfollow',
      {
        'description' => 'Do not follow symlinks when resolving paths. Symlinks can still be created, and readlink(1), readlink(2), realpath(1), and realpath(3) all still work properly.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      }
    ],
    'license' => 'LGPL2',
    'name' => 'Fstab::CommonOptions'
  }
]
;
