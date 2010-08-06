# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Config::Model ;
use Data::Dumper ;

BEGIN { plan tests => 23; }

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"Compilation done");

my @rules = (
    F => { choice => [qw/A B C F F2/], default => 'F' },
    G => { choice => [qw/A B C G G2/], default => 'G' }
);

my @args = (
    value_type => 'enum',
    mandatory  => 1,
    choice     => [qw/A B C/]
);

my $model = Config::Model->new(legacy => 'ignore',) ;
$model ->create_config_class 
  (
   name => "Master",
   element 
   => [
       enum => {type => 'leaf',
                class => 'Config::Model::Value',
                value_type => 'enum',
                choice =>[qw/F G H/], 
                default => undef
               },
       wrong_syntax_rule => {type => 'leaf',
                             class => 'Config::Model::Value',
                             warp => { follow => '- enum', 
                                      rules  => [ F => [ default => 'F' ]] },
                             @args
                            },
       warped_object => { type => 'leaf',
                          class =>'Config::Model::Value', 
                          @args, 
                          warp => { follow => '- enum' , 
                                    rules  => \@rules  }
                        },
       recursive_warped_object 
       => { type => 'leaf',
            class => 'Config::Model::Value', @args, 
            warp => { follow => '- warped_object' , rules  => \@rules }
          },
       [qw/w2 w3/] => { type => 'leaf',
                        class => 'Config::Model::Value', 
                        @args, 
                        warp =>  { follow => '- enum', rules  => \@rules },
                      },
      ] , # dummy class
  ) ;

# check model content
my $canonical_model = $model->get_element_model('Master','warped_object') ;
is_deeply($canonical_model->{warp},
   {
   'follow' => { 'f1' => '- enum' }, 
   'rules' => [ '$f1 eq \'F\'', { 'default' => 'F', 
                                  'choice' => [ 'A', 'B', 'C', 'F', 'F2' ] }, 
                '$f1 eq \'G\'', { 'default' => 'G', 
                                  'choice' => [ 'A', 'B', 'C', 'G', 'G2' ] } 
              ] 
   }, 
   "check munged warp arguments"
   );

my $inst = $model->instance (root_class_name => 'Master', 
                             instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my ( $w1, $w2, $w3, $bad_w, $rec_wo , $t);

eval {$bad_w = $root->fetch_element('wrong_syntax_rule') ;};
ok($@,"set up warped object with wrong rules syntax" ) ;
print "normal error:\n", $@, "\n" if $trace;

eval { $t = $bad_w->fetch ; } ;
ok( $@,"wrong rules semantic warped object blows up" );
print "normal error:\n", $@, "\n" if $trace;

ok( $w1 = $root->fetch_element('warped_object'), 
    "set up warped object");

eval { my $str = $w1->fetch ; } ;
ok($@, "try to read warped object while warp master is undef"  );
print "normal error:\n", $@, "\n" if $trace;

my $warp_master = $root->fetch_element('enum') ;
is( $warp_master->store('F'), 'F', 
    "store F in warp master" );
is( $w1->fetch, 'F', "read warped object default value" );

is( $w1 -> store ('F2'), 'F2', "store F2 in  warped object");
is( $w1->fetch, 'F2',"and read" );


ok($rec_wo=$root->fetch_element('recursive_warped_object'), 
   "set up recursive_warped_object");

eval { my $str = $rec_wo->fetch ; } ;
ok($@, "try to read recursive warped object while its warp master is F2"  );
print "normal error:\n", $@, "\n" if $trace;

eval { $t = $rec_wo->fetch ;};
ok( $@,"recursive_warped_object blows up" );
print "normal error:\n", $@, "\n" if $trace;

is( $w1 -> store ('F'), 'F', "store F in warped object");
is($rec_wo->fetch , 'F',
   "read recursive_warped_object: default value was set by warp master");

$warp_master->store('G') ;
is($w1->fetch, 'G',
   "warp 'enum' so that F2 value is clobbered (outside new choice)" );


$w1->store('A') ;
$warp_master->store('F') ;
is($w1->fetch, 'A',
   "set value valid for both warp, warp w1 to G and test that the value is still ok");

$w2 = $root->fetch_element('w2');
$w3 = $root->fetch_element('w3');

is($w2->fetch, 'F',
   "test unset value for w2 after setting warp master");
is($w3->fetch, 'F',
   "idem for w3");

$warp_master->store('G') ;
is($w1->fetch, 'A',
   "set warp master to G and test unset value for w1 ... 2 and w3");
is($w2->fetch, 'G', "... and w2 ...");
is($w3->fetch, 'G', "... and w3");

