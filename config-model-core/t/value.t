# -*- cperl -*-
# $Author: ddumont $
# $Date: 2007-10-19 11:43:42 $
# $Name: not supported by cvs2svn $
# $Revision: 1.5 $
use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 78 ;
use Config::Model ;
use Config::Model::Value;

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"Compilation done");

# minimal set up to get things working
my $model = Config::Model->new() ;
$model ->create_config_class 
  (
   name => "Master",
   element => [ crooked => { type => 'leaf',
			    class => 'Config::Model::Value',
			  },
		scalar => { type => 'leaf',
			    class => 'Config::Model::Value',
			    value_type => 'integer',
			    min        => 1,
			    max        => 4,
			  },
		bounded_number => {type => 'leaf',
				   class => 'Config::Model::Value',
				   value_type => 'number',
				   min        => 1,
				   max        => 4,
				  },
		mandatory_string => {type => 'leaf',
				     class => 'Config::Model::Value',
				     value_type => 'string',
				     mandatory  => 1,
				    },
		mandatory_boolean => {type => 'leaf',
				      class => 'Config::Model::Value',
				      value_type => 'boolean',
				      mandatory  => 1,
				     },
		crooked_enum => {type => 'leaf',
				 class => 'Config::Model::Value',
				 value_type => 'enum',
				 default    => 'foo',
				 choice     => [qw/A B C/]},
		enum => {type => 'leaf',
			 class => 'Config::Model::Value',
			 value_type => 'enum',
			 default    => 'A',
			 choice     => [qw/A B C/]},
		enum_integer => {type => 'leaf',
				 class => 'Config::Model::Value',
				 value_type => 'enum_integer',
				 choice  => 'none',
				 default => '0',
				 min     => -4,
				 max     => 4
				},
		enum_with_help => {type => 'leaf',
				   class => 'Config::Model::Value',
				   value_type => 'enum',
				   choice     => [qw/a b c/],
				   help       => { a => 'a help' }
				   },
		uc_convert => { type => 'leaf',
				class => 'Config::Model::Value',
				value_type => 'string',
				convert    => 'uc',
			      },
		lc_convert => { type => 'leaf',
				class => 'Config::Model::Value',
				value_type => 'string',
				convert    => 'lc',
			      },
		built_in_default => { type => 'leaf',
				      value_type => 'string',
				      built_in    => 'bi_def',
				    },
		a_uniline  => { type => 'leaf',
				value_type => 'uniline',
				built_in    => 'bi_def',
			      },
	      ] , # dummy class
  ) ;

