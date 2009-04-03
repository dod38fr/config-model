# $Author$
# $Date$
# $Revision$

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
  name => "Itself::Element",

  include => ['Itself::NonWarpableElement' ,'Itself::WarpableElement'],
  include_after => 'type' , 

  'element' 
  => [

      # structural information
      'type' => { type => 'leaf',
		  value_type => 'enum',
		  choice => [qw/node warped_node hash list leaf check_list/],
		  mandatory => 1 ,
		  description => 'specify the type of the configuration element.'
		               . 'Leaf is used for plain value.',
		},

      # all elements
      'status' 
      => {
	  type => 'leaf',
	  value_type => 'enum', 
	  choice => [qw/obsolete deprecated standard/],
	  built_in => 'standard' ,
	 },

       'experience' 
       => {
	   type => 'leaf',
	   value_type => 'enum', 
	   choice => [qw/master advanced beginner/] ,
	   built_in => 'beginner',
	   description => 'Used to categorize configuration elements in several "required skills". Use this feature if you need to hide a parameter to novice users',
	  },

       'level' 
       => {
	   type => 'leaf',
	   value_type => 'enum', 
	   choice => [qw/important normal hidden/] ,
	   built_in => 'normal',
	   description => 'Used to highlight important parameter or to hide others. Hidden parameter are mostly used to hide features that are unavailable at start time. They can be made available later using warp mechanism',
	  },

      'summary' 
      => {
	  type => 'leaf',
	  value_type => 'uniline', 
	  description => 'enter short information regarding this element',
	 },

      'description' 
      => {
	  type => 'leaf',
	  value_type => 'string', 
	  description => 'enter detailed help information regarding this element',
	 },

      # all but warped_node
      'warp' 
      => { type => 'warped_node' , # ?
	   level => 'hidden',
	   follow => { elt_type => '- type' } ,
	   rules  => [
		      '$elt_type ne "node"' =>
		      {
		       level => 'normal',
		       config_class_name => 'Itself::WarpValue',
		      }
		     ] ,
	   description => "change the properties (i.e. default value or its value_type) dynamically according to the value of another Value object locate elsewhere in the configuration tree. "
	 },

      'rules' => {
		  type => 'hash',
		  ordered => 1,
		  level      => 'hidden' ,
		  index_type => 'string',
		  warp => {
			   follow => '- type',
			   'rules'
			     => { 'warped_node' => {level => 'normal',}
				}
			  },
		  cargo => { type => 'warped_node',
			     follow => '- type',
			     'rules'
			     => { 'warped_node' 
				  => {
				      config_class_name => 'Itself::WarpOnlyElement' ,
				     }
				}
			   },
		  description => "Each key of a hash is a boolean expression using variables declared in the 'follow' parameters. The value of the hash specifies the effects on the node",
		 },
      # hash or list
      'index_type' 
      => { type => 'leaf',
	   value_type => 'enum',
	   level      => 'hidden' ,
	   warp => { follow => '?type',
		     'rules'
		     => { 'hash' => {
				     level => 'important',
				     mandatory => 1,
				     choice => [qw/string integer/] ,
				    }
			}
		   },
	   description => 'Specify the type of allowed index for the hash. "String" means no restriction.',
	 },

      'cargo' 
      => { type => 'warped_node',
	   level => 'hidden',
	   follow => { 't' => '- type' },
	   'rules' => [ '$t eq "list" or $t eq "hash"' 
			=> {
			    level => 'normal',
			    config_class_name => 'Itself::CargoElement',
			   },
		      ],
	   description => 'Specify the properties of the configuration element configuration in this hash or list',
	 },

     ],
 ],
];
