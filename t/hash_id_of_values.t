# -*- cperl -*-

use warnings;

use ExtUtils::testlib;
use Test::More ;
use Test::Memory::Cycle;
use Config::Model;
use Test::Exception;
use Test::Warn;
use Test::Differences;

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $arg =~ /l/ ? $TRACE : $WARN );

ok( 1, "Compilation done" );

# new parameter style
my @element = (

    # Value constructor args are passed in their specific array ref
    cargo => {
        type       => 'leaf',
        value_type => 'string',
        class => 'Config::Model::Value',
    },
);

# minimal set up to get things working
my $model = Config::Model->new( );
$model->create_config_class(
    name    => "Master",
    element => [
        plain_hash => {
            type => 'hash',
            index_type => 'integer',
            cargo => {
                type => 'leaf',
                value_type => 'string'
            },
        },
        bounded_hash => {
            type => 'hash',
            class => 'Config::Model::HashId',    # default
            index_type => 'integer',

            # hash boundaries
            min         => 1,
            max         => 123,
            max_nb      => 2,
            @element
        },
        hash_with_auto_created_id => {
            type        => 'hash',
            index_type  => 'string',
            auto_create_keys => ['yada'],
            @element
        },
        hash_with_several_auto_created_id => {
            type        => 'hash',
            index_type  => 'string',
            auto_create_keys => [qw/x y z/],
            @element
        },
        [qw/hash_with_default_id hash_with_default_id_2/] => {
            type       => 'hash',
            index_type => 'string',
            default_keys    => ['yada'],
            @element
        },
        hash_with_several_default_keys => {
            type       => 'hash',
            index_type => 'string',
            default_keys    => [qw/x y z/],
            @element
        },
        hash_follower => {
            type       => 'hash',
            index_type => 'string',
            @element,
            follow_keys_from => '- hash_with_several_auto_created_id',
        },
        hash_with_allow => {
            type       => 'hash',
            index_type => 'string',
            @element,
            allow_keys => [qw/foo bar baz/],
        },
        hash_with_allow_from => {
            type       => 'hash',
            index_type => 'string',
            @element,
            allow_keys_from => '- hash_with_several_auto_created_id',
        },
        hash_with_allow_keys_matching => {
            type       => 'hash',
            index_type => 'string',
            @element,
            allow_keys_matching => '^foo\d{2}$',
        },
        hash_with_follow_keys_from => {
            type       => 'hash',
            index_type => 'string',
            @element,
            follow_keys_from => '- hash_with_several_auto_created_id',
        },
        hash_with_migrate_keys_from => {
            type       => 'hash',
            index_type => 'string',
            @element,
            migrate_keys_from => '- hash_with_several_auto_created_id',
        },
        hash_with_follow_keys_from_unknown => {
            type       => 'hash',
            index_type => 'string',
            @element,
            follow_keys_from => '- unknown_hash',
        },
        ordered_hash => {
            type       => 'hash',
            index_type => 'string',
            @element,
            ordered => 1,
        },
        hash_with_warn_if_key_match => {
            type       => 'hash',
            index_type => 'string',
            @element,
            warn_if_key_match => 'foo',
        },
        hash_with_warn_unless_key_match => {
            type       => 'hash',
            index_type => 'string',
            @element,
            warn_unless_key_match => 'foo',
        },
        hash_with_default_and_init => {
            type              => 'hash',
            index_type        => 'string',
            default_with_init => {
                'def_1' => 'def_1 stuff',
                'def_2' => 'def_2 stuff'
            },
            @element
        },
        hash_with_convert_lc => {
            type       => 'hash',
            index_type => 'string',
            convert    => 'lc',
            @element
        },
    ],
);

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;
$inst->initial_load_stop;
is( $inst->needs_save, 0, "verify instance needs_save status after creation" );

my $b = $root->fetch_element('bounded_hash');
ok( $b, "bounded hash created" );

is( $b->get_cargo_type,               'leaf',   'check get_cargo_type' );
is( $b->get_cargo_info('value_type'), 'string', 'check get_cargo_info' );

is( $b->name, 'Master bounded_hash id', "check hash id name" );

