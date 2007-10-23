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

# Model for Monitor section of xorg.conf

[
 [
  'name' => 'Xorg::Screen',

  'element'
  => [
      'Device' => {
		   type => 'leaf',
		   value_type => 'reference' ,
		   refer_to => '! Device', # refer device identifier
		   mandatory => 1,
		  }  ,

      'Monitor' => {
		   type => 'leaf',
		   value_type => 'reference' ,
		   refer_to => '! Monitor', # refer device identifier
		   mandatory => 1,          # better to be mandatory
		  } ,

      'VideoAdaptor' => {
			 type => 'leaf',
			 value_type => 'uniline',
			} ,

      'DefaultDepth' => {
			 type => 'leaf',
			 value_type => 'reference',
			 refer_to => '- Display',
			} ,

      'DefaultFbBpp' => {
			 type => 'leaf',
			 value_type => 'uniline',
			} ,

      'Option' => { 
		   type     => 'node',
		   config_class_name => 'Xorg::Screen::Option' 
		  },
      'Display' => { 
		    type     => 'hash',
		    index_type => 'integer',
		    min => 1, max => 32,
		    cargo_type => 'node',
		    config_class_name => 'Xorg::Screen::Display' 
		   },
     ],
  'description'
  => [

       'Device' => 'specifies the Device section to be used for this
       screen. This is what ties a specific graphics card to a
       screen.',

       'Monitor' => 'specifies which monitor description is to be used
              for this screen. If a Monitor name is not specified, a
              default configuration is used. Currently the default
              configuration may not function as expected on all plat-
              forms.',

       'VideoAdaptor' => 'specifies an optional Xv video adaptor
              description to be used with this screen.',

      'DefaultDepth' => 'specifies which color depth the server should
              use by default.  The -depth command line option can be
              used to override this. If neither is specified, the
              default depth is driver-specific, but in most cases is
              8.',

      'DefaultFbBpp' => 'specifies which framebuffer layout to use by
              default.  The -fbbpp command line option can be used to
              override this.  In most cases the driver will chose the
              best default value for this.  The only case where there
              is even a choice in this value is for depth 24, where
              some hardware supports both a packed 24 bit framebuffer
              layout and a sparse 32 bit framebuffer layout.',

      'Display' => 'Each Screen section may have multiple Display
              subsections. The "active" Display subsection is the
              first that matches the depth and/or fbbpp values being
              used, or failing that, the first that has neither a
              depth or fbbpp value specified. The Display subsections
              are optional. When there isn\'t one that matches the
              depth and/or fbbpp values being used, all the parameters
              that can be specified here fall back to their
              defaults.',

   ],
 ]
] ;
