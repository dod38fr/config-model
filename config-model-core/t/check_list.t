# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Test::Differences ;
use Config::Model;
use Data::Dumper;
use Log::Log4perl qw(:easy :levels) ;

BEGIN { plan tests => 78; }

use strict;

my $arg = shift || '';
my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($log ? $WARN: $ERROR);
}

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok( 1, "Compilation done" );

# minimal set up to get things working
my $model = Config::Model->new();
$model->create_config_class(
    name    => "Master",
    element => [
        [qw/my_hash my_hash2 my_hash3/] => {
            type       => 'hash',
            index_type => 'string',
            cargo      => { type => 'leaf', value_type => 'string' },
        },

        choice_list => {
            type   => 'check_list',
            choice => [ 'A' .. 'Z' ],
            help   => { A => 'A help', E => 'E help' },
        },

        ordered_checklist => {
            type    => 'check_list',
            choice  => [ 'A' .. 'Z' ],
            ordered => 1,
            help    => { A => 'A help', E => 'E help' },
        },

        ordered_checklist_refer_to => {
            type     => 'check_list',
            refer_to => '- ordered_checklist',
            ordered  => 1,
        },

        choice_list_with_default => {
            type         => 'check_list',
            choice       => [ 'A' .. 'Z' ],
            default_list => [ 'A', 'D' ],
            help         => { A => 'A help', E => 'E help' },
        },

        choice_list_with_upstream_default => {
            type                  => 'check_list',
            choice                => [ 'A' .. 'Z' ],
            upstream_default_list => [ 'A', 'D' ],
            help                  => { A => 'A help', E => 'E help' },
        },

        choice_list_with_default_and_upstream_default => {
            type                  => 'check_list',
            choice                => [ 'A' .. 'Z' ],
            default_list          => [ 'A', 'C' ],
            upstream_default_list => [ 'A', 'D' ],
            help                  => { A => 'A help', E => 'E help' },
        },

        macro => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/AD AH AZ/],
        },

        'warped_choice_list' => {
            type  => 'check_list',
            level => 'hidden',
            warp  => {
                follow => '- macro',
                rules  => {
                    AD => {
                        choice       => [ 'A' .. 'D' ],
                        level        => 'normal',
                        default_list => [ 'A', 'B' ]
                    },
                    AH => {
                        choice => [ 'A' .. 'H' ],
                        level  => 'normal',
                    },
                }
            }
        },

        refer_to_list => {
            type     => 'check_list',
            refer_to => '- my_hash'
        },

        warped_refer_to_list => {
            type     => 'check_list',
            refer_to => '- warped_choice_list',
            level    => 'hidden',
            warp     => {
                follow => '- macro',
                rules  => {
                    AD => {
                        choice => [ 'A' .. 'D' ],
                        level  => 'normal',
                    },
                },
            },
        },

        refer_to_2_list => {
            type     => 'check_list',
            refer_to => '- my_hash + - my_hash2   + - my_hash3'
        },

        refer_to_check_list_and_choice => {
            type              => 'check_list',
            computed_refer_to => {
                formula   => '- refer_to_2_list + - $var',
                variables => { var => '- indirection ' },
            },
            choice => [qw/A1 A2 A3/],
        },

        indirection => { type => 'leaf', value_type => 'string' },

        dumb_list => {
            type  => 'list',
            cargo => { type => 'leaf', value_type => 'string' }
        },
        refer_to_dumb_list => {
            type     => 'check_list',
            refer_to => '- dumb_list + - my_hash',
        }
    ]
);

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

my $cl = $root->fetch_element('choice_list');

# check get_choice
is_deeply( [ $cl->get_choice ], [ 'A' .. 'Z' ], "check_get_choice" );

ok( 1, "test get_checked_list for empty check_list" );
my @got = $cl->get_checked_list;
is( scalar @got, 0, "test nb of elt in check_list " );
is_deeply( \@got, [], "test get_checked_list after set_checked_list" );

