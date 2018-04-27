# -*- cperl -*-


use ExtUtils::testlib;
use Test::More;
use Test::Exception;
use Test::Warn;
use Test::Differences;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;
use Config::Model::Value;

use strict;
use warnings;
use 5.010;

binmode STDOUT, ':utf8';

my ($model, $trace) = init_test();

# minimal set up to get things working
$model->create_config_class(
    name    => "BadClass",
    element => [
        crooked => {
            type  => 'leaf',
            class => 'Config::Model::Value',
        },
        crooked_enum => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'enum',
            default    => 'foo',
            choice     => [qw/A B C/]
        },
    ] );

$model->create_config_class(
    name    => "Master",
    element => [
        scalar => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'integer',
            min        => 1,
            max        => 4,
        },
        string => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'string',
        },
        bounded_number => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'number',
            min        => 1,
            max        => 4,
        },
        mandatory_string => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'string',
            mandatory  => 1,
        },
        mandatory_boolean => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'boolean',
            mandatory  => 1,
        },
        mandatory_with_default_value => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'string',
            mandatory  => 1,
            default    => 'booya',
        },
        boolean_with_write_as => {
            type       => 'leaf',
            value_type => 'boolean',
            write_as   => [qw/false true/],
        },
        boolean_with_write_as_and_default => {
            type       => 'leaf',
            value_type => 'boolean',
            write_as   => [qw/false true/],
            default    => 'true',
        },
        bare_enum => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'enum',
            choice     => [qw/A B C/]
        },
        enum => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'enum',
            default    => 'A',
            choice     => [qw/A B C/]
        },
        enum_with_help => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'enum',
            choice     => [qw/a b c/],
            help       => { a => 'a help' }
        },
        uc_convert => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'string',
            convert    => 'uc',
        },
        lc_convert => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'string',
            convert    => 'lc',
        },
        upstream_default => {
            type             => 'leaf',
            value_type       => 'string',
            upstream_default => 'up_def',
        },
        a_uniline => {
            type             => 'leaf',
            value_type       => 'uniline',
            upstream_default => 'a_uniline_def',
        },
        with_replace => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/a b c/],
            replace    => {
                a1       => 'a',
                c1       => 'c',
                'foo/.*' => 'b',
            },
        },
        replacement_hash => {
            type       => 'hash',
            index_type => 'string',
            cargo      => {
                type       => 'leaf',
                value_type => 'uniline',
            },
        },
        with_replace_follow => {
            type           => 'leaf',
            value_type     => 'string',
            replace_follow => '- replacement_hash',
        },
        match => {
            type       => 'leaf',
            value_type => 'string',
            match      => '^foo\d{2}/$',
        },
        prd_test_action => {
            type       => 'leaf',
            value_type => 'string',
        },
        prd_match => {
            type       => 'leaf',
            value_type => 'string',
            grammar    => q^check: <rulevar: local $failed = 0>
check: token (oper token)(s?) <reject:$failed>
oper: 'and' | 'or'
token: 'Apache' | 'CC-BY' | 'Perl' {
my $v = $arg[0]->grab("! prd_test_action")->fetch || '';
$failed++ unless $v =~ /$item[1]/ ; 
}
^,
        },
        warn_if_match => {
            type          => 'leaf',
            value_type    => 'string',
            warn_if_match => { 'foo' => { fix => '$_ = uc;' } },
        },
        warn_unless_match => {
            type              => 'leaf',
            value_type        => 'string',
            warn_unless_match => { foo => { msg => '', fix => '$_ = "foo".$_;' } },
        },
        assert => {
            type       => 'leaf',
            value_type => 'string',
            assert     => {
                assert_test => {
                    code => 'defined $_ and /\w/',
                    msg  => 'must not be empty',
                    fix  => '$_ = "foobar";'
                }
            },
        },
        warn_if_number => {
            type        => 'leaf',
            value_type  => 'string',
            warn_if => {
                warn_test => {
                    code => 'defined $_ && /\d/;',
                    msg  => 'should not have numbers',
                    fix  => 's/\d//g;'
                }
            },
        },
        warn_unless => {
            type        => 'leaf',
            value_type  => 'string',
            warn_unless => {
                warn_test => {
                    code => 'defined $_ and /\w/',
                    msg  => 'should not be empty',
                    fix  => '$_ = "foobar";'
                }
            },
        },
        warn_unless_file => {
            type        => 'leaf',
            value_type  => 'string',
            warn_unless => {
                warn_test => {
                    code => 'file($_)->exists',
                    msg  => 'file $_ should exist',
                    fix  => '$_ = "value.t";'
                }
            },
        },
        always_warn => {
            type       => 'leaf',
            value_type => 'string',
            warn       => 'Always warn whenever used',
        },
        'Standards-Version' => {
            'value_type'        => 'uniline',
            'warn_unless_match' => {
                '3\\.9\\.2' => {
                    'msg' => 'Current standard version is 3.9.2',
                    'fix' => '$_ = undef; #restore default'
                }
            },
            'match'   => '\\d+\\.\\d+\\.\\d+(\\.\\d+)?',
            'default' => '3.9.2',
            'type'    => 'leaf',
        },
        t_file => {
            type => 'leaf',
            value_type => 'file'
        },
        t_dir => {
            type => 'leaf',
            value_type => 'dir'
        }
    ],                          # dummy class
);

