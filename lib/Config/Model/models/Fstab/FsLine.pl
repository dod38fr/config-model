use strict;
use warnings;
use v5.20;
use utf8;

return [
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
            {
              'apply' => {
                'default' => 'proc'
              },
              'when' => '$f1 eq \'proc\''
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
            {
              'apply' => {
                'default' => '/proc'
              },
              'when' => '$f1 eq \'proc\''
            },
            {
              'apply' => {
                'default' => 'none'
              },
              'when' => '$f1 eq \'swap\''
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
            {
              'apply' => {
                'config_class_name' => 'Fstab::CommonOptions'
              },
              'when' => '$f1 eq \'proc\''
            },
            {
              'apply' => {
                'config_class_name' => 'Fstab::CommonOptions'
              },
              'when' => '$f1 eq \'auto\''
            },
            {
              'apply' => {
                'config_class_name' => 'Fstab::VfatOpt'
              },
              'when' => '$f1 eq \'vfat\''
            },
            {
              'apply' => {
                'config_class_name' => 'Fstab::SwapOptions'
              },
              'when' => '$f1 eq \'swap\''
            },
            {
              'apply' => {
                'config_class_name' => 'Fstab::Ext2FsOpt'
              },
              'when' => '$f1 eq \'ext2\''
            },
            {
              'apply' => {
                'config_class_name' => 'Fstab::Ext3FsOpt'
              },
              'when' => '$f1 eq \'ext3\''
            },
            {
              'apply' => {
                'config_class_name' => 'Fstab::Ext4FsOpt'
              },
              'when' => '$f1 eq \'ext4\''
            },
            {
              'apply' => {
                'config_class_name' => 'Fstab::UsbFsOptions'
              },
              'when' => '$f1 eq \'usbfs\''
            },
            {
              'apply' => {
                'config_class_name' => 'Fstab::CommonOptions'
              },
              'when' => '$f1 eq \'davfs\''
            },
            {
              'apply' => {
                'config_class_name' => 'Fstab::Iso9660_Opt'
              },
              'when' => '$f1 eq \'iso9660\''
            },
            {
              'apply' => {
                'config_class_name' => 'Fstab::CommonOptions'
              },
              'when' => '$f1 eq \'nfs\''
            },
            {
              'apply' => {
                'config_class_name' => 'Fstab::CommonOptions'
              },
              'when' => '$f1 eq \'nfs4\''
            },
            {
              'apply' => {
                'config_class_name' => 'Fstab::NoneOptions'
              },
              'when' => '$f1 eq \'none\''
            },
            {
              'apply' => {
                'config_class_name' => 'Fstab::CommonOptions'
              },
              'when' => '$f1 eq \'debugfs\''
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
            {
              'apply' => {
                'choice' => [
                  '0'
                ]
              },
              'when' => '$fstyp eq "none" and $isbound'
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
            {
              'apply' => {
                'max' => '0'
              },
              'when' => '$fstyp eq "none" and $isbound'
            }
          ]
        }
      }
    ],
    'gist' => '{fs_vfstype}: {fs_file}',
    'license' => 'LGPL2',
    'name' => 'Fstab::FsLine'
  }
]
;
