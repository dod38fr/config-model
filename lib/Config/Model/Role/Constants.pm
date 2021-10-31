package Config::Model::Role::Constants;

# ABSTRACT: Provide some constant data.

use Mouse::Role;
use strict;
use warnings;
use 5.020;

use feature qw/signatures/;
no warnings qw/experimental::signatures/;

sub get_default_property ($prop) {
    state %all_props = (
        status      => 'standard',
        level       => 'normal',
        summary     => '',
        description => '',
    );
    return $all_props{$prop};
}

1;
