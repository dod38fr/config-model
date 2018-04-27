use ExtUtils::testlib;
use Test::More;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;
use Pod::Simple;

use warnings;
use 5.10.1;

use strict;
use lib "t/lib";

my ($model, $trace) = init_test();

$model->load( 'Master', 'Config/Model/models/Master.pl' );
ok( 1, "big_model loaded" );

$model->augment_config_class(
    name => "Master",
    element => [
        'big_string' => {
            type => 'leaf',
            value_type => 'string',
            default => "A very\nlong\n\n\ndefault\nvalue\n"
        }
    ]
);

my $res = $model->get_model_doc('Master');
is_deeply(
    [ sort keys %$res ],
    [ map { "Config::Model::models::$_" } qw/Master SlaveY SlaveZ SubSlave SubSlave2/ ],
    "check doc classes"
);
like(
    $res->{'Config::Model::models::Master'},
    qr/Configuration class Master/,
    "check that doc is generated"
);

foreach my $class (sort keys %$res) {
    my $pod = $res->{$class};

    my $parser = Pod::Simple->new();
    $parser->no_errata_section( 1 );
    $parser->complain_stderr(1);

    $parser->parse_string_document($pod);
    my $res = $parser->any_errata_seen();

    say "Bad pod:\n++++++++++++\n$pod\n+++++++++++++" if $res;

    is($res, 0, "check generated pod error for class $class");
}


memory_cycle_ok($model, "memory cycles");

done_testing();
