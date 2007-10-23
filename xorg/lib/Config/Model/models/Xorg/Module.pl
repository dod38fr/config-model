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

$foo 
  = [
     [
     name => "Xorg::Module",

     'class_description' 
      => 'Xorg Module contains the list of module to load.',


      # problem: how can we list an extension that could be installed
      # by another package ??

      # On debian, complete list is given by:
      # find /usr/lib/xorg/modules/ -name *.so

      # Create a add_model_element method
      # and use XorgModel.d/foo.pl to add elements
      # but the /etc/config-model.d will become a mess
      # TBD : I need to split this directory in parts (Xorg::Module ??)

     'element' 
     => [ 
	 [qw/bitmap dbe ddc extmod freetype int10 record type1 vbe glx/]
	 => { type => 'leaf',
	      value_type => 'boolean',
	      default => 1,
	    },
	 [qw/dri v4l/]
	 => { type => 'leaf',
	      value_type => 'boolean',
	      default => 0,
	    },

	 # specific option that are mentionned in Subsection could be
	 # added as foo_option element which is available only
	 # if extmod is set to 1

	 # this model part is commented as I don't know which options
	 # are available to extmod
# Here's an example form Phoronix http://phoronix.com/forums/showthread.php?t=3496
# Load "extmod"
# SubSection "extmod"
# Option "omit XVideo"
# Option "omit XVideo-MotionCompensation"
# Option "omit XFree86-VidModeExtension"
# EndSubSection

# 	 'extmod_option'
# 	 => { type => 'warped_node',
# 	      follow => '- extmod',
# 	      rules => { 
# 			1 => { config_class_name => 'XorgExtModeOption'}
# 		       },
# 	    }

	],

     ]
    ];
