use strict;
use warnings;
use v5.20;
use utf8;

return [
  {
    'author' => [
      'Dominique Dumont'
    ],
    'copyright' => [
      '2026, Dominique Dumont'
    ],
    'element' => [
      'uid',
      {
        'description' => 'Set the owner and group of all files. (Default: the UID and GID of the current process.)',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'gid',
      '*uid',
      'umask',
      {
        'description' => 'Set the umask (the bitmask of the permissions that are not present). The default is the umask of the current process. The value is given in octal.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'dmask',
      {
        'description' => 'Set the umask applied to directories only. The default is the umask of the current process. The value is given in octal.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'fmask',
      {
        'description' => 'Set the umask applied to regular files only. The default is the umask of the current process. The value is given in octal.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'allow_utime',
      {
        'description' => "=pod

This option controls the permission check of mtime/atime. Possible
values:

'.'=over

'.'=item 20

If the current process is in the group of the file\x{2019}s group ID, you can
change the timestamp.

'.'=item 2

Other users can change the timestamp.

'.'=back


The default is set from the above dmask option. (If the directory is
writable, utime(2) is also allowed. That is: ~dmask & 022.)

Normally utime(2) checks that the current process is the owner of the
file, or that it has the CAP_FOWNER capability. But FAT filesystems
don\x{2019}t have UID/GID on disk, so the normal check is too
inflexible. With this option you can relax it.
",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'check',
      {
        'choice' => [
          'r',
          'n',
          's'
        ],
        'description' => 'Check file names. Three different levels of pickiness can be chosen:  r[elaxed] n[ormal] or s[trict]

',
        'help' => {
          'n' => 'n[ormal]: Like "relaxed", but many special characters (*, ?, <,
spaces, etc.) are rejected. This is the default.',
          'r' => 'r[elaxed]: Upper and lower case are accepted and equivalent, long name
parts are truncated (e.g. verylongname.foobar becomes verylong.foo),
leading and embedded spaces are accepted in each name part (name and
extension).
',
          's' => 's[trict]: Like "normal", but names that contain long parts or special
characters that are sometimes used on Linux but are not accepted by
MS-DOS (+, =, etc.) are rejected.
'
        },
        'type' => 'leaf',
        'upstream_default' => 'n',
        'value_type' => 'enum'
      },
      'codepage',
      {
        'description' => 'Sets the codepage for converting to shortname characters on FAT and VFAT filesystems. By default, codepage 437 is used.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'debug',
      {
        'description' => 'Turn on the debug flag. A version string and a list of filesystem parameters will be printed (these data are also printed if the parameters appear to be inconsistent).',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'discard',
      {
        'description' => 'If set, causes discard/TRIM commands to be issued to the block device when blocks are freed. This is useful for SSD devices and sparse/thinly-provisioned LUNs.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'dos1xfloppy',
      {
        'description' => 'If set, use a fallback default BIOS Parameter Block configuration, determined by backing device size. These static parameters match defaults assumed by DOS 1.x for 160 kiB, 180 kiB, 320 kiB, and 360 kiB floppies and floppy images.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'errors',
      {
        'choice' => [
          'panic',
          'continue',
          'remount-ro'
        ],
        'description' => 'Specify FAT behavior on critical errors: panic, continue without doing anything, or remount the partition in read-only mode (default behavior).
',
        'type' => 'leaf',
        'upstream_default' => 'remount-ro',
        'value_type' => 'enum'
      },
      'fat',
      {
        'choice' => [
          '12',
          '16',
          '32'
        ],
        'description' => 'Specify a 12, 16 or 32 bit fat. This overrides the automatic FAT type detection routine. Use with caution!
',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'iocharsets',
      {
        'description' => 'Character set to use for converting between 8 bit characters and 16 bit Unicode characters. The default is iso8859-1. Long filenames are stored on disk in Unicode format.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'tz',
      {
        'choice' => [
          'UTC'
        ],
        'description' => 'This option disables the conversion of timestamps between local time (as used by Windows on FAT) and UTC (which Linux uses internally). This is particularly useful when mounting devices (like digital cameras) that are set to UTC in order to avoid the pitfalls of local time.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'time_offset',
      {
        'description' => 'Set offset for conversion of timestamps from local time used by FAT to UTC. I.e., minutes will be subtracted from each timestamp to convert it to UTC used internally by Linux. This is useful when the time zone set in the kernel via settimeofday(2) is not the time zone used by the filesystem. Note that this option still does not provide correct time stamps in all cases in presence of DST - time stamps in a different DST setting will be off by one hour.',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'quiet',
      {
        'description' => 'Turn on the quiet flag. Attempts to chown or chmod files do not return errors, although they fail. Use with caution!',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'rodir',
      {
        'description' => "FAT has the ATTR_RO (read-only) attribute. On Windows, the ATTR_RO of the directory will just be ignored, and is used only by applications as a flag (e.g. it\x{2019}s set for the customized folder).

If you want to use ATTR_RO as read-only flag even for the directory, set this option.",
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'showexec',
      {
        'description' => 'If set, the execute permission bits of the file will be allowed only if the extension part of the name is .EXE, .COM, or .BAT. Not set by default.
',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'sys_immutable',
      {
        'description' => 'If set, ATTR_SYS attribute on FAT is handled as IMMUTABLE flag on Linux. Not set by default.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'flush',
      {
        'description' => 'If set, the filesystem will try to flush to disk more early than normal. Not set by default.',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'usefree',
      {
        'description' => "Use the \"free clusters\" value stored on FSINFO. It\x{2019}ll be used to determine number of free clusters without scanning disk. But it\x{2019}s not used by default, because recent Windows don\x{2019}t update it correctly in some case. If you are sure the \"free clusters\" on FSINFO is correct, by this option you can avoid scanning disk.",
        'type' => 'leaf',
        'value_type' => 'boolean'
      }
    ],
    'include' => [
      'Fstab::CommonOptions'
    ],
    'license' => 'LGPL2',
    'name' => 'Fstab::VfatOpt'
  }
]
;
