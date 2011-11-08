# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Test::Exception;
use Test::Warn ;
use Test::Differences ;
use Config::Model;
use Config::Model::AnyId;
use Log::Log4perl qw(:easy :levels) ;

BEGIN { plan tests => 89; }

use strict;

my $arg = shift || '';
my $test_only_model = shift || '';
my $do = shift ;

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

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

my @element = (

    # Value constructor args are passed in their specific array ref
    cargo => {
        type       => 'leaf',
        value_type => 'string'
    },
);

# minimal set up to get things working
$model->create_config_class(
    name    => "Master",
    element => [
        bounded_list => {
            type       => 'list',
            list_class => 'Config::Model::ListId',    # default

            max   => 123,
            cargo => {
                type       => 'leaf',
                value_type => 'string'
            },
        },
        plain_list                => { type => 'list', @element },
        list_with_auto_created_id => {
            type            => 'list',
            auto_create_ids => 4,
            @element
        },
        list_with_migrate_keys_from => {
            type => 'list',
            @element,
            migrate_keys_from => '- list_with_auto_created_id',
        },
        olist => {
            type  => 'list',
            cargo => {
                type              => 'node',
                config_class_name => 'Slave'
            },
        },
        list_with_default_with_init_leaf => {
            type              => 'list',
            default_with_init => {
                0 => 'def_1 stuff',
                1 => 'def_2 stuff'
            },
            @element,
        },
        list_with_default_with_init_node => {
            type              => 'list',
            default_with_init => {
                0 => 'X=Bv Y=Cv',
                1 => 'X=Av'
            },
            cargo => {
                type              => 'node',
                config_class_name => 'Slave'
            },
        },
        map { 
              ("list_with_".$_."_duplicates" => { type => 'list', duplicates => $_ , @element, },);
            } qw/warn allow forbid suppress/ ,
    ]
);

$model->create_config_class(
    name    => "Bogus",
    element => [
        list_with_wrong_auto_create => {
            type            => 'list',
            auto_create_ids => ['foo'],
            @element
        },
        list_with_wrong_duplicates => {
            type              => 'list',
            duplicates => 'forbid',
            cargo => {
                type              => 'node',
                config_class_name => 'Slave'
            },
        },
        list_with_yada_duplicates => { 
            type => 'list', 
            duplicates => 'yada' ,
            @element, 
        },
    ]
);

$model->create_config_class(
    name    => "Slave",
    element => [
        [qw/X Y Z/] => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/Av Bv Cv/]
        },
    ]
);

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

is_deeply( [ $root->fetch_element('olist')->get_all_indexes ],
    [], "check index list of empty list" );

my $b = $root->fetch_element('bounded_list');
ok( $b, "bounded list created" );

is( $b->fetch_with_id(1)->store('foo'), 'foo', "stored in 1" );
is( $b->fetch_with_id(0)->store('baz'), 'baz', "stored in 0" );
is( $b->fetch_with_id(2)->store('bar'), 'bar', "stored in 2" );

throws_ok { $b->fetch_with_id(124)->store('baz'); }
qr/Index 124 > max_index limit 123/, 'max error caught';

my $bogus_root = $model->instance( root_class_name => 'Bogus' )->config_root;
throws_ok { $bogus_root->fetch_element('list_with_wrong_auto_create'); }
qr/Wrong auto_create argument for list/, 'wrong auto_create caught';

is_deeply( [ $b->get_all_indexes ], [ 0, 1, 2 ], "check ids" );

$b->delete(1);
is( $b->fetch_with_id(1)->fetch, undef, "check deleted id" );

is( $b->index_type, 'integer', 'check list index_type' );
is( $b->max_index,  123,       'check list max boundary' );

$b->push( 'toto', 'titi' );
is( $b->fetch_with_id(2)->fetch, 'bar',  "check last item of table" );
is( $b->fetch_with_id(3)->fetch, 'toto', "check pushed toto item" );
is( $b->fetch_with_id(4)->fetch, 'titi', "check pushed titi item" );

