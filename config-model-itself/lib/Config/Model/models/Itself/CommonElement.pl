# $Author: ddumont $
# $Date: 2008-04-11 18:20:21 +0200 (ven, 11 avr 2008) $
# $Revision: 600 $

#    Copyright (c) 2007-2010 Dominique Dumont.
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
  name => 'Itself::CommonElement',

  # warp often depend on this one, so list it first
  'element'
  => [

      'mandatory'
      => { type => 'leaf',
	   value_type => 'boolean',
	   level => 'hidden',
	   warp => { follow => '?type',
		     'rules'
		     => { 'leaf' => {
				     upstream_default   => 0,
				     level => 'normal',
				    }
			}
		   }
	 },
      # node element (may be within a hash or list)

      'config_class_name'
      => {
	  type => 'leaf',
	  level => 'hidden',
	  value_type => 'reference', 
	  refer_to => '! class',
	  warp => {  follow => { t => '?type' },
		     rules  => [ '$t  eq "warped_node" '
				 => {
				     # should be able to warp refer_to ??
				     level => 'normal',
				    },
				 '$t  eq "node"'
				 => {
				     # should be able to warp refer_to ??
				     level => 'normal',
				     mandatory => 1,
				    },
			       ]
		  }
	 },

      # warped_node: warp parameter for warped_node. They must be
      # warped out when type is not a warped_node

      # end warp elements for warped_node

      # leaf element

      'choice'
      => { type => 'list',
	   level => 'hidden',
	   description => 'Specify the possible values',
	   warp => { follow => { t  => '?type',
				 vt => '?value_type',
			       },
		     'rules'
		     => [ '  ($t eq "leaf" and (   $vt eq "enum" 
                                                or $vt eq "reference")
                             )
                           or $t eq "check_list"' 
			  => {
			      level => 'normal',
			     } ,
			]
		   },
	   cargo => { type => 'leaf', value_type => 'uniline'},
	 },

      'min'
      => { type => 'leaf',
	   value_type => 'integer',
	   level => 'hidden',
	   description => 'minimum value',
	   experience => 'advanced',
	   warp => { follow => {
				'type'  => '?type',
				'vtype' => '?value_type' ,
			       },
		     'rules'
		     => [ '    $type eq "leaf" 
                           and (    $vtype eq "integer" 
                                 or $vtype eq "number" 
                               )
                          '
			  => {
			      level => 'normal',
			     }
			]
		   }
	 },

      'max'
      => { type => 'leaf',
	   value_type => 'integer',
	   level => 'hidden',
	   description => 'maximum value',
	   experience => 'advanced',
	   warp => { follow => {
				'type'  => '?type',
				'vtype' => '?value_type' ,
			       },
		     'rules'
		     => [ '    $type eq "leaf" 
                           and (    $vtype eq "integer" 
                                 or $vtype eq "number" 
                               )
                          '
			  => {
			      level => 'normal',
			     }
			]
		   }
	 },

      'min_index'
      => { type => 'leaf',
	   value_type => 'integer',
	   level => 'hidden',
	   experience => 'advanced',
	   description => 'minimum number of indexes',
	   warp => { follow => {'type'  => '?type',},
		     'rules'
		     => [ '$type eq "hash" or $type eq "list"'
			  => {level => 'normal',},
			]
		   }
	 },

      'max_index'
      => { type => 'leaf',
	   value_type => 'integer',
	   level => 'hidden',
	   experience => 'advanced',
	   description => 'maximum number of keys',
	   warp => { follow => {'type'  => '?type',},
		     'rules'
		     => [ '$type eq "hash" or $type eq "list"'
			  => {level => 'normal',},
			]
		   }
	 },

      'default'
      => { type => 'leaf',
	   level => 'hidden',
	   value_type => 'uniline',
	   description => 'Specify default value. This default value will be written in the configuration data',
	   warp => {  follow => { 't' => '?type' },
		      'rules'
		      => [ '$t eq "leaf"' 
			   => {
			       level => 'normal',
			      }
			 ]
		   }
	 },

      'upstream_default'
      => { type => 'leaf',
	   level => 'hidden',
	   value_type => 'uniline',
	   description => 'Another way to specify a default value. But this default value is considered as "built_in" the application and is not written in the configuration data (unless modified)',
	   warp => {  follow => { 't' => '?type' },
		      'rules'
		      => [ '$t eq "leaf"' 
			   => {
			       level => 'normal',
			      }
			 ]
		   }
	 },

      'convert'
      => { type => 'leaf',
	   value_type => 'enum',
	   level => 'hidden',
	   experience => 'advanced',
	   description => 'When stored, the value will be converted to uppercase (uc) or lowercase (lc).',
	   warp => {  follow => { 't' => '?type'},
		      'rules'
		      => [ '$t eq "leaf"'
			   => {
			       choice => [qw/uc lc/],
			       level => 'normal',
			      }
			 ]
		   }
	 },


      'match'
      => { type => 'leaf',
	   value_type => 'uniline',
	   level => 'hidden',
	   experience => 'advanced',
	   description => 'Perl regular expression to assert the validity of the value.',
	   warp => {  follow => { 'type' => '?type',
				  'vtype' => '?value_type' ,
				},
		      'rules'
		      => [ '    $type eq "leaf" 
                            and (    $vtype eq "uniline" 
                                  or $vtype eq "string" 
                                )
                          '
			  => {
			      level => 'normal',
			     }
			 ]
		   },
	 },

      'grammar'
      => { type => 'leaf',
	   value_type => 'string',
	   level => 'hidden',
	   experience => 'advanced',
	   description => "Feed this grammar to Parse::RecDescent to perform validation",
	   warp => {  follow => { 'type' => '?type',
				  'vtype' => '?value_type' ,
				},
		      'rules'
		      => [ '    $type eq "leaf" 
                            and (    $vtype eq "uniline" 
                                  or $vtype eq "string" 
                                )
                          '
			  => {
			      level => 'normal',
			     }
			 ]
		   },
	 },


      'default_list'
      => { type => 'check_list',
	   level => 'hidden',
	   refer_to => '- choice',
	   description => 'Specify items checked by default',
	   warp => { follow => { t => '?type', o => '?ordered' },
		     'rules'
		     => [ '$t eq "check_list" and not $o ' 
			  => {
			      level => 'normal',
			     } ,
			  '$t eq "check_list" and $o ' 
			  => {
			      level => 'normal',
			      ordered => 1 ,
			     } ,
			]
		   },
	 },

      'upstream_default_list'
      => { type => 'check_list',
	   level => 'hidden',
	   refer_to => '- choice',
	   description => 'Specify items checked by default in the application',
	   warp => { follow => { t => '?type', o => '?ordered' },
		     'rules'
		     => [ '$t eq "check_list" and not $o ' 
			  => {
			      level => 'normal',
			     } ,
			  '$t eq "check_list" and $o ' 
			  => {
			      level => 'normal',
			      ordered => 1 ,
			     } ,
			]
		   },
	 },

      # hash element

      # list element


     ],
 ],
];
