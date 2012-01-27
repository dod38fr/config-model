# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 13;
use Test::Differences ;
use Test::Memory::Cycle;
use Config::Model;
use Log::Log4perl qw(:easy) ;

use warnings;

use strict;

my $arg = shift ;
$arg = '' unless defined $arg ;

my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($log ? $WARN: $ERROR);
}

my $model = Config::Model -> new (legacy => 'ignore',) ;

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file => 't/big_model.pm',
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata" '
 .'hash_a:X2=x hash_a:Y2=xy  hash_b:X3=xy my_check_list=X2,X3 '
 .'olist:0 DX=Dv';
ok( $root->load( step => $step, experience => 'advanced' ),
  "set up data in tree with '$step'");

my @tests = ( 
    [ qw/value toto a_string/ ],
    [ qw/value tot a_string/ ],
    [ qw/key ab std_id:ab/ ],
    [ qw/value xy hash_a:Y2 hash_b:X3/ ],
    [ qw/description zorro/,'slave_y sub_slave sub_slave Z','slave_y warp2 sub_slave Z'],
    [ qw/value Bv/,'std_id:ab X'],
    [ qw/value B/,'std_id:ab X'],
    [ qw/value Dv/,'std_id:ab DX','std_id:bc DX','olist:0 DX'],
    [ qw/value X3/,'my_check_list'],
);

foreach my $ref (@tests) {
    my ($type, $string, @expected) = @$ref ;
    my $searcher = $root->tree_searcher(type => $type );
    my @res = $searcher->search($string);
    eq_or_diff(\@res,\@expected,"searched for $type $string");
    print "\treturned '",join("', '",@res),"'\n" if $trace ;
}
memory_cycle_ok($model);
