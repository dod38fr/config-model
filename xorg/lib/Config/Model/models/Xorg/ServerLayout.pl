# $Author: ddumont $
# $Date: 2007-10-23 16:18:25 $
# $Revision: 1.3 $

#    Copyright (c) 2005,2006,2008 Dominique Dumont.
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

# Model for ServerLayout section of xorg.conf

[
 [
  'name' => 'Xorg::ServerLayout',

  'element'
  => [
      'Screen' 
      => { type => 'list',
	   cargo_type => 'node',
	   config_class_name => 'Xorg::ServerLayout::Screen',
	   auto_create => 1 , # always one screen at minimum
	 }  ,
      'InputDevice' 
      => { type => 'hash',
	   index_type => 'string',
	   allow_from => '! InputDevice',
	   cargo_type => 'node',
	   default => ['kbd','mouse'],
	   config_class_name => 'Xorg::ServerLayout::InputDevice',
	 }  ,
      # CorePointer and CoreKeyboard option from ServerLayout are
      # stored in Xorg root conf (See Xorg.pl)
     ],
  'description'
  => [

      'Screen' => 'One of these entries must be given for each screen
              being used in a session.  The screen-id field is
              mandatory, and specifies the Screen section being
              referenced. ',

      'InputDevice' => 'One of these entries should be given for each
      input device being used in a session.  Normally at least two are
      required, one each for the core pointer and keyboard devices.'


     ],
 ],

 [
  name => 'Xorg::ServerLayout::Screen',
  'element' 
  => [
      screen_id => { type => 'leaf',
		     value_type => 'reference' ,
		     refer_to => '! Screen',
		   },
      position => { type => 'node',
		    config_class_name => 'Xorg::ServerLayout::ScreenPosition',
		  }
     ],
 ],

 [
  name => 'Xorg::ServerLayout::ScreenPosition',
  'element' 
  => [
      'relative_screen_location'
      => { type => 'leaf',
	   value_type => 'enum',
	   choice => [qw/Absolute RightOf LeftOf Above Below Relative/]
	 },
      'screen_id'
      => { type => 'leaf',
	   refer_to => '! Screen', 
	   level => 'hidden',
	   value_type => 'reference',
	   'warp'
	   => { follow => '- relative_screen_location',
		'rules' => [ 
			    [qw/RightOf LeftOf Above Below Relative/] 
			    => { level => 'normal', mandatory => 1 }
			   ]
	      }
	 },
      ['x','y'] 
      => { type => 'leaf',
	   value_type => 'integer',
	   level => 'hidden',
	   'warp'
	   => { follow => '- relative_screen_location',
		'rules' => [ 
			    [qw/Absolute Relative/] 
			    => {  level => 'normal', mandatory => 1 }
			   ]
	      }
	 },
     ],
 ],
 [
  name => 'Xorg::ServerLayout::InputDevice',
  'element' 
  => [
      'SendCoreEvents' => { type => 'leaf', value_type => 'boolean', }
     ],
  class_description => 'Specifies InputDevice options',
 ],
] ;
