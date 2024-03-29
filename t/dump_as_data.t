# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Test::Log::Log4perl;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

use warnings;
use strict;
use lib "t/lib";
use boolean;

Test::Log::Log4perl->ignore_priority("info");

my ($model, $trace) = init_test();

my $inst = $model->instance(
    root_class_name => 'Master',
    model_file      => 'dump_load_model.pl',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;
ok( $root, "Config root created" );

my $step = '
std_id:ab X=Bv -
std_id:bc X=Av -
bool_list=0,1
tree_macro=mXY
another_string="toto tata"
hash_a:toto=toto_value 
hash_a:titi=titi_value
ordered_hash:z=1 
ordered_hash:y=2
ordered_hash:x=3 
lista=a,b,c,d
olist:0 X=Av -
olist:1 X=Bv -
my_check_list=toto my_reference="titi"
warp warp2 aa2="foo bar"
';

$step =~ s/\n/ /g;

note("steps are $step") if $trace;
ok( $root->load( step => $step ), "set up data in tree" );

# load some values with undef
$root->fetch_element('hash_a')->fetch_with_id('undef_val');
$root->fetch_element('lista')->fetch_with_id(6)->store('g');

$root->load_data( { listb => 'bb' } );
ok( 1, "loaded single array element as listb => 'bb'" );

my $data = $root->dump_as_data( full_dump => 0 );

my $expect = {
    'olist'         => [ { 'X' => 'Av' }, { 'X' => 'Bv' } ],
    'my_check_list' => ['toto'],
    'tree_macro'    => 'mXY',
    'ordered_hash'   => [ 'z', '1', 'y', '2', 'x', '3' ],
    'another_string' => 'toto tata',
    bool_list => [ false, true ],
    'listb'          => ['bb'],
    'my_reference'   => 'titi',
    'hash_a'         => {
        'toto' => 'toto_value',
        'titi' => 'titi_value',
    },
    'std_id' => {
        'ab' => { 'X' => 'Bv' },
        'bc' => { 'X' => 'Av' }
    },
    'lista' => [qw/a b c d g/],
    'warp'  => {
        'warp2' => {
            'aa2' => 'foo bar'
        }
    },
};

#use Data::Dumper; print Dumper $data ;

is_deeply( $data, $expect, "check data dump" );

subtest "check default mapping of boolean value type" => sub {
    my $data = $root->dump_as_data( full_dump => 0 );
    for (0,1) {
        is($data->{bool_list}[$_], $_, "Perl data value of bool_list:$_ ");
        is(ref $data->{bool_list}[$_], '', "Perl data of bool_list:$_ is not a ref");
    }
};

subtest "check mapping of boolean value type to Perl boolean" => sub {
    my $data = $root->dump_as_data( full_dump => 0, to_boolean => sub { boolean(shift) } );
    for (0,1) {
        isa_ok($data->{bool_list}[$_], "boolean", "Perl data of bool_list:$_ ");
    };
};

subtest "check mapping of boolean value type to Perl boolean" => sub {
    plan skip_all => "JSON PP boolean behavior not yet checked";
    my $data = $root->dump_as_data( full_dump => 0, to_boolean => 'JSON::PP::Boolean' );
    for (0,1) {
        isa_ok($data->{bool_list}[$_], "JSON::PP::Boolean", "Perl data of bool_list:$_ ");
    }
};

# add default information provided by model to check full dump
$expect->{string_with_def} = 'yada yada';
$expect->{int_v}           = 10;
$expect->{olist}[0]{DX}    = 'Dv';
$expect->{olist}[1]{DX}    = 'Dv';
$expect->{std_id}{ab}{DX}  = 'Dv';
$expect->{std_id}{bc}{DX}  = 'Dv';
$expect->{a_uniline}       = 'yada yada';
my $full_data = $root->dump_as_data(mode => 'user');

is_deeply( $full_data, $expect, "check full data dump" );

my $inst2 = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test2'
);
ok( $inst, "created 2nd dummy instance" );

my $root2 = $inst2->config_root;
ok( $root2, "Config root2  created" );

$root2->load_data($data);

