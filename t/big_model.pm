# -*- cperl -*-

# this file is used by test script

[
  [
   name => 'SubSlave2',
   element => [
	       [qw/aa2 ab2 ac2 ad2 Z/] =>
	       { type => 'leaf', value_type => 'string' }
	      ],
    description => [ Z => 'Z comme zorro' ],
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

  [
   name => 'X_base_class2',
   element => [
	       X => { type => 'leaf',
		      value_type => 'enum',
		      choice     => [qw/Av Bv Cv/]
		    },
	      ],
   class_description => 'rather dummy class to check include feature',
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
   include_after => 'Z',
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
   include => 'X_base_class',
  ],


  [
   name => 'Master',
   permission => [ [qw/tree_macro warp/] => 'advanced'] ,
   class_description => "Master configuration class is a wonderful test class\n"
     . "widely used in Config::Model self tests",
    copyright => [ "2005-2011, Dominique Dumont" ],
    license => 'LGPL-2',
    author => 'Dominique Dumont' ,
   level      => [ [qw/lista hash_a tree_macro int_v/] => 'important' ],
   element => [
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
	       ordered_hash => { type => 'hash',
				 index_type => 'string',
				 ordered => 1 ,
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
	       warp => {
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

	       'slave_y' => { type => 'node',
			      config_class_name => 'SlaveY' ,
			    },

	       string_with_def => { type => 'leaf',
				    value_type => 'string',
				    default    => 'yada yada'
				  },
	       a_uniline => { type => 'leaf',
			     value_type => 'uniline',
			     default    => 'yada yada'
			    },
	       a_string => { type => 'leaf',
			     mandatory => 1 ,
			     value_type => 'string'
			   },
	       hidden_string 
	       => { type => 'leaf',
		    level => 'hidden',
		    value_type => 'string' ,
		    warp => {
			     follow => '! tree_macro',
			     rules => { XZ => {
					       level =>'normal',
					      }
				      }
			    },
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
	       my_reference => { type => 'leaf',
				 value_type => 'reference',
				 refer_to => '- hash_a + ! hash_b',
			       }
	      ],
   description => [
		   tree_macro => 'controls behavior of other elements',
		   hidden_string => 'shy text',
		  ]
   ],
] ;

# do not put 1; at the end or Model-> load will not work
