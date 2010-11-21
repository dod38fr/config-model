[
          {
            'name' => 'Fstab::Ext4FsOpt',
            'include' => [
                           'Fstab::Ext2FsOpt'
                         ],
            'element' => [
                           'lazy_itable_init',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '1',
                             'type' => 'leaf',
                             'description' => "If enabled and the uninit_bg feature is enabled, the inode table will not be fully initialized by mke2fs. This speeds up filesystem initialization notice\x{2010} ably, but it requires the kernel to finish initializing the filesystem in the background when the filesystem is first mounted."
                           }
                         ]
          }
        ]
;