my $b1 = $b->fetch_with_id(1);
isa_ok( $b1, 'Config::Model::Value', "fetched element id 1" );
is( $inst->needs_save, 0, "verify instance needs_save status after element creation" );

is( $b1->store('foo'), 1, "Storing in id 1" );
is( $inst->needs_save, 1, "verify instance needs_save status after storing into element" );

is( $b->fetch_with_id(2)->store('bar'), 1, "Storing in id 2" );
is( $inst->needs_save, 2, "verify instance needs_save status after storing into another element" );
print scalar $inst->list_changes, "\n" if $trace;

eval { $b->fetch_with_id('')->store('foo'); };
ok( $@, "empty index error" );
print "normal error: ", $@ if $trace;

eval { $b->fetch_with_id(0)->store('foo'); };
ok( $@, "min error" );
print "normal error: ", $@ if $trace;

eval { $b->fetch_with_id(124)->store('foo'); };
ok( $@, "max error" );
print "normal error: ", $@ if $trace;

eval { $b->fetch_with_id(40)->store('foo'); };
ok( $@, "max nb error" );
print "normal error: ", $@ if $trace;

is( $inst->needs_save, 2, "verify instance needs_save status after store errors" );
print scalar $inst->list_changes, "\n" if $trace;
$inst->clear_changes;

ok( $b->delete(2), "delete id 2" );
is( $b->exists(2),     '', "deleted id does not exist" );
is( $inst->needs_save, 1,  "verify instance needs_save status after delete" );
print scalar $inst->list_changes, "\n" if $trace;
$inst->clear_changes;

is( $b->index_type, 'integer', "reading value_type" );
is( $b->max_index,  123,       "reading max boundary" );

my $ac = $root->fetch_element('hash_with_auto_created_id');
ok( $ac, "created hash_with_auto_created_id" );

eq_or_diff( [ $ac->fetch_all_indexes ], ['yada'], "check auto-created id" );
ok( $ac->exists('yada'), "...idem" );

$ac->fetch_with_id('foo')->store(3);
ok( $ac->exists('yada'), "...idem after creating another id" );
eq_or_diff( [ $ac->fetch_all_indexes ], [ 'foo', 'yada' ], "check the 2 ids" );

my $dk = $root->fetch_element('hash_with_default_id');
ok( $dk, "created hash_with_default_id ..." );

eq_or_diff( [ $dk->fetch_all_indexes ], ['yada'], "check default id" );
ok( $dk->exists('yada'), "...and test default id on empty hash" );

my $dk2 = $root->fetch_element('hash_with_default_id_2');
ok( $dk2,                                 "created hash_with_default_id_2 ..." );
ok( $dk2->fetch_with_id('foo')->store(3), "... store a value..." );
eq_or_diff( [ $dk2->fetch_all_indexes ], ['foo'], "...check existing id..." );
is( $dk2->exists('yada'), '', "...and test that default id is not provided" );

my $dk3 = $root->fetch_element('hash_with_several_default_keys');
ok( $dk3, "created hash_with_several_default_keys ..." );
eq_or_diff( [ sort $dk3->fetch_all_indexes ], [qw/x y z/], "...check default id" );

my $ac2 = $root->fetch_element('hash_with_several_auto_created_id');
ok( $ac2,                                 "created hash_with_several_auto_created_id ..." );
ok( $ac2->fetch_with_id('foo')->store(3), "... store a value..." );
eq_or_diff( [ sort $ac2->fetch_all_indexes ], [qw/foo x y z/], "...check id..." );

my $follower = $root->fetch_element('hash_follower');
eq_or_diff( [ sort $follower->fetch_all_indexes ], [qw/foo x y z/], "check follower id" );

eval { $follower->fetch_with_id('zoo')->store('zoo'); };
ok( $@, "forbidden index error (not in followed object)" );
print "normal error: ", $@ if $trace;

my $allow = $root->fetch_element('hash_with_allow');

ok( $allow,                                 "created hash_with_allow ..." );
ok( $allow->fetch_with_id('foo')->store(3), "... store a value..." );

eval { $allow->fetch_with_id('zoo')->store('zoo'); };
ok( $@, "not allowed index error" );
print "normal error: ", $@ if $trace;

