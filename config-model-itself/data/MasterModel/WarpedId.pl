[
 [
  name => 'WarpedIdSlave',
  element => [
	      [qw/X Y Z/] => { type => 'leaf',
			       value_type => 'enum',
			       choice     => [qw/Av Bv Cv/],
			     }
	     ]
 ],

 [
  name => 'WarpedId',
  'element'
  => [
      macro => { type => 'leaf',
		 value_type => 'enum',
		 choice     => [qw/A B C/],
	       },
      version => { type => 'leaf',
		   value_type => 'integer',
		   default    => 1
		 },
      warped_hash => { type => 'hash',
		       index_type => 'integer',
		       max_nb     => 3,
		       warp       => {
				      follow => '- macro',
				      rules => { A => { max_nb => 1 },
						 B => { max_nb => 2 }
					       }
				     },
		       cargo_type => 'node',
		       config_class_name => 'WarpedIdSlave'
		     },
      'multi_warp' 
      => { type => 'hash',
	   index_type => 'integer',
	   min        => 0,
	   max        => 3,
	   default    => [ 0 .. 3 ],
	   warp
	   => {
	       follow => [ '- version', '- macro' ],
	       'rules'
	       => [ [ '2', 'C' ] => { max => 7, default => [ 0 .. 7 ] },
		    [ '2', 'A' ] => { max => 7, default => [ 0 .. 7 ] }
		  ]
	      },
	   cargo_type => 'node',
	   config_class_name => 'WarpedIdSlave'
	 },

      'hash_with_warped_value' 
      => { type => 'hash',
	   index_type => 'string',
	   cargo_type => 'leaf',
	   level => 'hidden', # must also accept level permission and description here
	   warp => { follow => '- macro',
		     'rules'
		     => { 'A' => {
				  level => 'normal' ,
				 } ,
			}
		   },
	   cargo_args => {
			  warp => { follow => '- macro',
				    'rules'
				    => { 'A' => {
						 value_type => 'string'
						} ,
				       }
				  }
			 }
	 },
       'multi_auto_create'
      => { type => 'hash',
	   index_type  => 'integer',
	   min         => 0,
	   max         => 3,
	   auto_create => [ 0 .. 3 ],
	   'warp'
	   => { follow => [ '- version', '- macro' ],
		'rules'
		=> [ [ '2', 'C' ] => { max => 7, auto_create => [ 0 .. 7 ] },
		     [ '2', 'A' ] => { max => 7, auto_create => [ 0 .. 7 ] }
		   ],
	      },
	   cargo_type => 'node',
	   config_class_name => 'WarpedIdSlave'
	 }
     ]
 ]
];
