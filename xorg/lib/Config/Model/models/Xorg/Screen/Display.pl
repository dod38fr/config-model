# $Author: ddumont $
# $Date: 2007-05-07 11:45:34 $
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


# This model was created from xorg.conf(5x) man page from xorg
# project (http://www.x.org/).

# Model for Display subsection (used by Screen section)
# see xorg.conf

[
 [
  name => "Xorg::Screen::Display::Virtual",
  'element'
  => [
      [qw/xdim ydim/]
      => => {type => 'leaf', value_type => 'integer',}
     ],
  'description'
  =>[
     xdim => 'xdim must be a multiple of either 8 or16 for most drivers, and a multiple of 32 when  running in monochrome mode.',
    ],

  'class_description' => 'This optional entry specifies the virtual
  screen resolution to be used. xdim must be a multiple of either 8 or
  16 for most drivers, and a multiple of 32 when running in monochrome
  mode.  The given value will be rounded down if this is not the case.
  Video modes which are too large for the specified virtual size will
  be rejected. If this entry is not present, the virtual screen
  resolution will be set to accommodate all the valid video modes
  given in the Modes entry.  Some drivers/hardware combinations do not
  support virtual screens. Refer to the appropriate driver-specific
  documentation for details.',

 ],
 [
  name => "Xorg::Screen::Display::ViewPort",
  'element'
  => [
      [qw/x0 y0/]
      => {type => 'leaf', value_type => 'integer',}
     ],
 ],
 [
  name => "Xorg::Screen::Display::Color",
  'element'
  => [
      [qw/red green blue/]
      => {type => 'leaf', value_type => 'integer',}
     ],
 ],
 [
  name => "Xorg::Screen::Display",
  'element'
  => [ 'Depth'
       => {type => 'leaf', value_type => 'integer', max => 24, min => 1  },

       ['FbBpp','Weight' ] => 
        => {type => 'leaf', value_type => 'integer',},

       'Virtual' => { type => 'node',
		      config_class_name => 'Xorg::Screen::Display::Virtual',
		    },

       'ViewPort' => { type => 'node',
		       config_class_name => 'Xorg::Screen::Display::ViewPort',
		     }, 

       'Modes'  
       => {
	   type => 'check_list',
	   refer_to => [ '! Modes:"$my_monitor_use_modes" + ! Monitor:"$my_monitor" Mode ',
			 'my_monitor' => '- - Monitor',
			 'my_monitor_use_modes' => '! Monitor:"$my_monitor" UseModes'
		       ],
	   # built-in Vesa modes
	   choice => ["1280x1024", "1024x768", "832x624", 
		      "800x600", "720x400", "640x480"],
	  },

       'Visual' 
       => {
	   type => 'leaf',
	   value_type => 'enum',
	   warp => { follow => '- Depth',
		     'rules'
		     =>  {
			  1 => { choice => [qw/StaticGray/],
				 built_in => 'StaticGray',
			       },
			  4 => { choice => [qw/StaticGray GrayScale 
                                               StaticColor PseudoColor/],
				 built_in => 'StaticColor',
			       },
			  8 => { choice => [qw/StaticGray GrayScale 
                                               StaticColor PseudoColor 
                                               TrueColor DirectColor/],
				 built_in => 'PseudoColor',
			       },
			  15 => { 
				 choice => [qw/TrueColor DirectColor/],
				 built_in => 'TrueColor',
				},
			  16 => { 
				 choice => [qw/TrueColor DirectColor/],
				 built_in => 'TrueColor',
				},
			  24 => { 
				 choice => [qw/TrueColor DirectColor/],
				 built_in => 'TrueColor',
				},
			 }
		   },
	  },
       [qw/Black White/] 
       => { 
	   type => 'warped_node',
	   follow => '- Depth',
	   'rules' 
	   =>  {1 => {config_class_name => 'Xorg::Screen::Display::Color',
		     }
	       },
	  }

     ],

  permission => [ 'BiosLocation' => 'master' ],

  'description'
  => [
      'Depth' => 'This entry specifies what colour depth the Display subsection  is  to  be  used  for.   This entry is usually specified, but it may be omitted to create a  match-all Display  subsection  or  when  wishing  to  match  only against the FbBpp parameter.  The range of depth values that  are  allowed depends on the driver.  Most drivers support 8, 15, 16 and 24.  Some also support  1  and/or 4,  and some may support other values (like 30).  Note: depth means the number of bits  in  a  pixel  that  are actually used to determine the pixel colour.  32 is not a valid depth value.  Most hardware that uses  32  bits per  pixel  only  uses  24  of  them to hold the colour information, which means that the colour depth  is  24, not 32.',

      'FbBpp' => 'This  entry  specifies the framebuffer format this Display subsection is to be used for.  This entry is  only needed  when  providing  depth  24  configurations that allow a choice between a 24 bpp packed framebuffer format  and  a  32bpp  sparse framebuffer format.  In most cases this entry should not be used.',

      'Weight' => 'red-weight green-weight blue-weight
              This optional entry specifies the relative RGB  weight-
              ing  to  be used for a screen is being used at depth 16
              for drivers that allow multiple formats.  This may also
              be  specified  from  the  command line with the -weight
              option (see Xorg(1)).',

       'Virtual' => 'This optional entry specifies the virtual screen
              resolution to be used.',

       'ViewPort' => 'This  optional  entry sets the upper left corner of the initial display.  This is only relevant when  the  virtual screen resolution is different from the resolution of the initial video mode.  If this entry is not given, then  the  initial display will be centered in the virtual display area.',

       'Modes' => 'This optional entry specifies the list of video
       modes to use.  Each mode-name specified must be in double
       quotes.  They must correspond to those specified or referenced
       in the appropriate Monitor section (includ- ing implicitly
       referenced built-in VESA standard modes).  The server will
       delete modes from this list which don\'t satisfy various
       requirements.  The first valid mode in this list will be the
       default display mode for startup.  The list of valid modes is
       converted internally into a circular list.  It is possible to
       switch to the next mode with Ctrl+Alt+Keypad-Plus and to the
       previous mode with Ctrl+Alt+Keypad-Minus.  When this entry is
       omitted, the valid modes referenced by the appropriate Monitor
       section will be used.  If the Monitor section contains no
       modes, then the selection will be taken from the built-in VESA
       standard modes.',

      'Visual' => 'This optional entry sets the default root visual
              type.  This may also be specified from the command line
              (see the Xserver(1) man page). Not all drivers support
              DirectColor at these depths 15 16 24.',


      'Black' => '  red green blue
              This  optional  entry  allows  the "black" colour to be
              specified.  This is only supported  at  depth  1.   The
              default is black.',

       'White' =>'  red green blue
              This  optional  entry  allows  the "white" colour to be
              specified.  This is only supported  at  depth  1.   The
              default is white.',

       'Options' => 
              'Option  flags  may  be specified in the Display subsec-
              tions.  These may include driver-specific  options  and
              driver-independent  options.   The former are described
              in the driver-specific documentation.  Some of the lat-
              ter are described above in the section about the Screen
              section, and they may also be included here.',

     ],
 ],
];
