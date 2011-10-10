
[
  [
   name => "Itself::MigratedValue",

   'element' 
   => [
       'variables',
       => {
	   type => 'hash',
	   index_type => 'string' ,
	   cargo => { type => 'leaf', value_type => 'uniline' } ,
	   description => 'Specify where to find the variables using path notation. For the formula "$a + $b", you need to specify "a => \'- a_path\', b => \'! b_path\' ',
	  },

       'formula' => { type => 'leaf',
		      value_type => 'string',
		      # making formula mandatory makes mandatory setting the
		      # compute parameter for a leaf. That's not a
		      # desired behavior.
		      # mandatory => 1 ,
		      description => 'Specify how the computation is done. This string can a Perl expression for integer value or a template for string values. Variables have the same notation than in Perl. Example "$a + $b" ',
		    },
       'replace'
       => {
	   type => 'hash',
	   index_type => 'string' ,
	   cargo => { type => 'leaf', value_type => 'string' } ,
	   description => 'Sometime, using the value of a tree leaf is not enough and you need to substitute a replacement for any value you can get. This replacement can be done using a hash like notation within the formula using the %replace hash. Example $replace{$who} , where "who => \'- who_elt\' ',
	  },

       'use_eval'
       => { type => 'leaf',
	    value_type => 'boolean',
	    upstream_default   => 0,
	    description => 'Set to 1 if you need to perform more complex operations than substition, like extraction with regular expressions. This will force an eval by Perl when computing the formula. The result of the eval will be used as the computed value.'
	  },
       'undef_is'
       => { type => 'leaf',
	    value_type => 'uniline',
	    description => 'Specify a replacement for undefined variables. This will replace undef'
	    .' values in the formula before migrating values. Use \'\' (2 single quotes) '
	    . 'if you want to specify an empty string',
	  },



      ],

  ],

];
