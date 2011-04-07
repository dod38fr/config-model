[
  {
    'class_description' => 'data of one /etc/fstab line',
    'name' => 'Fstab::FsLine',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
    'element' => [
      'fs_spec',
      {
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
        },
        'mandatory' => 1,
        'type' => 'leaf',
        'description' => 'block special device or remote filesystem to be mounted'
      },
      'fs_file',
      {
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
        },
        'mandatory' => 1,
        'type' => 'leaf',
        'description' => 'mount point for the filesystem'
      },
      'fs_vfstype',
      {
        'value_type' => 'enum',
        'help' => {
          'proc' => 'Kernel info through a special file system',
          'auto' => 'file system type is probed by the kernel when mounting the device',
          'vfat' => 'Older Windows file system often used on removable media',
          'ext3' => 'Common Linux file system with journaling ',
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
        ]
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
  }
]
;

