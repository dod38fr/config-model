# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Test::Warn ;
use Config::Model ;
use Log::Log4perl qw(:easy) ;

BEGIN { plan tests => 47; }

use strict;

my $arg = shift || '';

my $log = 0;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($arg =~ /l/ ? $DEBUG: $WARN);
}

ok(1,"Compilation done");


my $model = Config::Model->new() ;
$model->create_config_class(
    name    => "Slave",
    element => [
        find_node_element_name => {
            type       => 'leaf',
            value_type => 'string',
            compute    => {
                formula   => '&element(-)',
            },
        },
        location_function_in_formula => {
            type       => 'leaf',
            value_type => 'string',
            compute    => {
                formula   => '&location',
            },
        },
        check_node_element_name => {
            type       => 'leaf',
            value_type => 'boolean',
            compute    => {
                formula   => '"&element(-)" eq "foo2"',
            },
        },
        [qw/av bv/] => {
            type       => 'leaf',
            value_type => 'integer',
            compute    => {
                variables => { p => '! &element' },
                formula   => '$p',
            },
        },
    ]
);

$model->create_config_class(
    'name'    => 'LicenseSpec',
    'element' => [
        'text',
        {
            'value_type' => 'string',
            'type'       => 'leaf',
            'compute'    => {
                'replace' => { 
                    'GPL-1+' => "yada yada GPL-1+\nyada yada", 
                    'Artistic' => "yada yada Artistic\nyada yada", 
                },
                'formula'        => '$replace{&index(-)}',
                'allow_override' => '1',
                undef_is => '',
            },
        },
        short_name_from_index => {
            'type'       => 'leaf',
            'value_type' => 'string',
            compute => {
                'formula' => '&index( - );',
                'use_eval' => 1,
            },
        }
    ]
);

$model->create_config_class(
    name    => "Master",
    element => [
        [qw/av bv/] => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'integer',
        },
        compute_int => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'integer',
            compute    => {
                formula   => '$a + $b',
                variables => { a => '- av', b => '- bv' }
            },
            min => -4,
            max => 4,
        },
        [qw/sav sbv/] => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'string',
        },
        one_var => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'string',
            compute    => {
                formula   => '&element().$bar',
                variables => { bar => '- sbv' }
            },
          },
        one_wrong_var => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'string',
            compute    => {
                formula   => '$bar',
                variables => { bar => '- wrong_v' }
            },
        },
        meet_test => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'string',
            compute    => {
                formula   => 'meet $a and $b',
                variables => { a => '- sav', b => '- sbv' }
            },
        },
        compute_with_override => {
            type       => 'leaf',
            class      => 'Config::Model::Value',
            value_type => 'integer',
            compute    => {
                formula        => '$a + $b',
                variables      => { a => '- av', b => '- bv' },
                allow_override => 1,
            },
            min => -4,
            max => 4,
        },
        compute_no_var => {
            type       => 'leaf',
            value_type => 'string',
            compute    => { formula => '&element()', },
        },
        [qw/bar foo2/] => {
            type              => 'node',
            config_class_name => 'Slave'
        },

        'url' => {
            type       => 'leaf',
            value_type => 'uniline',
        },
        'host' => {
            type       => 'leaf',
            value_type => 'uniline',
            compute    => {
                formula   => '$url =~ m!http://([\w\.]+)!; $1 ;',
                variables => { url => '- url' },
                use_eval  => 1,
            },
        },
         'with_tmp_var' => {
            type       => 'leaf',
            value_type => 'uniline',
            compute    => {
                formula   => 'my $tmp = $url; $tmp =~ m!http://([\w\.]+)!; $1 ;',
                variables => { url => '- url' },
                use_eval  => 1,
            },
        },
       'Upstream-Contact' => {
            'cargo' => {
                'value_type'   => 'uniline',
                'migrate_from' => {
                    'formula'   => '$maintainer',
                    'variables' => {
                        'maintainer' => '- Upstream-Maintainer:&index'
                    }
                },
                'type' => 'leaf'
            },
            'type' => 'list',
        },
        'Upstream-Maintainer' => {
            'cargo' => {
                'value_type'   => 'uniline',
                'migrate_from' => {
                    'formula'   => '$maintainer',
                    'variables' => {
                        'maintainer' => '- Maintainer:&index'
                    }
                },
                'type' => 'leaf'
            },
            'status' => 'deprecated',
            'type'   => 'list'
        },
        'Maintainer' => {
            'cargo' => {
                'value_type' => 'uniline',
                'type'       => 'leaf'
            },
            'status' => 'deprecated',
            'type'   => 'list',
        },
        'Source' => {
            'value_type'   => 'string',
            'mandatory'    => '1',
            'migrate_from' => {
                'use_eval'  => '1',
                'formula'   => '$old || $older ;',
                undef_is => "''",
                'variables' => {
                    'older' => '- Original-Source-Location',
                    'old'   => '- Upstream-Source'
                }
            },
            'type' => 'leaf',
        },
         'Source2' => {
            'value_type'   => 'string',
            'mandatory'    => '1',
            'compute' => {
                'use_eval'  => '1',
                'formula'   => '$old || $older ;',
                undef_is => "''",
                'variables' => {
                    'older' => '- Original-Source-Location',
                    'old'   => '- Upstream-Source'
                }
            },
            'type' => 'leaf',
        },
       [qw/Upstream-Source Original-Source-Location/] => {
            'value_type' => 'string',
            'status'     => 'deprecated',
            'type'       => 'leaf'
        },
        Licenses => { 
            type => 'hash',
            index_type => 'string',
            cargo => { 
                type => 'node',
                config_class_name => 'LicenseSpec'
            }
        },
    ]
);

