# $Author: ddumont $
# $Date: 2007-10-23 16:18:25 $
# $Name: not supported by cvs2svn $
# $Revision: 1.3 $

#    Copyright (c) 2005,2006 Dominique Dumont.
#
#    This file is part of Config-Xorg.
#
#    Config-Xorg is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Xorg is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA


# Model for Mouse driver. Where's the doc ???

[
 [
  name => "Xorg::InputDevice::MouseOpt",
  'element' 
  => [ 
      'Device'          => { type   => 'leaf' ,
			     value_type => 'uniline',
			   },
      'Protocol'        => { type   => 'leaf',
			     value_type => 'enum',
			     choice => [qw!ImPS/2 IntelliMouse!] ,
			   },
      'Emulate3Buttons' => { type       => 'leaf',
			     value_type => 'boolean',
			     built_in   => 0,
			   },
      'ZAxisMapping'    => {type   => 'leaf' ,
			    value_type => 'uniline',
			   },
      'SendCoreEvents'  => { type       => 'leaf',
			     value_type => 'boolean',
			   },
      "Buttons"         => {type   => 'leaf' ,
			    value_type => 'uniline',
			   },
     ],

  'description' 
  => [

     ],
 ]
];
