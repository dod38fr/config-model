# test model used by t/*.t

[
 {
  read_config  => [
                    {   backend => 'ComplexIni', 
                        config_dir => '/etc/',
                        file => 'test.ini',
                        auto_create => 1,
                    },
                  ],

  name => 'Cini',

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
                                            config_class_name => 'Cini::Class'
                                           }
                  ]
  },
 {
  name => 'Cini::Class',
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



