# $Author: ddumont $
# $Date: 2006-12-07 13:13:22 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

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


# Model for Radeon driver (see radeon(5))

[
 [
  name => "Xorg::Device::Radeon",
  'element' 
  => [ 
      'MergedFB'         => { type       => 'leaf',
			      value_type => 'boolean',
			    },
     ],

  'description' 
  => [
      'MergedFB' => 'This enables merged framebuffer mode.  In this mode you have a single  shared  framebuffer  with  two  viewports looking into it.  It is similar to Xinerama, but has some advantages.  It is faster than Xinerama, the DRI works on both heads, and it supports clone modes.',
     ],
 ]
];