my $bad_inst = $model->instance(
    root_class_name => 'BadClass',
    instance_name   => 'test_bad_class'
);
ok( $bad_inst, "created bad_class instance" );
$bad_inst->initial_load_stop;

my $bad_root = $bad_inst->config_root;

my $result;

throws_ok { $bad_root->fetch_element('crooked'); }
    'Config::Model::Exception::Model',
    "test create expected failure";
print "normal error:\n", $@, "\n" if $trace;

my $inst = $model->instance(
    root_class_name => 'Master',
    # root_dir is used to test warn_unless_file
    root_dir => 't',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );
$inst->initial_load_stop;

sub check_store_error {
    my ( $obj, $v, $qr ) = @_;
    my $path = $obj->location;
    $obj->store( value => $v, silent => 1, check => 'skip' );
    is( $inst->errors->{$path}, '', "store error in $path is tracked" );
    like( scalar $inst->error_messages, $qr, "check $path error message" );
}

sub check_error {
    my ( $obj, $v, $qr ) = @_;
    my $old_v = $obj->fetch;
    check_store_error(@_);
    is( $obj->fetch, $old_v, "check that wrong value $v was not stored" );
}

my $root = $inst->config_root;

note "test simple scalar";
{
    my $i = $root->fetch_element('scalar');
    ok( $i, "test create bounded integer" );

    is( $inst->needs_save, 0, "verify instance needs_save status after creation" );

    is( $i->needs_check, 1, "verify check status after creation" );

    is( $i->has_data, 0, "check has_data on empty scalar" );

    $i->store(1);
    ok( 1, "store test done" );
    is( $i->needs_check,   0, "store does not trigger a check (check done during store)" );
    is( $inst->needs_save, 1, "verify instance needs_save status after store" );
    is( $i->has_data, 1, "check has_data after store" );

    is( $i->fetch,         1, "fetch test" );
    is( $i->needs_check,   0, "check was done during fetch" );
    is( $inst->needs_save, 1, "verify instance needs_save status after fetch" );

    check_error( $i, 5, qr/max limit/ );

    check_error( $i, 'toto', qr/not of type/ );

    check_error( $i, 1.5, qr/number but not an integer/ );

    # test that bad storage triggers an error
    throws_ok { $i->store(5); } 'Config::Model::Exception::WrongValue', "test max nb expected failure";
    print "normal error:\n", $@, "\n" if $trace;
}

note "test bounded number";
{
    my $nb = $root->fetch_element('bounded_number');
    ok( $nb, "created " . $nb->name );

    $nb->store( value => 1,   callback => sub { is( $nb->fetch, 1,   "assign 1" ); } );
    $nb->store( value => 1.5, callback => sub { is( $nb->fetch, 1.5, "assign 1.5" ); } );

    $nb->store(undef);
    ok( defined $nb->fetch() ? 0 : 1, "store undef" );
}

