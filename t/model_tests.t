# -*- cperl -*-
use warnings;

use strict;

use Config::Model::Tester 2.046;
use ExtUtils::testlib;

my $arg             = shift || '';
my $test_only_model = shift || '';
my $do              = shift;

run_tests( $arg, $test_only_model, $do );
