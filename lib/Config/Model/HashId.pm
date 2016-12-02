package Config::Model::HashId;

use Mouse;
use 5.10.1;

use Config::Model::Exception;
use Carp;

use Mouse::Util::TypeConstraints;

subtype 'HaskKeyArray' => as 'ArrayRef' ;
coerce 'HaskKeyArray' => from 'Str' => via { [$_] } ;

use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger("Tree::Element::Id::Hash");

extends qw/Config::Model::AnyId/;

has data => ( is => 'rw', isa => 'HashRef',  default => sub { {}; } );
has list => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    traits     => ['Array'],
    default => sub { []; },
    handles => {
        _sort => 'sort_in_place',
    }
);

has [qw/default_keys auto_create_keys/] => (
    is => 'rw',
    isa => 'HaskKeyArray',
    coerce => 1,
    default => sub { []; }
);
has [qw/morph ordered/] => ( is => 'ro', isa => 'Bool' );

sub BUILD {
    my $self = shift;

    # foreach my $wrong (qw/migrate_values_from/) {
    # Config::Model::Exception::Model->throw (
    # object => $self,
    # error =>  "Cannot use $wrong with ".$self->get_type." element"
    # ) if defined $self->{$wrong};
    # }

    # could use "required", but we'd get a Moose error instead of a Config::Model
    # error
    Config::Model::Exception::Model->throw(
        object => $self,
        error  => "Undefined index_type"
    ) unless defined $self->index_type;

    return $self;
}

sub set_properties {
    my $self = shift;

    $self->SUPER::set_properties(@_);

    my $idx_type = $self->{index_type};

    # remove unwanted items
    my $data = $self->{data};

    my $idx   = 1;
    my $wrong = sub {
        my $k = shift;
        if ( $idx_type eq 'integer' ) {
            return 1 if defined $self->{max_index} and $k > $self->{max_index};
            return 1 if defined $self->{min_index} and $k < $self->{min_index};
        }
        return 1 if defined $self->{max_nb} and $idx++ > $self->{max_nb};
        return 0;
    };

    # delete entries that no longer fit the constraints imposed by the
    # warp mechanism
    foreach my $k ( sort keys %$data ) {
        next unless $wrong->($k);
        $logger->debug( "set_properties: ", $self->name, " deleting id $k" );
        delete $data->{$k};
    }
}

sub _migrate {
    my $self = shift;

    return if $self->{migration_done};

    # migration must be done *after* initial load to make sure that all data
    # were retrieved from the file before migration.
    return if $self->instance->initial_load;
    $self->{migration_done} = 1;

    if ( $self->{migrate_keys_from} ) {
        my $followed = $self->safe_typed_grab( param => 'migrate_keys_from', check => 'no' );
        if ( $logger->is_debug ) {
            $logger->debug( $self->name, " migrate keys from ", $followed->name );
        }

        map { $self->_store( $_, undef ) unless $self->_defined($_) } $followed->fetch_all_indexes;
    }
    elsif ( $self->{migrate_values_from} ) {
        my $followed = $self->safe_typed_grab( param => 'migrate_values_from', check => 'no' );
        $logger->debug( $self->name, " migrate values from ", $followed->name )
            if $logger->is_debug;
        foreach my $item ( $followed->fetch_all_indexes ) {
            next if $self->exists($item);    # don't clobber existing entries
            my $data = $followed->fetch_with_id($item)->dump_as_data( check => 'no' );
            $self->fetch_with_id($item)->load_data($data);
        }
    }

}

sub get_type {
    my $self = shift;
    return 'hash';
}

# important: return the actual size (not taking into account auto-created stuff)
sub fetch_size {
    my $self = shift;
    return scalar keys %{ $self->{data} };
}

sub _fetch_all_indexes {
    my $self = shift;
    return $self->{ordered}
        ? @{ $self->{list} }
        : sort keys %{ $self->{data} };
}

