# $Author: ddumont $
# $Date: 2008-01-28 12:18:58 $
# $Name: not supported by cvs2svn $
# $Revision: 1.3 $

#    Copyright (c) 2005-2008 Dominique Dumont.
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


# This model was created from xorg.conf(5x) man page from xorg
# project (http://www.x.org/).

# Model for InputDevice section of xorg.conf

[
 [
  name => "Xorg::InputDevice",
  'element' 
  => [ 
      'Driver'         => { type       => 'leaf',
			    value_type => 'enum',
			    mandatory  => 1 ,
			    choice => [qw/kbd mouse/] ,
			    replace => { keyboard => 'kbd'} ,
			  },
      [qw/SendCoreEvents HistorySize/]
                       => { type       => 'leaf',
			    value_type => 'boolean' },
      'Option'
      => { type     => 'warped_node',
	   follow   => '- Driver',
	   'rules' 
	   => [
	       'kbd'
		=> { config_class_name => 'Xorg::InputDevice::KeyboardOpt' },
		'mouse' 
		=> { config_class_name => 'Xorg::InputDevice::MouseOpt' },
	      ]
	 },
     ],

  'description' 
  => [
      'Driver' => 'name of the driver to use for this input device',
      'SendCoreEvents' => 'when enabled cause the input  device  to  always report core events.  This can be used, for example, to allow an additional pointer device  to  generate core pointer events (like moving the cursor, etc).',
      'HistorySize' => 'Sets the motion history size.  Default: 0.'
     ],
 ]
];
