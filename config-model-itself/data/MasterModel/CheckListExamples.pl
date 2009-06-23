[
 [
   name => "MasterModel::CheckListExamples",
   element 
   => [
       [qw/my_hash my_hash2 my_hash3/] 
       => { type => 'hash',
	    index_type => 'string',
	    cargo_type => 'leaf',
	    cargo_args => { value_type => 'string' },
	  },

       choice_list 
       => { type => 'check_list',
	    choice     => ['A' .. 'Z'],
	    help => { A => 'A help', E => 'E help' } ,
	  },

       choice_list_with_default
       => { type => 'check_list',
	    choice     => ['A' .. 'Z'],
	    default_list   => [ 'A', 'D' ],
	    help => { A => 'A help', E => 'E help' } ,
	  },

       choice_list_with_upstream_default_list
       => { type          => 'check_list',
	    choice        => ['A' .. 'Z'],
	    upstream_default_list => [ 'A', 'D' ],
	    help          => { A => 'A help', E => 'E help' } ,
	  },

       macro => { type => 'leaf',
		  value_type => 'enum',
		  choice     => [qw/AD AH/],
		},

       'warped_choice_list'
       => { type => 'check_list',
	    warp => { follow => '- macro',
		      rules  => { AD => { choice => [ 'A' .. 'D' ], 
					  default_list => ['A', 'B' ] 
					},
				  AH => { choice => [ 'A' .. 'H' ] },
				}
		    }
	  },

       refer_to_list 
       => { type => 'check_list',
            refer_to => '- my_hash'
          },

       refer_to_2_list 
       => { type => 'check_list',
            refer_to => '- my_hash + - my_hash2   + - my_hash3'
          },

       refer_to_check_list_and_choice
       => { type => 'check_list',
            refer_to => [ '- refer_to_2_list + - $var',
			  var => '- indirection ',
			],
	    choice  => [qw/A1 A2 A3/],
          },

       indirection => { type => 'leaf', value_type => 'string' } ,

       ]
   ]
] ;

