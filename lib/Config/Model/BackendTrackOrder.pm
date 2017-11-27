package Config::Model::BackendTrackOrder;

# ABSTRACT: Track read order of elements from configuration

use Mouse;
use strict;
use warnings;
use Carp;
use 5.10.0;

use Mouse::Util;
use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger("BackendTrackOrder");

has backend_obj => (
    is => 'ro',
    isa => 'Config::Model::Backend::Any',
    weak_ref => 1,
    required => 1,
    handles => [qw/node get_element_names/],
);

has _creation_order => (
    is => 'bare',
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    default => sub { [] },
    handles => {
        _register_element => 'push',
        get_element_names_as_created => 'elements',
        _insert_element => 'insert',
    }
);

has _created => (
    is => 'rw',
    isa => 'HashRef[Str]',
    traits => ['Hash'],
    default => sub { {} },
    handles => {
        register_created => 'set',
        has_created => 'exists',
    }
);

# keeping order in Node does not make sense: one must read parameter
# in canonical order to enable warp mechanism from one elemnet to the
# other, so the read order will never differ from the canonical
# order. Only some elements will be missing

# What about default values, not created, no store done ????
# -> when writing back, mix all elements from canonical list into existing list ...
# or at the end of initial load ???
# or mixall at the end of init() ?

sub register_element {
    my ($self, $name) = @_;

    return if $self->has_created($name);
    $self->register_created($name => 1 );

    if ($self->node->instance->initial_load) {
        $logger->debug("registering $name during init");
        $self->_register_element($name);
    }
    else {
        # try to keep canonical order
        my $i = 1;
        my %has = map{ ($_ , $i++ ) } $self->get_element_names_as_created;

        my $found_me = 0;
        my $previous_idx = 0 ;
        my $previous_name ;
        # traverse the canonical list in reverse order (which includes
        # accepted elements) ...
        foreach my $std (reverse @{ $self->node->{model}{element_list} }) {
            # ... until the new element is found in the canonical list ...
            if ($name eq $std) {
                $found_me++;
            }
            # ... and the first previous element from the canonical
            # list already existing in the existing list is found
            elsif ($found_me and $has{$std}) {
                $previous_idx = $has{$std};
                $previous_name = $std;
                last;
            }
        }

        # then insert this element in the existing list after the
        # previous element (which may be 0, if the previous element
        # was not found, i.e. do an unshift). push it if search has failed.
        if ($found_me) {
            if ($logger->is_debug) {
                my $str = $previous_name ? "after $previous_name" : "at beginning";
                $logger->debug("registering $name $str");
            }
            $self->_insert_element($previous_idx, $name);
        }
        else {
            $logger->debug("registering $name at end of list");
            $self->_register_element($name);
        }
    }
}

sub get_ordered_element_names {
    my $self = shift;
    if ($self->node->instance->canonical) {
        return $self->get_element_names;
    }
    else {
        # triggers a registration of all remaining elements in _creation_order
        map { $self->register_element($_);} $self->get_element_names;
        return $self->get_element_names_as_created;
    }
}

1;

__END__

=head1 SYNOPSIS

 # inside a backend
 use Config::Model::BackendTrackOrder;

 has tracker => (
    is => 'ro',
    isa => 'Config::Model::BackendTrackOrder',
    lazy_build => 1,
 );

 sub _build_tracker {
    my $self = shift;
    return Config::Model::BackendTrackOrder->new(
        backend_obj => $self,
        node => $self->node,
    ) ;
 }

 # register elements to record user order
 $self->tracker->register_element('foo');
 $self->tracker->register_element('bar');

 # later, when writing data back
 foreach my $elt ( $self->tracker->get_ordered_element_names ) {
      # write data
 }

=head1 DESCRIPTION

This module is used by backends to record the order of the
configuration elements found in user file. Later these elements can be
written back in the file using the same order.

Data are written in canonical order if C<canonical> method of the
L<instance/Config::Model::Instance> returns true.

=head1 CONSTRUCTOR

THe constructor accepts the following parameters:

=over 4

=item backend_obj

The backend object holding this tracker (required).

=item node

The node holding the backend above

=back

=head1 METHODS

=head2 register_element

Register the element and keep track of the registration order during
L<initial load|Config::Model::Instance/start_initial_load>

Element registered after initial load (i.e . user modification) are
registered using canonical order.

=head2 get_ordered_element_names

Returns a list of elements respecting user's order.

Returns the canonical list if Instance canonical attribute is 1.

=cut

