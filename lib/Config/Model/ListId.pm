package Config::Model::ListId ;

use 5.10.1;
use Mouse ;
use namespace::autoclean;

use Config::Model::Exception ;
use Log::Log4perl qw(get_logger :levels);

use Carp;
extends qw/Config::Model::AnyId/ ;

my $logger = get_logger("Tree::Element::Id::List") ;

has data => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] ;},
    traits => ['Array'],
    handles => {
        _sort_data => 'sort_in_place',
        _all_data => 'elements',
        _splice_data => 'splice',
    }
) ;



# compatibility with HashId
has index_type => ( is => 'ro', isa => 'Str', default => 'integer' ) ;
has auto_create_ids => ( is => 'rw' ) ;

sub BUILD {
    my $self = shift;

    foreach my $wrong (qw/max_nb min_index default_keys/) {
        Config::Model::Exception::Model->throw (
            object => $self,
            error =>  "Cannot use $wrong with ".$self->get_type." element"
        ) if defined $self->{$wrong};
    }

    if (defined $self->{migrate_keys_from}) {
        warn $self->name, "Using migrate_keys_from with list element is deprecated.",
            " Use migrate_values_from\n" ;
    }

    # Supply the mandatory parameter
    return $self;
}


sub set_properties {
    my $self = shift ;

    $self->SUPER::set_properties(@_) ;

    # remove unwanted items
    my $data = $self->{data} ;

    return unless defined $self->{max_index} ;

    # delete entries that no longer fit the constraints imposed by the
    # warp mechanism
    foreach my $k (0 .. $#{$data}) {
        next unless  $k >  $self->{max_index};
        $logger->debug("set_properties: ",$self->name," deleting index $k") ;
        delete $data->[$k] ;
    }
}

sub _migrate {
    my $self = shift;

    return if $self->{migration_done};
    
    # migration must be done *after* initial load to make sure that all data
    # were retrieved from the file before migration. 
    return if $self->instance->initial_load ;
    
    $self->{migration_done} = 1;
    
    if ( $self->{migrate_values_from}) {
        my $followed = $self->safe_typed_grab(param => 'migrate_values_from', check => 'no') ;
        $logger ->debug($self->name," migrate values from ",$followed->name) if $logger->is_debug;
        my $idx   = $self->fetch_size ;
        foreach my $item ( $followed -> fetch_all_indexes ) {
            my $data = $followed->fetch_with_id($item) -> dump_as_data(check => 'no') ;
            $self->fetch_with_id( $idx++ )->load_data($data) ;
        }
    }
    elsif ($self->{migrate_keys_from}) {
        # FIXME: remove this deprecated stuff
        my $followed = $self->safe_typed_grab(param => 'migrate_keys_from', check => 'no') ;
        map { $self->_store($_, undef) unless $self->_defined($_) } $followed -> fetch_all_indexes ;
    }


}

sub get_type {
    my $self = shift;
    return 'list' ;
}

# important: return the actual size (not taking into account auto-created stuff)
sub fetch_size {
    my $self =shift ;
    return scalar @{$self->{data}} ;
}

sub _fetch_all_indexes {
    my $self = shift ;
    my $data = $self->{data} ;
    return scalar @$data ? (0 .. $#$data ) : () ;
}

# fetch without any check 
sub _fetch_with_id {
    my ($self, $idx) = @_ ;
    return $self->{data}[$idx];
}


sub load {
    my ($self, $string, %args) = @_ ;
    my $check = $self->_check_check($args{check}) ; # I write too many checks.
    
    my @set ;
    my $cmd = $string ;
    my $regex = qr/^(
                    (?:
                             "
                        (?: \\" | [^"] )*?
                      "
                    )
                    |
                    [^,]+
                   )
                  /x;

    
    while (length($string)) {
        #print "string: $string\n";
        $string =~ s/$regex// or last;
        my $tmp = $1 ;
        #print "tmp: $tmp\n";
        $tmp =~ s/^"|"$//g if defined $tmp; 
        $tmp =~ s/\\"/"/g  if defined $tmp; 
        push @set,$tmp ;

        last unless length($string) ;
    }
    continue {
        $string =~ s/^,// or last ;
    }

    if (length($string)) {
        Config::Model::Exception::Load
            -> throw ( object => $self, 
                       command => $cmd,
                       message => "unexpected load command '$cmd', left '$cmd'" ) ;
    }

    $self->store_set(@set ) ;
}