note "test mandatory string";
{
    my $ms = $root->fetch_element('mandatory_string');
    ok( $ms, "created mandatory_string" );

    throws_ok { my $v = $ms->fetch; } 'Config::Model::Exception::User', "mandatory string: undef error";
    print "normal error:\n", $@, "\n" if $trace;

    $ms->store('toto');
    is( $ms->fetch, 'toto', "mandatory_string: store and read" );

    my $toto_str = "a\nbig\ntext\nabout\ntoto";
    $ms->store($toto_str);
    $toto_str =~ s/text/string/;
    $ms->store($toto_str);

    print join( "\n", $inst->list_changes("\n") ), "\n" if $trace;
    $inst->clear_changes;
}

note "test mandatory string provided with a default value";
{
    my $mwdv = $root->fetch_element('mandatory_with_default_value');
    # note: calling fetch before store triggers a "notify_change" to
    # let user know that his file was changed by model
    $mwdv->store('booya'); # emulate reading a file containing default value
    is( $mwdv->has_data, 0, "check has_data after storing default value" );
    is( $mwdv->fetch,      'booya', "status quo" );
    is( $inst->needs_save, 0,       "verify instance needs_save status after storing default value" );

    $mwdv->store('boo');
    is( $mwdv->fetch,      'boo', "overrode default" );
    is( $inst->needs_save, 1,     "verify instance needs_save status after storing another value" );

    $mwdv->store(undef);
    is( $mwdv->fetch,      'booya', "restore default by writing undef value in mandatory string" );
    is( $inst->needs_save, 1,       "verify instance needs_save status after restoring default value" );

    print join( "\n", $inst->list_changes("\n") ), "\n" if $trace;
    $inst->clear_changes;
}

note "test mandatory boolean";
{
    my $mb = $root->fetch_element('mandatory_boolean');
    ok( $mb, "created mandatory_boolean" );

    throws_ok { my $v = $mb->fetch; } 'Config::Model::Exception::User',
        "mandatory bounded: undef error";
    print "normal error:\n", $@, "\n" if $trace;

    check_store_error( $mb, 'toto', qr/is not boolean/ );

    check_store_error( $mb, 2, qr/is not boolean/ );

    my @bool_test = ( 1, 1, yes => 1, Yes => 1, no => 0, Nope => 0, true => 1, False => 0 );

    while (@bool_test) {
        my $store = shift @bool_test;
        my $read  = shift @bool_test;

        $mb->store($store);

        is( $mb->fetch, $read, "mandatory boolean: store $store and read $read value" );
    }
}

note "test boolean where values are translated to true/false";

{
    $inst->clear_changes;
    my $bwwa = $root->fetch_element('boolean_with_write_as');
    is( $bwwa->fetch, undef, "boolean_with_write_as reads undef" );
    $bwwa->store('no');
    is( $bwwa->fetch, 'false', "boolean_with_write_as returns 'false'" );
    is( $inst->needs_save, 1, "check needs_save after writing 'boolean_with_write_as'" );

    my @changes = "boolean_with_write_as has new value: 'false'";
    eq_or_diff([$inst->list_changes],\@changes,
               "check change message after writing 'boolean_with_write_as'");

    $bwwa->store('false');
    is( $inst->needs_save, 1, "check needs_save after writing twice 'boolean_with_write_as'" );

    $bwwa->store(1);
    is( $bwwa->fetch, 'true', "boolean_with_write_as returns 'true'" );

    push @changes, "boolean_with_write_as: 'false' -> 'true'";
    eq_or_diff([$inst->list_changes], \@changes,
               "check change message after writing 'boolean_with_write_as'");
    my $bwwaad = $root->fetch_element('boolean_with_write_as_and_default');
    is( $bwwa->fetch, 'true', "boolean_with_write_as_and_default reads true" );
}

{
    my $bwwaad = $root->fetch_element('boolean_with_write_as_and_default');
    is( $bwwaad->fetch, 'true', "boolean_with_write_as_and_default reads true" );

    throws_ok { $bad_root->fetch_element('crooked_enum'); }
        'Config::Model::Exception::Model',
        "test create expected failure with enum with wrong default";
    print "normal error:\n", $@, "\n" if $trace;
}

