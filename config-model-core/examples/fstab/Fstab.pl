#    Copyright (c) 2005,2006,2010 Dominique Dumont.
#
#    This file is part of Config-Model.
#
#    Config-Model is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Model is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA


# This model was created from fstab(5) and mount(8) from util-linux
# project (http://freshmeat.net/projects/util-linux/).

# This model is just an example and is far from being complete.

# Here we have several choices to decide the structure of the fstab model:
# - by device name
# - by mount point
# - by line

# Sorting by device is not possible since we can mount one device
# under several mount points. Sorting by mount point is difficult
# since all swap devices have a 'none' mount point.
# So I've decided to use a label for fstab entries. This label
# will be constructed by the parser, but it cannot be stored
# in the fstab file. Hopefully, this will be easier to use 
# than a simple list.

[
  [
   name => "Fstab",
   class_description => 'static information about the filesystems',

   element => 
   [ fs   => 
         { type => 'hash' ,
           index_type => 'string',
           'description' => 'Each "fs" element contain the information about one filesystem. Each filesystem is referred in this model by a label constructed by the fstab parser. This label cannot be stored in the fstab file, so if you create a new file system, the label you will choose may not be stored and will be re-created by the fstab parser' ,
           cargo => {
					 type => 'node',
					 config_class_name => 'FsLine'
					}
         }
   ],
   # of course this could change if the information is stored outside
   # of /etc/fstab
  ],

  [
   name => "FsLine",

   'class_description' => 'data of one /etc/fstab line',

   'element' 
   => [ 
       'fs_spec'
           => { type => 'leaf' ,
                        value_type => 'string',
                        mandatory => 1,
                        # specify a default value only for 'proc' file system
                        warp => { follow => '- fs_vfstype',
                       rules => { 'proc' => { default => 'proc' },
                                }
                     },
                        description    => 'block special device or remote filesystem to be mounted',
           },

	   'fs_vfstype' 
	   => { type => 'leaf' ,
             mandatory => 1,
             value_type => 'enum',
             # ok, a lot of fs are missing, this is just an example
			description => 'file system type',
             choice => [qw/auto davfs ext2 ext3 swap proc iso9660 vfat usbfs ignore/],
             'help'
             => {
                 ext2   => 'Common Linux file system.',
                 ext3   => 'Common Linux file system with journalling '
                         . ' (recommended)',
                 auto   => 'file system type is probed by the kernel '
                         . 'when mounting the device',
                 iso9660 => 'CD-ROM or DVD file system',
                 proc   => 'Kernel info through a special file system',
                 vfat   => 'Older Windows file system often used on '
                         . 'removable media',
                 usbfs  => 'USB pseudo file system. Gives a file system view of kernel data related to usb',
                 davfs  => 'WebDav access',
                 ignore => 'unused disk partition',
                },
           },

        'fs_file'
        => { type => 'leaf' ,
             value_type => 'string',
             mandatory => 1,
			 description    => 'mount point for the filesystem',
             # specify some default values
             warp => { follow => '- fs_vfstype',
                       rules => { 'proc' => { default => '/proc' },
                                  'swap' => { default => 'none'  }
                                }
                     }
           },

       # Available options depends on the file system type
       'fs_mntopts'
        => { type => 'warped_node',
			 description  => 'mount options associated with the filesystem',
             follow => '- fs_vfstype',
             'rules'
             => { 
                 'ext2'          => { config_class_name => 'Ext2FsOpt'    },
                 'ext3'          => { config_class_name => 'Ext3FsOpt'    },
                 'iso9660'       => { config_class_name => 'Iso9660_Opt'  },
                 'vfat'          => { config_class_name => 'CommonOptions'},
                 auto            => { config_class_name => 'CommonOptions'},
                 proc            => { config_class_name => 'CommonOptions'},
                 davfs           => { config_class_name => 'CommonOptions'},
                 swap            => { config_class_name => 'SwapOptions'  },
                 usbfs           => { config_class_name => 'UsbFsOptions' },
                },
           },

        'fs_freq' => { type => 'leaf',
                       value_type => 'boolean',
					   description    => 'Specifies if the file system needs to be dumped',
                       default => '0',
                     },
        'fs_passno' => { type => 'leaf',
                         value_type => 'integer',
                         default => 0,
						 description  => 'used by the fsck(8) program to determine the order '
						 . 'in which filesystem checks are done at reboot time',
                       },
      ]
  ],

# These options are available for all file systems (according to mount(8))
  [
   name => "CommonOptions",
   class_description => "options valid for all types of file systems",
   'element' 
   => [
       [qw/async atime auto dev exec group mand/ ] 
       => { type => 'leaf' ,
            value_type => 'boolean',
          },
       user => { type => 'leaf' ,
                 value_type => 'boolean',
                 help => { 0 => 'Only root can mount the file system',
                           1 => 'user can mount the file system',
                         }
               },
       defaults => { type => 'leaf' ,
                     value_type => 'boolean',
                     help => {
                              1 => "option equivalent to rw, suid, dev, exec, "
                                 . "auto, nouser, and async",
                             }
               },
       rw => { type => 'leaf' ,
               value_type => 'boolean',
               help => {
                        0 => "read-only file system",
                       }
               },
      ]
  ],

  [
   name => "SwapOptions",
   class_description => "Swap options",
   'element' 
   => [
       sw => { type => 'leaf' ,
               value_type => 'boolean',
             },
      ]
  ],

  [
   name => "UsbFsOptions",
   class_description => "usbfs options",

   # all common option are part of ext2 options
   include => 'CommonOptions' ,

   'element' 
   => [
       [qw/devuid devgid busuid budgid listuid listgid/]
       => { type => 'leaf' ,
            value_type => 'integer',
            upstream_default => '0',
          },
       devmode => { type => 'leaf' ,
                    value_type => 'integer',
                    upstream_default => '0644',
                  },
       busmode => { type => 'leaf' ,
                    value_type => 'integer',
                    upstream_default => '0555',
                  },
       listmode => { type => 'leaf' ,
                    value_type => 'integer',
                    upstream_default => '0444',
                  },
      ]
  ],


# not all options are listed to keep example, err..., simple.
  [
   name => "Ext2FsOpt",

   # all common option are part of ext2 options
   include => 'CommonOptions' ,

   # ext2 specific elements
   'element' 
   => [ [qw/acl user_xattr/] => { type => 'leaf' ,
                                  value_type => 'boolean',
                                },
        statfs_behavior => { type => 'leaf' ,
                             value_type => 'enum',
                             choice => [qw/bsddf minixdf/],
                           },
        errors => { type => 'leaf' ,
                    value_type => 'enum',
                    choice => [qw/continue remount-ro panic/],
                  },
      ],

   accept => [ 
			  { type => 'leaf',
				value_type => 'uniline',
				description => 'unknown parameter',
			  }
			 ],
   'description' 
   => [ 
       'user_xattr' => 'Support "user." extended attributes '
      ]
  ],

  [
   name => "Ext3FsOpt",

   # ext3 feature all ext2 options
   include => 'Ext2FsOpt' ,

   'element' 
   =>  [ 
         'journalling_mode'
         => { type => 'leaf' ,
              value_type => 'enum',
              choice => [qw/journal ordered writeback/],

              # Here we can provide detailed help (extracted from mount(8) )
              'help' 
              => [ journal => 'All data is committed into the journal prior '
                            . 'to being written into the main file system. ',
                   ordered => 'This is the default mode. All data is forced '
                            . 'directly out to the main file system prior to '
                            . 'its metadata being committed to the journal.',
                   'writeback'
                   => 'Data ordering is not preserved - data may be written'
                    . 'into the main file system after its metadata has been '
                    . 'committed to the journal. This is rumoured to be the '
                    . 'highest-throughput option. It guarantees internal '
                    . 'file system integrity, however it can allow old data '
                    . 'to appear in files after a crash and journal recovery.'
                 ]
            },
       ],
   'description' 
   => [ 
       'journalling_mode' 
       => 'Specifies the journalling mode for file data. Metadata is always '
        . 'journaled. To use modes other than ordered on the root file '
        . 'system, pass the mode to the kernel as boot parameter, e.g. '
        . 'rootflags=data=journal.'
      ]
  ],

  [
   name => "Iso9660_Opt",
   include => 'CommonOptions' ,
   'element' 
   => [ [qw/rock joliet/] => { type => 'leaf' ,
                                   value_type => 'boolean',
                             },
      ]
  ],
] ;

# do not put 1; at the end of the file


