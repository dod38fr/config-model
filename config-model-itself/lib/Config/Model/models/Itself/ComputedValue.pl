# $Author: ddumont $
# $Date: 2008-02-26 13:36:21 $
# $Name: not supported by cvs2svn $
# $Revision: 1.3 $

#    Copyright (c) 2007 Dominique Dumont.
#
#    This file is part of Config-Model-Itself.
#
#    Config-Model-Itself is free software; you can redistribute it
#    and/or modify it under the terms of the GNU Lesser Public License
#    as published by the Free Software Foundation; either version 2.1
#    of the License, or (at your option) any later version.
#
#    Config-Model-Itself is distributed in the hope that it will be
#    useful, but WITHOUT ANY WARRANTY; without even the implied
#    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#    See the GNU Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model-Itself; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

[
  [
   name => "Itself::ComputedValue",

   'element' 
   => [
       'formula' => { type => 'leaf',
		      value_type => 'string',
		      # making formula mandatory makes mandatory setting the
		      # compute parameter for a leaf. That's not a
		      # desired behavior.
		      # mandatory => 1 ,
		    },
       ['variables','replace']
       => {
	   type => 'hash',
	   cargo_type => 'leaf',
	   index_type => 'string' ,
	   cargo_args => { value_type => 'uniline' } ,
	  },
      ],

   'description'
   => [
       formula => 'Specify how the computation is done. This string can a Perl expression for integer value or a template for string values. Variables have the same notation than in Perl. Example "$a + $b" ',
       variables => 'Specify where to find the variable using path notation. For the formula "$a + $b", you need to specify "a => \'- a_path\', b => \'! b_path\' ',
       replace => 'Sometime, using the value of a tree leaf is not enough and you need to substitute a replacement for any value you can get. This replacement can be done using a hash like notation within the formula using the %replace hash. Example $replace{$who} , where "who => \'- who_elt\' ',
      ] ,

  ],

];
