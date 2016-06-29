[
  {
    'author' => [
      'Dominique Dumont'
    ],
    'class_description' => 'Options for ext4 file systems. Please contact author (domi.dumont at cpan.org) if options are missing.',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'element' => [
      'journalling_mode',
      {
        'choice' => [
          'journal',
          'ordered',
          'writeback'
        ],
        'description' => 'Specifies the journalling mode for file data. Metadata is always journaled. To use modes other than ordered on the root file system, pass the mode to the kernel as boot parameter, e.g. rootflags=data=journal.',
        'help' => {
          'journal' => 'All data is committed into the journal prior to being written into the main file system. ',
          'ordered' => 'This is the default mode. All data is forced directly out to the main file system prior to its metadata being committed to the journal.',
          'writeback' => 'Data ordering is not preserved - data may be writteninto the main file system after its metadata has been committed to the journal. This is rumoured to be the highest-throughput option. It guarantees internal file system integrity, however it can allow old data to appear in files after a crash and journal recovery.'
        },
        'type' => 'leaf',
        'value_type' => 'enum'
      }
    ],
    'include' => [
      'Fstab::Ext2FsOpt'
    ],
    'license' => 'LGPL2',
    'name' => 'Fstab::Ext3FsOpt'
  }
]
;

