# $Author: ddumont $
# $Date: 2006-12-07 13:13:23 $
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


# This model was created from xorg.conf(5x) man page from xorg
# project (http://www.x.org/).

# Model for Mode line (used by Monitor and Modes section)
# see xorg.conf

[
 [
  name => "Xorg::Monitor::Mode::Timing",
  'element'
  => [ [qw/disp syncstart syncend total/ ]
       => {type       => 'leaf', value_type => 'integer'},
     ]
 ],
 [
  name => "Xorg::Monitor::Mode::Flags",
  'element'
  => [ [qw/Interlace DoubleScan Composite/]
       => {type => 'leaf', value_type => 'boolean', built_in => 0 },
       [qw/HSyncPolarity VSyncPolarity CSyncPolarity/]
       => {type => 'leaf', value_type => 'enum', 
	   choice => [qw/positive negative/],
	  },
     ],
  'description'
  => [

      "Interlace" => "indicates that the mode is interlaced.",

      "DoubleScan" => "indicates a mode where each scanline is doubled.",

      "HSyncPolarity" => "used to select the polarity of the HSync signal.",

      "VSyncPolarity" => "used to select the polarity of the VSync signal.",

      "Composite" => "be used to specify composite sync on hardware
      where this is supported.",

      "CsyncPolarity" => "On some hardware, this may be used to select
      the composite sync polarity.",
     ],
 ],
 [
  name => "Xorg::Monitor::Mode",
  'element' 
  => [ 
      'DotClock'
      => { type       => 'leaf',
	   value_type => 'number',
	 },
      [qw/HTimings VTimings/]
      => { type       => 'node',
	   config_class_name => 'Xorg::Monitor::Mode::Timing',
	 },
      'Flags'
      => { type       => 'node',
	   config_class_name => 'Xorg::Monitor::Mode::Flags',
	 },
      [qw/HSkew VScan/]
      => { type       => 'leaf',
	   value_type => 'number',
	 },
     ],

  'description' 
  => [

      'DotClock' => 'is the dot (pixel) clock rate to be used for the
      mode.',

      'HSkew' => 'specifies the number of pixels (towards the right
      edge of the screen) by which the display enable signal is to be
      skewed.  Not all drivers use this information.  This option
      might become necessary to override the default value supplied by
      the server (if any).  "Roving" horizontal lines indicate this
      value needs to be increased.  If the last few pixels on a scan
      line appear on the left of the screen, this value should be
      decreased.',

      'VScan' => 'specifies the number of times each scanline is
      painted on the screen.  Not all drivers use this information.
      Values less than 1 are treated as 1, which is the default.
      Generally, the "DoubleScan" Flag mentioned above doubles this
      value.'

     ],
 ],
];
