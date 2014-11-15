use ExtUtils::testlib;
use Test::More tests => 5;
use Test::Memory::Cycle;
use Config::Model;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model->new( legacy => 'ignore', );

my $arg = shift || '';
my $trace = $arg =~ /t/ ? 1 : 0;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $arg =~ /l/ ? $TRACE : $WARN );

ok( 1, "compiled" );

$model->load( 'Master', 't/big_model.pm' );
ok( 1, "big_model loaded" );

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

memory_cycle_ok($model);
