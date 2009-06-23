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
   name => "Itself::ComputedValue",
   include => "Itself::MigratedValue" ,

   'element' 
   => [

       'allow_override' 
       => { type => 'leaf',

	    value_type => 'boolean',
	    upstream_default   => 0,
	    level => 'normal',
	    description => "Allow user to override computed value (ignored if no computation is used for this variable).",
	 },


      ],

  ],

];
