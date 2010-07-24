# test model used by t/*.t

[
 {
  read_config  => [
                    {   backend => 'ComplexIni', 
                        config_dir => '/cini/',
                        file => 'hosts.ini',
                        auto_create => 1,
                    },
                  ],

  name => 'Host',

  accept =>      [
                    { 
                            match => 'list*',
                            type => 'list',
                            cargo => { 
                                        type => 'leaf',
                                        value_type => 'string',
                                     } ,
                     },
                     { 
                            match => 'str*',
                            type => 'leaf',
                            value_type => 'uniline'
                     },
                     #TODO: Some advanced structures, hashes, etc.
         ],
  element =>      [
                    id => { 
                                type => 'leaf',
                                value_type => 'uniline',
                           },

         ]

 }
];



