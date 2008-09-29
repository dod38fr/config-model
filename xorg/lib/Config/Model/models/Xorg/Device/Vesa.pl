# $Author: ddumont $
# $Date: 2007-10-23 16:18:25 $
# $Name: not supported by cvs2svn $
# $Revision: 1.2 $

#    Copyright (c) 2008 Dominique Dumont.
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


# Model for Vesa driver 

[
 [
  name => "Xorg::Device::Nvidia",
  'element' 
  => [ 
      ['ShadowFB', 'ModeSetClearScreen']
      => { type       => 'leaf',
	   value_type => 'boolean',
	   built_in   => 1,
	 },
     ],

  'description' 
  => [
      'ShadowFB'        => 'Enable or disable use of the shadow framebuffer layer. This option is recommended for performance reasons.',
      'ModeSetClearScreen' => 'Clear the screen on mode set. Some BIOSes seem to be broken in the sense that the newly set video mode is bogus if they are asked to clear the screen during mode setting. If you experience problems try to turn this option off.',
     ],
 ]
];
