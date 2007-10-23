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


# This model was created from xorg.conf(5x) man page from xorg
# project (http://www.x.org/).

# Model for Screen option
# see xorg.conf

[
 [
  name => "Xorg::Screen::Option",
  'element'
  => [ 'Accel'
       => {type       => 'leaf', value_type => 'boolean', built_in => 1 },

       [qw(InitPrimary NoInt10 NoMTRR
         XaaNoCPUToScreenColorExpandFill
         XaaNoColor8x8PatternFillRect
         XaaNoColor8x8PatternFillTrap
         XaaNoDashedBresenhamLine
         XaaNoDashedTwoPointLine
         XaaNoImageWriteRect
         XaaNoMono8x8PatternFillRect
         XaaNoMono8x8PatternFillTrap
         XaaNoOffscreenPixmaps
         XaaNoPixmapCache
         XaaNoScanlineCPUToScreenColorExpandFill
         XaaNoScanlineImageWriteRect
         XaaNoScreenToScreenColorExpandFill
         XaaNoScreenToScreenCopy
         XaaNoSolidBresenhamLine
         XaaNoSolidFillRect
         XaaNoSolidFillTrap
         XaaNoSolidHorVertLine
         XaaNoSolidTwoPointLine
         )
       ]
       => {type       => 'leaf', value_type => 'boolean', built_in => 0 },

       "BiosLocation" => {type       => 'leaf', 
			  value_type => 'uniline' },

     ],

  permission => [ 'BiosLocation' => 'master' ],

  'description'
  => [

      'Accel' => 'Enables XAA (X Acceleration Architecture), a mechanism that makes video cards\' 2D hardware acceleration available to the __xservername__ server. This option is on by default, but it may be necessary to turn it off if there are bugs in the driver. There are many options to disable specific accelerated operations, listed below.  Note that disabling an operation will have no effect if the operation is not accelerated (whether due to lack of support in the hardware or in the driver).',

      'BiosLocation' => 'Set the location of the BIOS for the Int10 module. One may select a BIOS of another card for posting or the legacy V_BIOS range located at 0xc0000 or an alterna- tive address (BUS_ISA). This is only useful under very special circumstances and should be used with extreme care.',

      'InitPrimary' => 'Use the Int10 module to initialize the primary graphics card.  Normally, only secondary cards are soft-booted using the Int10 module, as the primary card has already been initialized by the BIOS at boot time. Default: false.',

      'NoInt10' => 'Disables the Int10 module, a module that uses the int10 call to the BIOS of the graphics card to initialize it.',

      'NoMTRR' => 'Disables MTRR (Memory Type Range Register) support, a feature of modern processors which can improve video performance by a factor of up to 2.5.  Some hardware has buggy MTRR support, and some video drivers have been known to exhibit problems when MTRR\'s are used.',

      'XaaNoCPUToScreenColorExpandFill' => 'Disables accelerated rectangular expansion blits from source patterns stored in system memory (using a mem- ory-mapped aperture).',

      'XaaNoColor8x8PatternFillRect' => 'Disables accelerated fills of a rectangular region with a full-color pattern.',

      'XaaNoColor8x8PatternFillTrap' => 'Disables accelerated fills of a trapezoidal region with a full-color pattern.',

      'XaaNoDashedBresenhamLine' => 'Disables accelerated dashed Bresenham line draws.',

      'XaaNoDashedTwoPointLine' => 'Disables accelerated dashed line draws between two arbitrary points.',

      'XaaNoImageWriteRect' => 'Disables accelerated transfers of full-color rectangu- lar patterns from system memory to video memory (using a memory-mapped aperture).',

      'XaaNoMono8x8PatternFillRect' => 'Disables accelerated fills of a rectangular region with a monochrome pattern.',

      'XaaNoMono8x8PatternFillTrap' => 'Disables accelerated fills of a trapezoidal region with a monochrome pattern.',

      'XaaNoOffscreenPixmaps' => 'Disables accelerated draws into pixmaps stored in off- screen video memory.',

      'XaaNoPixmapCache' => 'Disables caching of patterns in offscreen video memory.',

      'XaaNoScanlineCPUToScreenColorExpandFill' => 'Disables accelerated rectangular expansion blits from source patterns stored in system memory (one scan line at a time).',

      'XaaNoScanlineImageWriteRect' => 'Disables accelerated transfers of full-color rectangu- lar patterns from system memory to video memory (one scan line at a time).',

      'XaaNoScreenToScreenColorExpandFill' => 'Disables accelerated rectangular expansion blits from source patterns stored in offscreen video memory.',

      'XaaNoScreenToScreenCopy' => 'Disables accelerated copies of rectangular regions from one part of video memory to another part of video mem- ory.',

      'XaaNoSolidBresenhamLine' => 'Disables accelerated solid Bresenham line draws.',

      'XaaNoSolidFillRect' => 'Disables accelerated solid-color fills of rectangles.',

      'XaaNoSolidFillTrap' => 'Disables accelerated solid-color fills of Bresenham trapezoids.',

      'XaaNoSolidHorVertLine' => 'Disables accelerated solid horizontal and vertical line draws.',

      'XaaNoSolidTwoPointLine' => 'Disables accelerated solid line draws between two arbi- trary points.',

   ],
 ],
];
