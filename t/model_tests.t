# -*- cperl -*-
use warnings;

use strict;

use Config::Model::Tester 2.062;
use ExtUtils::testlib;

$::_use_log4perl_to_warn = 1;

my $arg             = shift || '';
my $test_only_model = shift || '';
my $do              = shift;

run_tests( $arg, $test_only_model, $do );
