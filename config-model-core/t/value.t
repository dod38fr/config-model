# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 115;
use Test::Exception ;
use Test::Warn ;
use Config::Model ;
use Config::Model::Value;

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"Compilation done");

# minimal set up to get things working
my $model = Config::Model->new();
$model->create_config_class(
    name    => "Master",
    element => [
        crooked => {
            type  => 'leaf',
            class => 'Config::Model::Value',
        },
        scalar => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'integer',
            min        => 1,
            max        => 4,
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
        crooked_enum => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'enum',
            default    => 'foo',
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
            type => 'hash',
            index_type => 'string',
            cargo => {
                type => 'leaf',
                value_type => 'uniline',
            },
        },
        with_replace_follow => {
            type       => 'leaf',
            value_type => 'string',
            replace_follow => '- replacement_hash',
        },
        match => {
            type       => 'leaf',
            value_type => 'string',
            match      => '^foo\d{2}$',
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
        warn_if => {
            type          => 'leaf',
            value_type    => 'string',
            warn_if_match => { 'foo' => { fix => '$_ = uc;' } },
        },
        warn_unless => {
            type       => 'leaf',
            value_type => 'string',
            warn_unless_match =>
              { foo => { msg => '', fix => '$_ = "foo".$_;' } },
        },
        always_warn => {
            type       => 'leaf',
            value_type => 'string',
            warn       => 'Always warn whenever used',
        },
    ],    # dummy class
);