sub store_set {
    my $self = shift ;
    my @v = @_ ;
    my $r = shift ;
    my %args = (check => 'yes');
    
    if (ref $r eq 'ARRAY') {
        @v = @$r ;
        %args = @_; # note that $r was shifted out of @_
    }

    my @comments = @{ $args{comment} || [] } ;

    my $idx = 0 ;
    foreach (@v) { 
        if (defined $_) {
            my $v_obj = $self->fetch_with_id( $idx++ ) ;
            $v_obj -> store(%args, value => $_);
            $v_obj->annotation(shift @comments) if @comments ;
        }
        else {
            $self->{data}[$idx] = undef ; # detruit l'objet pas bon!
        }
    } ;

    # and delete unused items
    my $max = scalar @{$self->{data}} ;
    splice @{$self->{data}}, $idx, $max - $idx ;
}

# store without any check 
sub _store {
    my ($self, $idx, $value) =  @_ ;
    return $self->{data}[$idx] = $value ;
}

sub _defined {
    my ($self,$key) = @_ ;
    croak "argument '$key' is not numeric" unless $key =~ /^\d+$/;
    return defined $self->{data}[$key];
}

sub _exists {
    my ($self, $idx) = @_ ;
    return exists $self->{data}[$idx];
}

sub _delete {
    my ($self,$idx) = @_ ;
    return delete $self->{data}[$idx];
}

sub _clear {
    my ($self)= @_ ;
    $self->{data} = [] ;
}


sub move {
    my ($self,$from, $to,%args) = @_ ;
    my $check = $self->_check_check($args{check}) ;

    my $moved = $self->fetch_with_id($from) ;
    $self->_delete($from);
    delete $self->{warning_hash}{$from} ;

    my $ok = $self->check_idx($to) ;
    if ($ok or $check eq 'no') {
        $self->_store($to, $moved) ;
        $moved->index_value($to) ;
        $self->notify_change(note => "moved from index $from to $to") ;
        my $imode = $self->instance->get_data_mode ;
        $self->set_data_mode( $to, $imode ) ;
    }
    else {
        # restore moved item where it came from
        $self->_store($from, $moved) ;
        if ($check ne 'skip') {
            Config::Model::Exception::WrongValue 
                -> throw (
                          error => join("\n\t",@{$self->{error}}),
                          object => $self
                         ) ;
        }
    }
}


# list only methods
sub push {
    my $self = shift ;
    $self->_assert_leaf_cargo;
    my $idx   = $self->fetch_size ;
    map { $self->fetch_with_id( $idx++ )->store( $_ ) ; } @_ ;
}


# list only methods
sub push_x {
    my $self = shift ;
    my %args = @_ ;
    $self->_assert_leaf_cargo;
    my $check = delete $args{check} || 'yes'; 
    my $v_arg = delete $args{values} || delete $args{value};
    my @v = ref ($v_arg) ? @$v_arg : ($v_arg)  ;
    my $anno = delete $args{annotation} ;
    my @a = ref ($anno) ? @$anno : $anno ? ($anno) : () ;
    
    croak("push_x: unexpected parameter ",join(' ',keys %args)) if %args ;
    
    my $idx   = $self->fetch_size ;
    while (@v) {
        my $val = shift @v ;
        my $obj = $self->fetch_with_id( $idx++ );
        $obj->store( $val ) ;
        $obj->annotation(shift @a) if @a ;
    }
}

sub unshift {
    my $self = shift;
    $self->insert_at(0,@_) ;
}