my $inst = $model->instance (root_class_name => 'Master', 
                             instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

# order is important. Do no use sort.
is_deeply([$root->get_element_name()],
          [qw/av bv compute_int sav sbv one_var one_wrong_var 
              meet_test compute_with_override compute_no_var bar 
              foo2 url host with_tmp_var Upstream-Contact Source Source2 Licenses/],
         "check available elements");

my ( $av, $bv, $compute_int );
$av=$root->fetch_element('av') ;
$bv=$root->fetch_element('bv') ;

ok($bv,"created av and bv values") ;

ok($compute_int = $root->fetch_element('compute_int'),
   "create computed integer value (av + bv)");

no warnings 'once';

my $parser = new Parse::RecDescent ($Config::Model::ValueComputer::compute_grammar) ;

use warnings 'once';

{
    no warnings qw/once/;
    $::RD_HINT  = 1 if $arg =~ /rdt?h/;
    $::RD_TRACE = 1 if $arg =~ /rdh?t/;
}

my $object = $root->fetch_element('one_var') ;
my $rules =  { 
              bar => '- sbv',
             } ;
my $srules = {
               bv => 'rbv' 
             };

my $ref = $parser->pre_value( '$bar', 1, $object, $rules , $srules );
is( $$ref, '$bar' , "test pre_compute parser on a very small formula: '\$bar'");

$ref = $parser->value( '$bar', 1, $object, $rules , $srules  );
is($$ref,undef,"test compute parser on a very small formula with undef variable") ;

$root->fetch_element('sbv')->store('bv') ;
$ref = $parser->value( '$bar', 1, $object, $rules  , $srules);
is( $$ref, 'bv', "test compute parser on a very small formula: '\$bar'");

$ref = $parser->pre_value( '$replace{$bar}', 1, $object, $rules , $srules );
is( $$ref, '$replace{$bar}',"test pre-compute parser with substitution" );

$ref = $parser->value( '$replace{$bar}', 1, $object, $rules , $srules );
is( $$ref, 'rbv', "test compute parser with substitution");

my $txt = 'my stuff is  $bar, indeed';
$ref = $parser->pre_compute( $txt, 1, $object, $rules , $srules );
is( $$ref, $txt,"test pre_compute parser with a string" );

$ref = $parser->compute( $txt, 1, $object, $rules  , $srules);
is( $$ref, 'my stuff is  bv, indeed',
  "test compute parser with a string" );

$txt = 'local stuff is element:&element!';
$ref = $parser->pre_compute( $txt, 1, $object, $rules , $srules );
is( $$ref, 'local stuff is element:one_var!',
  "test pre_compute parser with function (&element)");

# In fact, function is formula is handled only by pre_compute.
$ref = $parser->compute( $txt, 1, $object, $rules , $srules );
is( $$ref, $txt,
    "test compute parser with function (&element)");

## test integer formula
my $result = $compute_int->fetch; 
is ($result, undef,"test that compute returns undef with undefined variables" );

$av->store(1) ;
$bv->store(2) ;

$result = $compute_int->fetch ;
is($result, 3, "test result :  computed integer is $result (a: 1, b: 2)");


eval { $compute_int->store(4); };
ok($@,"test assignment to a computed value (normal error)" );
print "normal error:\n", $@, "\n" if $trace;

$result = $compute_int->fetch ;
is($result, 3, "result has not changed") ;

$bv->store(-2) ;
$result = $compute_int->fetch ;
is($result, -1 ,
   "test result :  computed integer is $result (a: 1, b: -2)");

ok($bv->store(4),"change bv value") ;
eval { $result = $compute_int->fetch; };
ok($@,"computed integer: computed value error");
print "normal error:\n", $@, "\n" if $trace;

is($compute_int->fetch(check => 0), undef, 
   "test result :  computed integer is undef (a: 1, b: -2)");

my $s = $root->fetch_element('meet_test') ;
$result = $s->fetch ;
is($result,undef,"test for undef variables in string") ;

my ($as,$bs) = ('Linus','his penguin') ;
$root->fetch_element('sav')->store($as) ;
$root->fetch_element('sbv')->store($bs) ;
$result = $s->fetch ;
is($result, 'meet Linus and his penguin',
  "test result :  computed string is '$result' (a: $as, b: $bs)") ;


print "test allow_compute_override\n" if $trace;

my $comp_over =  $root-> fetch_element('compute_with_override');
$bv->store(2) ;

is( $comp_over->fetch, 3, "test computed value" );
$comp_over->store(4);
is( $comp_over->fetch, 4, "test overridden value" );

my $owv = $root->fetch_element('one_wrong_var');
eval {$owv -> fetch ;} ;
ok($@,"expected failure with one_wrong_var");
print "normal error:\n", $@, "\n" if $trace;

my $cnv = $root->fetch_element('compute_no_var');
is( $cnv->fetch, 'compute_no_var', "test compute_no_var" );

my $foo2 = $root->fetch_element('foo2') ;
my $fen  = $foo2->fetch_element('find_node_element_name') ;
ok($fen,"created element find_node_element_name") ;
is($fen->fetch,'foo2',"did find node element name");

my $cen  = $foo2->fetch_element('check_node_element_name') ;
ok($cen,"created element check_node_element_name") ;
is($cen->fetch,1,"did check node element name");

my $slave_av = $root->fetch_element('bar')->fetch_element('av') ;
my $slave_bv = $root->fetch_element('bar')->fetch_element('bv') ;

is($slave_av->fetch,$av->fetch,"compare slave av and av") ;
is($slave_bv->fetch,$bv->fetch,"compare slave bv and bv") ;

$root->fetch_element('url')->store('http://foo.bar/baz.html');

my $h = $root->fetch_element('host');

is($h->fetch,'foo.bar',"check extracted host") ;

$root->fetch_element(name => 'Maintainer', check => 'no')->store_set([qw/foo bar baz/] );
is($root->grab_value(step => 'Upstream-Maintainer:0', check => 'no'),'foo',"check compute with index in variable");
is($root->grab_value(step => 'Upstream-Contact:0'   ),'foo',"check compute with index in variable");

$root->fetch_element(name => 'Original-Source-Location', check => 'no')->store('foobar');
is($root->grab_value(step => 'Source'   ),'foobar',"check migrate_from with undef_is");

my $v ;
warning_like {$v = $root->grab_value(step => 'Source2'   );} 
    [ (qr/deprecated/) x 4 ], "check compute with undef_is" ;
is($v ,'foobar',"check result of compute with undef_is");

foreach (qw/bar foo2/) {
    my $path = "$_ location_function_in_formula";
    is($root->grab_value($path),$path,"check &location with $path");
}

# test formula with tmp variable
my $tmph = $root->fetch_element('with_tmp_var');

is($tmph->fetch,'foo.bar',"check extracted host with temp variable") ;

my $lic_gpl = $root->grab('Licenses:"GPL-1+"') ;
is($lic_gpl->grab_value('text'), "yada yada GPL-1+\nyada yada","check replacement with &index()");

is($root->grab_value('Licenses:PsF text'), "","check missing replacement with &index()");
is($root->grab_value('Licenses:"MPL-1.1" text'), "","check missing replacement with &index()");

is($root->grab_value('Licenses:"MPL-1.1" short_name_from_index'), "MPL-1.1",'evaled &index($holder)');

