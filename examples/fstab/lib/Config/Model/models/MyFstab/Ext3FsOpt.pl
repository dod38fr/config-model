[
          {
            'name' => 'MyFstab::Ext3FsOpt',
            'include' => [
                           'MyFstab::Ext2FsOpt'
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
          }
        ]
;