note "test enum";
{
    my $de = $root->fetch_element('enum');
    ok( $de, "Created enum with correct default" );

    $inst->clear_changes;

    is( $de->fetch, 'A', "enum with default: read default value" );

    is( $inst->needs_save, 1, "check needs_save after reading a default value" );
    $inst->clear_changes;

    $de->store('A');            # emulate config file read
    is( $inst->needs_save, 0,   "check needs_save after storing a value identical to default value" );
    is( $de->fetch,        'A', "enum with default: read default value" );
    is( $inst->needs_save, 0,   "check needs_save after reading a default value" );

    print "enum with default: read custom\n" if $trace;
    is( $de->fetch_custom, undef, "enum with default: read custom value" );

    $de->store('B');
    is( $de->fetch,          'B', "enum: store and read B" );
    is( $de->fetch_custom,   'B', "enum: read custom value" );
    is( $de->fetch_standard, 'A', "enum: read standard value" );

    ## check model data
    is( $de->value_type, 'enum', "enum: check value_type" );

    eq_array( $de->choice, [qw/A B C/], "enum: check choice" );

    ok( $de->set_properties( default => 'B' ), "enum: warping default value" );
    is( $de->default(), 'B', "enum: check new default value" );

    throws_ok { $de->set_properties( default => 'F' ) }
        'Config::Model::Exception::Model',
        "enum: warped default value to wrong value";
    print "normal error:\n", $@, "\n" if $trace;

    ok( $de->set_properties( choice => [qw/A B C D/] ), "enum: warping choice" );

    ok( $de->set_properties( choice => [qw/A B C D/], default => 'D' ),
        "enum: warping default value to new choice" );

    ok(
        $de->set_properties( choice => [qw/F G H/], default => undef ),
        "enum: warping choice to completely different set"
    );

    is( $de->default(), undef, "enum: check that new default value is undef" );

    is( $de->fetch, undef, "enum: check that new current value is undef" );

    $de->store('H');
    is( $de->fetch(), 'H', "enum: set and read a new value" );
}

note "test uppercase conversion";
{
    my $uc_c = $root->fetch_element('uc_convert');
    ok( $uc_c, "testing convert => uc" );
    $uc_c->store('coucou');
    is( $uc_c->fetch(), 'COUCOU', "uc_convert: testing" );
}

note "test lowercase conversion";
{
    my $lc_c = $root->fetch_element('lc_convert');
    ok( $lc_c, "testing convert => lc" );
    $lc_c->store('coUcOu');
    is( $lc_c->fetch(), 'coucou', "lc_convert: testing" );
}

note "Testing integrated help";
{
    my $value_with_help = $root->fetch_element('enum_with_help');
    my $full_help       = $value_with_help->get_help;

    is( $full_help->{a},                 'a help', "full enum help" );
    is( $value_with_help->get_help('a'), 'a help', "enum help on one choice" );
    is( $value_with_help->get_help('b'), undef,    "test undef help" );

    is( $value_with_help->fetch, undef, "test undef enum" );
}

note "Testing upstream default value";
{
    my $up_def = $root->fetch_element('upstream_default');

    is( $up_def->fetch,                         undef,    "upstream actual value" );
    is( $up_def->fetch_standard,                'up_def', "upstream standard value" );
    is( $up_def->fetch('upstream_default'),     'up_def', "upstream actual value" );
    is( $up_def->fetch('non_upstream_default'), undef,    "non_upstream value" );
    is( $up_def->has_data, 0, "does not have data");

    $up_def->store('yada');
    is( $up_def->fetch('upstream_default'),     'up_def', "after store: upstream actual value" );
    is( $up_def->fetch('non_upstream_default'), 'yada',   "after store: non_upstream value" );
    is( $up_def->fetch,                         'yada',   "after store: upstream actual value" );
    is( $up_def->fetch('standard'),             'up_def', "after store: upstream standard value" );
    is( $up_def->has_data, 1, "has data");
}

note "test uniline type";
{
    my $uni = $root->fetch_element('a_uniline');
    check_error( $uni, "foo\nbar", qr/value must not contain embedded newlines/ );

    $uni->store("foo bar");
    is( $uni->fetch, "foo bar", "tested uniline value" );

    is( $inst->errors()->{'a_uniline'}, undef, "check that error was deleted by correct store" );

    $uni->store('');
    is( $uni->fetch, '', "tested empty value" );
}

note "testing replace feature";
{
    my $wrepl = $root->fetch_element('with_replace');
    $wrepl->store('c1');
    is( $wrepl->fetch, "c", "tested replaced value" );

    $wrepl->store('foo/bar');
    is( $wrepl->fetch, "b", "tested replaced value with regexp" );
}

