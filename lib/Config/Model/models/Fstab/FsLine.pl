[
  {
    'author' => [
      'Dominique Dumont'
    ],
    'class_description' => 'data of one /etc/fstab line',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'element' => [
      'fs_spec',
      {
        'description' => 'block special device or remote filesystem to be mounted',
        'mandatory' => 1,
        'type' => 'leaf',
        'value_type' => 'uniline',
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
        }
      },
      'fs_file',
      {
        'description' => 'mount point for the filesystem',
        'mandatory' => 1,
        'type' => 'leaf',
        'value_type' => 'uniline',
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
        }
      },
      'fs_vfstype',
      {
        'choice' => [
          'auto',
          'davfs',
          'ext2',
          'ext3',
          'ext4',
          'swap',
          'proc',
          'iso9660',
          'vfat',
          'usbfs',
          'ignore',
          'nfs',
          'nfs4',
          'none',
          'ignore',
          'debugfs'
        ],
        'description' => 'file system type',
        'help' => {
          'auto' => 'file system type is probed by the kernel when mounting the device',
          'davfs' => 'WebDav access',
          'ext2' => 'Common Linux file system.',
          'ext3' => 'Common Linux file system with journaling ',
          'ignore' => 'unused disk partition',
          'iso9660' => 'CD-ROM or DVD file system',
          'proc' => 'Kernel info through a special file system',
          'usbfs' => 'USB pseudo file system. Gives a file system view of kernel data related to usb',
          'vfat' => 'Older Windows file system often used on removable media'
        },
        'mandatory' => 1,
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'fs_mntopts',
      {
        'description' => 'mount options associated with the filesystem',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'f1' => '- fs_vfstype'
          },
          'rules' => [
            '$f1 eq \'proc\'',
            {
              'config_class_name' => 'Fstab::CommonOptions'
            },
            '$f1 eq \'auto\'',
            {
              'config_class_name' => 'Fstab::CommonOptions'
            },
            '$f1 eq \'vfat\'',
            {
              'config_class_name' => 'Fstab::CommonOptions'
            },
            '$f1 eq \'swap\'',
            {
              'config_class_name' => 'Fstab::SwapOptions'
            },
            '$f1 eq \'ext2\'',
            {
              'config_class_name' => 'Fstab::Ext2FsOpt'
            },
            '$f1 eq \'ext3\'',
            {
              'config_class_name' => 'Fstab::Ext3FsOpt'
            },
            '$f1 eq \'ext4\'',
            {
              'config_class_name' => 'Fstab::Ext4FsOpt'
            },
            '$f1 eq \'usbfs\'',
            {
              'config_class_name' => 'Fstab::UsbFsOptions'
            },
            '$f1 eq \'davfs\'',
            {
              'config_class_name' => 'Fstab::CommonOptions'
            },
            '$f1 eq \'iso9660\'',
            {
              'config_class_name' => 'Fstab::Iso9660_Opt'
            },
            '$f1 eq \'nfs\'',
            {
              'config_class_name' => 'Fstab::CommonOptions'
            },
            '$f1 eq \'nfs4\'',
            {
              'config_class_name' => 'Fstab::CommonOptions'
            },
            '$f1 eq \'none\'',
            {
              'config_class_name' => 'Fstab::NoneOptions'
            },
            '$f1 eq \'debugfs\'',
            {
              'config_class_name' => 'Fstab::CommonOptions'
            }
          ]
        }
      },
      'fs_freq',
      {
        'choice' => [
          '0',
          '1'
        ],
        'default' => '0',
        'description' => 'Specifies if the file system needs to be dumped',
        'type' => 'leaf',
        'value_type' => 'enum',
        'warp' => {
          'follow' => {
            'fstyp' => '- fs_vfstype',
            'isbound' => '- fs_mntopts bind'
          },
          'rules' => [
            '$fstyp eq "none" and $isbound',
            {
              'choice' => [
                '0'
              ]
            }
          ]
        }
      },
      'fs_passno',
      {
        'default' => 0,
        'description' => 'used by the fsck(8) program to determine the order in which filesystem checks are done at reboot time',
        'summary' => 'fsck pass number',
        'type' => 'leaf',
        'value_type' => 'integer',
        'warp' => {
          'follow' => {
            'fstyp' => '- fs_vfstype',
            'isbound' => '- fs_mntopts bind'
          },
          'rules' => [
            '$fstyp eq "none" and $isbound',
            {
              'max' => '0'
            }
          ]
        }
      }
    ],
    'license' => 'LGPL2',
    'name' => 'Fstab::FsLine'
  }
]
;

