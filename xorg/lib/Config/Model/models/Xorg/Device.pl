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


# This model was created from xorg.conf(5x) man page from xorg
# project (http://www.x.org/).

# Model for Device section of xorg.conf

[
 [
  name => "Xorg::Device",
  'element' 
  => [ 
      'Driver'         => { type       => 'leaf',
			    value_type => 'enum',
			    mandatory  => 1 ,
			    # obviously, some more work is needed here
			    choice => [qw/radeon nvidia vesa/] ,
			  },

      'BusID'          => { type       => 'leaf',
			    value_type => 'uniline',
			    warp => { follow => '! MultiHead',
				      rules => { 
						1 => { mandatory  => 1 } 
					       }
				    }
			  },

      'Screen'         => { type       => 'leaf',
			    value_type => 'integer',
			    warp => { follow => '! MultiHead',
				      rules => { 
						1 => { mandatory  => 1 } 
					       }
				    }
			  },

      'Option'
      => { type     => 'warped_node',
	   follow   => '- Driver',
	   'rules' 
	   => { 'radeon' => { config_class_name => 'Xorg::Device::Radeon' },
		'nvidia' => { config_class_name => 'Xorg::Device::Nvidia' },
		'vesa'   => { config_class_name => 'Xorg::Device::Vesa' },
	      }
	 },

      [qw/Chipset Ramdac DacSpeed/]
                       => { type       => 'leaf',
			    value_type => 'uniline',
			  },


     ],

  # need deep knowledge to set up these options
  permission => [ [qw/Chipset Ramdac DacSpeed/] => 'advanced' ] ,

  'description' 
  => [
      'Driver' => 'name of the driver to use for this graphics device',
     ],
 ]
];
