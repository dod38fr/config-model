# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Test::Differences ;
use Config::Model;
use Config::Model::ValueComputer;
use Log::Log4perl qw(:easy) ;

BEGIN { plan tests => 67; }

use strict;

my ($log,$show) = (0) x 3 ;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($arg =~ /l/ ? $DEBUG: $WARN);
}

ok( 1, "Compilation done" );

my $model = Config::Model->new();

$model->create_config_class(
    name    => "RSlave",
    element => [
        recursive_slave => {
            type       => 'hash',
            index_type => 'string',
            cargo      => {
                type              => 'node',
                config_class_name => 'RSlave'
            },
        },
        big_compute => {
            type       => 'hash',
            index_type => 'string',
            cargo      => {
                type       => 'leaf',
                value_type => 'string',
                compute    => {
                    variables => {
                        up  => '-',
                        'm' => '!  macro',
                    },
                    formula => 'macro is $m, my idx: &index, '
                      . 'my element &element, '
                      . 'upper element &element($up), '
                      . 'up idx &index($up)',
                }
            },
        },
        big_replace => {
            type       => 'leaf',
            value_type => 'string',
            compute    => {
                formula   => 'trad idx $replace{&index($up)}',
                variables => { up => '-', },
                replace   => {
                    l1 => 'level1',
                    l2 => 'level2'
                }
            }
        },
        [qw/bar foo foo2/] => {
            type              => 'node',
            config_class_name => 'Slave'
        },
        macro_replace => {
            type       => 'hash',
            index_type => 'string',
            cargo      => {
                type       => 'leaf',
                value_type => 'string',
                compute    => {
                    formula   => 'trad macro is $replace{$m}',
                    variables => { 'm' => '!  macro', },
                    replace   => {
                        A => 'macroA',
                        B => 'macroB',
                        C => 'macroC'
                    },
                }
            },
        }
    ],
);

$model->create_config_class(
    name => "Slave",

    'element' => [
        [qw/X Y Z/] => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/Av Bv Cv/],
            warp       => {
                follow => '- - macro',
                rules  => {
                    A => { default => 'Av' },
                    B => { default => 'Bv' }
                }
            }
        },
        'recursive_slave' => {
            type       => 'hash',
            index_type => 'string',
            cargo      => {
                type              => 'node',
                config_class_name => 'RSlave',
            },
        },
        W => {
            type       => 'leaf',
            value_type => 'enum',
            level      => 'hidden',
            warp       => {
                follow  => '- - macro',
                'rules' => {
                    A => {
                        default    => 'Av',
                        level      => 'normal',
                        experience => 'beginner',
                        choice     => [qw/Av Bv Cv/],
                    },
                    B => {
                        default    => 'Bv',
                        level      => 'normal',
                        experience => 'advanced',
                        choice     => [qw/Av Bv Cv/]
                    }
                }
            },
        },
        Comp => {
            type       => 'leaf',
            value_type => 'string',
            compute    => {
                formula   => 'macro is $m',
                variables => { 'm' => '- - macro' },
            },
        },
        warped_by_location => {
            type       => 'leaf',
            value_type => 'uniline',
            default    => 'slaved',
            warp       => {
                rules =>
                  [ '&location =~ /recursive/', { 'default' => 'rslaved' } ]
            },
        },
    ]
);

