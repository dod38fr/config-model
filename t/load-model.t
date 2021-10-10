use Test::More;
use Test::Memory::Cycle;
use Test::Differences;
use Path::Tiny;
use YAML::PP;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;

use strict;
use warnings;
use 5.20.0;
use feature qw/postderef/;
no warnings qw/experimental::postderef/;

use lib 'wr_root/load_model_snippets';

my ($model, $trace) = init_test();

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir();


my $file = path('t/lib/test_ini_backend_model.yml'); # any model is fine
my $ypp = YAML::PP->new;
my @data = $ypp->load_file($file);

my @expected = map { $_->{name} } $data[0]->@*;

# load model like Config::Model::Itself
my @models = $model -> load ( 'Tmp' , $file->absolute ) ;

eq_or_diff(\@models, \@expected,"check loaded classes");

memory_cycle_ok($model,"memory cycles");
done_testing;
