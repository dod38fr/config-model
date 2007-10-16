# -*- cperl -*-
# $Author: ddumont $
# $Date: 2007-10-16 11:15:38 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $


# this file is used by test script

[

  [
   name => 'X_base_class2',
   element => [
	       X => { type => 'leaf',
		      value_type => 'enum',
		      choice     => [qw/Av Bv Cv/]
		    },
	      ],
   class_description => 'rather dummy class to check include',
  ],

  [
   name => 'X_base_class',
   include => 'X_base_class2',
  ],

] ;

# do not put 1; at the end or Model-> load will not work