my %expect;
map { $expect{$_} = 0 } ( 'A' .. 'Z' );

my $hr = $cl->get_checked_list_as_hash;
is_deeply( $hr, \%expect, "test get_checked_list_as_hash for empty checklist" );

# check help
is( $cl->get_help('A'), 'A help', "test help" );

# test with the polymorphic 'set' method
$cl->set( '', 'A,Z,Y,B' );
ok( 1, "test set method" );
@got = $cl->get_checked_list;
is( scalar @got, 4, "test nb of elt in check_list after set" );
is_deeply( \@got, [qw/A B Y Z/], "test get_checked_list after set" );

my @set = sort qw/A C Z V Y/;
$cl->set_checked_list(@set);
ok( 1, "test set_checked_list" );
@got = $cl->get_checked_list;
is( scalar @got, 5, "test nb of elt in check_list after set_checked_list" );
is_deeply( \@got, \@set, "test get_checked_list after set_checked_list" );

# test global get and set as hash
$hr = $cl->get_checked_list_as_hash;
map { $expect{$_} = 1 } @set;
is_deeply( $hr, \%expect, "test get_checked_list_as_hash" );

$expect{V} = 0;
$expect{W} = 1;
$cl->set_checked_list_as_hash(%expect);
ok( 1, "test set_checked_list_as_hash" );
@got = sort $cl->get_checked_list;
is_deeply(
    \@got,
    [ sort qw/A C Z W Y/ ],
    "test get_checked_list after set_checked_list_as_hash"
);

$cl->clear;

# test global get and set
@got = $cl->get_checked_list;
is( scalar @got, 0, "test nb of elt in check_list after clear" );

eval { $cl->check('a'); };
ok( $@, "check 'a': which is an error" );
print "normal error:\n", $@, "\n" if $trace;

# test layered choice_list
$inst->layered_start ;
my @l_set = qw/B M W/ ;
$cl->set_checked_list(@l_set);
$inst->layered_stop ;

eq_or_diff( [ $cl->get_checked_list(mode => 'layered') ], \@l_set,"check layered content");
eq_or_diff( [ $cl->get_checked_list(mode => 'standard') ], \@l_set,"check standard content");
eq_or_diff( [ $cl->get_checked_list() ], [],"check content");

# now test with a refer_to parameter

$root->load("my_hash:X=x my_hash:Y=y");
ok( 1, "load my_hash:X=x my_hash:Y=y worked correctly" );

my $rflist = $root->fetch_element('refer_to_list');
ok( $rflist, "created refer_to_list" );

is_deeply( [ $rflist->get_choice ], [qw/X Y/], 'check simple refer choices' );

$root->load("my_hash:Z=z");
ok( 1, "load my_hash:Z=z worked correctly" );

is_deeply( [ $rflist->get_choice ],
    [qw/X Y Z/], 'check simple refer choices after 2nd load' );

# load hashes that are used by reference check list
$root->load("my_hash2:X2=x my_hash2:X=xy");

my $rf2list = $root->fetch_element('refer_to_2_list');
ok( $rf2list, "created refer_to_2_list" );
is_deeply( [ sort $rf2list->get_choice ],
    [qw/X X2 Y Z/], 'check refer_to_2_list choices' );

$root->load("my_hash3:Y2=y");
is_deeply( [ sort $rf2list->get_choice ],
    [qw/X X2 Y Y2 Z/], 'check refer_to_2_list choices' );

my $rtclac = $root->fetch_element('refer_to_check_list_and_choice');
ok( $rtclac, "created refer_to_check_list_and_choice" );

is_deeply( [ sort $rtclac->get_choice ],
    [qw/A1 A2 A3/], 'check refer_to_check_list_and_choice choices' );

