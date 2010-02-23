# test model used by t/*.t

$model->create_config_class 
  (
   name => 'Host',

   element => [
	       [qw/ipaddr canonical alias/] 
	       => { type => 'leaf',
		    value_type => 'uniline',
		  } 
	      ]
   );


$model->create_config_class 
  (
   name => 'Hosts',

   read_config  => [ { backend => 'augeas', 
		       config_dir => '/etc/',
		       file => 'hosts',
		       set_in => 'record',
		       save   => 'backup',
		       #sequential_lens => ['record'],
		     },
		   ],

   element => [
	       record => { type => 'list',
			   cargo => { type => 'node',
				      config_class_name => 'Host',
				    } ,
			 },
	      ]
   );

$model->create_config_class 
  (
   name => 'Sshd',

   'read_config'
   => [ { backend => 'augeas', 
	  config_dir => '/etc/ssh/',
	  file => 'sshd_config',
	  save   => 'backup',
	  sequential_lens => [qw/HostKey Subsystem Match/],
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
	       'AllowUsers',
	       {
		'cargo' => {
			    'value_type' => 'uniline',
			    'type' => 'leaf'
			   },
		'type' => 'list',
	       },
	       'ForceCommand',
	       {
		'value_type' => 'uniline',
		'type' => 'leaf',
	       },
	       'HostbasedAuthentication',
	       {
		'value_type' => 'enum',
		choice => [qw/no yes/],
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
	       'DenyUSers',
	       {
		'cargo' => {
			    'value_type' => 'uniline',
			    'type' => 'leaf'
			   },
		'type' => 'list',
	       },
	       'Protocol',
	       {
		'default_list' => ['1', '2'],
		'type' => 'check_list',
		'choice' => ['1', '2']
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
	       'Match',
	       {
		'cargo' => {
			    'type' => 'node',
			    'config_class_name' => 'Sshd::MatchBlock'
			   },
		'type' => 'list',
	       },
	       'Ciphers',
	       {
		'experience' => 'master',
		'upstream_default_list' => [
					    'aes256-cbc',
					    'aes256-ctr',
					    'arcfour256'
					   ],
		ordered => 1,
		'type' => 'check_list',
		'description' => 'Specifies the ciphers allowed for protocol version 2. By default, all ciphers are allowed.',
		'choice' => [
			     'arcfour256',
			     'aes192-cbc',
			     'aes192-ctr',
			     'aes256-cbc',
			     'aes256-ctr'
			    ]
	       },
 	      ]
   );

$model->create_config_class 
  (
   'name' => 'Sshd::MatchBlock',
   'element' => [
		 'Condition',
		 {
		  'type' => 'node',
		  'config_class_name' => 'Sshd::MatchCondition'
		 },
		 'Settings',
		 {
		  'type' => 'node',
		  'config_class_name' => 'Sshd::MatchElement'
		 }
		]
  );

$model->create_config_class 
  (
   'name' => 'Sshd::MatchCondition',
   'element' => [
		 'User',
		 {
		  'value_type' => 'uniline',
		  'type' => 'leaf',
		 },
		 'Group',
		 {
		  'value_type' => 'uniline',
		  'type' => 'leaf',
		 },
		 'Host',
		 {
		  'value_type' => 'uniline',
		  'type' => 'leaf',
		 },
		 'Address',
		 {
		  'value_type' => 'uniline',
		  'type' => 'leaf',
		 }
		]
  );


$model->create_config_class 
  (
   'name' => 'Sshd::MatchElement',
   'element' => [
		 'AllowTcpForwarding',
		 {
		  'value_type' => 'enum',
		  'type' => 'leaf',
		  'choice' => ['no', 'yes']
		 },
		 'Banner',
		 {
		  'value_type' => 'uniline',
		  'type' => 'leaf',
		 },
		 ]
  );