my $inst = $model->instance (root_class_name => 'Master', 
				 instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $result ;

eval {$root->fetch_element('crooked') ; } ;
ok( $@,"test create expected failure");
print "normal error:\n", $@, "\n" if $trace;

my $i = $root->fetch_element('scalar') ;
ok($i,"test create bounded integer") ;

ok( $i->store( 1),"store test" );
is( $i->fetch, 1, "fetch test" );

eval { $i->store(  5); } ;
ok( $@ ,"bounded integer: max error" );
print "normal error:\n", $@, "\n" if $trace;

eval { $i->store( 'toto'); } ;
ok( $@ , "bounded integer: string error");
print "normal error:\n", $@, "\n" if $trace;

eval { $i->store( 1.5 ); } ;
ok($@ , "bounded integer: number error");
print "normal error:\n", $@, "\n" if $trace;


my $nb = $root->fetch_element('bounded_number');
ok($nb,"created ".$nb->name) ;

ok($nb->store(1)  ,"assign 1") ;
ok($nb->store(1.5),"assign 1.5") ;

eval { $i->store( 'toto' ); } ;
ok($@ , "bounded integer: string error");
print "normal error:\n", $@, "\n" if $trace;

$nb->store(undef);
ok( defined $nb->fetch() ? 0: 1  ,"store undef") ;


my $ms = $root->fetch_element('mandatory_string') ;
ok($ms,"created mandatory_string") ;

eval { my $v = $ms->fetch; } ;
ok( $@, "mandatory string: undef error") ;
print "normal error:\n", $@, "\n" if $trace;

ok( $ms->store('toto'),"mandatory_string: store" );
is($ms->fetch,'toto'  ,"and read");


my $mb = $root->fetch_element('mandatory_boolean') ;
ok($mb,"created mandatory_boolean") ;

eval { my $v = $mb->fetch; } ;
ok( $@, "mandatory bounded: undef error") ;
print "normal error:\n", $@, "\n" if $trace;

eval { $mb->store('toto'); } ;
ok( $@, "mandatory bounded: store string error" );
print "normal error:\n", $@, "\n" if $trace;

eval { $mb->store(2); } ;
ok( $@, "mandatory bounded: store 2 error" );
print "normal error:\n", $@, "\n" if $trace;

ok( $mb->store(1), "mandatory boolean: set to 1" );

ok($mb->fetch, "mandatory boolean: read");

print "mandatory boolean: set to yes\n" if $trace;
ok( $mb->store('yes'), "mandatory boolean: set to yes" );
is( $mb->fetch, 1, "and read" );

print "mandatory boolean: set to Yes\n" if $trace;
ok( $mb->store('Yes'), "mandatory boolean: set to Yes" );
is( $mb->fetch, 1, "and read" );

print "mandatory boolean: set to no\n" if $trace;
is( $mb->store('no'),  0, "mandatory boolean: set to no" );
is( $mb->fetch, 0, "and read" );

print "mandatory boolean: set to Nope\n" if $trace;
is( $mb->store('Nope'), 0, "mandatory boolean: set to Nope" );
is( $mb->fetch,0, "and read" );

print "mandatory boolean: set to true\n" if $trace;
is( $mb->store('true'), 1,"mandatory boolean: set to true" );
is( $mb->fetch, 1, "and read" );

print "mandatory boolean: set to False\n" if $trace;
is( $mb->store('False'), 0, "mandatory boolean: set to False" );
is( $mb->fetch,0, "and read" );

eval {$root->fetch_element('crooked_enum') ; } ;
ok( $@,"test create expected failure with enum with wrong default");
print "normal error:\n", $@, "\n" if $trace;



my $de = $root->fetch_element('enum') ;
ok($de,"Created enum with correct default") ;

eval { $mb->store('toto'); } ;
ok( $@, "enum: store 'toto' error" );
print "normal error:\n", $@, "\n" if $trace;

is( $de->fetch, 'A' ,"enum with default: read default value" );

print "enum with default: read custom\n" if $trace;
is( $de->fetch_custom ,undef, "enum with default: read custom value" );

is( $de->store('B'),'B',"enum: store B" );
is( $de->fetch_custom, 'B', "enum: read custom value" );
is( $de->fetch_standard, 'A', "enum: read standard value" );


## check model data
is( $de->value_type, 'enum',"enum: check value_type" );

eq_array( $de->choice , [qw/A B C/],"enum: check choice"  );

ok( $de->set( default => 'B' ), "enum: warping default value" );
is( $de->default(), 'B',"enum: check new default value" );

eval { $de->set( default => 'F' ) } ;
ok($@,"enum: warped default value to wrong value") ;
print "normal error:\n", $@, "\n" if $trace;

ok( $de->set( choice => [qw/A B C D/] ),"enum: warping choice" );

ok( $de->set( choice => [qw/A B C D/], default => 'D' ), 
    "enum: warping default value to new choice" );

ok( $de->set( choice => [qw/F G H/], default => undef ),
  "enum: warping choice to completely different set");

is( $de->default(), undef, "enum: check that new default value is undef" );

is( $de->fetch, undef, "enum: check that new current value is undef" );

is( $de->store('H'), 'H', "enum:  set a new value");


###

my $ei= $root->fetch_element('enum_integer') ;
ok($ei, "Creating enum_integer") ;

is( $ei->store(1), 1, "enum_integer: store 1" );
is( $ei->fetch, 1,"and read" );

eval { $ei->store(5);};
ok($@,"enum integer: max error") ;
print "normal error:\n", $@, "\n" if $trace;

eval { $ei->store('toto');};
ok($@,"enum integer: string error") ;
print "normal error:\n", $@, "\n" if $trace;

is( $ei->store('none'), 'none',"enum integer: store'none' value" );
is( $ei->fetch, 'none',"and read" );

is( $ei->store(-3 ), -3 ,"enum integer: negative value");
is( $ei->fetch, -3,"and read" );

eval { $ei->store(-5);};
ok($@,"enum integer: too negative value") ;
print "normal error:\n", $@, "\n" if $trace;

eval { $ei->store('--2');};
ok($@,"enum integer: too many --") ;
print "normal error:\n", $@, "\n" if $trace;


my $uc_c = $root -> fetch_element('uc_convert');
ok($uc_c, "testing convert => uc");
is( $uc_c->store('coucou'), 'COUCOU', "uc_convert: testing store");
is( $uc_c->fetch(),         'COUCOU', "uc_convert: testing read");

my $lc_c = $root -> fetch_element('lc_convert');
ok($lc_c, "testing convert => lc");
is( $lc_c->store('coUcOu'), 'coucou', "lc_convert: testing store");
is( $lc_c->fetch(),         'coucou', "lc_convert: testing read");



print "Testing integrated help\n" if $trace;

my $value_with_help = $root->fetch_element('enum_with_help');
my $full_help = $value_with_help->get_help;

is( $full_help->{a}, 'a help',"full enum help" );
is( $value_with_help->get_help( 'a' ), 'a help',"enum help on one choice") ;
is( $value_with_help->get_help('b'), undef ,"test undef help");


print "Testing built_in default value\n" if $trace ;

my $bi_def = $root->fetch_element('built_in_default');

is( $bi_def->fetch, undef,"built_in actual value" );
is( $bi_def->fetch_standard,'bi_def' ,"built_in actual value" );

###

my $uni = $root->fetch_element('a_uniline') ;
eval { $uni->store("foo\nbar");};
ok($@,"uniline: tried to store a multi line") ;
print "normal error:\n", $@, "\n" if $trace;

$uni->store("foo bar");
is($uni->fetch, "foo bar","tested uniline value") ;
