package DummyNode;
use strict;
use warnings;

use base qw/Config::Model::Node/;

sub dummy {
    $_[1]++;
}

1;
