# $Author: ddumont $
# $Date: 2007-10-16 11:15:38 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

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
   name => "Itself::Element",

   include => 'Itself::CargoElement' ,
   include_after => 'cargo_type' ,

   'element' 
   => [

       # structural information
       'type' => { type => 'leaf',
		   value_type => 'enum',
		   choice => [qw/node warped_node leaf hash list check_list/],
		   mandatory => 1 ,
		   description => 'specify the type of the configuration element. Leaf is used for plain value.',
		 },

       # all elements

       'status' 
       => {
	   type => 'leaf',
	   value_type => 'enum', 
	   choice => [qw/obsolete deprecated standard/],
	   built_in => 'standard' ,
	  },

       'description' 
       => {
	   type => 'leaf',
	   value_type => 'string', 
	  },

       # hash or list
       'cargo_type' 
       => { type => 'leaf',
	    level => 'hidden',
	    warp => { follow => { t => '- type' },
		     'rules'
		      => [ '$t eq "hash" or $t eq "list"' 
			   => {
			       level => 'normal',
			       value_type => 'enum',
			       mandatory => 1,
			       choice => [qw/node leaf/] ,
			      },
			 ]
		    },
	    description => 'Specify the type of configuration element contained in this hash or list.',
	  },

       # list element


       # hash or list
       'cargo_args' 
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