my $allow_from = $root->fetch_element('hash_with_allow_from');

ok( $allow_from,                                 "created hash_with_allow ..." );
ok( $allow_from->fetch_with_id('foo')->store(3), "... store a value..." );

eval { $allow_from->fetch_with_id('zoo')->store('zoo'); };
ok( $@, "not allowed index error" );
print "normal error: ", $@ if $trace;

print scalar $inst->list_changes, "\n" if $trace;
$inst->clear_changes;

my $ph = $root->fetch_element('plain_hash');
$ph->fetch_with_id(2)->store('baz');
ok( $ph->copy( 2, 3 ), "value copy" );
is( $ph->fetch_with_id(3)->fetch, $ph->fetch_with_id(2)->fetch, "compare copied value" );
print scalar $inst->list_changes, "\n" if $trace;
$inst->clear_changes;

my $hwfkf = $root->fetch_element('hash_with_follow_keys_from');
ok( $hwfkf, "created hash_with_follow_keys_from ..." );
eq_or_diff( [ $hwfkf->get_default_keys ],
    [qw/foo x y z/], 'check default keys of hash_with_follow_keys_from' );

my $hwfkfu = $root->fetch_element('hash_with_follow_keys_from_unknown');
ok( $hwfkfu, "created hash_with_follow_keys_from_unknown ..." );
eval { $hwfkfu->get_default_keys; };
ok( $@, "failed to get keys from hash_with_follow_keys_from_unknown" );
print "normal error: $@" if $trace;

my $oh = $root->fetch_element('ordered_hash');
ok( $oh, "created ordered_hash ..." );
$oh->fetch_with_id('z')->store('1z');
$oh->fetch_with_id('x')->store('2x');
$oh->fetch_with_id('a')->store('3a');

eq_or_diff( [ $oh->fetch_all_indexes ], [qw/z x a/], "check index order of ordered_hash" );
$inst->clear_changes;

$oh->swap(qw/z x/);
is( $inst->needs_save, 1, "verify instance needs_save status after swap" );
print scalar $inst->list_changes, "\n" if $trace;
$inst->clear_changes;

eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/x z a/], "check index order of ordered_hash after swap(z x)" );

$oh->swap(qw/a z/);

eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/x a z/], "check index order of ordered_hash after swap(a z)" );

$inst->clear_changes;
$oh->move_up(qw/a/);
is( $inst->needs_save, 1, "verify instance needs_save status after move_up" );
print scalar $inst->list_changes, "\n" if $trace;
$inst->clear_changes;

eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/a x z/], "check index order of ordered_hash after move_up(a)" );

$oh->move_down(qw/x/);
is( $inst->needs_save, 1, "verify instance needs_save status after move_down" );
print scalar $inst->list_changes, "\n" if $trace;
$inst->clear_changes;

eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/a z x/], "check index order of ordered_hash after move_down(x)" );

is( $oh->fetch_with_id('x')->fetch, '2x', "Check copied value" );

$oh->copy(qw/x d/);
is( $inst->needs_save, 1, "verify instance needs_save status after copy" );
print scalar $inst->list_changes, "\n" if $trace;
$inst->clear_changes;

eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/a z x d/], "check index order of ordered_hash after copy(x d)" );
is( $oh->fetch_with_id('d')->fetch, '2x', "Check copied value" );

$oh->copy(qw/a e/);
eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/a z x d e/], "check index order of ordered_hash after copy(a e)" );
is( $oh->fetch_with_id('e')->fetch, '3a', "Check copied value" );

$inst->clear_changes;
$oh->move_after('d');
eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/d a z x e/], "check index order of ordered_hash after move_after(d)" );
is( $inst->needs_save, 1, "verify instance needs_save status after move_after" );
print scalar $inst->list_changes, "\n" if $trace;
$inst->clear_changes;

$oh->move_after( 'd', 'z' );
eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/a z d x e/], "check index order of ordered_hash after move_after(d z)" );
is( $inst->needs_save, 1, "verify instance needs_save status after move_after" );
print scalar $inst->list_changes, "\n" if $trace;
$inst->clear_changes;