note "test preset feature";
{
    my $pinst = $model->instance(
        root_class_name => 'Master',
        instance_name   => 'preset_test'
    );
    ok( $pinst, "created dummy preset instance" );

    my $p_root = $pinst->config_root;

    $pinst->preset_start;
    ok( $pinst->preset, "instance in preset mode" );

    my $p_scalar = $p_root->fetch_element('scalar');
    $p_scalar->store(3);

    my $p_enum = $p_root->fetch_element('enum');
    $p_enum->store('B');

    $pinst->preset_stop;
    is( $pinst->preset, 0, "instance in normal mode" );

    is( $p_scalar->fetch, 3, "scalar: read preset value as value" );
    $p_scalar->store(4);
    is( $p_scalar->fetch,           4, "scalar: read overridden preset value as value" );
    is( $p_scalar->fetch('preset'), 3, "scalar: read preset value as preset_value" );
    is( $p_scalar->fetch_standard,  3, "scalar: read preset value as standard_value" );
    is( $p_scalar->fetch_custom,    4, "scalar: read custom_value" );

    is( $p_enum->fetch, 'B', "enum: read preset value as value" );
    $p_enum->store('C');
    is( $p_enum->fetch,           'C', "enum: read overridden preset value as value" );
    is( $p_enum->fetch('preset'), 'B', "enum: read preset value as preset_value" );
    is( $p_enum->fetch_standard,  'B', "enum: read preset value as standard_value" );
    is( $p_enum->fetch_custom,    'C', "enum: read custom_value" );
    is( $p_enum->default,         'A', "enum: read default_value" );
}

note "test layered feature";
{
    my $layer_inst = $model->instance(
        root_class_name => 'Master',
        instance_name   => 'layered_test'
    );
    ok( $layer_inst, "created dummy layered instance" );

    my $l_root = $layer_inst->config_root;

    $layer_inst->layered_start;
    ok( $layer_inst->layered, "instance in layered mode" );

    my $l_scalar = $l_root->fetch_element('scalar');
    $l_scalar->store(3);

    my $l_enum = $l_root->fetch_element('bare_enum');
    $l_enum->store('B');

    my $msl = $l_root->fetch_element('mandatory_string');
    $msl->store('plop');

    $layer_inst->layered_stop;
    is( $layer_inst->layered, 0, "instance in normal mode" );

    is( $l_scalar->fetch, undef, "scalar: read layered value as backend value" );
    is( $l_scalar->fetch( mode => 'user' ), 3, "scalar: read layered value as user value" );
    is( $l_scalar->has_data, 0, "scalar: has no data" );
    is( $l_scalar->fetch(mode => 'non_upstream_default'), 3,
        "scalar: read non upstream default value before store" );
    $l_scalar->store(4);
    is( $l_scalar->fetch,            4, "scalar: read overridden layered value as value" );
    is( $l_scalar->fetch('layered'), 3, "scalar: read layered value as layered_value" );
    is( $l_scalar->fetch_standard,   3, "scalar: read standard_value" );
    is( $l_scalar->fetch(mode => 'non_upstream_default'), 4,
        "scalar: read non upstream default value after store" );
    is( $l_scalar->fetch_custom,     4, "scalar: read custom_value" );
    is( $l_scalar->has_data,         1, "scalar: has data" );

    is( $l_enum->fetch, undef, "enum: read layered value as backend value" );
    is( $l_enum->fetch( mode => 'user' ), 'B', "enum: read layered value as user value" );
    is( $l_enum->has_data, 0, "enum: has no data" );
    $l_enum->store('C');
    is( $l_enum->fetch,            'C', "enum: read overridden layered value as value" );
    is( $l_enum->fetch('layered'), 'B', "enum: read layered value as layered_value" );
    is( $l_enum->fetch_standard,   'B', "enum: read layered value as standard_value" );
    is( $l_enum->fetch_custom,     'C', "enum: read custom_value" );
    is( $l_enum->has_data, 1, "enum: has data" );

    is($msl->fetch('layered'), 'plop',"check mandatory value in layer");
    is($msl->fetch, undef,"check mandatory value backend mode");
    is($msl->fetch('user'), 'plop',"check mandatory value user mode with layer");
}