eval { $rtclac->check('X'); };
ok( $@, "get_choice with undef 'indirection' parm: which is an error" );
print "normal error:\n", $@, "\n" if $trace;

$root->fetch_element('indirection')->store('my_hash');

is_deeply( [ sort $rtclac->get_choice ],
    [qw/A1 A2 A3 X Y Z/],
    'check refer_to_check_list_and_choice choices with indirection set' );

$rf2list->check('X2');
is_deeply(
    [ sort $rtclac->get_choice ],
    [ sort qw/A1 A2 A3 X X2 Y Z/ ],
    'check X2 and test choices'
);

# load hashes that are used by reference check list
$root->load("my_hash2:X3=x");
$rf2list->check( 'X3', 'Y2' );
is_deeply( [ sort $rf2list->get_choice ],
    [qw/X X2 X3 Y Y2 Z/], 'check refer_to_2_list choices with X3' );
is_deeply(
    [ sort $rtclac->get_choice ],
    [qw/A1 A2 A3 X X2 X3 Y Y2 Z/],
    'check refer_to_check_list_and_choice choices'
);

my $dflist = $root->fetch_element('choice_list_with_default');
ok( $dflist, "created choice_list_with_default" );
@got = $dflist->get_checked_list;
is_deeply( \@got, [ 'A', 'D' ], "test default of choice_list_with_default" );

$dflist->check('C');
$dflist->uncheck('D');
@got = $dflist->get_checked_list;
is_deeply( \@got, [ 'A', 'C' ], "test default of choice_list_with_default" );

@got = $dflist->get_checked_list('custom');
is_deeply( \@got, ['C'], "test custom of choice_list_with_default" );

@got = $dflist->get_checked_list('standard');
is_deeply( \@got, [ 'A', 'D' ], "test standard of choice_list_with_default" );

my $warp_list;
eval { $warp_list = $root->fetch_element('warped_choice_list'); };
ok( $@, "fetch_element without warp set (macro=undef): which is an error" );
print "normal error:\n", $@, "\n" if $trace;

# force read of hidden element
$warp_list =
  $root->fetch_element( name => 'warped_choice_list', accept_hidden => 1 );

ok( $warp_list, "created warped_choice_list" );

eval { $warp_list->get_choice; };
ok( $@, "get_choice without warp set (macro=undef): which is an error" );
print "normal error:\n", $@, "\n" if $trace;

$root->load("macro=AD");

is_deeply(
    [ $warp_list->get_choice ],
    [ 'A' .. 'D' ],
    'check warp_list choice after setting macro=AD'
);

@got = $warp_list->get_checked_list;
is_deeply( \@got, [ 'A', 'B' ], "test default of warped_choice_list" );

$root->load("macro=AH");

is_deeply(
    [ $warp_list->get_choice ],
    [ 'A' .. 'H' ],
    'check warp_list choice after setting macro=AH'
);

@got = $warp_list->get_checked_list;
is_deeply( \@got, [],
    "test default of warped_choice_list after setting macro=AH" );

# test reference to list values
$root->load("dumb_list=a,b,c,d,e");

my $rtl = $root->fetch_element("refer_to_dumb_list");
is_deeply( [ $rtl->get_choice ],
    [qw/X Y Z a b c d e/], "check choice of refer_to_dumb_list" );

# test check list with built_in default
my $wud = $root->fetch_element("choice_list_with_upstream_default");
@got = $wud->get_checked_list();
is_deeply( \@got, [], "test default of choice_list_with_upstream_default" );

@got = $wud->get_checked_list('upstream_default');
is_deeply( \@got, [qw/A D/],
    "test upstream_default of choice_list_with_upstream_default" );

# test check list with upstream_default *and* default (should override)
my $wudad =
  $root->fetch_element("choice_list_with_default_and_upstream_default");
@got = $wudad->get_checked_list('default');
is_deeply( \@got, [qw/A C/],
    "test default of choice_list_with_default_and_upstream_default" );

