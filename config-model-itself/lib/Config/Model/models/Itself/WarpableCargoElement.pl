# $Author: ddumont $
# $Date: 2008-03-24 15:05:19 +0100 (Mon, 24 Mar 2008) $
# $Revision: 559 $

#    Copyright (c) 2007-2008 Dominique Dumont.
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
   name => "Itself::WarpableCargoElement",

   'element' 
   => [

       [qw/default built_in/] 
       => { type => 'leaf',
	    value_type => 'uniline',
	    level => 'hidden',
	    warp => {  follow => { ct => '?cargo_type' },
		       'rules'
		       => [ '$ct eq "leaf"' 
			    => {
				level => 'normal',
			       }
			  ]
		    }
	  },
 
       [qw/convert/] 
       => { type => 'leaf',
	    value_type => 'enum',
	    level => 'hidden',
	    warp => {  follow => { ct => '?cargo_type' },
		       'rules'
		       => [ '$ct eq "leaf"' 
			    => {
				choice => [qw/uc lc/],
				level => 'normal',
			       }
			  ]
		    }
	  },

       [qw/min max/]
       => { type => 'leaf',
	    value_type => 'integer',
	    level => 'hidden',
	    warp => { follow => {
				 ct    => '?cargo_type' ,
				 vtype => '?value_type' ,
				},
		     'rules'
		      => [ '     $ct eq "leaf" 
                             and (    $vtype eq "integer" 
                                   or $vtype eq "number" 
                                 ) '
			   => {
			       level => 'normal',
			      }
			 ]
		    }
	  },

       'mandatory'
       => { type => 'leaf',
	    value_type => 'boolean',
	    level => 'hidden',
	    warp => { follow => '?cargo_type',
		     'rules'
		      => { 'leaf' => {
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
	    warp => { follow => { ct => '?cargo_type',
				  vt => '?value_type',
				},
		      'rules'
		      => [ '  ($ct eq "leaf" and $vt eq "enum" )
                            or $ct eq "check_list"' 
			   => {
			       level => 'normal',
			      } ,
			 ]
		    },
	    'cargo_args' =>  { value_type => 'uniline' }
	  },

       [qw/default_list/] 
       => { type => 'list',
	    level => 'hidden',
	    warp => { follow => { ct => '?cargo_type' },
		      'rules'
		      => [ '$ct eq "check_list"' 
			   => {
			       level => 'normal',
			      } ,
			 ]
		    },
	    cargo_type => 'leaf',
	    cargo_args => {
			   refer_to => '- choice',
			   value_type => 'reference',
			  }
	  },

       'config_class_name'
       => {
	   type => 'leaf',
	   level => 'hidden',
	   value_type => 'reference', 
	   refer_to => '! class',
	   warp => {  follow => { ct => '?cargo_type'},
		      rules  => [ '$ct eq "warped_node"' 
				  => { 
				       # should be able to warp refer_to ??
				       level => 'normal',
				     },
				]
		   }
	  },

       [qw/replace help/]
       => {
	   type => 'hash',
	   index_type => 'string',
	   level => 'hidden',
	   warp => {  follow => { ct => '?cargo_type' },
		      'rules'
		      => [ '$ct eq "leaf"' 
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
      ],

   'description' 
   => [
       value_type => 'specify the type of a leaf element.',
       default => 'Specify default value. This default value will be written in the configuration data',
       built_in => 'Another way to specify a default value. But this default value is considered as "built_in" the application and is not written in the configuration data (unless modified)',
       convert => 'When stored, the value will be converted to uppercase (uc) or lowercase (lc).',
       choice => 'Specify the possible values',
       default_list => 'Specify items checked by default',
       help => 'Specify help string specific to possible values. E.g for "light" value, you could write " red => \'stop\', green => \'walk\' ',
       replace => 'Used for enum to substitute one value with another. This parameter must be used to enable user to upgrade a configuration with obsolete values. The old value is the key of the hash, the new one is the value of the hash',
      ],
  ],

];