# fetch without any check
sub _fetch_with_id {
    my ( $self, $key ) = @_;
    my $i = $self->instance;
    return $self->{data}{$key};
}

# store without any check
sub _store {
    my ( $self, $key, $value ) = @_;
    push @{ $self->{list} }, $key
        unless exists $self->{data}{$key};
    return $self->{data}{$key} = $value;
}

sub _exists {
    my ( $self, $key ) = @_;
    return exists $self->{data}{$key};
}

sub _defined {
    my ( $self, $key ) = @_;
    return defined $self->{data}{$key} ? 1 : 0;
}

#internal
sub auto_create_elements {
    my $self = shift;

    my $auto_p = $self->auto_create_keys;
    return unless defined $auto_p;

    # create empty slots
    map { $self->_store( $_, undef ) unless exists $self->{data}{$_}; }
        ( ref $auto_p ? @$auto_p : ($auto_p) );
}

# internal
sub create_default {
    my $self = shift;
    my @temp = keys %{ $self->{data} };

    return if @temp;

    # hash is empty so create empty element for default keys
    my $def = $self->get_default_keys;
    map { $self->_store( $_, undef ) } @$def;
    $self->create_default_with_init;
}

sub _delete {
    my ( $self, $key ) = @_;

    # remove key in ordered list
    @{ $self->{list} } = grep { $_ ne $key } @{ $self->{list} };

    return delete $self->{data}{$key};
}

sub remove {
    my $self = shift;
    $self->delete(@_);
}

sub _clear {
    my ($self) = @_;
    $self->{list} = [];
    $self->{data} = {};
}

sub sort {
    my $self = shift;
    if ($self->ordered) {
        $self->_sort;
    }
    else {
        Config::Model::Exception::User->throw(
            object  => $self,
            message => "cannot call sort on non ordered hash"
        );
    }
}


# hash only method
sub firstkey {
    my $self = shift;

    $self->warp
        if ( $self->{warp} and @{ $self->{warp_info}{computed_master} } );

    $self->create_default if defined $self->{default};

    # reset "each" iterator (to be sure, map is also an iterator)
    my @list = $self->_fetch_all_indexes;
    $self->{each_list} = \@list;
    return shift @list;
}

# hash only method
sub nextkey {
    my $self = shift;

    $self->warp
        if ( $self->{warp} and @{ $self->{warp_info}{computed_master} } );

    my $res = shift @{ $self->{each_list} };

    return $res if defined $res;

    # reset list for next call to next_keys
    $self->{each_list} = [ $self->_fetch_all_indexes ];

    return;
}

sub swap {
    my $self = shift;
    my ( $key1, $key2 ) = @_;

    foreach my $k (@_) {
        Config::Model::Exception::User->throw(
            object  => $self,
            message => "swap: unknow key $k"
        ) unless exists $self->{data}{$k};
    }

    my @copy = @{ $self->{list} };
    for ( my $idx = 0 ; $idx <= $#copy ; $idx++ ) {
        if ( $copy[$idx] eq $key1 ) {
            $self->{list}[$idx] = $key2;
        }
        if ( $copy[$idx] eq $key2 ) {
            $self->{list}[$idx] = $key1;
        }
    }

    $self->notify_change( note => "swap ordered hash keys '$key1' and '$key2'" );
}

