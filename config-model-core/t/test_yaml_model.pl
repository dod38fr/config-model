# test model used by t/*.t

[
 {
  name => 'Host',

  element => [
	      [qw/ipaddr canonical alias/] 
	      => { type => 'leaf',
		   value_type => 'uniline',
		 } 
	     ]
 },
 {
  name => 'Hosts',

  read_config  => [ { backend => 'yaml', 
		      config_dir => '/yaml/',
		      file => 'hosts.yml',
		    },
		  ],

  element => [
	      record => { type => 'list',
			  cargo => { type => 'node',
				     config_class_name => 'Host',
				   } ,
			},
	     ]
 }
];