$model->create_config_class(
    name    => "Master",
    element => [
        get_element => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/m_value_element compute_element/]
        },
        where_is_element => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/get_element/]
        },
        macro => {
            type       => 'leaf',
            value_type => 'enum',
            mandatory  => 1,
            choice     => [qw/A B C D/]
        },
        m_value_out => {
            type       => 'leaf',
            value_type => 'uniline',
             warp       => {
                follow  => '- macro',
                'rules' => [
                    "B" => {
                        level  => 'hidden',
                    },
                ]
            }
        },
        m2_value_out => {
            type       => 'leaf',
            value_type => 'uniline',
            warp       => {
                follow => { m => '- macro', m2 => '- macro2' },
                rules =>
                  [ '$m eq "A" or $m2 eq "A"' => { level => 'hidden', }, ]
            }
         },
        macro2 => {
            type       => 'leaf',
            value_type => 'enum',
            level      => 'hidden',
            warp       => {
                follow  => '- macro',
                'rules' => [
                    "B" => {
                        level  => 'normal',
                        choice => [qw/A B C D/]
                    },
                ]
            }
        },
        'm_value' => {
            type       => 'leaf',
            value_type => 'enum',
            level      => 'hidden',
            'warp'     => {
                follow  => { m => '- macro' },
                'rules' => [
                    '$m eq "A" or $m eq "D"' => {
                        choice => [qw/Av Bv/],
                        level  => 'normal',
                        help   => { Av => 'Av help' },
                    },
                    '$m eq "B"' => {
                        choice => [qw/Bv Cv/],
                        level  => 'normal',
                        help   => { Bv => 'Bv help' },
                    },
                    '$m eq "C"' => {
                        choice => [qw/Cv/],
                        level  => 'normal',
                        help   => { Cv => 'Cv help' },
                    }
                ]
            }
        },
        'm_value_old' => {
            type       => 'leaf',
            value_type => 'enum',
            level      => 'hidden',
            'warp'     => {
                follow  => '- macro',
                'rules' => [
                    [qw/A D/] => {
                        choice => [qw/Av Bv/],
                        level  => 'normal',
                        help   => { Av => 'Av help' },
                    },
                    B => {
                        choice => [qw/Bv Cv/],
                        level  => 'normal',
                        help   => { Bv => 'Bv help' },
                    },
                    C => {
                        choice => [qw/Cv/],
                        level  => 'normal',
                        help   => { Cv => 'Cv help' },
                    }
                ]
            }
        },
        'compute' => {
            type       => 'leaf',
            value_type => 'string',
            compute    => {
                formula   => 'macro is $m, my element is &element',
                variables => { 'm' => '!  macro' },
            },
        },

        'var_path' => {
            type       => 'leaf',
            value_type => 'string',
            mandatory  => 1,          # will croak if value cannot be computed
            compute    => {
                formula =>
                  'get_element is $replace{$s}, indirect value is \'$v\'',
                variables => {
                    's'   => '! $where',
                    where => '! where_is_element',
                    v     => '! $replace{$s}',
                },
                replace => {qw/m_value_element m_value compute_element compute/}
            }
        },

        'class' => {
            type       => 'hash',
            index_type => 'string',
            cargo      => {
                type       => 'leaf',
                value_type => 'string'
            },
        },
        'warped_out_ref' => {
            type       => 'leaf',
            refer_to   => '! class',
            value_type => 'reference',
            level      => 'hidden',
            warp       => {
                follow => { m => '- macro', m2 => '- macro2' },
                rules =>
                  [ '$m eq "A" or $m2 eq "A"' => { level => 'normal', }, ]
            }
        },

        [qw/bar foo foo2/] => {
            type              => 'node',
            config_class_name => 'Slave'
        },
        'ClientAliveCheck',
        {
            'value_type'       => 'boolean',
            'upstream_default' => '0',
            'type'             => 'leaf',
        },
        'ClientAliveInterval',
        {
            'value_type' => 'integer',
            'level'      => 'hidden',
            'min'        => '1',
            'warp'       => {
                'follow' => { 'c_a_check' => '- ClientAliveCheck' },
                'rules' => [ '$c_a_check == 1', { 'level' => 'normal' } ]
            },
            'type' => 'leaf'
        },
    ]
);