sub insert_at {
    my $self = shift;
    my $idx = shift;

    $self->_assert_leaf_cargo;
    # check if max_idx is respected
    $self->check_idx($self->fetch_size + scalar @_) ;

    # make room at the beginning of the array
    $self->_splice_data( $idx, 0, (undef) x scalar @_ );
    my $i = $idx ;
    map { $self->fetch_with_id($i++)->store($_) ; } @_ ;

    $self->_reindex;
}

sub insert_before {
    my $self = shift;
    my $val  = shift;
    my $test
        = ref($val) eq 'Regexp' ? sub { $_[0] =~ /$val/ }
        :                         sub { $_[0] eq $val } ;

    $self->_assert_leaf_cargo;

    my $point = 0;
    foreach my $v ($self->fetch_all_values) {
        last if $test->($v) ;
        $point++;
    }

    $self->insert_at($point,@_) ;
}

sub insort {
    my $self = shift;
    $self->_assert_leaf_cargo;
    my @insert = sort @_ ;

    my $point = 0;
    foreach my $v ( $self->fetch_all_values) {
        while (@insert and $insert[0] lt $v ) {
            $self->insert_at($point++,shift @insert) ;
        }
        $point++;
    }
    $self->push(@insert) if @insert;
}


sub store {
    my $self = shift;
    $self->push_x(@_) ;
}

sub _assert_leaf_cargo {
    my $self = shift;

    my $ct = $self->cargo_type;

    Config::Model::Exception::User ->throw (
        object => $self,
        error => "Cannot call sort on list of $ct"
    ) unless $ct eq 'leaf';
}

sub sort {
    my $self = shift;

    $self->_assert_leaf_cargo;
     ;
    $self->_sort_data( sub { $_[0]->fetch cmp $_[1]->fetch; });

    my $has_changed = $self->_reindex;
    $self->notify_change(note => "sorted") if $has_changed ;
}

sub _reindex {
    my $self = shift;

    my $i = 0;
    my $has_changed = 0;
    foreach my $o ($self->_all_data) {
        next unless defined $o;
        $has_changed =1 if $o->index_value != $i;
        $o->index_value($i++);
    }
    return $has_changed;
}

sub swap {
    my $self = shift ;
    my $ida  = shift ;
    my $idb  = shift ;

    my $obja = $self->{data}[$ida] ;
    my $objb = $self->{data}[$idb] ;

    # swap the index values contained in the objects
    my $obja_index = $obja->index_value ;
    $obja->index_value( $objb->index_value ) ;
    $objb->index_value( $obja_index ) ;

    # then swap the objects
    $self->{data}[$ida] = $objb ;
    $self->{data}[$idb] = $obja ;
    
    $self->notify_change(note => "swapped index $ida and $idb") ;
}

#die "check index number after wap";


sub remove {
    my $self = shift ;
    my $idx  = shift ;

    Config::Model::Exception::User ->throw (
        object => $self,
        error => "Non numeric index for list: $idx"
    ) unless $idx =~ /^\d+$/;

    $self->delete_data_mode(index => $idx) ;
    $self->notify_change ;
    splice @{$self->{data}}, $idx , 1 ;
}

#internal
sub auto_create_elements {
    my $self = shift ;

    my $auto_nb = $self->auto_create_ids ;
    return unless defined $auto_nb ;
    
    $logger->debug($self->name," auto-creating $auto_nb elements");

    Config::Model::Exception::Model
        ->throw (
                 object => $self,
                 error => "Wrong auto_create argument for list: $auto_nb"
                ) unless $auto_nb =~ /^\d+$/;

    my $auto_p = $auto_nb - 1;

    # create empty slots
    map {
        $self->{data}[$_] = undef unless defined $self->{data}[$_];
    }  (0 .. $auto_p ) ;
}

# internal
sub create_default {
    my $self = shift ;

    return if @{$self->{data}} ;

    # list is empty so create empty element for default keys
    my $def = $self->get_default_keys ;

    map {$self->{data}[$_] = undef } @$def ;

    $self->create_default_with_init ;
}


