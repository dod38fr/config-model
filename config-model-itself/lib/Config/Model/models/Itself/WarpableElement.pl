# $Author: ddumont $
# $Date: 2008-02-26 13:36:21 $
# $Name: not supported by cvs2svn $
# $Revision: 1.4 $

#    Copyright (c) 2007 Dominique Dumont.
#
#    This file is part of Config-Model-Itself.
#
#    Config-Model-Itself is free software; you can redistribute it
#    and/or modify it under the terms of the GNU Lesser Public License
#    as published by the Free Software Foundation; either version 2.1
#    of the License, or (at your option) any later version.
#
#    Config-Model-Itself is distributed in the hope that it will be
#    useful, but WITHOUT ANY WARRANTY; without even the implied
#    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#    See the GNU Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model-Itself; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

[
  [
   name => "Itself::WarpableElement",

   'element' 
   => [

       'permission' 
       => {
	   type => 'leaf',
	   value_type => 'enum', 
	   choice => [qw/master advanced intermediate/] ,
	   built_in => 'intermediate',
	  },

       'level' 
       => {
	   type => 'leaf',
	   value_type => 'enum', 
	   choice => [qw/important normal hidden/] ,
	   built_in => 'normal',
	  },

       'value_type' 
       => { type => 'leaf',
	    level => 'hidden',
	    'warp'
	    => { follow => { 't' => '?type' , ct => '?cargo_type' },
		 'rules'
		 => [ '$t eq "leaf" or $ct eq "leaf"' 
		      => {
			  value_type => 'enum',
			  choice => [qw/boolean enum integer reference
					enum_integer number uniline string/],
			  level => 'normal',
			  #mandatory => 1,
			 }
		    ]
	       }
	  },

       [qw/default built_in/] 
       => { type => 'leaf',
	    level => 'hidden',
	    warp => {  follow => { 't' => '?type' , ct => '?cargo_type' },
		       'rules'
		       => [ '$t eq "leaf" or $ct eq "leaf"' 
			    => {
				value_type => 'uniline',
				level => 'normal',
			       }
			  ]
		    }
	  },
 
      [qw/follow_keys_from allow_keys_from/] 
       => { type => 'leaf',
	    level => 'hidden',
	    value_type => 'uniline' ,
	    warp => {  follow => { 't' => '?type' , ct => '?cargo_type' },
		       'rules'
		       => [ '$t eq "hash" or $ct eq "hash"' 
			    => {
				level => 'normal',
			       }
			  ]
		    }
	  },

      [qw/ordered/] 
       => { type => 'leaf',
	    level => 'hidden',
	    value_type => 'boolean' ,
	    warp => {  follow => { 't' => '?type' , ct => '?cargo_type' },
		       'rules'
		       => [ '$t eq "hash" or $ct eq "hash"' 
			    => {
				level => 'normal',
			       }
			  ]
		    }
	  },


      [qw/default_keys auto_create allow_keys/] 
       => { type => 'list',
	    level => 'hidden',
	    cargo_type => 'leaf',
	    cargo_args => { value_type => 'string'} ,
	    warp => {  follow => { 't' => '?type' , ct => '?cargo_type' },
		       'rules'
		       => [ '$t eq "hash" or $ct eq "hash"' 
			    => {
				level => 'normal',
			       }
			  ]
		    }
	  },

      [qw/default_with_init/] 
       => { type => 'hash',
	    level => 'hidden',
	    index_type => 'string',
	    cargo_type => 'leaf',
	    cargo_args => { value_type => 'string'} ,
	    warp => {  follow => { 't' => '?type' , ct => '?cargo_type' },
		       'rules'
		       => [ '$t eq "hash" or $ct eq "hash"' 
			    => {
				level => 'normal',
			       }
			  ]
		    }
	  },

       [qw/convert/] 
       => { type => 'leaf',
	    level => 'hidden',
	    warp => {  follow => { 't' => '?type' , ct => '?cargo_type' },
		       'rules'
		       => [ '$t eq "leaf" or $ct eq "leaf"' 
			    => {
				value_type => 'enum',
				choice => [qw/uc lc/],
				level => 'normal',
			       }
			  ]
		    }
	  },

       [qw/min max max_nb/]
       => { type => 'leaf',
	    level => 'hidden',
	    warp => { follow => {
				 'type'  => '?type',
				 ct => '?cargo_type' ,
				 'vtype' => '?value_type' ,
				},
		     'rules'
		      => [ '($type eq "hash" or $ct eq "hash" )
                            or
                            (    ( $type eq "leaf" or $ct eq "leaf") 
                             and (    $vtype eq "integer" 
                                   or $vtype eq "number" 
                                   or $vtype eq "enum_integer" 
                                 )
                            ) '
			   => {
			       value_type => 'integer',
			       level => 'normal',
			      }
			 ]
		    }
	  },

       'mandatory'
       => { type => 'leaf',
	    level => 'hidden',
	    warp => { follow => '?type',
		     'rules'
		      => { 'leaf' => {
				      value_type => 'boolean',
				      built_in   => 0,
				      level => 'normal',
				     }
			 }
		    }
	  },

       'choice'
       => { type => 'list',
	    cargo_type => 'leaf',
	    level => 'hidden',
	    warp => { follow => { t => '?type',
				  vt => '?value_type',
				},
		      'rules'
		      => [ '  ($t eq "leaf" and $vt =~ /enum/ )
                            or $t eq "check_list"' 
			   => {
			       level => 'normal',
			      } ,
			 ]
		    },
	    'cargo_args' =>  { value_type => 'uniline'}
	  },

       [qw/default_list/] 
       => { type => 'list',
	    level => 'hidden',
	    warp => { follow => { t => '?type' },
		      'rules'
		      => [ '$t eq "check_list"' 
			   => {
			       level => 'normal',
			      } ,
			 ]
		    },
	    cargo_type => 'leaf',
	    cargo_args => {
			   value_type => 'reference',
			   refer_to => '- choice',
			   level => 'normal',
			  }
	  },

       'config_class_name'
       => {
	   type => 'leaf',
	   level => 'hidden',
	   value_type => 'reference', 
	   refer_to => '! class',
	   warp => {  follow => { t => '?type', ct => '?cargo_type'},
		      rules  => [ '$t eq "node" or $t eq "warped_node" or $ct eq "node"' 
				  => { 
				       # should be able to warp refer_to ??
				       level => 'normal',
				     },
				]
		   }
	  },

       'replace'
       => {
	   type => 'hash',
	   index_type => 'string',
	   level => 'hidden',
	   warp => {  follow => { 't' => '?type' , ct => '?cargo_type' },
		      'rules'
		      => [ '$t eq "leaf" or $ct eq "leaf"' 
			   => {
			       level => 'normal',
			      }
			 ]
		   },
	   cargo_type => 'leaf',
	   # TBD this could be a reference if we restrict replace to
	   # enum value...
	   cargo_args => { value_type => 'string' } ,
	  },

       'help'
       => {
	   type => 'hash',
	   index_type => 'string',
	   cargo_type => 'leaf',
	   cargo_args => { value_type => 'string' } ,
	  }


      ],

   'description' 
   => [
       permission => 'Used to categorize configuration elements in several "required skills". Use this feature if you need to hide a parameter to novice users',
       level => 'Used to highlight important parameter or to hide others. Hidden parameter are mostly used to hide features that are unavailable at start time. They can be made available later using warp mechanism',
       value_type => 'specify the type of a leaf element.',
       default => 'Specify default value. This default value will be written in the configuration data',
       built_in => 'Another way to specify a default value. But this default value is considered as "built_in" the applicaiton and is not written in the configuration data (unless modified)',
       follow_keys_from => 'this hash will contain the same keys as the hash pointed by the path string',
       allow_keys_from =>'this hash will allow keys from the keys of the hash pointed by the path string', 
       ordered => 'keep track of the order of the elements of this hash',
       default_keys => 'default keys hashes.',
       auto_create => 'always create a set of keys',
       allow_keys => 'specify a set of allowed keys',
       default_with_init => 'specify a set of keys to create and initialisaiton on some elements . E.g. \' foo => "X=Av Y=Bv", bar => "Y=Av Z=Cz"\' ',
       convert => 'When stored, the value will be converted to uppercase (uc) or lowercase (lc).',
       choice => 'Specify the possible values',
       default_list => 'Speicfy items checked by default',
       help => 'Specify help string specific to possible values. E.g for "light" value, you could write " red => \'stop\', green => \'walk\' ',
      ],
  ],

];
