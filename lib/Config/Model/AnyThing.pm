package Config::Model::AnyThing;

use Mouse;

# FIXME: must cleanup warp mechanism to implement this
# use MouseX::StrictConstructor;

use Pod::POM;
use Carp;
use Log::Log4perl qw(get_logger :levels);
use 5.10.1;

my $logger        = get_logger("Anything");
my $change_logger = get_logger("ChangeTracker");

has element_name => ( is => 'ro', isa => 'Str' );
has parent       => ( is => 'ro', isa => 'Config::Model::Node', weak_ref => 1 );

has instance     => (
    is => 'ro',
    isa => 'Config::Model::Instance',
    weak_ref => 1,
    handles => [qw/show_message/]
);

# needs_check defaults to 1 to trap undef mandatory values
has needs_check => ( is => 'rw', isa => 'Bool', default => 1 );

# index_value can be written to when move method is called. But let's
# not advertise this feature.
has index_value => (
    is      => 'rw',
    isa     => 'Str',
    trigger => sub { my $self = shift; $self->{location} = $self->_location; },
);

has container => ( is => 'ro', isa => 'Ref', required => 1, weak_ref => 1 );

has container_type => ( is => 'ro', isa => 'Str', builder => '_container_type', lazy => 1 );

sub _container_type {
    my $self = shift;
    my $p    = $self->parent;
    return defined $p
        ? $p->element_type( $self->element_name )
        : 'node';    # root node

}

has root => (
    is       => 'ro',
    isa      => 'Config::Model::Node',
    weak_ref => 1,
    builder  => '_root',
    lazy     => 1
);

sub _root {
    my $self = shift;

    return $self->parent || $self;
}

has location       => ( is => 'ro', isa => 'Str', builder => '_location', lazy => 1 );
has location_short => ( is => 'ro', isa => 'Str', builder => '_location_short', lazy => 1 );

has backend_support_annotation => (
    is => 'ro',
    isa => 'Bool',
    builder  => '_backend_support_annotation',
    lazy     => 1
);

sub _backend_support_annotation {
    my $self = shift;
    # this method is overridden in Config::Model::Node
    return $self->parent->backend_support_annotation;
};

sub notify_change {
    my $self = shift;
    my %args = @_;

    return if $self->instance->initial_load and not $args{really};

    $change_logger->trace( "called for ", $self->name, " from ", join( ' ', caller ),
        " with ", join( ' ', %args ) )
        if $change_logger->is_trace;

    # needs_save may be overridden by caller
    $args{needs_save} //= 1;
    $args{path}       //= $self->location;
    $args{name}       //= $self->element_name if $self->element_name;
    $args{index}      //= $self->index_value if $self->index_value;

    # better use %args instead of @_ to forward arguments. %args eliminates duplicated keys
    $self->container->notify_change(%args);
}

sub _location {
    my $self = shift;

    my $str = '';
    $str .= $self->parent->location if defined $self->parent;

    $str .= ' ' if $str;

    $str .= $self->composite_name;

    return $str;
}

sub _location_short {
    my $self = shift;

    my $str = '';
    $str .= $self->parent->location_short if defined $self->parent;

    $str .= ' ' if $str;

    $str .= $self->composite_name_short;

    return $str;
}

#has composite_name => (is => 'ro', isa => 'Str' , builder => '_composite_name', lazy => 1);

sub composite_name {
    my $self = shift;

    my $element = $self->element_name;
    $element = '' unless defined $element;

    my $idx = $self->index_value;
    return $element unless defined $idx;
    $idx = '"' . $idx . '"' if $idx =~ /\W/;

    return "$element:$idx";
}

sub composite_name_short {
    my $self = shift;

    my $element = $self->element_name;
    $element = '' unless defined $element;


    my $idx = $self->shorten_idx($self->index_value);
    return $element unless length $idx;
    $idx = '"' . $idx . '"' if $idx =~ /\W/;
    return "$element:$idx";
}

sub shorten_idx {
    my $self = shift;
    my $long_index = shift ;

    my @idx = split /\n/, $long_index // '' ;
    my $idx = shift @idx;
    $idx .= '[...]' if @idx;

    return $idx // ''; # may be undef on freebsd with perl 5.10.1 ...
}


## Fixme: not yet tested
sub xpath {
    my $self = shift;

    $logger->trace("xpath called on $self");

    my $element = $self->element_name;
    $element = '' unless defined $element;

    my $idx = $self->index_value;

    my $str = '';
    $str .= $self->cim_parent->parent->xpath
        if $self->can('cim_parent')
        and defined $self->cim_parent;

    $str .= '/' . $element . ( defined $idx ? "[\@id=$idx]" : '' ) if $element;

    return $str;
}

sub annotation {
    my $self = shift;
    my $old_note = $self->{annotation} || '';
    if (@_ and not $self->instance->preset and not $self->instance->layered) {
        my $new = $self->{annotation} = join( "\n", grep ( defined $_, @_ ) );
        $self->notify_change(note => 'updated annotation') unless $new eq $old_note;
    }

    return $self->{annotation} || '';
}

sub clear_annotation {
    my $self = shift;
    $self->notify_change(note => 'deleted annotation') if $self->{annotation};
    $self->{annotation} = '';
}

# may be used (but not yet) to load annotation from perl data file
sub load_pod_annotation {
    my $self = shift;
    my $pod  = shift;

    my $parser = Pod::POM->new();
    my $pom    = $parser->parse_text($pod)
        || croak $parser->error();
    my $sections = $pom->head1();

    foreach my $s (@$sections) {
        next unless $s->title eq 'Annotations';

        foreach my $item ( $s->over->[0]->item ) {
            my $path = $item->title . '';    # force string representation. Not understood why...
            $path =~ s/^[\s\*]+//;
            my $note = $item->text . '';
            $note =~ s/\s+$//;
            $logger->trace("load_pod_annotation: '$path' -> '$note'");
            $self->grab( steps => $path )->annotation($note);
        }
    }
}

