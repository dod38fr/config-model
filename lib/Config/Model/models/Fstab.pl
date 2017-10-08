[
  {
    'author' => [
      'Dominique Dumont'
    ],
    'class_description' => 'static information about the filesystems. fstab contains descriptive information about the various file systems. 
',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'element' => [
      'fs',
      {
        'cargo' => {
          'config_class_name' => 'Fstab::FsLine',
          'type' => 'node'
        },
        'description' => 'Each "fs" element contain the information about one filesystem. Each filesystem is referred in this model by a label constructed by the fstab parser. This label cannot be stored in the fstab file, so if you create a new file system, the label you will choose may not be stored and will be re-created by the fstab parser',
        'index_type' => 'string',
        'summary' => 'specification of one file system',
        'type' => 'hash'
      }
    ],
    'license' => 'LGPL2',
    'name' => 'Fstab',
    'rw_config' => {
      'backend' => 'Fstab',
      'config_dir' => '/etc',
      'file' => 'fstab'
    }
  }
]
;

