# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-05-17 12:03:39 $
# $Name: not supported by cvs2svn $
# $Revision: 1.7 $

# this file is used by test script

$model->create_config_class 
  (
   name => 'SubSlave2',
   element => [
	       [qw/aa2 ab2 ac2 ad2 Z/] =>
	       { type => 'leaf', value_type => 'string' }
	      ]
  );

$model->create_config_class 
  (
   name => 'SubSlave',
   element => [
	       [qw/aa ab ac ad/] => 
	       { type => 'leaf', value_type => 'string' },
	       sub_slave => { type => 'node' ,
			      config_class_name => 'SubSlave2',
			    }
	      ]
  );

# rather dummy class to check inheritance
$model->create_config_class
  (
   name => 'X_base_class2',
   element => [
	       X => { type => 'leaf',
		      value_type => 'enum',
		      choice     => [qw/Av Bv Cv/]
		    },
	      ],
  ) ;

$model->create_config_class
  (
   name => 'X_base_class',
   inherit => 'X_base_class2',
  ) ;


$model->create_config_class 
  (
   name => 'SlaveZ',
   element => [
	       [qw/Z/] => { type => 'leaf',
			      value_type => 'enum',
			      choice     => [qw/Av Bv Cv/]
			    },
	       [qw/DX/] => { type => 'leaf',
			     value_type => 'enum',
			     default    => 'Dv',
			     choice     => [qw/Av Bv Cv Dv/]
			   },
	      ],
   inherit => 'X_base_class',
  );

$model->create_config_class 
  (
   name => 'SlaveY',
   element => [
	       std_id => {
			  type => 'hash',
			  index_type  => 'string',
			  collected_type => 'node',
			  config_class_name => 'SlaveZ' ,
			 },
	       sub_slave => { type => 'node' ,
			      config_class_name => 'SubSlave',
			    },
	       Y => { type => 'leaf',
		      value_type => 'enum',
		      choice     => [qw/Av Bv Cv/]
		    },
	      ],
   inherit => [ 'X_base_class', 'element' ],
  );


$model->create_config_class 
  (
   name => 'Master',
   permission => [ [qw/tree_macro warp/] => 'advanced'] ,
   class_description => "Master description",
   level      => [ [qw/hash_a tree_macro/] => 'important' ],
   element => [
	       std_id => { type => 'hash',
			   index_type  => 'string',
			   collected_type => 'node',
			   config_class_name => 'SlaveZ' ,
			 },
	       [qw/lista listb/] => { type => 'list',
				      collected_type => 'leaf',
				      element_args => {value_type => 'string'},
				    },
	       hash_a => { type => 'hash',
			  index_type => 'string',
			  collected_type => 'leaf',
			  element_args => {value_type => 'string'},
			},
	       olist => { type => 'list',
			  collected_type => 'node',
			  config_class_name => 'SlaveZ' ,
			},
	       tree_macro => { type => 'leaf',
			       value_type => 'enum',
			       choice     => [qw/XY XZ mXY/]
			     },
	       warp => {
			type => 'warped_node',
			follow  => '! tree_macro',
			config_class_name   => 'SlaveY', 
			morph => 1 ,
			rules => [
				  #XY => { config_class_name => 'SlaveY'},
				  mXY => { config_class_name => 'SlaveY'},
				  XZ  => { config_class_name => 'SlaveZ' }
				 ]
		       },
	       string_with_def => { type => 'leaf',
				    value_type => 'string',
				    default    => 'yada yada'
				  },
	       a_string => { type => 'leaf',
			     mandatory => 1 ,
			     value_type => 'string'
			   },
	       int_v => { type => 'leaf',
			  value_type => 'integer',
			  default    => '10',
			  min        => 5,
			  max        => 15
			}
	      ]
  );

1;