ok( 1, "loaded perl data structure in 2nd instance" );

my $dump1 = $root->dump_tree;
my $dump2 = $root2->dump_tree;

is( $dump2, $dump1, "check that dump of 2nd tree is identical to dump of the first tree" );

# try partial dumps

my @tries = (
    [ 'olist'           => $expect->{olist} ],
    [ 'olist:0'         => $expect->{olist}[0] ],
    [ 'olist:0 DX'      => $expect->{olist}[0]{DX} ],
    [ 'string_with_def' => $expect->{string_with_def} ],
    [ 'ordered_hash'    => $expect->{ordered_hash} ],
    [ 'hash_a'          => $expect->{hash_a} ],
    [ 'std_id:ab'       => $expect->{std_id}{ab} ],
    [ 'my_check_list'   => $expect->{my_check_list} ],
);

foreach my $test (@tries) {
    my ( $path, $expect ) = @$test;
    my $obj  = $root->grab($path);
    my $dump = $obj->dump_as_data(mode => 'user');
    is_deeply( $dump, $expect, "check data dump for '$path'" );
}

# try dump of ordered hash as hash
my $ohah_dump = $root->grab('ordered_hash')->dump_as_data( ordered_hash_as_list => 0 );
is_deeply(
    $ohah_dump,
    { __ordered_hash_order => [qw/z y x/], 'z', '1', 'y', '2', 'x', '3' },
    "check dump of ordered hash as hash"
);

subtest "test ordered_hash warnings" => sub {
    my $tw = Test::Log::Log4perl->get_logger("Tree.Element.Id.Hash");
    Test::Log::Log4perl->start(ignore_priority => "info");
    $tw->warn(qr/order is not defined/);

    # load 2 items in ordered_hash without __order produces a warning";
    $root->load_data( { ordered_hash => { y => '2', 'x' => '3' }});

    # load one item in ordered_hash without __order produce no warning";
    $root->load_data( { ordered_hash => { 'x' => '3' }});
    Test::Log::Log4perl->end("warnings without __order");
};

# test ordered hash load with hash ref instead of array ref
my $inst3 = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test3'
);
ok( $inst, "created 3rd dummy instance" );
my $root3 = $inst3->config_root;
$data->{ordered_hash} = { @{ $expect->{ordered_hash} }, __order => [qw/y x z/] };
$root3->load_data($data);

@tries = (
    [ 'olist'           => $expect->{olist} ],
    [ 'olist:0'         => $expect->{olist}[0] ],
    [ 'olist:0 DX'      => $expect->{olist}[0]{DX} ],
    [ 'string_with_def' => $expect->{string_with_def} ],
    [ 'ordered_hash'    => [qw/y 2 x 3 z 1/] ],
    [ 'hash_a'          => $expect->{hash_a} ],
    [ 'std_id:ab'       => $expect->{std_id}{ab} ],
    [ 'my_check_list'   => $expect->{my_check_list} ],
);

foreach my $test (@tries) {
    my ( $path, $expect ) = @$test;
    my $obj  = $root3->grab($path);
    my $dump = $obj->dump_as_data(mode => 'user');
    is_deeply( $dump, $expect, "check data dump for '$path'" );
}

# test dump of annotations as pod
my %notes =
    map { ( $_ => $_ ? "$_ annotation\nwith long text" : "root annotation" ); }
    ( '', 'olist', 'olist:0', 'olist:0 DX', 'hash_a', 'std_id:ab', 'my_check_list' );
foreach ( keys %notes ) {
    $root->grab($_)->annotation( $notes{$_} );
}

print $root->dump_tree if $trace;

my $pod_notes = $root->dump_annotations_as_pod;

print $pod_notes if $trace;

foreach ( keys %notes ) {
    my $v = $notes{$_};
    like( $pod_notes, qr/$v/, "found note for $_ in pod notes" );
}

$root2->load_pod_annotation($pod_notes);
my $pod_notes2 = $root2->dump_annotations_as_pod;

is( $pod_notes2, $pod_notes, "check 2nd pod notes" );

memory_cycle_ok($model, "memory cycles");

done_testing;