sub load_data {
    my $self = shift ;
    my %args = @_ > 1 ? @_ : ( data => shift) ;
    my $raw_data    = delete $args{data};
    my $check = $self->_check_check($args{check}) ;

    my $data = ref($raw_data) eq 'ARRAY' ? $raw_data 
             : $args{split_reg}          ? [ split $args{split_reg}, $raw_data ]
             : defined $raw_data         ? [ $raw_data ] 
             :                             undef; 

    Config::Model::Exception::LoadData -> throw (
        object => $self,
        message => "load_data called with non expected data. Expected array ref or scalar",
        wrong_data => $raw_data ,
    ) unless defined $data;

    $self->clear ;

    my $idx = 0;
    $logger->info("ListId load_data (",$self->location,") will load idx ",
        "0..$#$data");
    foreach my $item (@$data ) {
        my $obj = $self->fetch_with_id($idx++) ;
        $obj -> load_data(%args, data => $item) ;
    }   
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Handle list element for configuration model

__END__

=head1 SYNOPSIS

See L<Config::Model::AnyId/SYNOPSIS>

=head1 DESCRIPTION

This class provides list elements for a L<Config::Model::Node>.

=head1 CONSTRUCTOR

ListId object should not be created directly.

=head1 List model declaration

See
L<model declaration section|Config::Model::AnyId/"Hash or list model declaration">
from L<Config::Model::AnyId>.

=head1 Methods

=head2 get_type

Returns C<list>.

=head2 fetch_size

Returns the number of elements of the list.

=head2 load(string, [ check => 'no' ] )

Store a set of values passed as a comma separated list of values. 
Values can be quoted strings. (i.e C<"a,a",b> will yield
C<('a,a', 'b')> list). 

C<check> can be yes, no or skip

=head2 store_set( ... )

Store a set of values (passed as list)

If tinkering with check is required, use the following way : 

 store_set ( \@v , check => 'skip' );

=head2 move ( from_index, to_index, [ check => 'no' )

Move an element within the list. C<check> can be 'yes' 'no' 'skip'

=head2 push( value1, [ value2 ... ] )

push some values at the end of the list.

=head2 push_x ( values => [ v1','v2', ...] ,  ...  )

Like push with extended options. Options are:

=over

=item check

Check value validaty. Either C<yes> (default), C<no>, C<skip> 

=item values

Values to push (array_ref)

=item value

Single value to push

=item annotation

=back

=head2 unshift( value1, [ value2 ... ] )

unshift some values at the end of the list.

=head2 insert_at( idx, value1, [ value2 ... ] )

unshift some values at index idx in the list.

=head2 insert_before( ( val | qr/stuff/ ) , value1, [ value2 ... ] )

unshift some values before value equal to C<val> or before value matching C<stuff>.

=head2 insort( value1, [ value2 ... ] )

Insert C<zz> value on C<xxx> list so that existing alphanumeric order is preserved.
Will yield unpexpected results if call on an unsorted list.

=head2 store

Equivalent to push_x. This method is provided to help write
configuration parser, so the call is the same when dealing with leaf or
list values. Prefer C<push_x> when practical.

=over 4

=item check 

C<yes>, C<no> or C<skip>

=item annotation

list ref of annotation to store with the list values

=back

Example:

 $elt->push_x (
    values => [ 'v1','v2' ] ,
    annotation => [ 'v1 comment', 'v2 comment' ],
    check => 'skip'
 );

=head2 sort()

Sort the content of the list. Can only be called on list of leaf.

=head2 swap ( C<ida> , C<idb> )

Swap 2 elements within the array

=head2 remove ( C<idx> )

Remove an element from the list. Equivalent to C<splice @list,$idx,1>

=head2 load_data ( data => ( ref | scalar ) [, check => ... ] [ , split_reg => $re ] )

Clear and load list from data contained in the C<data> array ref. If a scalar or a hash ref
is passed, the list is cleared and the data is stored in
the first element of the list. If split_reg is specified, the scalar will be split
to load the array.

For instance

   $elt->load_data( data => 'foo,bar', split_reg => qr(,) ) ;

will load C< [ 'foo','bar']> in C<$elt>

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::AnyId>,
L<Config::Model::HashId>,
L<Config::Model::Value>

=cut
