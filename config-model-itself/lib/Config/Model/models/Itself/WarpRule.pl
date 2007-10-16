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
   name => "Itself::WarpRule",

   class_description => 'Specify one condition and one effect to be applied on the warped object',

   'element' 
   => [

       'condition' => { type => 'leaf',
			value_type => 'string',
			mandatory => 1 ,
			description => 'boolean expression using variables. E.g.\'$m1 eq "A" && $m2 eq "C"\' ',
		      },

       'effect' => {
		    type => 'node',
		    config_class_name => 'Itself::WarpableElement',
		    description => 'Specified the property changes to be applied when the associated condition is true',
		   },
      ],

  ],

];
