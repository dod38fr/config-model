package Config::Model::Role::FileHandler;

# ABSTRACT: role to read or write configuration files

use strict;
use warnings;
use Carp;
use 5.10.0;

use Mouse::Util;
use Log::Log4perl qw(get_logger :levels);

use Mouse::Role;
requires 'config_dir';

my $logger = get_logger("FileHandler");

# used only for tests
my $__test_home = '';
sub _set_test_home { $__test_home = shift; }

sub get_tuned_config_dir {
    my ($self, %args) = @_;

    my $dir = $args{os_config_dir}{$^O} || $args{config_dir} || $self->config_dir || '';
    if ( $dir =~ /^~/ ) {
        my $home = $__test_home || File::HomeDir->my_home;
        $dir =~ s/^~/$home/;
    }

    $dir .= '/' if $dir and $dir !~ m(/$);

    return $dir;
}

1;

__END__

=head1 SYNOPSIS


=head1 DESCRIPTION

Role used to handle configuration files on the behalf of a backend.

=head1 METHODS




=cut