$oh->move_after( 'd', 'e' );
eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/a z x e d/], "check index order of ordered_hash after move_after(d e)" );

$oh->sort;
eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/a d e x z/], "check index order of ordered_hash after sort" );

$oh->insort('v')->store('v val');
eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/a d e v x z/], "check index order of ordered_hash after insort" );
is($oh->fetch_with_id('v')->fetch,'v val',"check value entered with insort");

$inst->clear_changes;
$oh->clear;

is( $inst->needs_save, 1, "verify instance needs_save status after clear" );
eq_or_diff([$inst->list_changes],['ordered_hash: cleared all entries'],"check change message after clear");
eq_or_diff( [ $oh->fetch_all_indexes ], [], "check index order of ordered_hash after clear" );

$oh->load_data( [qw/a va b vb c vc d vd e ve/] );
eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/a b c d e/], "check index order of ordered_hash after clear" );

$oh->clear;
$oh->load_data( {
    __order => [qw/a b c d e/],
    qw/a va b vb c vc d vd e ve/
} );
eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/a b c d e/], "check index order of ordered_hash loaded with hash and __order" );

$oh->move( 'e', 'e2' );
eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/a b c d e2/], "check index order of ordered_hash after move(e e2)" );
my $v = $oh->fetch_with_id('e2')->fetch;
is( $v, 've', "Check moved value" );

$oh->move( 'd', 'e2' );
eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/a b c e2/], "check index order of ordered_hash after move(d e2)" );

$v = $oh->fetch_with_id('e2')->fetch;
is( $v, 'vd', "Check moved value" );

$oh->move( 'b', 'd' );
eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/a d c e2/], "check index order of ordered_hash after move(b d)" );

$v = $oh->fetch_with_id('d')->fetch;
is( $v, 'vb', "Check moved value" );

$oh->move( 'c', 'a' );
eq_or_diff( [ $oh->fetch_all_indexes ],
    [qw/d a e2/], "check index order of ordered_hash after move(c a)" );

$v = $oh->fetch_with_id('a')->fetch;
is( $v, 'vc', "Check moved value" );

my $hwakm = $root->fetch_element('hash_with_allow_keys_matching');
throws_ok { $hwakm->fetch_with_id('bar2'); } 'Config::Model::Exception::WrongValue',
    "check not matching key";

ok( $hwakm->fetch_with_id('foo22'), "check matching key" );

# test warnings with keys
my $hwwikm = $root->fetch_element('hash_with_warn_if_key_match');
warning_like { $hwwikm->fetch_with_id('foo2'); } qr/key 'foo2' should not match/,
    "warn if matching key";

warning_like {
 $hwwikm->fetch_with_id("foo2 multi\nline\nid");
} qr/key 'foo2 multi\[\.\.\.\]' should not match/,
    "warn if matching multi_line key";

my $hwwukm = $root->fetch_element('hash_with_warn_unless_key_match');
warning_like { $hwwukm->fetch_with_id('bar2'); } qr/key 'bar2' should match foo/,
    "warn unless matching key";

# test key migration
my $hwmkf      = $root->fetch_element('hash_with_migrate_keys_from');
my @to_migrate = $root->fetch_element('hash_with_several_auto_created_id')->fetch_all_indexes;
eq_or_diff( [ $hwmkf->fetch_all_indexes ],
    \@to_migrate, "check ids of hash_with_migrate_keys_from" );

my $hwdai = $root->fetch_element('hash_with_default_and_init');

# calling fetch_all_indexes will trigger the creation of the default_with_init keys
foreach my $idx ( $hwdai->fetch_all_indexes ) {
    is( $hwdai->fetch_with_id($idx)->fetch, "$idx stuff", "check default_with_init with '$idx'" );
}

# test convert lc
my $hwclc = $root->fetch_element('hash_with_convert_lc');
$hwclc->fetch_with_id('Debian')->store('DebV');
$hwclc->fetch_with_id('Grip')->store('GripV');
eq_or_diff( [ $hwclc->fetch_all_indexes ], [qw/debian grip/], "check converted ids" );

memory_cycle_ok( $model, "check memory cycles" );

done_testing;
