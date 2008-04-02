# $Author: ddumont $
# $Date: 2007-10-23 16:18:25 $
# $Revision: 1.4 $

#    Copyright (c) 2006-2008 Dominique Dumont.
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

# Model for Monitor section of xorg.conf

[
 [
  name => "Xorg::Monitor",
  'element' 
  => [ 
      [qw/VendorName ModelName/]
      => { type       => 'leaf',
	   value_type => 'uniline',
	 },
      'HorizSync'    => { type       => 'leaf',
			  value_type => 'uniline',
			  built_in   => '28-33kHz'
			},
      'VertRefresh'  => { type       => 'leaf',
			  value_type => 'uniline',
			  built_in   => '43-72Hz'
			},
      'DisplaySize' =>  { type => 'node', 
			  config_class_name => 'Xorg::Monitor::DisplaySize'},

      'Gamma'       =>  { type => 'node', 
			  config_class_name => 'Xorg::Monitor::Gamma'},

      'UseModes'    => { type => 'leaf',
			 value_type => 'reference' ,
			 refer_to => '! Modes ',
		       } ,
      'Mode'        => { type => 'hash',
			 index_type => 'string',
			 cargo_type => 'node' ,
			 config_class_name => 'Xorg::Monitor::Mode'
		       },
      'Option'
      => { type     => 'node',
	   config_class_name => 'Xorg::Monitor::Option' 
	 },
     ],

  'description' 
  => [
      'VendorName' =>  "optional entry for the monitor's manufacturer",

      'ModelName'  => "optional entry for the monitor's model",

      'HorizSync' => "gives the range(s) of horizontal sync
              frequencies supported by the monitor.  horizsync-range
              may be a comma separated list of either discrete values
              or ranges of values.  A range of values is two values
              separated by a dash.  By default the values are in units
              of kHz.  They may be specified in MHz or Hz if MHz or Hz
              is added to the end of the line.  The data given here is
              used by the Xorg server to determine if video modes are
              within the spec- ifications of the monitor.  This
              information should be available in the monitor's
              handbook.  If this entry is omitted, a default range of
              28-33kHz is used.",

      'VertRefresh' => "gives the range(s) of vertical refresh
              frequencies supported by the monitor.  vertrefresh-range
              may be a comma separated list of either discrete values
              or ranges of values.  A range of values is two values
              separated by a dash.  By default the values are in units
              of Hz.  They may be specified in MHz or kHz if MHz or
              kHz is added to the end of the line.  The data given
              here is used by the Xorg server to determine if video
              modes are within the spec- ifications of the monitor.
              This information should be available in the monitor's
              handbook.  If this entry is omitted, a default range of
              43-72Hz is used.",

       'DisplaySize' => "This optional entry gives the width and
              height, in millimetres, of the picture area of the
              monitor.  If given, this is used to calculate the
              horizontal and vertical pitch (DPI) of the screen.",

      'UseModes' => "Include the set of modes listed in the Modes
              section.  This make all of the modes defined in that
              section available for use by this monitor.",

     ],
 ],
 [
  name => 'Xorg::Monitor::DisplaySize',
  'element'
  => [ [qw/width height/] =>  { type       => 'leaf',
				value_type => 'integer',
			      }
     ],
  'description' 
  => [ [qw/width height/] => 'in millimeters', ],
 ],
 [
  name => 'Xorg::Monitor::Gamma',
  'element'
  => [ 'use_global_gamma' =>  { type       => 'leaf',
			      value_type => 'boolean',
			      default    => 1,
			    },
       'gamma' => { type       => 'leaf',
		    value_type => 'number',
		    built_in   => 1 ,
		    level => 'hidden',
		    warp => { follow => '- use_global_gamma',
			      rules => {
					1 => { level => 'normal', }
				       }
			    }

		  },
       [qw/red_gamma green_gamma blue_gamma/]
       => { type       => 'leaf',
	    value_type => 'number',
	    built_in   => 1 ,
	    level => 'hidden',
	    warp => { follow => '- use_global_gamma',
		      rules => {
				0 => { 
				      level => 'normal',
				      mandatory  => 1 , # all 3 are required
				     }
			       }
		    }
	  },
     ],
  'description' 
  => [ [qw/width height/] => 'in millimeters',],
 ],
];
