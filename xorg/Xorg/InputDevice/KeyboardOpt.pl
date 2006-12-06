# $Author: ddumont $
# $Date: 2006-12-06 13:09:15 $
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


# Model for keyboard driver (see keyboard(4))

[
 [
  name => "Xorg::InputDevice::KeyboardOpt::AutoRepeat",
  element => [
	      delay => {
			type => 'leaf',
			value_type  => 'integer',
			built_in => '500',
		       },
	      rate => {
			type => 'leaf',
			value_type  => 'integer',
			built_in => '30',
		       },
	     ],
  'description'
  => [
      'delay' => 'time in milliseconds before a key starts repeating',
      'rate' => 'number of times a key repeats per second',
     ],
 ],
 [
  name => "Xorg::InputDevice::KeyboardOpt",
  'element' 
  => [ 
      # CoreKeyboard option is stored at top level (in Xorg model)

      "Protocol"         => {
			     type => 'leaf',
			     value_type  => 'enum',
			     choice => [qw/Standard Xqueue/],
			     built_in => 'Standard',
			    },
      "AutoRepeat"
      => {
	  type => 'node',
	  config_class_name => "Xorg::InputDevice::KeyboardOpt::AutoRepeat"
	 },

      "XLeds" => { type => 'list',
		   cargo_type => 'leaf',
		   cargo_args => { value_type => 'integer', 
				   min => 1, max => 3 } ,
		 },

      "XkbDisable" => { type => 'leaf',
			value_type => "boolean",
			built_in => 0,
		      },

      'XkbRules'        => {
			     type => 'leaf',
			     value_type  => 'enum',
			     choice => [qw/xorg xfree98/] ,
			     default => 'xorg',
			    },

      "XkbModel"  => {
		      type => 'leaf',
		      value_type  => 'enum',
		      choice => [qw/pc104 pc105 pc98/] ,
		      default => 'pc105',
		     },

      "XkbLayout" => {
		      type => 'leaf',
		      value_type  => 'enum',
		      choice => [qw!us nec/jp!] ,
		      default => 'us',
		     },

      "XkbVariant" => {
		       type => 'leaf',
		       value_type  => 'enum',
		       choice => [qw!!] ,
		      },
      # needs to be refined ...
      "XkbOptions" => {
		       type => 'leaf',
		       value_type  => 'string',
		      }, 
     ],


  status => [ 'XkbDisable' => 'deprecated' ] ,

  'description' 
  => [
      "Protocol" => "Specify the keyboard protocol. Not all protocols are supported on all platforms.",

      "AutoRepeat" => "sets the auto repeat behaviour for the keyboard. This is not implemented on all platforms.",

      "XLeds" => "makes the keyboard LEDs specified available for client  use instead of their traditional function (Scroll Lock, Caps Lock and Num Lock). The numbers are in the range 1 to 3.",

      "XkbRules" => "specifies which XKB rules file to use for interpreting the XkbModel, XkbLayout,  XkbVariant,  and  XkbOptions settings.",

      "XkbModel" => "specifies the XKB keyboard model name.",

      "XkbLayout" => "specifies the XKB keyboard layout name. This is usually the country or language type of the keyboard.",

      "XkbVariant" => "specifies the XKB keyboard variant components. These can be used to enhance the keyboard layout details.",

      "XkbOptions" => "specifies the XKB keyboard option components. These can be used to enhance the keyboard behaviour.",

     ],
 ]
];
