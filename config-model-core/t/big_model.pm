# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-01-18 17:02:56 $
# $Name: not supported by cvs2svn $
# $Revision: 1.2 $

# this file is used by test script

$model->create_config_class 
  (
   name => 'SubSlave2',
   element => [
	       [qw/aa2 ab2 ac2 ad2/] =>
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
			      class => 'SubSlave2',
			    }
	      ]
  );

$model->create_config_class 
  (
   name => 'SlaveZ',
   element => [
	       [qw/X Z/] => { type => 'leaf',
			      value_type => 'enum',
			      choice     => [qw/Av Bv Cv/]
			    },
	       [qw/DX/] => { type => 'leaf',
			     value_type => 'enum',
			     default    => 'Dv',
			     choice     => [qw/Av Bv Cv Dv/]
			   },
	      ]
  );

$model->create_config_class 
  (
   name => 'SlaveY',
   element => [
	       std_id => {
			  type => 'hash',
			  index_type  => 'string',
			  element_type => 'node',
			  element_args => { config_class_name 
					    => 'SlaveZ' },
			 },
	       sub_slave => { type => 'node' ,
			      class => 'SubSlave',
			    },
	       [qw/X Y/] => { type => 'leaf',
			      value_type => 'enum',
			      choice     => [qw/Av Bv Cv/]
			    },
	      ]
  );


$model->create_config_class 
  (
   name => 'Master',
   permission => [ [qw/tree_macro warp/] => 'advanced'] ,
   class_description => "Master description",
   element => [
	       std_id => { type => 'hash',
			   index_type  => 'string',
			   element_type => 'node',
			   element_args => { config_class_name => 'SlaveZ' },
			 },
	       [qw/lista listb/] => { type => 'list',
				      element_type => 'leaf',
				      element_args => {value_type => 'string'},
				    },
	       hash_a => { type => 'hash',
			  index_type => 'string',
			  element_type => 'leaf',
			  element_args => {value_type => 'string'},
			},
	       olist => { type => 'list',
			  element_type => 'node',
			  element_args => { config_class_name => 'SlaveZ' },
			},
	       tree_macro => { type => 'leaf',
			       value_type => 'enum',
			       choice     => [qw/XY XZ mXY/]
			     },
	       warp => {
			type => 'warped_node',
			warper  => '! tree_macro',
			class   => 'SlaveY', 
			morph => 1 ,
			linkage => {
				    #XY => { class => 'SlaveY'},
				    mXY => { class => 'SlaveY'},
				    XZ  => { class => 'SlaveZ' }
				   }
		       },
	       string_with_def => { type => 'leaf',
				    value_type => 'string',
				    default    => 'yada yada'
				  },
	       a_string => { type => 'leaf',
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
