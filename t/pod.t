use strict;
use warnings;

BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        require Test::More;
        Test::More::plan( skip_all => 'these tests are for testing by the author' );
    }
}

use strict;
use Test::More;
use Test::Pod 1.00;
all_pod_files_ok( );
