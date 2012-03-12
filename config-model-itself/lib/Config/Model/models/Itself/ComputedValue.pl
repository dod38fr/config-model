[
  [
   name => "Itself::ComputedValue",
   include => "Itself::MigratedValue" ,

   'element' 
   => [

       'allow_override' 
       => { type => 'leaf',

	    value_type => 'boolean',
	    compute => {
                formula => '$upstream_knowns',
                variables => {
                    upstream_knowns => '- use_as_upstream_default',
                },
                use_as_upstream_default => 1,
            },

	    level => 'normal',
	    description => "Allow user to override computed value",
	 },

       'use_as_upstream_default' 
       => { type => 'leaf',

	    value_type => 'boolean',
	    upstream_default   => 0,
	    level => 'normal',
	    description => "Indicate that the computed value is known by the "
                ."application and does not need to be written in the configuration file. Implies allow_override."
	 },

      ],

  ],

];
