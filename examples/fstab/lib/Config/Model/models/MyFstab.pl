[
          {
            'class_description' => 'static information about the filesystems',
            'name' => 'MyFstab',
            'element' => [
                           'fs',
                           {
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'MyFstab::FsLine'
                                        },
                             'type' => 'hash',
                             'description' => 'Each "fs" element contain the information about one filesystem. Each filesystem is referred in this model by a label constructed by the fstab parser. This label cannot be stored in the fstab file, so if you create a new file system, the label you will choose may not be stored and will be re-created by the fstab parser',
                             'index_type' => 'string'
                           }
                         ]
          }
        ]
;
