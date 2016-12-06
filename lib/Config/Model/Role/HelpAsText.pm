package Config::Model::Role::HelpAsText;

# ABSTRACT: Transalet element help from pod to text

use Mouse::Role;
use strict;
use warnings;
use Pod::Text;
use Pod::Simple 3.23;
use 5.10.1;

requires('get_help');

sub get_help_as_text {
    my $self = shift;

    my $pod = $self->get_help(@_) ;
    return undef unless defined $pod;

    my $parser = Pod::Text->new(
        indent => 0,
        nourls => 1,
    );

    # require Pod::Simple 3.23
    $parser->parse_characters('utf8');

    my $output = '';
    $parser->output_string(\$output);

    $parser->parse_string_document("=pod\n\n" . $pod);
    $output =~ s/[\n\s]+$//;

    return $output;
}

1;

__END__

=head1 SYNOPSIS

 $self->get_help_as_text( ... );

=head1 DESCRIPTION

Role used to transform Config::Model help text or description from pod
to text. The provided method should be used when the help text should
be displayed on STDOUT.

This functionality is provided as a role because the interface to
L<Pod::Text> is not so easy.

=head1 METHODS

=head2 get_help_as_text

Calls C<get_help> and transform the Pod output to text.

=head2 SEE ALSO

L<Pod::Text>, L<Pod::Simple>

=cut

