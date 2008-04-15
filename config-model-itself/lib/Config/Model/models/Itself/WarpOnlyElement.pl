# $Author: ddumont $
# $Date: 2008-04-14 15:57:49 +0200 (Mon, 14 Apr 2008) $
# $Revision: 604 $

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
   name => "Itself::WarpOnlyElement",

   include => 'Itself::WarpableElement' ,

   'element' 
   => [

       'permission' 
       => {
	   type => 'leaf',
	   value_type => 'enum', 
	   choice => [qw/master advanced intermediate/] ,
	  },

       'level' 
       => {
	   type => 'leaf',
	   value_type => 'enum', 
	   choice => [qw/important normal hidden/] ,
	  },

      ],

   'description' 
   => [
       permission => 'Used to categorize configuration elements in several "required skills". Use this feature if you need to hide a parameter to novice users',
       level => 'Used to highlight important parameter or to hide others. Hidden parameter are mostly used to hide features that are unavailable at start time. They can be made available later using warp mechanism',
      ],
  ],

];
