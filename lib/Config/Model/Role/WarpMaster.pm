package Config::Model::Role::WarpMaster;

# ABSTRACT: register and trigger a warped element

use Mouse::Role;
use strict;
use warnings;

use Mouse::Util;
use Log::Log4perl qw(get_logger :levels);
use Scalar::Util qw/weaken/;

my $logger = get_logger("Warper");

has 'warp_these_objects' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        _slave_info        => 'elements',
        _add_slave_info    => 'push',
        _delete_slave       => 'delete',
        has_warped_slaves  => 'count',
        # find_slave_idx    => 'first_index', not available in Mouse
    },
);

sub register {
    my ( $self, $warped, $warper_name ) = @_;

    my $w_name = $warped->name;
    $logger->debug( $self->get_type . ": " . $self->name, " registered $w_name ($warper_name)" )
        if $logger->is_debug;

    # weaken only applies to the passed reference, and there's no way
    # to duplicate a weak ref. Only a strong ref is created. See
    #  qw(weaken) module for weaken()
    my @tmp = ( $warped, $w_name, $warper_name );
    weaken( $tmp[0] );
    $self->_add_slave_info( \@tmp );

    return defined $self->{compute} ? 'computed' : 'regular';
}

sub unregister {
    my ( $self, $w_name ) = @_;
    $logger->debug(  $self->get_type .": " . $self->name, " unregister $w_name" )
        if $logger->is_debug;

    my $idx = 0;
    foreach my $info ($self->_slave_info) {
        last if $info->[0] eq $w_name ;
        $idx++;
    }

    $self->_delete_slave($idx);
}

# And I'm going to warp them ...
sub trigger_warp {
    my $self = shift;
    my $value = shift;
    my $str_val = shift // $value // 'undefined';

    foreach my $ref ( $self->_slave_info ) {
        my ( $warped, $w_name, $warp_index ) = @$ref;
        next unless defined $warped;    # $warped is a weak ref and may vanish

        # pure warp of object
        if ($logger->is_debug) {
            $logger->debug("trigger_warp: ".$self->get_type." ", $self->name,
                           " warps '$w_name' with value <$str_val> ");
        }
        $warped->trigger( $value, $warp_index );
    }
}

sub get_warped_slaves {
    my $self = shift;

    # grep is used to clean up weak ref to object that were destroyed
    return grep { defined $_ } map { $_->[0] } $self->_slave_info;
}

1;

__END__

=head1 SYNOPSIS

 $self->load_node( config_class_name => "...", %other_args);

=head1 DESCRIPTION


=head1 METHODS



=cut

