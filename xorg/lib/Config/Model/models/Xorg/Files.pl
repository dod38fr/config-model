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

# Top level class feature xorg.conf sections

$foo 
  = [
     [
     name => "Xorg::Files",
     'element' 
     => [ 
	 # we might want to create a dedicated class to help
	 # check validity of path. OTOH, a line like 
	 # " /usr/lib/X11/fonts/75dpi/:unscaled" is valid and
	 # is not a path because of the ":unscaled" wart.
	 [qw/FontPath RGBPath ModulePath/]
	 => { type => 'list',
	      cargo_type => 'leaf',
	      cargo_args => {value_type => 'uniline'},
	    },
	],

     'description' 
     => [
	 FontPath => 'search path for fonts',
	 RGBPath  => 'path name for the RGB color database',
	 ModulePath => 'search path for loadable  Xorg  server  modules',
	],
     ]
    ];
