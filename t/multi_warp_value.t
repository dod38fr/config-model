# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 65;
use Test::Memory::Cycle;
use Config::Model ;
use Storable qw/dclone/ ;

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"Compilation done");

my @m1 = qw/A1 B1/;
my @m2 = qw/A2 B2 C2/;
my @m3 = qw/A3 B3/;
my @rules;

foreach my $c1 (@m1) {
    foreach my $c2 (@m2) {
        foreach my $c3 (@m3) {
            push @rules, [ $c1, $c2, $c3 ], { default => "m$c1$c2$c3" };
        }
    }
}
#use Data::Dumper; print Dumper \@rules ;

# minimal set up to get things working
my $model = Config::Model->new(legacy => 'ignore',) ;
my $model_data = 
  {
   name => 'Master',
   'element'
   => [
       macro1 => { type => 'leaf',
		   value_type => 'enum',
		   choice     => \@m1
		 },
       macro2 => { type => 'leaf',
		   value_type => 'enum',
		   choice     => \@m2
		 },
       macro3 => { type => 'leaf',
		   value_type => 'enum',
		   choice     => \@m3
		 },
       m1 => { type => 'leaf',
	       value_type => 'string',
	       'warp'
	       => {
		   follow => [ '- macro1', ' - macro2', '- macro3' ],
		   rules => \@rules 
		  }
	     },
       'm2'
       => { type => 'leaf',
	    value_type => 'string',
	    default    => 'unsatisfied',
	    'warp'
	    => {
		follow => [ '- macro1', ' - macro2', '- macro3' ],
		'rules'
		=>  [
		     [ 'A1', 'A2', 'A3' ] => { default => '3xA' },
		     [ 'B1', [ 'B2', 'C2' ], 'B3' ] => { default => '3x[BC]' },
		    ]
	       },
	  },
       'm3'
       => { type => 'leaf',
	    value_type => 'string',
	    default    => 'unsatisfied',
	    'warp'
	    => {
		follow => '- macro2', 
		'rules'
		=>  [
		     ['B2', 'A2' ] => { default => 'A2 B2 rule' },
		     'C2'          => { default => 'C2 rule'    },
		    ]
	       },
	  },
       'm4'
       => { type => 'leaf',
	    value_type => 'string',
	    default    => 'unsatisfied',
	    'warp'
	    => {
		follow => { m1 => '- macro1', 
			    m2 => ' - macro2',
			    m3 => '- macro3' },
		'rules'
		=>  [
		     '$m1 eq "A1" and $m2 eq "A2" and $m3 eq "A3"'
		     => { default => '3xA' },
		     '($m1 eq "B1") and ($m2 eq "B2" or $m2 eq "C2") and ($m3 eq "B3")'
		     => { default => '3x[BC]' },
		    ]
	       },
	  },
      ]
  };

my $copy = dclone $model_data ;

$model ->create_config_class (%$copy) ;

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

use Config::Model::Warper ;

is_deeply( [ Config::Model::Warper::_dclone_key('foo') ],
    ['foo'], "Test _dclone_key (single key)" );



#use Devel::TraceCalls;
#trace_calls {Class => "Config::Model::Value",};
#trace_calls {Class => "Config::Model::WarpedThing",};

foreach my $c1 (@m1) {
    ok( $root->load("macro1=$c1"), "Setting Root macro1 to $c1" );
    foreach my $c2 (@m2) {
        ok( $root->load("macro2=$c2"), "Setting Root macro2 to $c2" );
        foreach my $c3 (@m3) {
            ok( $root->load("macro3=$c3"), "Setting Root macro3 to $c3" );

	    my $vm1 = $root->grab_value('m1') ;
            is( $vm1 , "m$c1$c2$c3", "Reading Root slot m1: $vm1" );

            my $index  = "$c1$c2$c3";
            my $m2_val =
                  $index eq 'A1A2A3' ? '3xA'
                : $index =~ /B1[BC]2B3/ ? '3x[BC]'
                : 'unsatisfied';
            is( $root->grab_value('m2'), $m2_val, "Reading Root slot m2" );
            is( $root->grab_value('m4'), $m2_val, "Reading Root slot m4" );
        }
    }
}

my @test = ( ["macro2=A2" ,"A2 B2 rule" ],
	     ["macro2=C2" ,"C2 rule" ],
	     ["macro2=B2" ,"A2 B2 rule" ],
	   ) ;

foreach my $u_test (@test) {
    my ($load,$exp) = @$u_test ;
    $root->load($load) ;
    is($root->grab_value('m3'),$exp,"test m3 with $load") ;
}


# check that model_data was not modified
is_deeply($copy, $model_data, "check that copy was not modified") ;

delete $model_data->{name} ; # not part of saved raw_model

is_deeply($model->get_raw_model('Master'), $model_data, 
	  "check that copy in model object was not modified") ;
memory_cycle_ok($model);
