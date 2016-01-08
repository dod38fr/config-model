package Config::Model::Role::WarpMaster;

# ABSTRACT: register and trigger a warped element

use Mouse::Role;
use strict;
use warnings;

use Mouse::Util;
use Log::Log4perl qw(get_logger :levels);
use Scalar::Util qw/weaken/;

my $logger = get_logger("WarpMaster"); # Warper ?

# Now I'm a warper !
sub register {
    my ( $self, $warped, $w_idx ) = @_;

    my $w_name = $warped->name;
    $logger->debug( "Value: " . $self->name, " registered $w_name ($w_idx)" );

    # weaken only applies to the passed reference, and there's no way
    # to duplicate a weak ref. Only a strong ref is created. See
    #  qw(weaken) module for weaken()
    my @tmp = ( $warped, $w_name, $w_idx );
    weaken( $tmp[0] );
    push @{ $self->{warp_these_objects} }, \@tmp;

    return defined $self->{compute} ? 'computed' : 'regular';
}

sub unregister {
    my ( $self, $w_name ) = @_;
    $logger->debug( "Value: " . $self->name, " unregister $w_name" );

    my @new = grep { $_->[1] ne $w_name; } @{ $self->{warp_these_objects} };

    $self->{warp_these_objects} = \@new;
}

# And I'm going to warp them ...
sub trigger_warp {
    my $self = shift;

    # retrieve current value if not provided
    my $value = @_ ? $_[0] : $self->fetch_no_check;

    foreach my $ref ( @{ $self->{warp_these_objects} } ) {
        my ( $warped, $w_name, $warp_index ) = @$ref;
        next unless defined $warped;    # $warped is a weak ref and may vanish

        # pure warp of object
        if ($logger->is_debug) {
            my $str = $value // 'undefined';
            $logger->debug("trigger_warp: from ", $self->name,
                           " (value $str) warping '$w_name'");
        }
        $warped->trigger( $value, $warp_index );
    }
}

__END__

=head1 SYNOPSIS

 $self->load_node( config_class_name => "...", %other_args);

=head1 DESCRIPTION


=head1 METHODS



=cut