# fallback method for object that don't implement has_data
sub has_data {
    my $self= shift;
    $logger->trace("called fall-back has_data for element", $self->name) if $logger->is_trace;
    return 1;
}

sub model_searcher {
    my $self = shift;
    my %args = @_;

    my $model = $self->instance->config_model;
    return Config::Model::SearchElement->new( model => $model, node => $self, %args );
}

sub searcher {
    carp "Config::Model::AnyThing searcher is deprecated";
    goto &model_searcher;
}

sub dump_as_data {
    my $self   = shift;
    my $dumper = Config::Model::DumpAsData->new;
    $dumper->dump_as_data( node => $self, @_ );
}

# hum, check if the check information is valid
sub _check_check {
    my $self = shift;
    my $p    = shift;

    return 'yes' if not defined $p or $p eq '1' or $p eq 'yes';
    return 'no'  if $p eq '0'      or $p eq 'no';
    return $p    if $p eq 'skip';

    croak "Internal error: Unvalid check value: $p";
}

sub has_fixes {
    my $self = shift;
    $logger->trace( "dummy has_fixes called on " . $self->name );
    return 0;
}

sub has_warning {
    my $self = shift;
    $logger->trace( "dummy has_warning called on " . $self->name );
    return 0;
}

sub warp_error {
    my $self = shift;
    return '' unless defined $self->{warper};
    return $self->{warper}->warp_error;
}

# used by Value and AnyId
sub set_convert {
    my ( $self, $arg_ref ) = @_;

    my $convert = delete $arg_ref->{convert};

    # convert_sub keeps a subroutine reference
    $self->{convert_sub} =
          $convert eq 'uc' ? sub { uc(shift) }
        : $convert eq 'lc' ? sub { lc(shift) }
        :                    undef;

    Config::Model::Exception::Model->throw(
        object => $self,
        error  => "Unexpected convert value: $convert, " . "expected lc or uc"
    ) unless defined $self->{convert_sub};
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Base class for configuration tree item

__END__

=head1 SYNOPSIS

 # internal class

=head1 DESCRIPTION

This class must be inherited by all nodes or leaves of the
configuration tree.

AnyThing provides some methods and no constructor.

=head1 Introspection methods

=head2 element_name()

Returns the element name that contain this object.

=head2 index_value()

For object stored in an array or hash element, returns the index (or key)
containing this object.

=head2 parent

Returns the node containing this object. May return undef if C<parent()> 
is called on the root of the tree.

=head2 container_type()

Returns the type (e.g. C<list> or C<hash> or C<leaf> or C<node> or
C<warped_node>) of the element containing this object. 

=head2 root()

Returns the root node of the configuration tree.

=head2 location()

Returns the node location in the configuration tree. This location
conforms with the syntax defined by L<grab|Config::Model::Role::Grab/grab> method.

=head2 location_short()

Returns the node location in the configuration tree. This location truncates long
indexes to be readable. It cannot be used by L<grab|Config::Model::Role::Grab/grab> method.

=head2 composite_name

Return the element name with its index (if any). I.e. returns C<foo:bar> or
C<foo>.

=head2 composite_name_short

Return the element name with its index (if any). Too long indexes are
truncated to be readable.

=head1 Annotation

Annotation is a way to store miscellaneous information associated to
each node. (Yeah... comments). Reading and writing annotation makes
sense only if they can be read from and written to the configuration
file, hence the need for the following method:

=head2 backend_support_annotation

Returns 1 if at least one of the backends attached to a parent node
support to read and write annotations (aka comments) in the
configuration file.

=head2 support_annotation

Returns 1 if at least one of the backends support to read and write annotations
(aka comments) in the configuration file.

=head2 annotation( [ note1, [ note2 , ... ] ] )

Without argument, return a string containing the object's annotation (or 
an empty string).

With several arguments, join the arguments with "\n", store the annotations 
and return the resulting string.

=head2 load_pod_annotation ( pod_string )

Load annotations in configuration tree from a pod document. The pod must
be in the form:

 =over
 
 =item path
 
 Annotation text
 
 =back
 
=head2 clear_annotation

Clear the annotation of an element

=head1 Information management

=head2 notify_change(...)

Notify the instance of semantic changes. Parameters are:

=over 8

=item old

old value. (optional)

=item new

new value (optional)

=item path

Location of the changed parameter starting from root node. Default to C<$self->location>.

=item name

element name. Default to C<$self->element_name>

=item index

If the changed parameter is part of a hash or an array, C<index>
contains the key or the index to get the changed parameter.

=item note

information about the change. Mandatory of neither old or new value are defined.

=item really

When set to 1, force recording of change even if in initial load phase.

=item needs_save

internal parameter.

=back

=head2 show_message( string )

Forwarded to L<Config::Model::Instance/"show_message( string )">.

=head2 model_searcher ()

Returns an object dedicated to search an element in the configuration
model (respecting privilege level).

This method returns a L<Config::Model::SearchElement> object. See
L<Config::Model::Searcher> for details on how to handle a search.

=head2 dump_as_data ( )

Dumps the configuration data of the node and its siblings into a perl
data structure. 

Returns a hash ref containing the data. See
L<Config::Model::DumpAsData> for details.

=head2 warp_error

Returns a string describing any issue with L<Config::Model::Warper> object. 
Returns '' if invoked on a tree object without warp specification.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::Node>, 
L<Config::Model::Loader>, 
L<Config::Model::Dumper>

=cut
