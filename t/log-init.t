# -*- cperl -*-
use strict;
use warnings;
use Path::Tiny;

use Test::More;
use Config::Model qw/initialize_log4perl/;

my %specs = (
    'single class' => 'Loader',
    'multiple classes' => [ 'Loader', 'Thingy' ],
);

$Config::Model::force_default_log = 1;

foreach my $test (sort keys %specs) {
    subtest "$test log init" => sub {
        my $arg = $specs{$test};
        my $res = initialize_log4perl( verbose => $arg );
        ok ($res, "$test init called" );
        my @classes = ref $arg ? @$arg: ($arg) ;
        foreach my $c (@classes) {
            is($res->{"log4perl.logger.Verbose.$c"}, "INFO, PlainMsgOnScreen", "check changed setting");
        }
        is($res->{"log4perl.appender.Screen"}, "Log::Log4perl::Appender::Screen", "check default setting");
    };
}

done_testing;
