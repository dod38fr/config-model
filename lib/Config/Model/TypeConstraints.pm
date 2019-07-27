package Config::Model::TypeConstraints;

use Mouse;
use Mouse::Util::TypeConstraints;

# used only for tests
my $__test_home = '';
sub _set_test_home { $__test_home = shift; }
sub _get_test_home { return $__test_home ; }

subtype 'Config::Model::TypeContraints::Path' => as 'Maybe[Path::Tiny]' ;
coerce 'Config::Model::TypeContraints::Path' => from 'Str' => via sub {
    if (defined $_ and /^~/) {
        # because of tests, we can't rely on Path::Tiny's tilde processing
        # TODO: should this be my_config ? May be once this is done:
        # https://github.com/perl5-utils/File-HomeDir/pull/5/files
        # beware of compat and migration issues
        my $home = $__test_home || File::HomeDir->my_home;
        s/^~/$home/;
    }
    return defined $_ ?  Path::Tiny::path($_) : undef ;
} ;

1;

# ABSTRACT: Mouse type constraints for Config::Model

__END__

=head1 SYNOPSIS

 use Config::Model::TypeConstraints ;

 has 'some_dir' => (
    is => 'ro',
    isa => 'Config::Model::TypeContraints::Path',
    coerce => 1
 );

=head1 DESCRIPTION

This module provides type constraints used by Config::Model:

=over

=item *

C<Config::Model::TypeContraints::Path>. A C<Maybe[Path::Tiny]>
type. This type can be coerced from C<Str> type if C<< coerce => 1 >>
is used to construct the attribute.

=back

=head1 SEE ALSO

L<Config::Model>,
L<Mouse::Util::TypeConstraints>

=cut