$b->push_x(
    values     => [ 'toto', 'titi' ],
    check      => 'no',
    annotation => ['toto comment']
);
is( $b->fetch_with_id(5)->fetch, 'toto', "check pushed toto item with push_x" );
is( $b->fetch_with_id(5)->annotation,
    'toto comment', "check pushed toto annotation with push_x" );
is( $b->fetch_with_id(6)->fetch, 'titi', "check pushed titi item with push_x" );

$b->push_x(
    values     => 'toto2',
    check      => 'no',
    annotation => 'toto2 comment'
);

is( $b->fetch_with_id(7)->fetch, 'toto2', "check pushed toto2 item with push_x" );
is( $b->fetch_with_id(7)->annotation,
    'toto2 comment', "check pushed toto2 annotation with push_x" );

my @all = $b->fetch_all_values;
is_deeply( \@all, [qw/baz bar toto titi toto titi toto2/], "check fetch_all_values" );

my $lac = $root->fetch_element('list_with_auto_created_id');
is_deeply(
    [ $lac->get_all_indexes ],
    [ 0 .. 3 ],
    "check list_with_auto_created_id"
);

map { is( $b->fetch_with_id($_)->index_value, $_, "Check index value $_" ); }
  ( 0 .. 4 );

$b->move( 3, 4 );
is( $b->fetch_with_id(3)->fetch, undef,  "check after move idx 3 in 4" );
is( $b->fetch_with_id(4)->fetch, 'toto', "check after move idx 3 in 4" );
map {
    is( $b->fetch_with_id($_)->index_value, $_, "Check moved index value $_" );
} ( 0 .. 4 );

$b->fetch_with_id(3)->store('titi');
$b->swap( 3, 4 );

map {
    is( $b->fetch_with_id($_)->index_value, $_,
        "Check swapped index value $_" );
} ( 0 .. 4 );

is( $b->fetch_with_id(3)->fetch, 'toto', "check value after swap" );
is( $b->fetch_with_id(4)->fetch, 'titi', "check value after swap" );

$b->remove(3);
is( $b->fetch_with_id(3)->fetch, 'titi', "check after remove" );

# test move swap with node list
my $ol = $root->fetch_element('olist');

my @set = ( [qw/X Av/], [qw/X Bv/], [qw/Y Av/], [qw/Z Cv/], [qw/Z Av/], );

my $i = 0;
foreach my $item (@set) {
    my ( $e, $v ) = @$item;
    $ol->fetch_with_id( $i++ )->fetch_element($e)->store($v);
}

$ol->move( 3, 4 );
is( $ol->fetch_with_id(3)->fetch_element('Z')->fetch,
    undef, "check after move idx 3 in 4" );
is( $ol->fetch_with_id(4)->fetch_element('Z')->fetch,
    'Cv', "check after move idx 3 in 4" );
map {
    is( $ol->fetch_with_id($_)->index_value, $_, "Check moved index value $_" );
} ( 0 .. 4 );

$ol->swap( 0, 2 );
is( $ol->fetch_with_id(0)->fetch_element('X')->fetch,
    undef, "check after move idx 0 in 2" );
is( $ol->fetch_with_id(0)->fetch_element('Y')->fetch, 'Av',
    "check after move" );

is( $ol->fetch_with_id(2)->fetch_element('Y')->fetch,
    undef, "check after move" );
is( $ol->fetch_with_id(2)->fetch_element('X')->fetch, 'Av',
    "check after move" );

map {
    is( $ol->fetch_with_id($_)->index_value, $_, "Check moved index value $_" );
} ( 0 .. 4 );
print $root->dump_tree( experience => 'beginner' ) if $trace;

is( $ol->fetch_with_id(0)->fetch_element('X')->fetch,
    undef, "check before move" );
$ol->remove(0);
print $root->dump_tree( experience => 'beginner' ) if $trace;
is( $ol->fetch_with_id(0)->fetch_element('X')->fetch, 'Bv',
    "check after move" );