my $inst = $model->instance(
    root_class_name => 'Master',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

my $mvo = $root->fetch_element('m_value_out');
isa_ok($mvo->{warper},'Config::Model::Warper',"check warper object");

my $macro = $root->fetch_element('macro');

my @macro_slaves = ('Warper of Master m_value_out');

eq_or_diff( 
    [ map { $_->name } $macro->get_depend_slave ] ,
    \@macro_slaves,
    "check m_value_out warper"
    );
    
my $mvo2 = $root->fetch_element('m2_value_out');
isa_ok($mvo2->{warper},'Config::Model::Warper',"check warper object");

push @macro_slaves , 'Warper of Master m2_value_out', 'Warper of Master macro2' ;

eq_or_diff( 
    [ map { $_->name } $macro->get_depend_slave ] ,
    \@macro_slaves,
    "check m_value_out and m2_value_out warper"
    );
    
eq_or_diff(
    [ $root->get_element_name( for => 'beginner' ) ],
    [
        qw'get_element where_is_element macro m_value_out m2_value_out 
        compute var_path class bar foo foo2 ClientAliveCheck'
    ],
    "Elements of Master"
);

# query the model instead of the instance
eq_or_diff(
    [
        $model->get_element_name(
            class => 'Slave',
            for   => 'beginner'
        )
    ],
    [qw'X Y Z recursive_slave Comp warped_by_location'],
    "Elements of Slave from the model"
);

my $slave = $root->fetch_element('bar');
ok( $slave, "Created slave(bar)" );

eq_or_diff(
    [ $slave->get_element_name( for => 'beginner' ) ],
    [qw'X Y Z recursive_slave Comp warped_by_location'],
    "Elements of Slave from the object"
);
my $result;
eval { $result = $slave->fetch_element('W')->fetch; };
ok( $@, "reading slave->W (undef value_type error)" );
print "normal error: $@" if $trace;

is( $slave->fetch_element('X')->fetch, undef, "reading slave->X (undef)" );

is( $macro->store('B'), 'B', "setting master->macro to B" );

eq_or_diff(
    [ $root->get_element_name( for => 'beginner' ) ],
    [
        qw'get_element where_is_element macro m2_value_out macro2 m_value
          m_value_old compute var_path class bar foo foo2
          ClientAliveCheck'
    ],
    "Elements of Master when macro = B"
);

is( $root->fetch_element('macro2')->store('A'),
    'A', "setting master->macro2 to A" );

is_deeply(
    [ $root->get_element_name( for => 'beginner' ) ],
    [
        qw'get_element where_is_element macro macro2
          m_value m_value_old compute var_path class warped_out_ref bar
          foo foo2 ClientAliveCheck'
    ],
    "Elements of Master when macro = B macro2 = A"
);

$root->fetch_element('class')->fetch_with_id('foo')->store('foo_v');
$root->fetch_element('class')->fetch_with_id('bar')->store('bar_v');

is( $root->fetch_element('warped_out_ref')->store('foo'),
    'foo', "setting master->warped_out_ref to foo" );

is( $root->fetch_element('macro')->store('A'),
    'A', "setting master->macro to A" );

map { is( $slave->fetch_element($_)->fetch, 'Av', "reading slave->$_ (Av)" ); }
  qw/X Y Z/;

is( $root->fetch_element('macro')->store('C'),
    'C', "setting master->macro to C" );

is( $root->fetch_element('m_value')->get_help('Cv'),
    'Cv help', 'test m_value help with macro=C' );

is( $slave->fetch_element('X')->fetch, undef, "reading slave->X (undef)" );

$root->fetch_element('macro')->store('A');

is( $root->fetch_element('m_value')->store('Av'),
    'Av', 'test m_value with macro=A' );

is( $root->fetch_element('m_value_old')->store('Av'),
    'Av', 'test m_value_old with macro=A' );

is( $root->fetch_element('m_value')->get_help('Av'),
    'Av help', 'test m_value help with macro=A' );

is( $root->fetch_element('m_value')->get_help('Cv'),
    undef, 'test m_value help with macro=A' );

$root->fetch_element('macro')->store('D');

is( $root->fetch_element('m_value')->fetch, 'Av', 'test m_value with macro=D' );

is( $root->fetch_element('m_value_old')->fetch,
    'Av', 'test m_value_old with macro=D' );

$root->fetch_element('macro')->store('A');

is_deeply(
    [ $slave->get_element_name( for => 'beginner' ) ],
    [qw/X Y Z recursive_slave W Comp warped_by_location/],
    "Slave elements from the object (W pops in when macro is set to A)"
);
$root->fetch_element('macro')->store('B');

is_deeply(
    [ $slave->get_element_name( for => 'beginner' ) ],
    [qw/X Y Z recursive_slave Comp warped_by_location/],
    "Slave elements from the object (W's out when macro is set to B)"
);
is_deeply(
    [ $slave->get_element_name( for => 'advanced' ) ],
    [qw/X Y Z recursive_slave W Comp warped_by_location/],
    "Slave elements from the object for advanced level"
);

map { is( $slave->fetch_element($_)->fetch, 'Bv', "reading slave->$_ (Bv)" ); }
  qw/X Y Z/;

is( $slave->fetch_element('Y')->store('Cv'), 'Cv', 'Set slave->Y to Cv' );

# testing warp in warp out
$root->fetch_element('macro')->store('C');
is( $slave->is_element_available( name => 'W', experience => 'advanced' ),
    0, " test W is not available" );
$root->fetch_element('macro')->store('B');
is( $slave->is_element_available( name => 'W', experience => 'advanced' ),
    1, " test W is available" );

$root->fetch_element('macro')->store('C');

map {
    is( $slave->fetch_element($_)->fetch, undef, "reading slave->$_ (undef)" );
} qw/X Z/;
is( $slave->fetch_element('Y')->fetch, 'Cv', "reading slave->Y (Cv)" );

is( $slave->fetch_element('Comp')->fetch, 'macro is C', "reading slave->Comp" );

is( $root->fetch_element('m_value')->store('Cv'), 'Cv', 'set m_value to Cv' );

my $rslave1 = $slave->fetch_element('recursive_slave')->fetch_with_id('l1');
my $rslave2 = $rslave1->fetch_element('recursive_slave')->fetch_with_id('l2');
my $big_compute_obj =
  $rslave2->fetch_element('big_compute')->fetch_with_id('b1');

isa_ok( $big_compute_obj, 'Config::Model::Value',
    'Created new big compute object' );

my $txt   = 'macro is $m, my idx: &index, my element &element, ';
my $rules = {
    m   => '! macro',
    up  => '-',
    up2 => '- -',
};

my $parser =
  new Parse::RecDescent($Config::Model::ValueComputer::compute_grammar);

# the 2 next tests are used to check what going on before trying the
# real test below. But beware, the error messages for these 2 tests
# might be misleading.
my $str_r = $parser->pre_compute( $txt, 1, $big_compute_obj, $rules );
is(
    $$str_r,
    'macro is $m, my idx: b1, my element big_compute, ',
    "testing pre_compute with & and &index on \$big_compute_obj"
);

$txt .=
'upper elements &element($up2) &element($up), up idx &index($up2) &index($up)';

$str_r = $parser->pre_compute( $txt, 1, $big_compute_obj, $rules );

is(
    $$str_r,
    'macro is $m, my idx: b1, my element big_compute, '
      . 'upper elements recursive_slave recursive_slave, up idx l1 l2',
    "testing pre_compute with &element(stuff) and &index(\$stuff)"
);

my $bc_val =
  $rslave2->fetch_element('big_compute')->fetch_with_id("test_1")->fetch;

is(
    $bc_val,
'macro is C, my idx: test_1, my element big_compute, upper element recursive_slave, up idx l2',
    'reading slave->big_compute(test1)'
);

is(
    $big_compute_obj->fetch,
'macro is C, my idx: b1, my element big_compute, upper element recursive_slave, up idx l2',
    'reading slave->big_compute(b1)'
);

is(
    $rslave1->fetch_element('big_replace')->fetch(),
    'trad idx level1',
    'reading rslave1->big_replace(br1)'
);

is(
    $rslave2->fetch_element('big_replace')->fetch(),
    'trad idx level2',
    'reading rslave2->big_replace(br1)'
);

is(
    $rslave1->fetch_element('macro_replace')->fetch_with_id('br1')->fetch,
    'trad macro is macroC',
    'reading rslave1->macro_replace(br1)'
);

is(
    $rslave2->fetch_element('macro_replace')->fetch_with_id('br1')->fetch,
    'trad macro is macroC',
    'reading rslave2->macro_replace(br1)'
);

is(
    $root->fetch_element('compute')->fetch(),
    'macro is C, my element is compute',
    'reading root->compute'
);

my @masters = $root->fetch_element('macro')->get_depend_slave();
my @names = sort map { $_->name } @masters;
print "macro controls:\n\t", join( "\n\t", @names ), "\n"
  if $trace;

is( scalar @masters, 16, 'reading macro slaves' );

eq_or_diff(
    \@names,
    [
        'Master compute',
        'Warper of Master m2_value_out',
        'Warper of Master m_value',
        'Warper of Master m_value_old',
        'Warper of Master m_value_out',
        'Warper of Master macro2',
        'Warper of Master warped_out_ref',
        'Warper of bar W',
        'Warper of bar X',
        'Warper of bar Y',
        'Warper of bar Z',
        'bar Comp',
        'bar recursive_slave:l1 macro_replace:br1',
        'bar recursive_slave:l1 recursive_slave:l2 big_compute:b1',
        'bar recursive_slave:l1 recursive_slave:l2 big_compute:test_1',
        'bar recursive_slave:l1 recursive_slave:l2 macro_replace:br1',
    ],
    "check names of values using 'macro' element"
);

Config::Model::Exception::Any->Trace(1);

eval { $root->fetch_element('var_path')->fetch; };
like(
    $@,
    qr/'! where_is_element' is undef/,
    'reading var_path while where_is_element variable is undef'
);

# set one variable of the formula
$root->fetch_element('where_is_element')->store('get_element');

eval { $root->fetch_element('var_path')->fetch; };
like(
    $@,
    qr/'! where_is_element' is 'get_element'/,
    'reading var_path while where_is_element is defined'
);
like(
    $@,
    qr/Mandatory value is not defined/,
    'reading var_path while get_element variable is undef'
);

# set the other variable of the formula
$root->fetch_element('get_element')->store('m_value_element');

is(
    $root->fetch_element('var_path')->fetch(),
    'get_element is m_value, indirect value is \'Cv\'',
    "reading var_path through m_value element"
);

# modify the other variable of the formula
$root->fetch_element('get_element')->store('compute_element');

is(
    $root->fetch_element('var_path')->fetch(),
'get_element is compute, indirect value is \'macro is C, my element is compute\'',
    "reading var_path through compute element"
);

$root->fetch_element('ClientAliveCheck')->store(0);

eval { $root->fetch_element('ClientAliveInterval')->fetch; };
like(
    $@,
    qr/unavailable element/,
    'reading ClientAliveInterval when ClientAliveCheck is 0'
);

$root->fetch_element('ClientAliveCheck')->store(1);
$root->fetch_element('ClientAliveInterval')->store(10);
is( $root->fetch_element('ClientAliveInterval')->fetch,
    10, "check ClientAliveInterval" );

my %loc_h = (
    qw/bar slaved foo2 slaved/,
    'bar recursive_slave:l1 foo2' => 'rslaved', 
    'bar recursive_slave:l1 recursive_slave:l2 foo2' => 'rslaved'
);

foreach my $k ( sort keys %loc_h ) {
    my $path = "$k warped_by_location";
    is( $root->grab_value($path), $loc_h{$k}, "check &location with $path" );
}
