package Config::Model::Role::Utils;

# ABSTRACT: Provide some utilities

use Mouse::Role;
use strict;
use warnings;
use 5.020;

use feature qw/signatures/;
no warnings qw/experimental::signatures/;

sub _resolve_arg_shortcut ($args, @param_list) {
    return $args->@* > @param_list ? $args->@*
         :                           map { $_ => shift @$args; } @param_list;
}

1;


