# $Author: ddumont $
# $Date: 2007-10-23 16:18:25 $
# $Name: not supported by cvs2svn $
# $Revision: 1.4 $

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

   read_config => [ { class => 'Config::Model::Xorg::Read', function => 'read'}] ,
   # config file location is now inherited from a model generated at build time
   inherit => 'Xorg::ConfigDir',

   write_config => { class => 'Config::Model::Xorg::Write', function => 'write'},

   'element' 
   => [
       'Files' => {
		   type => 'node',
		   config_class_name => 'Xorg::Files',
		  },

        'ServerFlags' => {
			  type => 'node',
			  config_class_name => 'Xorg::ServerFlags',
			 },

       'Module' => {
 		    type => 'node',
 		    config_class_name => 'Xorg::Module',
		   },

       # From InputDevice section
       [qw/CorePointer CoreKeyboard/]
       => { type => 'leaf',
	   # mandatory => 1,
	    value_type => 'reference',
	    refer_to => '! InputDevice',
	  },

       'InputDevice' 
       => {
	   type => 'hash',
	   index_type => 'string' , # Identifier field in xorg.conf
	   cargo_type => 'node',
	   config_class_name => 'Xorg::InputDevice',
	   # set up default keyboard and mouse as recommended by xorg.conf
	   default => { 'kbd'   => 'Driver=keyboard',
			'mouse' => 'Driver=mouse'     } ,

	  },

       'MultiHead' => { type => 'leaf',
			value_type => 'boolean',
			default => 0,
		      },

       # Graphics device description
       'Device' 
       => {
	   type => 'hash',
	   index_type => 'string' , # Identifier field in xorg.conf
	   cargo_type => 'node',
	   config_class_name => 'Xorg::Device',
	  },

       # VideoAdaptor   Xv video adaptor description
       # Difficult to provide a model without doc...

       'Monitor'
       => {
	   type => 'hash',
	   index_type => 'string' , # Identifier field in xorg.conf
	   cargo_type => 'node',
	   config_class_name => 'Xorg::Monitor',
	  },


       # Video modes descriptions
       'Modes' => {
	   type => 'hash',
	   index_type => 'string' , 
	   cargo_type => 'node',
	   config_class_name => 'Xorg::Monitor::Mode',
	  },

       # Screen configuration
       'Screen' => { 
		    type => 'hash',
		    index_type => 'string' , # Identifier field in xorg.conf
		    cargo_type => 'node',
		    config_class_name => 'Xorg::Screen',
		   },

       # Overall layout
       'ServerLayout' => { 
		    type => 'hash',
		    index_type => 'string' , # Identifier field in xorg.conf
		    cargo_type => 'node',
		    config_class_name => 'Xorg::ServerLayout',
		   },
       # DRI            DRI-specific configuration
       'DRI' => {
		 type => 'node',
		 config_class_name => 'Xorg::DRI',
		},
       # Vendor         Vendor-specific configuration
      ],

   level => [ [qw/MultiHead/] => 'important' ],

   'description' 
   => [
       Files          => 'File pathnames',
       ServerFlags    => 'Server flags used to specify some global Xorg server options.',
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

       ServerLayout => 'represents the binding of one or more screens
       (Screen sections) and one or more input devices (InputDevice
       sections) to form a complete configuration.',

       DRI            => 'DRI-specific configuration',
       Vendor         => 'Vendor-specific configuration',
       Keyboard       => 'Keyboard configuration (obsolete)',
       Pointer        => 'Pointer/mouse configuration (obsolete)',
      ],
  ],

  [
   name => "Xorg::DRI",
   # A lot of info is still missing.
   element => [
	       Mode => { type => 'leaf',
			 value_type => 'uniline', # err, placeholder...
		       },
	      ],
   description => [
		   Mode => 'DRI mode, usually set to 0666',
		  ]
  ],
];