note "test match regexp";
{
    my $match = $root->fetch_element('match');

    check_error( $match, 'bar', qr/does not match/ );

    $match->store('foo42/');
    is( $match->fetch, 'foo42/', "test stored matching value" );
}

note "test validation done with a Parse::RecDescent grammar";
{
    my $prd_match = $root->fetch_element('prd_match');

    check_error( $prd_match, 'bar',  qr/does not match grammar/ );
    check_error( $prd_match, 'Perl', qr/does not match grammar/ );
    $root->fetch_element('prd_test_action')->store('Perl CC-BY Apache');

    foreach my $prd_test ( ( 'Perl', 'Perl and CC-BY', 'Perl and CC-BY or Apache' ) ) {
        $prd_match->store($prd_test);
        is( $prd_match->fetch, $prd_test, "test stored prd value $prd_test" );
    }
}

note "test warn_if_match with a string";
{
    my $wim = $root->fetch_element('warn_if_match');
    warning_like { $wim->store('foobar'); } qr/should not match/, "test warn_if condition";

    is( $wim->has_fixes, 1, "test has_fixes" );

    is( $wim->fetch( check => 'no', silent => 1 ), 'foobar', "check warn_if stored value" );
    is( $wim->has_fixes, 1, "test has_fixes after fetch with check=no" );

    is( $wim->fetch( mode => 'standard' ), undef, "check warn_if standard value" );
    is( $wim->has_fixes, 1, "test has_fixes after fetch with mode = standard" );

    ### test fix included in model
    $wim->apply_fixes;
    is( $wim->fetch, 'FOOBAR', "test if fixes were applied" );
}

note "test warn_if_match with a regexp";
{
    my $win = $root->fetch_element('warn_if_number');
    warning_like { $win->store('bar51'); } qr/should not have numbers/, "test warn_if condition";

    is( $win->has_fixes, 1, "test has_fixes" );
    $win->apply_fixes;
    is( $win->fetch, 'bar', "test if fixes were applied" );
}

note "test warn_unless_match feature";
{
    my $wup = $root->fetch_element('warn_unless_match');
    warning_like { $wup->store('bar'); } qr/should match/, "test warn_unless_match condition";

    is( $wup->has_fixes, 1, "test has_fixes" );
    $wup->apply_fixes;
    is( $wup->fetch, 'foobar', "test if fixes were applied" );
}

note "test unconditional feature";
{
    my $aw = $root->fetch_element('always_warn');
    warning_like { $aw->store('whatever'); } qr/always/i, "got unconditional warning";
}

note "test warning and repeated storage in same element";
{
    my $aw = $root->fetch_element('always_warn');
    warning_like { $aw->store('what ?'); } qr/always/i, "got unconditional warning";
    warning_is { $aw->store('what ?'); } undef, "no warning when repeating a store with same value";
    warning_like { $aw->store('what never'); } qr/always/i, "got unconditional warning when storing a changed value";
}

note "test unicode";
{
    my $wip = $root->fetch_element('warn_if_match');
    my $smiley = "\x{263A}";    # See programming perl chapter 15
    $wip->store(':-)');         # to test list_changes just below
    $wip->store($smiley);
    is( $wip->fetch, $smiley, "check utf-8 string" );
}

print join( "\n", $inst->list_changes("\n") ), "\n" if $trace;

note "test replace_follow";
{
    my $wrf = $root->fetch_element('with_replace_follow');
    $inst->clear_changes;

    $wrf->store('foo');
    is( $inst->needs_save, 1, "check needs_save after store" );
    $inst->clear_changes;

    is( $wrf->fetch,       'foo', "check replacement_hash with foo (before replacement)" );
    is( $inst->needs_save, 0,     "check needs_save after simple fetch" );

    $root->load('replacement_hash:foo=repfoo replacement_hash:bar=repbar');
    is( $inst->needs_save, 2, "check needs_save after load" );
    $inst->clear_changes;

    is( $wrf->fetch,       'repfoo', "check replacement_hash with foo (after replacement)" );
    is( $inst->needs_save, 1,        "check needs_save after fetch with replacement" );

    $wrf->store('bar');
    is( $wrf->fetch, 'repbar', "check replacement_hash with bar" );

    $wrf->store('baz');
    is( $wrf->fetch, 'baz', "check replacement_hash with baz (no replacement)" );

    ok(
        !$root->fetch_element('replacement_hash')->exists('baz'),
        "check that replacement hash was not changed by missed substitution"
    );

    $inst->clear_changes;
}