sub move {
    my $self = shift;
    my ( $from, $to, %args ) = @_;

    Config::Model::Exception::User->throw(
        object  => $self,
        message => "move: unknow key $from"
    ) unless exists $self->{data}{$from};

    my $ok = $self->check_idx($to);

    my $check = $args{check};
    if ($ok or $check eq 'no') {

        # this may clobber the old content of $self->{data}{$to}
        $self->{data}{$to} = delete $self->{data}{$from};
        delete $self->{warning_hash}{$from};

        # update index_value attribute in moved objects
        $self->{data}{$to}->index_value($to);

        $self->notify_change( note => "rename key from '$from' to '$to'" );

        # data_mode is preset or layered or user. Actually only user
        # mode makes sense here
        my $imode = $self->instance->get_data_mode;
        $self->set_data_mode( $to, $imode );

        my ( $to_idx, $from_idx );
        my $idx  = 0;
        my $list = $self->{list};
        map {
            $to_idx   = $idx if $list->[$idx] eq $to;
            $from_idx = $idx if $list->[$idx] eq $from;
            $idx++;
        } @$list;

        if ( defined $to_idx ) {

            # Since $to is clobbered, $from takes its place in the list
            $list->[$from_idx] = $to;

            # and the $from entry is removed from the list
            splice @$list, $to_idx, 1;
        }
        else {
            # $to is moved in the place of from in the list
            $list->[$from_idx] = $to;
        }
    }
    elsif ($check eq 'yes') {
        Config::Model::Exception::WrongValue->throw(
            error  => join( "\n\t", @{ $self->{error} } ),
            object => $self
        );
    }
    $logger->debug("Skipped move $from -> $to");
    return $ok;
}

sub move_after {
    my $self = shift;
    my ( $key_to_move, $ref_key ) = @_;

    if ( not $self->ordered ) {
        $logger->warn("called move_after on unordered hash");
        return;
    }

    foreach my $k (@_) {
        Config::Model::Exception::User->throw(
            object  => $self,
            message => "swap: unknow key $k"
        ) unless exists $self->{data}{$k};
    }

    # remove the key to move in ordered list
    @{ $self->{list} } = grep { $_ ne $key_to_move } @{ $self->{list} };

    my $list = $self->{list};

    my $msg;
    if ( defined $ref_key ) {
        for ( my $idx = 0 ; $idx <= $#$list ; $idx++ ) {
            if ( $list->[$idx] eq $ref_key ) {
                splice @$list, $idx + 1, 0, $key_to_move;
                last;
            }
        }

        $msg = "moved key '$key_to_move' after '$ref_key'";
    }
    else {
        unshift @$list, $key_to_move;
        $msg = "moved key '$key_to_move' at beginning";
    }

    $self->notify_change( note => $msg );

}

sub move_up {
    my $self = shift;
    my ($key) = @_;

    if ( not $self->ordered ) {
        $logger->warn("called move_up on unordered hash");
        return;
    }

    Config::Model::Exception::User->throw(
        object  => $self,
        message => "move_up: unknow key $key"
    ) unless exists $self->{data}{$key};

    my $list = $self->{list};

    # we start from 1 as we can't move up idx 0
    for ( my $idx = 1 ; $idx < scalar @$list ; $idx++ ) {
        if ( $list->[$idx] eq $key ) {
            $list->[$idx] = $list->[ $idx - 1 ];
            $list->[ $idx - 1 ] = $key;
            $self->notify_change( note => "moved up key '$key'" );
            last;
        }
    }

    # notify_change is placed in the loop so the notification
    # is not sent if the user tries to move up idx 0
}

sub move_down {
    my $self = shift;
    my ($key) = @_;

    if ( not $self->ordered ) {
        $logger->warn("called move_down on unordered hash");
        return;
    }

    Config::Model::Exception::User->throw(
        object  => $self,
        message => "move_down: unknown key $key"
    ) unless exists $self->{data}{$key};

    my $list = $self->{list};

    # we end at $#$list -1  as we can't move down last idx
    for ( my $idx = 0 ; $idx < scalar @$list - 1 ; $idx++ ) {
        if ( $list->[$idx] eq $key ) {
            $list->[$idx] = $list->[ $idx + 1 ];
            $list->[ $idx + 1 ] = $key;
            $self->notify_change( note => "moved down key $key" );
            last;
        }
    }

    # notify_change is placed in the loop so the notification
    # is not sent if the user tries to move past last idx
}

