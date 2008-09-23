[
 [
  name => 'MasterModel::SshdWithAugeas',

  'read_config'
  => [ { backend => 'augeas', 
	 config_file => '/etc/ssh/sshd_config',
	 save   => 'backup',
	 lens_with_seq => [qw/AcceptEnv AllowGroups AllowUsers 
			      DenyGroups  DenyUsers/],
       },
     ],

  element => [
	      'AcceptEnv',
	      {
	       'cargo' => {
			   'value_type' => 'uniline',
			   'type' => 'leaf'
			  },
	       'type' => 'list',
	      },
	      'HostbasedAuthentication',
	      {
	       'value_type' => 'boolean',
	       'type' => 'leaf',
	      },
	      'HostKey',
	      {
	       'cargo' => {
			   'value_type' => 'uniline',
			   'type' => 'leaf'
			  },
	       'type' => 'list',
	      },
	      'Subsystem',
	      {
	       'cargo' => {
			   'value_type' => 'uniline',
			   'mandatory' => '1',
			   'type' => 'leaf'
			  },
	       'type' => 'hash',
	       'index_type' => 'string'
	      },
	     ],
 ]
];


