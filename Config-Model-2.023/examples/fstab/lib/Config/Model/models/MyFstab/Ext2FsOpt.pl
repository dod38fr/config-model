#
# This file is part of Config-Model
#
# This software is Copyright (c) 2012 by Dominique Dumont, Krzysztof Tyszecki.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
          {
            'accept' => [
                          {
                            'value_type' => 'uniline',
                            'type' => 'leaf',
                            'description' => 'unknown parameter'
                          }
                        ],
            'name' => 'MyFstab::Ext2FsOpt',
            'include' => [
                           'MyFstab::CommonOptions'
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
