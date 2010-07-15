# test model used by t/*.t

[
 {
  read_config  => [{ backend => 'ComplexIni', 
		      config_dir => '/cini/',
		      file => 'hosts.ini',
		      auto_create => 1,
		    },
		  ],

  name => 'Host',

  element => [
	      [qw/ipaddr id/] 
	       => { type => 'leaf',
		   value_type => 'uniline',
		 },

	      aliases => { type => 'list',
			  cargo => { type => 'leaf',
				     value_type => 'string',
				   } ,
			},
	     ]
 }
];



