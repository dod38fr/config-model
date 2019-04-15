package Config::Model::TypeConstraints;

use Mouse;
use Mouse::Util::TypeConstraints;

subtype 'Config::Model::TypeContraints::Path' => as 'Maybe[Path::Tiny]' ;
coerce 'Config::Model::TypeContraints::Path' => from 'Str' => via sub { defined $_ ?  Path::Tiny::path($_) : undef ; } ;

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
