# -*- cperl -*-
# $Author: ddumont $
# $Date: 2007-05-04 11:44:59 $
# $Name: not supported by cvs2svn $
# $Revision: 1.8 $

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Config::Model;
use Config::Model::ValueComputer ;

BEGIN { plan tests => 46; }

use strict;

my $trace = shift || '' ;

Config::Model::Exception::Any->Trace(1) if $trace =~ /e/;

ok(1,"Compilation done");

my $model = Config::Model->new() ;
$model ->create_config_class 
  (
   name => "RSlave",
   element 
   => [ 
       recursive_slave 
       => {
	   type => 'hash',
	   index_type => 'string',
	   cargo_type => 'node',
	   config_class_name => 'RSlave' ,
	  },
       big_compute
       => {
	   type => 'hash',
	   index_type => 'string',
	   cargo_type => 'leaf',
	   cargo_args 
	   => {
	       value_type => 'string',
	       compute    => ['macro is $m, my idx: &index, '
			      .'my element &element, '
			      .'upper element &element($up), '
			      .'up idx &index($up)',
			      'm'  => '!  macro',
			      up => '-'
			     ]
	      },
	  },
       big_replace
       => {
	   type => 'leaf',
	   value_type => 'string',
	   compute    => [
			  'trad idx $replace{&index($up)}',
			  up      => '-',
			  replace => {
				      l1 => 'level1',
				      l2 => 'level2'
				     }
			 ]
	  },
       macro_replace
       => {
	   type => 'hash',
	   index_type => 'string',
	   cargo_type => 'leaf',
	   cargo_args 
	   => {
	       value_type => 'string',
	       compute    => [
			      'trad macro is $macro{$m}',
			      'm'     => '!  macro',
			      macro => {
					A => 'macroA',
					B => 'macroB',
					C => 'macroC'
				       }
			     ]
	      },
	  }
      ],
   );

$model -> create_config_class 
  (
   name => "Slave",
   level => [ [qw/Comp W/] => 'hidden' ] ,
   element 
   =>  [
	[qw/X Y Z/] => {
			type => 'leaf',
			value_type => 'enum',
			choice     => [qw/Av Bv Cv/],
			warp       => {
				       follow => '- - macro',
				       rules => { A => { default => 'Av' },
						  B => { default => 'Bv' }
						}
				      }
		       },
	recursive_slave
	=> {
	    type => 'hash',
            index_type => 'string',
	    cargo_type => 'node',
	    config_class_name => 'RSlave',
	   },
	W => {
	      type => 'leaf',
	      warp => {
		       follow => '- - macro',
		       'rules' 
		       => {
			   A => {
				 value_type => 'enum',
				 default    => 'Av',
				 level      => 'normal',
				 permission => 'intermediate',
				 choice     => [qw/Av Bv Cv/]
				},
			   B => {
				 value_type => 'enum',
				 default    => 'Bv',
				 level      => 'normal',
				 permission => 'advanced',
				 choice     => [qw/Av Bv Cv/]
				}
			  }
		      },
	     },
	Comp => {
		 type => 'leaf',
		 value_type => 'string',
		 compute    => [ 'macro is $m', 'm' => '- - macro' ],
		},
       ]
  );

$model -> create_config_class 
  (
   name => "Master",
   element 
   => [
       get_element => {
		    type => 'leaf',
		    value_type => 'enum',
		    choice     => [qw/m_value_element compute_element/]
		    },
       where_is_element => {
			 type => 'leaf',
			 value_type => 'enum',
			 choice     => [qw/get_element/]
			},
       macro => {
		 type => 'leaf',
		 value_type => 'enum',
		 name       => 'macro',
		 choice     => [qw/A B C D/]
		},
       'm_value' => {
		     type => 'leaf',
		     value_type => 'enum',
		     warp       => {
				    follow => '- macro',
				    'rules' 
				    => [
					[qw/A D/] => { choice => [qw/Av Bv/] },
					B => { choice => [qw/Bv Cv/] },
					C => { choice => [qw/Cv/] }
				       ]
				   }
		    },
       'compute' 
       => {
	   type => 'leaf',
	   value_type => 'string',
	   compute    => [ 'macro is $m, my element is &element', 'm' => '!  macro' ]
	  },

       'var_path' 
       => {
	   type => 'leaf',
	   value_type => 'string',
	   mandatory => 1 , # will croak if value cannot be computed
	   compute
	   => [
	       'get_element is $element_table{$s}, indirect value is \'$v\'',
	       's'        => '! $where',
	       where      => '! where_is_element',
	       v          => '! $element_table{$s}',
	       element_table => {qw/m_value_element m_value compute_element compute/}
	      ]
	  },
       [qw/bar foo foo2/ ] => {
			       type => 'node',
			       config_class_name => 'Slave'
			      }
      ]
   );