# test store
my @test = (
    [ a1         => ['a1'] ],
    [ '"a","b"'  => [qw/a b/] ],
    [ 'a,b'      => [qw/a b/] ],
    [ '"a\"a",b' => [qw/a"a b/] ],
    [ '"a,a",b'  => [ 'a,a', 'b' ] ],
    [ '",a1"'    => [',a1'] ],
);
foreach my $l (@test) {
    $b->load( $l->[0] );
    is_deeply( [ $b->fetch_all_values ], $l->[1], "test store $l->[0]" );
}

throws_ok { $b->load('a,,b'); } "Config::Model::Exception::Load",
  "fails load 'a,,b'";

# test preset mode
$inst->preset_start;
my $pl = $root->fetch_element('plain_list');

$pl->fetch_with_id(0)->store('prefoo');
$pl->fetch_with_id(1)->store('prebar');
$inst->preset_stop;
ok( 1, "filled preset values" );

is_deeply(
    [ $pl->fetch_all_values ],
    [ 'prefoo', 'prebar' ],
    "check that preset values are read"
);
$pl->fetch_with_id(2)->store('bar');

is_deeply(
    [ $pl->fetch_all_values ],
    [ 'prefoo', 'prebar', 'bar' ],
    "check that values are read"
);

is_deeply( [ $pl->fetch_all_values( mode => 'custom' ) ],
    ['bar'], "check that custom values are read" );

# test key migration
my $lwmkf = $root->fetch_element('list_with_migrate_keys_from');
my @to_migrate =
  $root->fetch_element('list_with_auto_created_id')->get_all_indexes;
is_deeply( [ $lwmkf->get_all_indexes ],
    \@to_migrate, "check migrated ids (@to_migrate)" );
    
# test default_with_init on leaf
my $lwdwil = $root->fetch_element('list_with_default_with_init_leaf');
# note: calling get_all_indexes is required to trigger creation of default_with_init keys
eq_or_diff([$lwdwil->get_all_indexes],[0,1],"check default keys");
is($lwdwil->fetch_with_id(0)->fetch,'def_1 stuff',"test default_with_init leaf 0") ;
is($lwdwil->fetch_with_id(1)->fetch,'def_2 stuff',"test default_with_init leaf 1") ;

# test default_with_init on node
my $lwdwin = $root->fetch_element('list_with_default_with_init_node');
eq_or_diff([$lwdwin->get_all_indexes],[0,1],"check default keys");
is($lwdwin->fetch_with_id(0)->fetch_element('X')->fetch,'Bv',"test default_with_init node 0") ;
is($lwdwin->fetch_with_id(0)->fetch_element('Y')->fetch,'Cv',"test default_with_init node 0") ;
is($lwdwin->fetch_with_id(1)->fetch_element('X')->fetch,'Av',"test default_with_init node 0") ;

throws_ok { $bogus_root->fetch_element('list_with_wrong_duplicates'); } "Config::Model::Exception::Model",
  "fails duplicates with node cargo";

throws_ok { $bogus_root->fetch_element('list_with_yada_duplicates'); } "Config::Model::Exception::Model",
  "fails yada duplicates";

foreach my $what (qw/forbid warn suppress/) {
    my $lwd = $root->fetch_element('list_with_'.$what.'_duplicates');
    $lwd->push(qw/string1 string2/);
    $lwd->push('string1'); # does not trigger duplicate issues, yet
    $lwd->push('string1'); # does not trigger duplicate issues, yet
    
    # there we go
    if ($what eq 'forbid') {
        throws_ok { $lwd->fetch_all_values ; } "Config::Model::Exception::WrongValue", 
            "fails forbidden duplicates" ;
        $lwd->delete(2) ;
    }
    elsif ($what eq 'warn') {
        warnings_like { $lwd->fetch_all_values ; } qr/Duplicated/ ,
            "warns with duplicated values" ;
        is($lwd->has_fixes, 2,"check nb of fixes") ;
        $inst->apply_fixes ;
        warnings_like { $lwd->fetch_all_values ; } [] , # no warning accepted
            "no longer warns with duplicated values" ;
    }
    else {
        $lwd->check ; 
    }
    is ($lwd->fetch_with_id(0)->fetch,'string1',
        "check that original values is untouched after $what duplicates");
}
