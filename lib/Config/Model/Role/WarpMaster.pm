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

 package Config::Model::Stuff;
 use Mouse;
 with Config::Model::Role::WarpMaster

=head1 DESCRIPTION

This role enable a configuration element to become a warp maser, i.e. a parameter
whose value can change the features of the configuration tree (by controlling a
warped_node) or the feature of various elements like leaf, hash ...

=head1 METHODS

=head2 register

Parameters: C<< ( $warped_object, warper_name ) >>

Register a new warped object. Called by an element which has a C<warp> parameter.
This method is calling on the object pointed by C<follow> value.

=head2 unregister

Parameters: C<< ( warper_name ) >>

Remove a warped object from the object controlled by this warp master.

=head2 trigger_warp

Parameters: C<< ( value, stringified_value ) >>

Called by the object using this role when the value held by this object is changed (i.e.
something like store was called). The passed value can be a plain scalar (from a value
object) or a hash (from a check_list object). The stringified_value is a string shown
in debug log.

-head2 has_warped_slaves

Return the number of object controlled by this master.

=head2 get_warped_slaves

Return a list of object controlled by this master.

=cut

