# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-02-29 12:43:15 $
# $Name: not supported by cvs2svn $
# $Revision: 1.3 $

# this file is used by test script

[
  [
   name => 'SubSlave2',
   element => [
	       [qw/aa2 ab2 ac2 ad2 Z/] =>
	       { type => 'leaf', value_type => 'string' }
	      ]
  ],

  [
   name => 'SubSlave',
   element => [
	       [qw/aa ab ac ad/] => 
	       { type => 'leaf', value_type => 'string' },
	       sub_slave => { type => 'node' ,
			      config_class_name => 'SubSlave2',
			    }
	      ]
  ],

# rather dummy class to check inclusion
  [
   name => 'X_base_class2',
   element => [
	       X => { type => 'leaf',
		      value_type => 'enum',
		      choice     => [qw/Av Bv Cv/]
		    },
	      ],
  ],

  [
   name => 'X_base_class',
   include => 'X_base_class2',
  ],


  [
   name => 'SlaveZ',
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
   include => 'X_base_class',
  ],

  [
   name => 'SlaveY',
   element => [
	       std_id => {
			  type => 'hash',
			  index_type  => 'string',
			  cargo_type => 'node',
			  config_class_name => 'SlaveZ' ,
			 },
	       sub_slave => { type => 'node' ,
			      config_class_name => 'SubSlave',
			    },
	       warp2 => {
			 type => 'warped_node',
			 follow  => '! tree_macro',
			 config_class_name   => 'SubSlave', 
			 morph => 1 ,
			 rules => [
				   mXY => { config_class_name => 'SubSlave2'},
				   XZ  => { config_class_name => 'SubSlave2'}
				  ]
			},
	       Y => { type => 'leaf',
		      value_type => 'enum',
		      choice     => [qw/Av Bv Cv/]
		    },
	      ],
   include =>  'X_base_class',
  ],


  [
   name => 'Master',

   read_config => 'cds',
   read_config_dir => 'data' ,

   write_config => 'cds',
   write_config_dir => 'wr_data',

   permission => [ [qw/tree_macro warp/] => 'advanced'] ,
   class_description => "Master description",
   level      => [ [qw/hash_a tree_macro/] => 'important' ],
   element => [
	       a_string => { type => 'leaf',
			     value_type => 'string'
			   },
	       string_with_def => { type => 'leaf',
				    value_type => 'string',
				    default    => 'yada yada'
				  },
	       m_string => { type => 'leaf',
			     mandatory => 1 ,
			     value_type => 'string',
			     description =>'an important mandatory string',
			   },
	       m_int_v  => { type => 'leaf',
			     value_type => 'integer',
			     default    => '10',
			     mandatory => 1,
			     min        => 5,
			     max        => 15
			   },
	       m_bool_v => { type => 'leaf',
			     value_type => 'boolean', 
			     mandatory => 1 
			   },
	       int_v => { type => 'leaf',
			  value_type => 'integer',
			  default    => '10',
			  min        => 5,
			  max        => 15
			},
	       int_v_built_in => { type => 'leaf',
				   value_type => 'integer',
				   built_in    => '5',
				   min        => 5,
				   max        => 15
				 },
	       std_id => { type => 'hash',
			   index_type  => 'string',
			   cargo_type => 'node',
			   config_class_name => 'SlaveZ' ,
			 },
	       [qw/lista listb/] => { type => 'list',
				      cargo_type => 'leaf',
				      cargo_args => {value_type => 'string'},
				    },
	       [qw/hash_a hash_b/] => { type => 'hash',
			  index_type => 'string',
			  cargo_type => 'leaf',
			  cargo_args => {value_type => 'string'},
			},
	       olist => { type => 'list',
			  cargo_type => 'node',
			  config_class_name => 'SlaveZ' ,
			},
	       tree_macro => { type => 'leaf',
			       value_type => 'enum',
			       choice     => [qw/XY XZ mXY/],
			       help => { XY  => 'XY help',
					 XZ  => 'XZ help',
					 mXY => 'mXY help',
				       }
			     },
	       'a_warped_node'
	       => {
		   type => 'warped_node',
		   follow  => '! tree_macro',
		   config_class_name   => 'SlaveY', 
		   morph => 1 ,
		   rules => [
			     #XY => { config_class_name => 'SlaveY'},
			     mXY => { config_class_name => 'SlaveY'},
			     XZ  => { config_class_name => 'SlaveZ'}
			    ]
		  },

	       'a_warped_out_node'
	       => {
		   type => 'warped_node',
		   follow  => '! tree_macro',
		   morph => 1 ,
		   rules => [
			     XY => { config_class_name => 'SlaveY'},
			     mXY => { config_class_name => 'SlaveY'},
			     XZ  => { config_class_name => 'SlaveZ'}
			    ]
		  },

	       'slave_y' => { type => 'node',
			      config_class_name => 'SlaveY' ,
			    },

	       my_check_list => { type => 'check_list',
				  choice => [ 'A', 'B', 'C', 'D' ],
				  help => { 'A' => 'some help on A',
					    'B' => 'some help on B not A',
					    'C' => 'some help on C not AB',
					    'D' => 'some help on D not ABC',
					  }
				} ,
	       my_ref_check_list => { type => 'check_list',
				      refer_to => '- hash_a + ! hash_b',
				    } ,

	       my_reference => { type => 'leaf',
				 value_type => 'reference',
				 refer_to => '- hash_a + ! hash_b',
			       },
               my_uniline => { type => 'leaf', value_type => 'uniline'},

	      ],
   description => [
		   tree_macro => 'controls behavior of other elements',
		   std_id => 'a dumb hash of SlaveZ nodes',
		   my_ref_check_list => 'checkable items are defined by hash_a and hash_b'
		  ]
   ],
] ;

# do not put 1; at the end or Model-> load will not work

