[
          {
            'accept' => [
                          {
                            'value_type' => 'uniline',
                            'type' => 'leaf',
                            'description' => 'unknown parameter'
                          }
                        ],
            'name' => 'Fstab::Ext2FsOpt',
            'include' => [
                           'Fstab::CommonOptions'
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
          }
        ]
;
