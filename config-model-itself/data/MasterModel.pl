# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-03-07 13:42:08 $
# $Name: not supported by cvs2svn $
# $Revision: 1.2 $


# this file is used by test script

[
  [
   name => 'MasterModel::SubSlave2',
   element => [
	       [qw/aa2 ab2 ac2 ad2 Z/] =>
	       { type => 'leaf', value_type => 'string' }
	      ]
  ],

  [
   name => 'MasterModel::SubSlave',
   element => [
	       [qw/aa ab ac ad/] => 
	       { type => 'leaf', value_type => 'string' },
	       sub_slave => { type => 'node' ,
			      config_class_name => 'MasterModel::SubSlave2',
			    }
	      ]
  ],

  [
   name => 'MasterModel::SlaveZ',
   element => [
	       [qw/Z/] => { type => 'leaf',
			      value_type => 'enum',
			      choice     => [qw/Av Bv Cv/]
			    },
	       [qw/DX/] => { type => 'leaf',
			     value_type => 'enum',
			     default    => 'Dv',
			     choice     => [qw/Av Bv Cv Dv/]
			   },
	      ],
   include => 'MasterModel::X_base_class',
  ],

  [
   name => 'MasterModel::SlaveY',
   element => [
	       std_id => {
			  type => 'hash',
			  index_type  => 'string',
			  cargo_type => 'node',
			  config_class_name => 'MasterModel::SlaveZ' ,
			 },
	       sub_slave => { type => 'node' ,
			      config_class_name => 'MasterModel::SubSlave',
			    },
	       warp2 => {
			 type => 'warped_node',
			 follow  => '! tree_macro',
			 config_class_name   => 'MasterModel::SubSlave', 
			 morph => 1 ,
			 rules => [
				   mXY => { config_class_name => 'MasterModel::SubSlave2'},
				   XZ  => { config_class_name => 'MasterModel::SubSlave2'}
				  ]
			},
	       Y => { type => 'leaf',
		      value_type => 'enum',
		      choice     => [qw/Av Bv Cv/]
		    },
	      ],
   include => 'MasterModel::X_base_class',
  ],


  [
   name => 'MasterModel',
   permission => [ [qw/tree_macro warp/] => 'advanced'] ,
   class_description => "Master description",
   level      => [ [qw/hash_a tree_macro int_v/] => 'important' ],

   read_config  =>  { backend => 'cds_file',  config_dir  => 'wr_test/conf_data'},
   write_config => [{ backend => 'cds_file',  config_dir  => 'wr_test/conf_data'},
		    { backend => 'perl_file', config_dir  => 'wr_test/conf_data'}],

   element => [
	       std_id => { type => 'hash',
			   index_type  => 'string',
			   cargo_type => 'node',
			   config_class_name => 'MasterModel::SlaveZ' ,
			 },
	       [qw/lista listb/] => { type => 'list',
				      cargo_type => 'leaf',
				      cargo_args => {value_type => 'string'},
				    },
	       "list_XLeds" => { type => 'list',
			    cargo_type => 'leaf',
			    cargo_args => { value_type => 'integer', 
					    min => 1, max => 3 } ,
			  },
	       [qw/hash_a hash_b/] => { type => 'hash',
			  index_type => 'string',
			  cargo_type => 'leaf',
			  cargo_args => {value_type => 'string'},
			},
	       olist => { type => 'list',
			  cargo_type => 'node',
			  config_class_name => 'MasterModel::SlaveZ' ,
			},
	       tree_macro => { type => 'leaf',
			       value_type => 'enum',
			       choice     => [qw/XY XZ mXY/],
			       help => { XY  => 'XY help',
					 XZ  => 'XZ help',
					 mXY => 'mXY help',
				       }
			     },
	       warp_el => {
			type => 'warped_node',
			follow  => '! tree_macro',
			config_class_name   => 'MasterModel::SlaveY', 
			morph => 1 ,
			rules => [
				  #XY => { config_class_name => 'MasterModel::SlaveY'},
				  mXY => { config_class_name => 'MasterModel::SlaveY'},
				  XZ  => { config_class_name => 'MasterModel::SlaveZ'}
				 ]
		       },

	       'slave_y' => { type => 'node',
			      config_class_name => 'MasterModel::SlaveY' ,
			    },

	       string_with_def => { type => 'leaf',
				    value_type => 'string',
				    default    => 'yada yada'
				  },
	       a_string => { type => 'leaf',
			     mandatory => 1 ,
			     value_type => 'string'
			   },
	       int_v => { type => 'leaf',
			  value_type => 'integer',
			  default    => '10',
			  min        => 5,
			  max        => 15
			},
	       my_check_list => { type => 'check_list',
				  refer_to => '- hash_a + ! hash_b',
				} ,
	       'ordered_checklist'
	       => { type => 'check_list',
		    choice     => ['A' .. 'Z'],
		    ordered => 1 ,
		    help => { A => 'A help', E => 'E help' } ,
		  },

	       my_reference => { type => 'leaf',
				 value_type => 'reference',
				 refer_to => '- hash_a + ! hash_b',
			       },
	       lot_of_checklist => {
				    type => 'node',
				    config_class_name => 'MasterModel::CheckListExamples',
				   },
	       warped_values => {
				 type => 'node',
				 config_class_name => 'MasterModel::WarpedValues',
				},
	       warped_id => {
			     type => 'node',
			     config_class_name => 'MasterModel::WarpedId',
			    },
	       hash_id_of_values => {
			     type => 'node',
			     config_class_name => 'MasterModel::HashIdOfValues',
			    },
	       'deprecated_p'
	       => { type => 'leaf',
		    value_type => 'enum',
		    choice => [qw/cds perl ini custom/],
		    status => 'deprecated',
		    description => 'deprecated_p is replaced by new_from_deprecated',
		  },

	       'new_from_deprecated'
	       => { type => 'leaf',
		    value_type => 'enum',
		    choice => [qw/cds_file perl_file ini_file augeas custom/],
		    migrate_from => { formula => '$replace{$old}' , 
				      variables => { old => '- deprecated_p' } ,
				      replace => { 
						  perl => 'perl_file',
						  ini  => 'ini_file',
						  cds  => 'cds_file',
						 },
				    },
		  },
	       'old_url' => { type => 'leaf',
			      value_type => 'uniline',
			      status => 'deprecated',
			    },
	       'host' 
	       => { type => 'leaf',
		    value_type => 'uniline',
		    migrate_from => { formula => '$old =~ m!http://([\w\.]+)!; $1 ;' , 
				      variables => { old => '- old_url' } ,
				      use_eval => 1 ,
				    },
		  },
	       'sshd_augeas' 
	       => {
		   type => 'node',
		   config_class_name => 'MasterModel::SshdWithAugeas',
		  },
	      ],
   description => [
		   tree_macro => 'controls behavior of other elements'
		  ]
   ],
] ;

# do not put 1; at the end or Model-> load will not work