@got = $wudad->get_checked_list();
is_deeply( \@got, [qw/A C/],
    "test choice_list_with_default_and_upstream_default" );

is_deeply( $wudad->fetch(), 'A,C',
    "test fetch choice_list_with_default_and_upstream_default" );

### test preset feature

my $pinst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'preset_test'
);
ok( $pinst, "created dummy preset instance" );

my $p_root = $pinst->config_root;

$pinst->preset_start;
ok( $pinst->preset, "instance in preset mode" );

my $p_cl = $p_root->fetch_element('choice_list');
$p_cl->set_checked_list(qw/H C L/);    # acid burn test :-)

$pinst->preset_stop;
is( $pinst->preset, 0, "instance in normal mode" );

is( $p_cl->fetch, "C,H,L", "choice_list: read preset list" );

$p_cl->check(qw/A S H/);
is( $p_cl->fetch, "A,C,H,L,S", "choice_list: read completed preset LIST" );
is( $p_cl->fetch('preset'),
    "C,H,L", "choice_list: read preset value as preset_value" );
is( $p_cl->fetch('standard'),
    "C,H,L", "choice_list: read preset value as standard_value" );
is( $p_cl->fetch('custom'), "A,S", "choice_list: read custom_value" );

$p_cl->set_checked_list(qw/A S H E/);
is( $p_cl->fetch, "A,E,H,S", "choice_list: read overridden preset LIST" );
is( $p_cl->fetch('custom'),
    "A,E,S", "choice_list: read custom_value after override" );

my $wrtl =
  $p_root->fetch_element( name => 'warped_refer_to_list', accept_hidden => 1 );
ok( $wrtl, "created warped_refer_to_list (hidden)" );

my $ocl = $root->fetch_element('ordered_checklist');
@got = $ocl->get_checked_list();
is_deeply( \@got, [], "test default of ordered_checklist" );

@set = qw/A C Z V Y/;
$ocl->set_checked_list(@set);
@got = $ocl->get_checked_list;
is_deeply( \@got, \@set, "test ordered_checklist after set_checked_list" );

$ocl->swap(qw/A Y/);
@got = $ocl->get_checked_list;
is_deeply( \@got, [qw/Y C Z V A/], "test ordered_checklist after swap" );

$ocl->move_up(qw/Y/);
@got = $ocl->get_checked_list;
is_deeply( \@got, [qw/Y C Z V A/], "test ordered_checklist after move_up Y" );

$ocl->move_up(qw/V/);
@got = $ocl->get_checked_list;
is_deeply( \@got, [qw/Y C V Z A/], "test ordered_checklist after move_up V" );

$ocl->move_down(qw/A/);
@got = $ocl->get_checked_list;
is_deeply( \@got, [qw/Y C V Z A/], "test ordered_checklist after move_down A" );

$ocl->move_down(qw/C/);
@got = $ocl->get_checked_list;
is_deeply( \@got, [qw/Y V C Z A/], "test ordered_checklist after move_down C" );

$ocl->check('B');
@got = $ocl->get_checked_list;
is_deeply( \@got, [qw/Y V C Z A B/], "test ordered_checklist after check B" );

$ocl->move_up(qw/B/);
$ocl->uncheck('B');
@got = $ocl->get_checked_list;
is_deeply( \@got, [qw/Y V C Z A/],
    "test ordered_checklist after move_up B uncheck B" );

$ocl->check('B');
@got = $ocl->get_checked_list;
is_deeply( \@got, [qw/Y V C Z B A/], "test ordered_checklist after check B" );

is( $root->grab_value( $ocl->location ), "Y,V,C,Z,B,A", "test grab_value" );

my $oclrt = $root->fetch_element('ordered_checklist_refer_to');
@got = $oclrt->get_choice();
is_deeply( \@got, [qw/Y V C Z B A/],
    "test default of ordered_checklist_refer_to" );
