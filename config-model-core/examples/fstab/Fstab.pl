[
          {
            'class_description' => 'static information about the filesystems',
            'name' => 'Fstab',
            'element' => [
                           'fs',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'FsLine'
                                        },
                             'type' => 'hash',
                             'description' => 'Each "fs" element contain the information about one filesystem. Each filesystem is referred in this model by a label constructed by the fstab parser. This label cannot be stored in the fstab file, so if you create a new file system, the label you will choose may not be stored and will be re-created by the fstab parser',
                             'index_type' => 'string'
                           }
                         ]
          },
          {
            'class_description' => 'data of one /etc/fstab line',
            'name' => 'FsLine',
            'element' => [
                           'fs_spec',
                           {
                             'value_type' => 'string',
                             'warp' => {
                                         'follow' => {
                                                       'f1' => '- fs_vfstype'
                                                     },
                                         'rules' => [
                                                      '$f1 eq \'proc\'',
                                                      {
                                                        'default' => 'proc'
                                                      }
                                                    ]
                                       },
                             'mandatory' => 1,
                             'type' => 'leaf',
                             'description' => 'block special device or remote filesystem to be mounted'
                           },
                           'fs_vfstype',
                           {
                             'value_type' => 'enum',
                             'help' => {
                                         'proc' => 'Kernel info through a special file system',
                                         'auto' => 'file system type is probed by the kernel when mounting the device',
                                         'vfat' => 'Older Windows file system often used on removable media',
                                         'ext3' => 'Common Linux file system with journalling  (recommended)',
                                         'usbfs' => 'USB pseudo file system. Gives a file system view of kernel data related to usb',
                                         'iso9660' => 'CD-ROM or DVD file system',
                                         'ignore' => 'unused disk partition',
                                         'ext2' => 'Common Linux file system.',
                                         'davfs' => 'WebDav access'
                                       },
                             'mandatory' => 1,
                             'type' => 'leaf',
                             'description' => 'file system type',
                             'choice' => [
                                           'auto',
                                           'davfs',
                                           'ext2',
                                           'ext3',
                                           'swap',
                                           'proc',
                                           'iso9660',
                                           'vfat',
                                           'usbfs',
                                           'ignore'
                                         ]
                           },
                           'fs_file',
                           {
                             'value_type' => 'string',
                             'warp' => {
                                         'follow' => {
                                                       'f1' => '- fs_vfstype'
                                                     },
                                         'rules' => [
                                                      '$f1 eq \'proc\'',
                                                      {
                                                        'default' => '/proc'
                                                      },
                                                      '$f1 eq \'swap\'',
                                                      {
                                                        'default' => 'none'
                                                      }
                                                    ]
                                       },
                             'mandatory' => 1,
                             'type' => 'leaf',
                             'description' => 'mount point for the filesystem'
                           },
                           'fs_mntopts',
                           {
                             'follow' => {
                                           'f1' => '- fs_vfstype'
                                         },
                             'type' => 'warped_node',
                             'rules' => [
                                          '$f1 eq \'proc\'',
                                          {
                                            'config_class_name' => 'CommonOptions'
                                          },
                                          '$f1 eq \'auto\'',
                                          {
                                            'config_class_name' => 'CommonOptions'
                                          },
                                          '$f1 eq \'vfat\'',
                                          {
                                            'config_class_name' => 'CommonOptions'
                                          },
                                          '$f1 eq \'swap\'',
                                          {
                                            'config_class_name' => 'SwapOptions'
                                          },
                                          '$f1 eq \'ext3\'',
                                          {
                                            'config_class_name' => 'Ext3FsOpt'
                                          },
                                          '$f1 eq \'usbfs\'',
                                          {
                                            'config_class_name' => 'UsbFsOptions'
                                          },
                                          '$f1 eq \'davfs\'',
                                          {
                                            'config_class_name' => 'CommonOptions'
                                          },
                                          '$f1 eq \'iso9660\'',
                                          {
                                            'config_class_name' => 'Iso9660_Opt'
                                          },
                                          '$f1 eq \'ext2\'',
                                          {
                                            'config_class_name' => 'Ext2FsOpt'
                                          }
                                        ],
                             'description' => 'mount options associated with the filesystem'
                           },
                           'fs_freq',
                           {
                             'value_type' => 'boolean',
                             'default' => '0',
                             'type' => 'leaf',
                             'description' => 'Specifies if the file system needs to be dumped'
                           },
                           'fs_passno',
                           {
                             'value_type' => 'integer',
                             'default' => 0,
                             'type' => 'leaf',
                             'description' => 'used by the fsck(8) program to determine the order in which filesystem checks are done at reboot time'
                           }
                         ]
          },
          {
            'class_description' => 'options valid for all types of file systems.',
            'name' => 'CommonOptions',
            'element' => [
                           'async',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           },
                           'atime',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           },
                           'auto',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           },
                           'dev',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           },
                           'exec',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           },
                           'group',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           },
                           'mand',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           },
                           'user',
                           {
                             'value_type' => 'boolean',
                             'help' => {
                                         '1' => 'user can mount the file system',
                                         '0' => 'Only root can mount the file system'
                                       },
                             'type' => 'leaf'
                           },
                           'defaults',
                           {
                             'value_type' => 'boolean',
                             'help' => {
                                         '1' => 'option equivalent to rw, suid, dev, exec, auto, nouser, and async'
                                       },
                             'type' => 'leaf'
                           },
                           'rw',
                           {
                             'value_type' => 'boolean',
                             'help' => {
                                         '0' => 'read-only file system'
                                       },
                             'type' => 'leaf'
                           }
                         ]
          },
          {
            'class_description' => 'Swap options',
            'name' => 'SwapOptions',
            'element' => [
                           'sw',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           }
                         ]
          },
          {
            'class_description' => 'usbfs options',
            'name' => 'UsbFsOptions',
            'include' => [
                           'CommonOptions'
                         ],
            'element' => [
                           'devuid',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0',
                             'type' => 'leaf'
                           },
                           'devgid',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0',
                             'type' => 'leaf'
                           },
                           'busuid',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0',
                             'type' => 'leaf'
                           },
                           'budgid',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0',
                             'type' => 'leaf'
                           },
                           'listuid',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0',
                             'type' => 'leaf'
                           },
                           'listgid',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0',
                             'type' => 'leaf'
                           },
                           'devmode',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0644',
                             'type' => 'leaf'
                           },
                           'busmode',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0555',
                             'type' => 'leaf'
                           },
                           'listmode',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '0444',
                             'type' => 'leaf'
                           }
                         ]
          },
          {
            'accept' => [
                          {
                            'value_type' => 'uniline',
                            'type' => 'leaf',
                            'description' => 'unknown parameter'
                          }
                        ],
            'name' => 'Ext2FsOpt',
            'include' => [
                           'CommonOptions'
                         ],
            'element' => [
                           'acl',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           },
                           'user_xattr',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf',
                             'description' => 'Support "user." extended attributes '
                           },
                           'statfs_behavior',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'choice' => [
                                           'bsddf',
                                           'minixdf'
                                         ]
                           },
                           'errors',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'choice' => [
                                           'continue',
                                           'remount-ro',
                                           'panic'
                                         ]
                           }
                         ]
          },
          {
            'name' => 'Ext3FsOpt',
            'include' => [
                           'Ext2FsOpt'
                         ],
            'element' => [
                           'journalling_mode',
                           {
                             'value_type' => 'enum',
                             'help' => {
                                         'ordered' => 'This is the default mode. All data is forced directly out to the main file system prior to its metadata being committed to the journal.',
                                         'writeback' => 'Data ordering is not preserved - data may be writteninto the main file system after its metadata has been committed to the journal. This is rumoured to be the highest-throughput option. It guarantees internal file system integrity, however it can allow old data to appear in files after a crash and journal recovery.',
                                         'journal' => 'All data is committed into the journal prior to being written into the main file system. '
                                       },
                             'type' => 'leaf',
                             'description' => 'Specifies the journalling mode for file data. Metadata is always journaled. To use modes other than ordered on the root file system, pass the mode to the kernel as boot parameter, e.g. rootflags=data=journal.',
                             'choice' => [
                                           'journal',
                                           'ordered',
                                           'writeback'
                                         ]
                           }
                         ]
          },
          {
            'name' => 'Iso9660_Opt',
            'include' => [
                           'CommonOptions'
                         ],
            'element' => [
                           'rock',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           },
                           'joliet',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
