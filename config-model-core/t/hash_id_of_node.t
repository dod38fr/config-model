# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 17 ;
use Test::Memory::Cycle;
use Config::Model ;
use Data::Dumper ;
use Log::Log4perl qw(:easy :levels) ;

use strict;

my $arg = shift || '';
my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

Log::Log4perl->easy_init($log ? $TRACE: $WARN);

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"Compilation done");

my @element = ( 
	       # Value constructor args are passed in their specific array ref
	       cargo => { type => 'node', config_class_name => 'Slave' } ,
	      ) ;

# minimal set up to get things working
my $model = Config::Model->new() ;
$model ->create_config_class 
  (
   name => "Master",
   element 
   => [ 
       'plain_hash'
       => { type => 'hash',
	    # hash_class constructor args are all keys of this hash
	    # except type and class
	    hash_class => 'Config::Model::HashId', # default
	    index_type  => 'integer',

	    @element
	  },
        'bounded_hash'
       => { type => 'hash',
	    # hash_class constructor args are all keys of this hash
	    # except type and class
	    hash_class => 'Config::Model::HashId', # default
	    index_type  => 'integer',

	    # hash boundaries
	    min => 1, max => 123, max_nb => 2 ,
	    @element
	  },
       'hash_with_default_and_init'
       => { type => 'hash',
	    index_type  => 'string',
	    default_with_init => { 'def_1' => 'X=Av Y=Bv'  ,
			 'def_2' => 'Y=Av Z=Cv' } ,
	    @element
	  },
      ],
   );

$model -> create_config_class 
  (
   name => "Slave",
   element 
   =>  [
	[qw/X Y Z/] => {
			type => 'leaf',
			value_type => 'enum',
			choice     => [qw/Av Bv Cv/]
		       },
       ]
  );

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $b = $root->fetch_element('bounded_hash') ;
ok($b,"bounded hash created") ;

is($b->name,'Master bounded_hash id',"check hash id name");

my $b1 = $b->fetch_with_id(1) ;
isa_ok($b1,'Config::Model::Node',"fetched element id 1") ;

is($b1->config_class_name,'Slave', 'check config_class_name') ;

my $h_with_def = $root->fetch_element('hash_with_default_and_init') ;
my $res = [$h_with_def->get_all_indexes] ;

#print Dumper( $res ) ;

is_deeply($res , [qw/def_1 def_2/], 'check default items') ;

#print $root->dump_tree ;
is ($root->dump_tree ,
   'bounded_hash:1 -
hash_with_default_and_init:def_1
  X=Av
  Y=Bv -
hash_with_default_and_init:def_2
  Y=Av
  Z=Cv - -
', "check default items with children setup") ;

is ($h_with_def->fetch_with_id('def_1')->index_value, 'def_1',
   'check index_value prior to move') ;

$h_with_def->move('def_1', 'moved_1') ;

is ($h_with_def->fetch_with_id('moved_1')->index_value, 'moved_1',
   'check index_value after move') ;

$res = [$h_with_def->get_all_indexes] ;
is_deeply($res , [qw/def_2 moved_1/], 'check moved items keys') ;

#print $root->dump_tree ;
is ($root->dump_tree ,
   'bounded_hash:1 -
hash_with_default_and_init:def_2
  Y=Av
  Z=Cv -
hash_with_default_and_init:moved_1
  X=Av
  Y=Bv - -
', "check moved items with children setup") ;

$root->load("plain_hash:2 X=Av Y=Av Z=Cv") ;
my $ph = $root->fetch_element('plain_hash') ;
ok($ph->copy(2,3),"node copy in hash") ;
is($ph->fetch_with_id(2)->dump_tree, 
   $ph->fetch_with_id(3)->dump_tree, "compare copied values") ;

ok($ph->move(2,4),"node move in hash") ;
is($ph->fetch_with_id(4)->dump_tree, 
   $ph->fetch_with_id(3)->dump_tree, "compare copied then moved values") ;

is_deeply([$ph->get_all_indexes],[3,4],"compare indexes after move") ;
memory_cycle_ok($model);
