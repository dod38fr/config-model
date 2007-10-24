# $Author: ddumont $
# $Date: 2007-10-24 16:00:10 $
# $Name: not supported by cvs2svn $
# $Revision: 1.2 $

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
   name => "Itself::WarpValue",

   class_description => 'Warp functionality enable a Value object to change its properties (i.e. default value or its type) dynamically according to the value of another Value object locate elsewhere in the configuration tree.',

   'element' 
   => [
       'follow' 
       => {
	   type => 'hash',
	   cargo_type => 'leaf',
	   index_type =>'string',
	   cargo_args => { value_type => 'uniline' } ,
	   description => 'Specify with a path the configuration element that will drive the warp , i.e .the elements that control the property change. These a specified using a variable name (used in the "rules" formula) and a path to fetch the actual value. Example $country => " ! country"',
	  },
       'rules' => {
		   type => 'hash',
		   ordered => 1,
		   index_type => 'string',
		   cargo_type => 'node',
		   config_class_name => 'Itself::WarpableElement' ,
		   description => 'Specify several test (as formula using the variables defined in "follow" element) to try in sequences and their associated effects',
		  },
      ],
  ],
];