$::verbose = 1 if $trace =~ /v/;
$::debug   = 1 if $trace =~ /d/ ;

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

is_deeply( [$root->get_element_name(for => 'intermediate')],
	   [qw'get_element where_is_element macro compute var_path bar foo foo2'], 
	   "Elements of Master"
	 );

# query the model instead of the instance
is_deeply( [$model->get_element_name(class => 'Slave',
				     for => 'intermediate')
	   ],
	   [qw'X Y Z recursive_slave'], 
	   "Elements of Slave from the model"
	 );

my $slave = $root-> fetch_element('bar') ;
ok($slave,"Created slave(bar)");

is_deeply( [$slave->get_element_name(for => 'intermediate')],
	   [qw'X Y Z recursive_slave'], 
	   "Elements of Slave from the object"
	 );
my $result ;
eval { $result = $slave->fetch_element('W')->fetch ;} ;
ok($@,"reading slave->W (undef value_type error)") ;
print "normal error: $@" if $trace;

is($slave->fetch_element('X')->fetch , undef,
  "reading slave->X (undef)") ;

is($root->fetch_element('macro')->store('A'), 'A',
   "setting master->macro to A") ;

map {is($slave->fetch_element($_)->fetch , 'Av',
	"reading slave->$_ (Av)") ; } qw/X Y Z/;

is($root->fetch_element('macro')->store('C'), 'C',
   "setting master->macro to C") ;

is($slave->fetch_element('X')->fetch , undef,
  "reading slave->X (undef)") ;

$root->fetch_element('macro')->store('A') ;

is($root->fetch_element('m_value')->store('Av') , 'Av',
   'test m_value with macro=A') ;

$root->fetch_element('macro')->store('D') ;

is($root->fetch_element('m_value')->fetch , 'Av',
   'test m_value with macro=D') ;

$root->fetch_element('macro')->store('A') ;

is_deeply( [$slave->get_element_name(for => 'intermediate')],
	   [qw/X Y Z recursive_slave W/], 
	   "Slave elements from the object (W pops in when macro is set to A)"
	 );
$root->fetch_element('macro')->store('B') ;

is_deeply( [$slave->get_element_name(for => 'intermediate')],
	   [qw/X Y Z recursive_slave/], 
	   "Slave elements from the object (W's out when macro is set to B)"
	 );
is_deeply( [$slave->get_element_name(for => 'advanced')],
	   [qw/X Y Z recursive_slave W/], 
	   "Slave elements from the object for advanced level"
	 );

map {is($slave->fetch_element($_)->fetch , 'Bv',
	"reading slave->$_ (Bv)") ; } qw/X Y Z/;

is($slave->fetch_element('Y')->store('Cv'), 'Cv',
   'Set slave->Y to Cv');


# testing warp in warp out
$root->fetch_element('macro')->store('C') ;
eval {$result = $slave->fetch_element('W')->fetch ;} ;
ok($@,"reading slave->W (undef value_type error)") ;
print "normal error: $@" if $trace;


map {is($slave->fetch_element($_)->fetch , undef,
	"reading slave->$_ (undef)") ; } qw/X Z/;
is($slave->fetch_element('Y')->fetch , 'Cv',
	"reading slave->Y (Cv)") ;

is($slave->fetch_element('Comp')->fetch , 'macro is C',
	"reading slave->Comp") ;

is($root->fetch_element('m_value')->store('Cv'), 'Cv',
   'set m_value to Cv'
  );

my $rslave1  = $slave  ->fetch_element('recursive_slave')->fetch_with_id('l1');
my $rslave2  = $rslave1->fetch_element('recursive_slave')->fetch_with_id('l2') ;
my $big_compute_obj 
             = $rslave2->fetch_element('big_compute')    ->fetch_with_id('b1');

