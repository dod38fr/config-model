# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-02-16 13:09:43 $
# $Name: not supported by cvs2svn $
# $Revision: 1.2 $

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 56 ;
use Config::Model ;

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

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
my $model = Config::Model->new() ;
$model ->create_config_class 
  (
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
      ]
  );

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

use Config::Model::WarpedThing ;

is_deeply( [ Config::Model::WarpedThing::_dclone_key('foo') ],
    ['foo'], "Test _dclone_key (single key)" );


my @expanded_keys = Config::Model::WarpedThing::_expand_key('foo');

#print Dumper \@expanded_keys ;
is_deeply( \@expanded_keys, ['foo'], "Test _expand_key (single key)" );
my $simple_rule = [ 'my', 'rules' ];

my @expected_rules = ( 'foo', $simple_rule );

my @expanded_rules
    = Config::Model::WarpedThing::_expand_rules( 'foo' => $simple_rule );

#print Dumper \@expanded_rules , \@expected_rules;
is_deeply( \@expanded_rules, \@expected_rules,
    "Test _expand_rules ( single keys)" );

my @keys = (qw/foo bar baz/);
is_deeply(
    \@keys,
    Config::Model::WarpedThing::_dclone_key( \@keys ),
    "Test _dclone_key (backward)"
);

@expanded_keys = Config::Model::WarpedThing::_expand_key( \@keys );

#print Dumper \@expanded_keys , \@keys ;
is_deeply( \@expanded_keys, [ \@keys ], "Test _expand_key (backward)" );

@expected_rules = ( \@keys, $simple_rule );

@expanded_rules
    = Config::Model::WarpedThing::_expand_rules( \@keys => $simple_rule );

is_deeply( \@expanded_rules, \@expected_rules,
    "Test _expand_rules (backward)" );

#print Dumper \@expanded_rules , \@expected_rules;

@keys = ( qw/foo bar/, [qw/b1 b2 b3/], 'baz', [qw/c1 c2 c3/] );
is_deeply(
    \@keys,
    Config::Model::WarpedThing::_dclone_key( \@keys ),
    "Test _dclone_key"
);

my @expected_keys = (
    [ 'foo', 'bar', 'b1', 'baz', 'c1' ],
    [ 'foo', 'bar', 'b2', 'baz', 'c1' ],
    [ 'foo', 'bar', 'b3', 'baz', 'c1' ],
    [ 'foo', 'bar', 'b1', 'baz', 'c2' ],
    [ 'foo', 'bar', 'b1', 'baz', 'c3' ],
    [ 'foo', 'bar', 'b2', 'baz', 'c2' ],
    [ 'foo', 'bar', 'b2', 'baz', 'c3' ],
    [ 'foo', 'bar', 'b3', 'baz', 'c2' ],
    [ 'foo', 'bar', 'b3', 'baz', 'c3' ]
);

@expanded_keys = Config::Model::WarpedThing::_expand_key( \@keys );

#print Dumper \@keys,\@expanded_keys , \@expected_keys;
is_deeply( \@expanded_keys, \@expected_keys, "Test _expand_key" );

@expanded_rules
    = Config::Model::WarpedThing::_expand_rules( \@keys => [ 'my', 'rules' ] );

# perl 5.8.7's Test::More seems more strict than 5.8.4 when comnparing
# data (it checks also if ref are identicals...)
my $tmp_array = [ 'my', 'rules' ];
@expected_rules = map { ( $_ => $tmp_array ) } @expected_keys;

#print Dumper \@expanded_rules, \@expected_rules;
is_deeply( \@expanded_rules, \@expected_rules, "Test _expand_rules" );

#print Dumper \@expanded_rules, \@expected_rules ;

#use Devel::TraceCalls;
#trace_calls {Class => "Config::Model::Value",};
#trace_calls {Class => "Config::Model::WarpedThing",};

foreach my $c1 (@m1) {
    ok( $root->load("macro1=$c1"), "Setting Root macro1 to $c1" );
    foreach my $c2 (@m2) {
        ok( $root->load("macro2=$c2"), "Setting Root macro2 to $c2" );
        foreach my $c3 (@m3) {
            ok( $root->load("macro3=$c3"), "Setting Root macro3 to $c3" );

            is( $root->grab_value('m1'), "m$c1$c2$c3", "Reading Root slot m1" );

            my $index  = "$c1$c2$c3";
            my $m2_val =
                  $index eq 'A1A2A3' ? '3xA'
                : $index =~ /B1[BC]2B3/ ? '3x[BC]'
                : 'unsatisfied';
            is( $root->grab_value('m2'), $m2_val, "Reading Root slot m2" );
        }
    }
}

my @array = $root->fetch_element('m1')->get_all_warper_object;
is( @array, 3, "test number of warp roots" );