sub load_data {
    my $self  = shift;
    my %args  = @_ > 1 ? @_ : ( data => shift );
    my $data  = delete $args{data};
    my $check = $self->_check_check( $args{check} );

    if ( ref($data) eq 'HASH' ) {
        my @load_keys;
        my $from = '';

        my $order_key = '__'.$self->element_name.'_order';
        if ( $self->{ordered} and (defined $data->{$order_key} or defined $data->{__order} )) {
            @load_keys = @{ delete $data->{$order_key} or delete $data->{__order} };
            $from      = ' with '.$order_key;
        }
        elsif ( $self->{ordered} ) {
            $logger->warn( "HashId "
                    . $self->location
                    . ": loading ordered "
                    . "hash from hash ref without special key '__order'. Element "
                    . "order is not defined" );
            $from = ' without '.$order_key;
        }

        @load_keys = sort keys %$data unless @load_keys;

        $logger->info( "HashId load_data ("
                . $self->location
                . ") will load idx @load_keys from hash ref"
                . $from );
        foreach my $elt (@load_keys) {
            my $obj = $self->fetch_with_id($elt);
            $obj->load_data( %args, data => $data->{$elt} );
        }
    }
    elsif ( ref($data) eq 'ARRAY' ) {
        $logger->info(
            "HashId load_data (" . $self->location . ") will load idx 0..$#$data from array ref" );
        $self->notify_change( note => "Converted ordered data to non ordered", really => 1) unless $self->ordered;
        my $idx = 0;
        while ( $idx < @$data ) {
            my $elt = $data->[ $idx++ ];
            my $obj = $self->fetch_with_id($elt);
            $obj->load_data( %args, data => $data->[ $idx++ ] );
        }
    }
    elsif ( defined $data ) {

        # we can skip undefined data
        my $expected = $self->{ordered} ? 'array' : 'hash';
        Config::Model::Exception::LoadData->throw(
            object     => $self,
            message    => "load_data called with non $expected ref arg",
            wrong_data => $data,
        );
    }
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Handle hash element for configuration model

__END__

=head1 SYNOPSIS

See L<Config::Model::AnyId/SYNOPSIS>

=head1 DESCRIPTION

This class provides hash elements for a L<Config::Model::Node>.

The hash index can either be en enumerated type, a boolean, an integer
or a string.

=head1 CONSTRUCTOR

HashId object should not be created directly.

=head1 Hash model declaration

See
L<model declaration section|Config::Model::AnyId/"Hash or list model declaration">
from L<Config::Model::AnyId>.

=head1 Methods

=head2 get_type

Returns C<hash>.

=head2 fetch_size

Returns the number of elements of the hash.

=head2 sort

Sort an ordered hash. Throws an error if called on a non ordered hash.

=head2 firstkey

Returns the first key of the hash. Behaves like C<each> core perl
function.

=head2 nextkey

Returns the next key of the hash. Behaves like C<each> core perl
function.

=head2 swap ( key1 , key2 )

Swap the order of the 2 keys. Ignored for non ordered hash.

=head2 move ( key1 , key2 )

Rename key1 in key2. 

Also also optional check parameter to disable warning:

 move ('foo','bar', check => 'no')

=head2 move_after ( key_to_move [ , after_this_key ] )

Move the first key after the second one. If the second parameter is
omitted, the first key is placed in first position. Ignored for non
ordered hash.

=head2 move_up ( key )

Move the key up in a ordered hash. Attempt to move up the first key of
an ordered hash is ignored. Ignored for non ordered hash.

=head2 move_down ( key )

Move the key down in a ordered hash. Attempt to move up the last key of
an ordered hash is ignored. Ignored for non ordered hash.

=head2 load_data ( data => ( hash_ref | array_ref ) [ , check => ... , ... ])

Load check_list as a hash ref for standard hash. 

Ordered hash should be loaded with an array ref or with a hash
containing a special C<__order> element. E.g. loaded with either:

  [ a => 'foo', b => 'bar' ]

or

  { __order => ['a','b'], b => 'bar', a => 'foo' }

load_data can also be called with a single ref parameter.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::AnyId>,
L<Config::Model::ListId>,
L<Config::Model::Value>

=cut
