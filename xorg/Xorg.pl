# $Author: ddumont $
# $Date: 2006-11-07 12:38:02 $
# $Name: not supported by cvs2svn $
# $Revision: 1.5 $

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

[
  [
   name => "Xorg",

   read_config => [ { class => 'Config::Xorg::Read', function => 'read'}] ,
   config_dir => '/etc/X11/' ,

   'element' 
   => [
       'Files' => {
		   type => 'node',
		   config_class_name => 'Xorg::Files',
		  },

#        ServerFlags    will be done later

       'Module' => {
 		    type => 'node',
 		    config_class_name => 'Xorg::Module',
		   },

       # From InputDevice section
       [qw/CorePointer CoreKeyboard/]
       => { type => 'leaf',
	    mandatory => 1,
	    refer_to => '! InputDevice',
	  },

       'InputDevice' 
       => {
	   type => 'hash',
	   index_type => 'string' , # Identifier field in xorg.conf
	   cargo_type => 'node',
	   config_class_name => 'Xorg::InputDevice',
	   # set up default keyboard and mouse as recommended by xorg.conf
	   default => { 'kbd'   =>'driver=keyboard',
			'mouse' => 'driver=mouse' } ,

	  },

       'MultiHead' => => { type => 'leaf',
			   value_type => 'boolean',
			   default => 0,
			 },

#        Device         Graphics device description
       'Device' 
       => {
	   type => 'hash',
	   index_type => 'string' , # Identifier field in xorg.conf
	   cargo_type => 'node',
	   config_class_name => 'Xorg::Device',
	  },

#        VideoAdaptor   Xv video adaptor description
#        Difficult to provide a model without doc...

#        Monitor        Monitor description
       'Monitor'
       => {
	   type => 'hash',
	   index_type => 'string' , # Identifier field in xorg.conf
	   cargo_type => 'node',
	   config_class_name => 'Xorg::Monitor',
	  },


#        Modes          Video modes descriptions
       'Modes' => {
	   type => 'hash',
	   index_type => 'string' , 
	   cargo_type => 'node',
	   config_class_name => 'Xorg::Monitor::Mode',
	  },

#        Screen         Screen configuration
       'Screen' => { 
		    type => 'hash',
		    index_type => 'string' , # Identifier field in xorg.conf
		    cargo_type => 'node',
		    config_class_name => 'Xorg::Screen',
		   },
       
#        ServerLayout   Overall layout

#        DRI            DRI-specific configuration
#        Vendor         Vendor-specific configuration
      ],

   level => [ [qw/MultiHead/] => 'important' ],
       
   'description' 
   => [
       Files          => 'File pathnames',
       ServerFlags    => 'Server flags',
       Module         => 'Dynamic module loading',
       CorePointer    => 'name of the core (primary) pointer device',
       CoreKeyboard   => 'name of the core (primary) keyboard device',
       InputDevice    => 'Input device(s) description',
       MultiHead      => 'Set this to one if you plan to use more than 1 display',
       Device         => 'Graphics device description',
       VideoAdaptor   => 'Xv video adaptor description',
       Monitor        => 'Monitor description',
       Modes          => 'Video modes descriptions',
       Screen         => 'Screen configuration',
       ServerLayout   => 'Overall layout',
       DRI            => 'DRI-specific configuration',
       Vendor         => 'Vendor-specific configuration',
       Keyboard       => 'Keyboard configuration (obsolete)',
       Pointer        => 'Pointer/mouse configuration (obsolete)',
      ],
  ]
];