isa_ok($big_compute_obj,'Config::Model::Value',
       'Created new big compute object'
      ) ;

my $txt   = 'macro is $m, my idx: &index, my element &element, ';
my $rules = {
    m   => '! macro',
    up  => '-',
    up2 => '- -',
};

no warnings 'once' ;
my $parser = Parse::RecDescent->new($Config::Model::ValueComputer::compute_grammar) ;
use warnings 'once';

# the 2 next tests are used to check what going on before trying the
# real test below. But beware, the error messages for these 2 tests
# might be misleading.
my $str_r = $parser->pre_compute( $txt, 1, $big_compute_obj, $rules );
is( $$str_r, 'macro is $m, my idx: b1, my element big_compute, ' ,
  "testing pre_compute with & and &index on \$big_compute_obj");

$txt .= 'upper elements &element($up2) &element($up), up idx &index($up2) &index($up)';

$str_r = $parser->pre_compute( $txt, 1, $big_compute_obj, $rules );

is( $$str_r,
          'macro is $m, my idx: b1, my element big_compute, '
        . 'upper elements recursive_slave recursive_slave, up idx l1 l2',
  "testing pre_compute with &element(stuff) and &index(\$stuff)");

my $bc_val  
  = $rslave2->fetch_element('big_compute')->fetch_with_id("test_1")->fetch;

is( $bc_val,
    'macro is C, my idx: test_1, my element big_compute, upper element recursive_slave, up idx l2',
    'reading slave->big_compute(test1)'
);


is( $big_compute_obj->fetch,
    'macro is C, my idx: b1, my element big_compute, upper element recursive_slave, up idx l2',
    'reading slave->big_compute(b1)'
);

is( $rslave1->fetch_element('big_replace')->fetch('br1'),
    'trad idx level1',
    'reading rslave1->big_replace(br1)');

is( $rslave2->fetch_element('big_replace')->fetch('br1'),
    'trad idx level2',
    'reading rslave2->big_replace(br1)');

is( $rslave1->fetch_element('macro_replace')->fetch_with_id('br1')->fetch,
    'trad macro is macroC',
    'reading rslave1->macro_replace(br1)');

is( $rslave2->fetch_element('macro_replace')->fetch_with_id('br1')->fetch,
    'trad macro is macroC',
    'reading rslave2->macro_replace(br1)');

is( $root->fetch_element('compute')->fetch(),
    'macro is C, my element is compute',
    'reading root->compute');

my @masters = $root->fetch_element('macro')->get_depend_slave();
my @names = sort map { $_->name } @masters;
print "macro controls:\n\t", join( "\n\t", @names ), "\n"
    if $trace;

is( scalar @masters, 11,'reading macro slaves' );

is_deeply( \@names ,
	   [
	    'Master compute',
	    'Master m_value',
	    'bar Comp',
	    'bar W',
	    'bar X',
	    'bar Y',
	    'bar Z',
	    'bar recursive_slave:l1 macro_replace:br1',
	    'bar recursive_slave:l1 recursive_slave:l2 big_compute:b1',
	    'bar recursive_slave:l1 recursive_slave:l2 big_compute:test_1',
	    'bar recursive_slave:l1 recursive_slave:l2 macro_replace:br1',
	   ],
	   "check names of values using 'macro' element" );

Config::Model::Exception::Any->Trace(1);

eval { $root->fetch_element('var_path')->fetch; };
like( $@, qr/'! where_is_element' is undef/,
      'reading var_path while where_is_element variable is undef');

# set one variable of the formula
$root->fetch_element('where_is_element')->store('get_element');

eval { $root->fetch_element('var_path')->fetch; };
like( $@, qr/'! where_is_element' is 'get_element'/,
    'reading var_path while where_is_element is defined');
like( $@, qr/Mandatory value is not defined/,
    'reading var_path while get_element variable is undef');

# set the other variable of the formula
$root->fetch_element('get_element')->store('m_value_element');

is($root->fetch_element('var_path')->fetch(),
   'get_element is m_value, indirect value is \'Cv\'',
   "reading var_path through m_value element");

# modify the other variable of the formula
$root->fetch_element('get_element')->store('compute_element');

is($root->fetch_element('var_path')->fetch(),
   'get_element is compute, indirect value is \'macro is C, my element is compute\'',
   "reading var_path through compute element");

