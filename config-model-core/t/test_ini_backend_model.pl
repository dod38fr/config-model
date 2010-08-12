# test model used by t/*.t

[
 {
  read_config  => [
                    {   backend => 'IniFile', 
                        config_dir => '/etc/',
                        file => 'test.ini',
                        auto_create => 1,
                    },
                  ],

  name => 'IniTest',

  element =>      [
                    [qw/foo bar/] => { 
                                      type => 'list',
                                      cargo => {
                                                type => 'leaf',
                                                value_type => 'uniline',
                                                }
                                     },

                    [qw/class1 class2/] => { 
                                            type => 'node',
                                            config_class_name => 'IniTest::Class'
                                           }
                  ]
  },
 {
  name => 'IniTest::Class',
  element => [
              [qw/lista listb/] => {
                                    type => 'list',
                                    cargo => { 
                                              type => 'leaf',
                                              value_type => 'uniline',
                                             } ,
                                   },
             ]
 }
];