{
    my $sv = $root->fetch_element('Standards-Version');
    warning_like { $sv->store('3.9.1'); } qr/Current/, "store old standard version";
    is( $inst->needs_save, 1, "check needs_save after load" );
    $sv->apply_fixes;
    is( $inst->needs_save, 2, "check needs_save after load" );
    print join( "\n", $inst->list_changes("\n") ), "\n" if $trace;

    is( $sv->fetch, '3.9.2', "check fixed standard version" );

    is( $sv->fetch( mode => 'custom' ), undef, "check custom standard version" );
}

note "test assert";
{
    my $assert_elt = $root->fetch_element('assert');
    throws_ok { $assert_elt->fetch(); } 'Config::Model::Exception::WrongValue', "check assert error";

    $assert_elt->apply_fixes;
    ok( 1, "assert_elt apply_fixes called" );
    is( $assert_elt->fetch, 'foobar', "check fixed assert pb" );
}

note "test warn_unless";
{
    my $warn_unless = $root->fetch_element('warn_unless');

    warning_like { $warn_unless->fetch(); } qr/should not be empty/, "check warn_unless";

    $warn_unless->apply_fixes;
    ok( 1, "warn_unless apply_fixes called" );
    is( $warn_unless->fetch, 'foobar', "check fixed warn_unless pb" );
}

note "test warn_unless_file";
{
    my $warn_unless_file = $root->fetch_element('warn_unless_file');

    warning_like { $warn_unless_file->store('not-value.t'); } qr/file not-value.t should exist/, "check warn_unless_file";

    $warn_unless_file->apply_fixes;
    ok( 1, "warn_unless_file apply_fixes called" );
    is( $warn_unless_file->fetch, 'value.t', "check fixed warn_unless_file" );
}

note "test file and dir value types" ;
{
    my $t_file = $root->fetch_element('t_file');
    my $t_dir  = $root->fetch_element('t_dir');
    warning_like {$t_file->store('toto')} qr/not exist/, "test non existent file" ;
    warning_like {$t_file->store('t')} qr/not a file/, "test not a file" ;
    warning_like {$t_dir->store('t/value.t')} qr/not a dir/, "test not a dir" ;

    $t_file->store('t/value.t') ;
    is($t_file->has_warning, 0, "test a file");

    $t_dir->store('t/') ;
    is($t_dir->has_warning, 0, "test a dir");

}

note "test problems during initial load";
{
    my $inst2 = $model->instance(
        root_class_name => 'Master',
        instance_name   => 'initial_test'
    );
    ok( $inst2, "created initial_test inst2ance" );

    # is triggered internally only when at least one node has a RW backend
    $inst2->initial_load_start;

    my $s = $inst2->config_root->fetch_element('string');
    $s->store('foo');
    $s->store('foo');


    is( $inst2->needs_save, 1, "verify instance needs_save status after redundant data" );

    eq_or_diff([$inst2->list_changes],['string: removed redundant initial value'],"check change message for redundant data");
    $inst2->clear_changes;
    is( $inst2->needs_save, 0, "needs_save after clearing changes" );

    $s->store('bar');
    eq_or_diff([$inst2->list_changes],['string: \'foo\' -> \'bar\' # conflicting initial values'],"check change message for redundant data");
    is( $inst2->needs_save, 1, "verify instance needs_save status after conflicting data" );

    $inst2->clear_changes;
    $s->parent->fetch_element('uc_convert')->store('foo');
    eq_or_diff([$inst2->list_changes],['uc_convert: \'foo\' -> \'FOO\' # initial value changed by model'],
               "check change message when model changes data coming from config file");

    $inst2->clear_changes;
    $s->parent->fetch_element('boolean_with_write_as')->store('true');
    is( $inst2->needs_save, 0, "verify instance needs_save status after writing 'boolean_with_write_as'" );

    $inst2->initial_load_stop;
}

memory_cycle_ok( $model, "check memory cycles" );

done_testing;