my $inst = $model->instance (root_class_name => 'Master', 
				 instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $result ;

throws_ok {$root->fetch_element('crooked') ; } 'Config::Model::Exception::Model',
    "test create expected failure" ;
print "normal error:\n", $@, "\n" if $trace;

my $i = $root->fetch_element('scalar') ;
ok($i,"test create bounded integer") ;

ok( $i->store( 1),"store test" );
is( $i->fetch, 1, "fetch test" );

throws_ok { $i->store(  5); }  'Config::Model::Exception::User',
    "bounded integer: max error" ;
print "normal error:\n", $@, "\n" if $trace;

throws_ok { $i->store( 'toto'); }  'Config::Model::Exception::User',
    "bounded integer: string error";
print "normal error:\n", $@, "\n" if $trace;

throws_ok { $i->store( 1.5 ); }  'Config::Model::Exception::User',
    "bounded integer: number error";
print "normal error:\n", $@, "\n" if $trace;


my $nb = $root->fetch_element('bounded_number');
ok($nb,"created ".$nb->name) ;

ok($nb->store(1)  ,"assign 1") ;
ok($nb->store(1.5),"assign 1.5") ;

throws_ok { $i->store( 'toto' ); }  'Config::Model::Exception::User',
    "bounded integer: string error";
print "normal error:\n", $@, "\n" if $trace;

$nb->store(undef);
ok( defined $nb->fetch() ? 0: 1  ,"store undef") ;


my $ms = $root->fetch_element('mandatory_string') ;
ok($ms,"created mandatory_string") ;

throws_ok { my $v = $ms->fetch; }  'Config::Model::Exception::User',
    "mandatory string: undef error" ;
print "normal error:\n", $@, "\n" if $trace;

is( $ms->store('toto'),'toto',"mandatory_string: store" );
is($ms->fetch,'toto'  ,"and read");


my $mb = $root->fetch_element('mandatory_boolean') ;
ok($mb,"created mandatory_boolean") ;

throws_ok { my $v = $mb->fetch; }  'Config::Model::Exception::User',
    "mandatory bounded: undef error" ;
print "normal error:\n", $@, "\n" if $trace;

throws_ok { $mb->store('toto'); }  'Config::Model::Exception::User',
    "mandatory bounded: store string error" ;
print "normal error:\n", $@, "\n" if $trace;

throws_ok { $mb->store(2); }  'Config::Model::Exception::User',
    "mandatory bounded: store 2 error" ;
print "normal error:\n", $@, "\n" if $trace;

ok( $mb->store(1), "mandatory boolean: set to 1" );

ok($mb->fetch, "mandatory boolean: read");

print "mandatory boolean: set to yes\n" if $trace;
ok( $mb->store('yes'), "mandatory boolean: set to yes" );
is( $mb->fetch, 1, "and read" );

print "mandatory boolean: set to Yes\n" if $trace;
ok( $mb->store('Yes'), "mandatory boolean: set to Yes" );
is( $mb->fetch, 1, "and read" );

print "mandatory boolean: set to no\n" if $trace;
is( $mb->store('no'),  0, "mandatory boolean: set to no" );
is( $mb->fetch, 0, "and read" );

print "mandatory boolean: set to Nope\n" if $trace;
is( $mb->store('Nope'), 0, "mandatory boolean: set to Nope" );
is( $mb->fetch,0, "and read" );

print "mandatory boolean: set to true\n" if $trace;
is( $mb->store('true'), 1,"mandatory boolean: set to true" );
is( $mb->fetch, 1, "and read" );

print "mandatory boolean: set to False\n" if $trace;
is( $mb->store('False'), 0, "mandatory boolean: set to False" );
is( $mb->fetch,0, "and read" );

throws_ok {$root->fetch_element('crooked_enum') ; } 
    'Config::Model::Exception::Model',
    "test create expected failure with enum with wrong default";
print "normal error:\n", $@, "\n" if $trace;



my $de = $root->fetch_element('enum') ;
ok($de,"Created enum with correct default") ;

throws_ok { $mb->store('toto'); }  'Config::Model::Exception::User',
    "enum: store 'toto' error" ;
print "normal error:\n", $@, "\n" if $trace;

is( $de->fetch, 'A' ,"enum with default: read default value" );

print "enum with default: read custom\n" if $trace;
is( $de->fetch_custom ,undef, "enum with default: read custom value" );

is( $de->store('B'),'B',"enum: store B" );
is( $de->fetch_custom, 'B', "enum: read custom value" );
is( $de->fetch_standard, 'A', "enum: read standard value" );


## check model data
is( $de->value_type, 'enum',"enum: check value_type" );

eq_array( $de->choice , [qw/A B C/],"enum: check choice"  );

ok( $de->set_properties( default => 'B' ), "enum: warping default value" );
is( $de->default(), 'B',"enum: check new default value" );

throws_ok { $de->set_properties( default => 'F' )}
    'Config::Model::Exception::Model',
    "enum: warped default value to wrong value" ;
print "normal error:\n", $@, "\n" if $trace;

ok( $de->set_properties( choice => [qw/A B C D/] ),"enum: warping choice" );

ok( $de->set_properties( choice => [qw/A B C D/], default => 'D' ), 
    "enum: warping default value to new choice" );

ok( $de->set_properties( choice => [qw/F G H/], default => undef ),
  "enum: warping choice to completely different set");

is( $de->default(), undef, "enum: check that new default value is undef" );

is( $de->fetch, undef, "enum: check that new current value is undef" );

is( $de->store('H'), 'H', "enum:  set a new value");


###

my $uc_c = $root -> fetch_element('uc_convert');
ok($uc_c, "testing convert => uc");
is( $uc_c->store('coucou'), 'COUCOU', "uc_convert: testing store");
is( $uc_c->fetch(),         'COUCOU', "uc_convert: testing read");

my $lc_c = $root -> fetch_element('lc_convert');
ok($lc_c, "testing convert => lc");
is( $lc_c->store('coUcOu'), 'coucou', "lc_convert: testing store");
is( $lc_c->fetch(),         'coucou', "lc_convert: testing read");



print "Testing integrated help\n" if $trace;

my $value_with_help = $root->fetch_element('enum_with_help');
my $full_help = $value_with_help->get_help;

is( $full_help->{a}, 'a help',"full enum help" );
is( $value_with_help->get_help( 'a' ), 'a help',"enum help on one choice") ;
is( $value_with_help->get_help('b'), undef ,"test undef help");

is( $value_with_help->fetch, undef, "test undef enum") ;

print "Testing upstream default value\n" if $trace ;

my $up_def = $root->fetch_element('upstream_default');

is( $up_def->fetch,                undef,    "upstream actual value" );
is( $up_def->fetch_standard,       'up_def' ,"upstream standard value" );
is( $up_def->fetch('upstream_default'),    'up_def' ,"upstream actual value" );
is( $up_def->fetch('non_upstream_default'),undef ,   "non_upstream value" );

$up_def->store('yada');
is( $up_def->fetch('upstream_default'),    'up_def' ,"after store: upstream actual value" );
is( $up_def->fetch('non_upstream_default'),'yada' ,  "after store: non_upstream value" );
is( $up_def->fetch,                'yada',   "after store: upstream actual value" );
is( $up_def->fetch('standard'),    'up_def' ,"after store: upstream standard value" );

###

my $uni = $root->fetch_element('a_uniline') ;
throws_ok { $uni->store("foo\nbar");} 'Config::Model::Exception::User',
    "uniline: tried to store a multi line" ;
print "normal error:\n", $@, "\n" if $trace;

$uni->store("foo bar");
is($uni->fetch, "foo bar","tested uniline value") ;

### test replace feature
my $wrepl =  $root->fetch_element('with_replace') ;
$wrepl -> store ('c1') ;
is($wrepl->fetch, "c","tested replaced value") ;

$wrepl -> store ('foo/bar') ;
is($wrepl->fetch, "b","tested replaced value with regexp") ;

### test preset feature

my $pinst = $model->instance (root_class_name => 'Master', 
			      instance_name => 'preset_test');
ok($pinst,"created dummy preset instance") ;

my $p_root = $pinst -> config_root ;

$pinst->preset_start ;
ok($pinst->preset,"instance in preset mode") ;

my $p_scalar = $p_root->fetch_element('scalar') ;
$p_scalar -> store(3) ;

my $p_enum = $p_root->fetch_element('enum') ;
$p_enum -> store ('B') ;

$pinst->preset_stop ;
is($pinst->preset,0,"instance in normal mode") ;

is($p_scalar->fetch,3,"scalar: read preset value as value") ;
$p_scalar -> store(4) ;
is($p_scalar->fetch,4,"scalar: read overridden preset value as value") ;
is($p_scalar->fetch('preset'),3,"scalar: read preset value as preset_value") ;
is($p_scalar->fetch_standard,3,"scalar: read preset value as standard_value") ;
is($p_scalar->fetch_custom,4,"scalar: read custom_value") ;

is($p_enum->fetch,'B',"enum: read preset value as value") ;
$p_enum -> store('C') ;
is($p_enum->fetch,'C',"enum: read overridden preset value as value") ;
is($p_enum->fetch('preset'),'B',"enum: read preset value as preset_value") ;
is($p_enum->fetch_standard,'B',"enum: read preset value as standard_value") ;
is($p_enum->fetch_custom,'C',"enum: read custom_value") ;
is($p_enum->default,'A',"enum: read default_value") ;

warning_like { $p_enum->store('foobar', check => 'skip' ) ; } 
    qr/skipping value/, "test that errors are displayed as warnings with check = skip" ;

### test match regexp
my $match = $root->fetch_element('match') ;
throws_ok { $match->store('bar');} 'Config::Model::Exception::WrongValue',
    'match value: test for non matching value';

$match->store('foo42') ;
is($match->fetch, 'foo42',"test stored matching value") ;

### test match and check stuff
is($match->store(qw/value bar check no/),'bar',"force storage of wrong value");
is($match->fetch(qw/check no silent 1/),'bar',"read forced wrong value");

### test Parse::RecDescent validation
my $prd_match = $root->fetch_element('prd_match') ;
throws_ok { $prd_match->store('bar');} 'Config::Model::Exception::WrongValue',
    'match value: test for non matching grammar';
throws_ok { $prd_match->store('Perl');} 'Config::Model::Exception::WrongValue',
    'match value: test for non matching grammar';
$root->fetch_element('prd_test_action')->store('Perl CC-BY Apache');

throws_ok { $prd_match->store('bar');} 'Config::Model::Exception::WrongValue',
    'match value: test for non matching grammar';
is($prd_match->store(qw/value bar check no/),'bar',"force storage of wrong value");
is($prd_match->fetch(qw/check no silent 1/),'bar',"read forced wrong value");


foreach my $prd_test (('Perl','Perl and CC-BY', 'Perl and CC-BY or Apache')) {
    $prd_match->store($prd_test) ;
    is($prd_match->fetch, $prd_test,"test stored prd value $prd_test") ;
}

### test warn_if parameter
my $wip = $root->fetch_element('warn_if') ;
warning_like {$wip->store('foobar');} qr/should not match/, "test warn_if condition" ;

### test fix included in model
is($wip -> has_fixes,1,"test has_fixes") ;
$wip->apply_fixes ;
is($wip -> fetch,'FOOBAR',"test if fixes were applied") ;


### test warn_unless parameter
my $wup = $root->fetch_element('warn_unless') ;
warning_like {$wup->store('bar');} qr/should match/, "test warn_unless condition" ;

is($wup -> has_fixes,1,"test has_fixes") ;
$wup->apply_fixes ;
is($wup -> fetch,'foobar',"test if fixes were applied") ;

### test always_warn parameter
my $aw = $root->fetch_element('always_warn') ;
warning_like {$aw->store('whatever');} qr/always/i, "test unconditional warn" ;

# test unicode
my $smiley = "\x{263A}" ; # See programming perl chapter 15
$wip -> store($smiley) ;
is($wip->fetch,$smiley,"check utf-8 string");

# test replace_follow
$root->load('replacement_hash:foo=repfoo replacement_hash:bar=repbar');
my $wrf = $root->fetch_element('with_replace_follow');
$wrf->store('foo') ;
is($wrf->fetch,'repfoo',"check replacement_hash with foo");

$wrf->store('bar') ;
is($wrf->fetch,'repbar',"check replacement_hash with bar");

$wrf->store('baz') ;
is($wrf->fetch,'baz',"check replacement_hash with baz (no replacement)");

ok( ! $root->fetch_element('replacement_hash')->exists('baz'), 
    "check that replacement hash was not changed by missed substitution") ;