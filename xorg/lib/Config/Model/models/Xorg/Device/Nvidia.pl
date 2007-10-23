# $Author: ddumont $
# $Date: 2007-10-23 16:18:25 $
# $Name: not supported by cvs2svn $
# $Revision: 1.2 $

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


# Model for Nvidia proprietary driver (see 
# http://download.nvidia.com/XFree86/Linux-x86/1.0-8774/README/appendix-d.html)

# this model is preliminary. More work is required.

[
 [
  name => "Xorg::Device::Nvidia",
  'element' 
  => [ 
      'TwinView'         => { type       => 'leaf',
			      value_type => 'boolean',
			      built_in   => 0,
			    },
      'MetaModes'        => { type       => 'leaf',
			      value_type => 'uniline',
			    },
      'CrtcNumber'       => { type       => 'leaf',
			      value_type => 'integer',
			    },
     ],

  'description' 
  => [
      # See 
      # http://download.nvidia.com/XFree86/Linux-x86/1.0-8774/README/appendix-g.html
      'MetaModes'        => 'Incomplete model. TBD',
      
     ],
 ]
];
