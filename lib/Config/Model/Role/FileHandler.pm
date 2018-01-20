package Config::Model::Role::FileHandler;

# ABSTRACT: role to read or write configuration files

use strict;
use warnings;
use Carp;
use 5.10.0;

use Mouse::Util;
use Log::Log4perl qw(get_logger :levels);
use Path::Tiny;

use Mouse::Role;

my $logger = get_logger("FileHandler");

# used only for tests
my $__test_home = '';
sub _set_test_home { $__test_home = shift; }

# Configuration directory where to read and write files. This value
# does not override the configuration directory specified in the model
# data passed to read and write functions.
has config_dir => ( is => 'ro', isa => 'Maybe[Str]', required => 0 );

sub get_tuned_config_dir {
    my ($self, %args) = @_;

    my $dir = $args{os_config_dir}{$^O} || $args{config_dir} || $self->config_dir || '';
    if ( $dir =~ /^~/ ) {
        # because of tests, we can't rely on Path::Tiny's tilde processing
        my $home = $__test_home || File::HomeDir->my_home;
        $dir =~ s/^~/$home/;
    }

    return $args{root} ? path($args{root})->child($dir)
        : $dir ?  path($dir)
        :         path ('.');
}

1;

__END__

=head1 SYNOPSIS


=head1 DESCRIPTION

Role used to handle configuration files on the behalf of a backend.

=head1 METHODS




=cut

