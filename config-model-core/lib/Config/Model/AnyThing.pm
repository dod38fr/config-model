package Config::Model::AnyThing;

use Any::Moose ;
use namespace::autoclean;

use Pod::POM ;
use Carp;
use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger("Anything") ;

has element_name => ( is => 'ro', isa => 'Str') ;
has parent => (is => 'ro', isa => 'Config::Model::Node' , weak_ref => 1);
has instance => (is => 'ro', isa => 'Config::Model::Instance', weak_ref => 1) ;

# needs_check defaults to 1 to trap undef mandatory values
has needs_check => (is => 'rw', isa => 'Bool', default => 1 );

# index_value can be written to when move method is called. But let's
# not advertise this feature.
has index_value => ( 
    is => 'rw', 
    isa => 'Str', 
    trigger => sub { my $self = shift; $self->{location} = $self->_location; } ,
) ;

has container => (is => 'ro', isa => 'Ref', required => 1, weak_ref => 1 ) ;

has container_type => ( is => 'ro', isa => 'Str' , builder => '_container_type', lazy => 1 );

sub _container_type {
    my $self = shift;
    my $p = $self->parent ;
    return defined $p ? $p->element_type($self->element_name)
                      : 'node' ; # root node

}

has root => (is => 'ro', isa => 'Config::Model::Node' , weak_ref => 1,
    builder => '_root', lazy => 1);

sub _root {
    my $self = shift;

    return $self->parent || $self;
}

has location => (is => 'ro', isa => 'Str' , builder => '_location', lazy => 1);

sub DEMOLISH {
    my $self = shift;

    # logger does not work during global desctruction
    #$logger->debug(ref($self).' '.$self->location." demolished") if $logger->is_debug ;

    # container may not be defined during global desctruction
    $self->container->notify_change(
	name => $self->element_name, 
	index => $self->index_value
    ) if defined $self->container;
}

sub notify_change {	
    my $self = shift ;

    $self->container->notify_change(
	needs_write => 1 , # may be overridden by caller
	@_, 
	name => $self->element_name, 
	index => $self->index_value
    );
}


sub _location {
    my $self = shift;

    my $str = '';
    $str .= $self->parent->location
        if defined $self->parent;

    $str .= ' ' if $str;

    $str .= $self->composite_name ;

    return $str;
}

#has composite_name => (is => 'ro', isa => 'Str' , builder => '_composite_name', lazy => 1);

sub composite_name {
    my $self = shift;

    my $element = $self->element_name;
    $element = '' unless defined $element;

    my $idx = $self->index_value;
    $idx = '"'.$idx.'"' if defined $idx && $idx =~ /\W/ ;

    return $element . ( defined $idx ? ':' . $idx : '' );
}

## Fixme: not yet tested
sub xpath { 
    my $self = shift;

    $logger->debug("xpath called on $self");

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
    my $self = shift ;
    $self->{annotation} = join("\n", grep (defined $_,@_)) 
        if @_ and not $self->instance->preset and not $self->instance->layered;
    return $self->{annotation} || '';
}


sub load_pod_annotation {
    my $self = shift ;
    my $pod = shift ;
    
    my $parser = Pod::POM->new();
    my $pom = $parser->parse_text($pod) 
        || croak $parser->error();
    my $sections = $pom->head1();

    foreach my $s ( @$sections ) {
        next unless $s->title eq 'Annotations' ;
        
        foreach my $item ( $s->over->[0]->item ) {
            my $path = $item->title.''; # force string representation. Not understood why...
            $path =~ s/^[\s\*]+//; 
            my $note = $item->text.'' ;
            $note =~ s/\s+$//;
            $logger->debug("load_pod_annotation: '$path' -> '$note'");
            $self->grab(step => $path )-> annotation($note) ;
        }
    }
}


## Navigation

# accept commands like
# item:b -> go down a node, create a new node if necessary
# - climbs up
# ! climbs up to the top 

# Now return an object and not a value !

sub grab {
    my $self = shift ;
    my ($step,$mode,$autoadd, $type, $grab_non_available,$check)
      = (undef, 'strict', 1, undef, 0, 'yes' ) ;

    my %args = @_ > 1 ? @_ : (step => $_[0] );

    $step    = delete $args{step};
    $mode    = delete $args{mode}  if defined $args{mode};
    $autoadd = delete $args{autoadd} if defined $args{autoadd};
    $grab_non_available = delete $args{grab_non_available} 
	if defined $args{grab_non_available};
    $type    = delete $args{type} ; # node, leaf or undef
    $check = $self->_check_check(delete $args{check}) ;

    if (defined $args{strict}) {
        carp "grab: deprecated parameter 'strict'. Use mode";
        $mode = delete $args{strict} ? 'strict' : 'adaptative' ;
    }

    Config::Model::Exception::User -> throw (
	object => $self,
	message => "grab: unexpected parameter: ".join(' ',keys %args)
    ) 
    if %args;

    Config::Model::Exception::Internal ->throw (
        error => "grab: step parameter must be a string ".
		 "or an array ref"
    ) 
    unless ref $step eq 'ARRAY' || not ref $step ;

    # accept commands, grep remove empty items left by spurious spaces
    my $huge_string = ref $step ? join (' ', @$step) : $step ;
    my @command = 
      ( 
       $huge_string =~ 
       m/
         (         # begin of *one* command
          (?:        # group parts of a command (e.g ...:... )
           [^\s"]+  # match anything but a space and a quote
           (?:        # begin quoted group 
             "         # begin of a string
              (?:        # begin group
                \\"       # match an escaped quote
                |         # or
                [^"]      # anything but a quote
              )*         # lots of time
             "         # end of the string
           )          # end of quoted group
           ?          # match if I got more than one group
          )+      # can have several parts in one command
         )        # end of *one* command
        /gx
      ) ;

    my @saved = @command ;

    $logger->debug( "grab: executing '",join("' '",@command), "' on object '",$self->name, "'");

    my @found = ($self) ;

  COMMAND:
    while ( @command ) {
	last if $mode eq 'step_by_step' and @saved > @command;

	my $cmd = shift @command ;

	my $obj = $found[-1] ;
        $logger->debug( "grab: executing cmd '$cmd' on object '",$obj->name, "($obj)'");

        if ($cmd eq '!') { 
            push @found, $obj->grab_root();
            next ;
          }
          
        if ($cmd =~ /^!([\w:]*)/) { 
            my $ancestor = $obj->grab_ancestor($1) ;
            if (defined $ancestor) {
                push @found, $ancestor ;
                next ;
            }
            else {
                Config::Model::Exception::AncestorClass -> throw (
                    object => $obj,
                    info => "grab called from '".$self->name.
                    "' with steps '@saved' looking for class $1"
		) if $mode eq 'strict' ;
                return ;
            }
        }

        if ($cmd =~ /^\?(\w[\w-]*)/) {
	    push @found, $obj->grab_ancestor_with_element_named($1) ;
	    $cmd =~ s/^\?// ; #remove the go up part
	    unshift @command, $cmd ;
	    next ;
          }

        if ($cmd eq '-') { 
            if (defined $obj->parent) {
                push @found, $obj->parent ; 
                next ;
              } 
            else {
                $logger->debug("grab: ",$obj->name," has no parent");
                return $mode eq 'adaptative' ? $obj : undef ;
              }
          }

        unless ($obj->isa('Config::Model::Node') 
		or $obj->isa('Config::Model::WarpedNode')) {
            Config::Model::Exception::Model
		->throw (
			 object => $obj,
			 message => "Cannot apply command '$cmd' on leaf item".
			 " (full command is '@saved')"
			) ;
	}

        my ($name, $action, $arg) 
	  = ($cmd =~ /(\w[\-\w]*)(?:(:)((?:"[^\"]*")|(?:[\w:\/\.\-\+]+)))?/);

	if (defined $arg and $arg =~ /^"/ and $arg =~ /"$/) {
	    $arg =~ s/^"// ; # remove leading quote
	    $arg =~ s/"$// ; # remove trailing quote
	}

	{
	  no warnings "uninitialized" ;
	  $logger->debug("grab: cmd '$cmd' -> name '$name', action '$action', arg '$arg'");
	}

        unless ($obj->has_element($name)) {
            if ($mode eq 'step_by_step') {
                return wantarray ? (undef,@command) : undef ;
            }
            elsif ($mode eq 'loose') {
                return ;
            }
            elsif ($mode eq 'adaptative') {
                last;
            }
            else {
                Config::Model::Exception::UnknownElement ->throw (
                    object => $obj,
                    element => $name,
                    function => 'grab',
                    info => "grab called from '".$self->name.
                        "' with steps '@saved'"
		) ;
	    }
	}

        unless ($grab_non_available 
		or $obj->is_element_available(name => $name, 
					      experience => 'master')) {
            if ($mode eq 'step_by_step') {
                return wantarray ? (undef,@command) : undef ;
            }
            elsif ($mode eq 'loose') {
                return ;
            }
            elsif ($mode eq 'adaptative') {
                last;
            }
            else {
                Config::Model::Exception::UnavailableElement ->throw (
                    object => $obj,
                    element => $name,
                    function => 'grab',
                    info => "grab called from '".$self->name.
			 "' with steps '@saved'"
		);
            }
	}

	my $next_obj = $obj->fetch_element( name => $name,
	    experience => 'master', check => $check, accept_hidden => $grab_non_available) ;

	# create list or hash element only if autoadd is true
        if (defined $action and $autoadd == 0
	    and not $next_obj->exists($arg)) 
	  {
            return if $mode eq 'loose' ;
            Config::Model::Exception::UnknownId->throw(
                object   => $obj->fetch_element($name),
                element  => $name,
                id       => $arg,
                function => 'grab'
            ) unless $mode eq 'adaptative';
	    last ;
	}

        if (defined $action and not $next_obj->isa('Config::Model::AnyId')) {
            Config::Model::Exception::Model
		->throw (
			 object => $obj,
			 message => "Cannot apply command '$cmd' on non hash or non list item".
			 " (full command is '@saved'). item is '".$next_obj->name."'"
			) ;
	    last ;
	}

	# action can only be :
	$next_obj = $next_obj -> fetch_with_id($arg) if defined $action ;

	push @found, $next_obj ;
    }

    # check element type
    if ( defined $type ) {
	while ( @found and $found[-1]-> get_type ne $type ) {
	    Config::Model::Exception::WrongType
		->throw (
			 object => $found[-1],
			 function => 'grab',
			 got_type => $found[-1] -> get_type,
			 expected_type => $type,
			 info   => "requested with step '$step'"
			) if $mode ne 'adaptative';
	    pop @found;
	}
    }

    my $return = $found[-1] ;
    $logger->debug("grab: returning object '",$return->name, "($return)'");
    return wantarray ? ($return,@command) : $return ;
}


sub grab_value {
    my $self = shift ;
    my %args = scalar @_ == 1 ? ( step => $_[0] ) : @_ ;
    
    my $obj = $self->grab(%args) ;
    # Pb: may return a node. add another option to grab ?? 
    # to get undef value when needed?

    return if ($args{mode} and $args{mode} eq 'loose' and not defined $obj);

    Config::Model::Exception::User -> throw (
		  object => $self,
		  message => "grab_value: cannot get value of non-leaf or check_list "
		  ."item with '".join("' '",@_)."'. item is $obj"
		 ) 
	  unless ref $obj and ( $obj->isa("Config::Model::Value") or 
            $obj->isa("Config::Model::CheckList"));

    my $value = $obj->fetch;
    if ($logger->is_debug) {
        my $str = defined $value ? $value : '<undef>' ;
        $logger->debug("grab_value: returning value $str of object '",$obj->name);
    }
    return $value ;
}


sub grab_annotation {
    my $self = shift ;
    my @args = scalar @_ == 1 ? ( step => $_[0] ) : @_ ;

    my $obj = $self->grab(@args) ;

    return $obj->annotation ;
}


sub grab_root {
    my $self = shift;
    return defined $self->parent ? $self->parent->grab_root
      : $self ;
}


sub grab_ancestor {
    my $self = shift ;
    my $class = shift || die "grab_ancestor: missing ancestor class" ;
    
    return $self if $self->get_type eq 'node' and $self->config_class_name eq $class ;
	
    return $self->{parent}->grab_ancestor ($class) if defined $self->{parent} ;
    return ;
}

#internal. Used by grab with '?xxx' steps
sub grab_ancestor_with_element_named {
    my ($self, $search, $type) = @_ ;

    my $obj = $self ;

    while (1) { 
	$logger->debug("grab_ancestor_with_element_named: executing cmd '?$search' on object "
	  .$obj->name);

	my $obj_element_name = $obj->element_name ;

	if ($obj->isa('Config::Model::Node') and $obj->has_element(name => $search, type => $type) ) {
	    # object contains the search element, we need to grab the
	    # searched object (i.e. the '?foo' part is done
	    return $obj ;
	}
	elsif (defined $obj->parent) {
	    # going up
	    $obj = $obj->parent ;
	}
	else {
	    # there's no more up to go to...
	    Config::Model::Exception::Model
		->throw (
			 object => $self,
			 error => "Error: cannot grab '?$search'"
			 ."from ". $self->name
			) ;
	}
    }
}


sub model_searcher {
    my $self = shift ;
    my %args = @_ ;

    my $model = $self->instance->config_model ;
    return Config::Model::SearchElement
      -> new(model => $model, node => $self, %args ) ;
}

sub searcher { 
    carp "Config::Model::AnyThing searcher is deprecated";
    goto &model_searcher ; 
}


sub dump_as_data {
    my $self = shift ;
    my $dumper = Config::Model::DumpAsData->new ;
    $dumper->dump_as_data(node => $self, @_) ;
}

# hum, check if the check information is valid
sub _check_check {
    my $self = shift ;
    my $p = shift ;

    return 'yes' if not defined $p or $p eq '1' or $p eq 'yes';
    return 'no'  if $p eq '0' or $p eq 'no' ;
    return $p    if $p eq 'skip' ;

    croak "Internal error: Unvalid check value: $p" ;
}

sub has_fixes {
    my $self = shift ;
    $logger->debug("dummy has_fixes called on ".$self->name);
    return 0;
}


sub warp_error {
    my $self = shift ;
    return '' unless defined $self->{warper} ;
    return $self->{warper} -> warp_error ;
}

# used by Value and AnyId
sub set_convert {
    my ($self, $arg_ref) = @_ ;

    my $convert = delete $arg_ref->{convert} ;
    # convert_sub keeps a subroutine reference
    $self->{convert_sub} = $convert eq 'uc' ? sub {uc(shift)} :
      $convert eq 'lc' ? sub {lc(shift)} : undef;

    Config::Model::Exception::Model
	-> throw (
		  object => $self,
		  error => "Unexpected convert value: $convert, "
		  ."expected lc or uc"
		 ) 
	  unless defined $self->{convert_sub};
}

__PACKAGE__->meta->make_immutable;


1;


__END__

=pod

=head1 NAME

Config::Model::AnyThing - Base class for configuration tree item

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

=head2 parent()

Returns the node containing this object. May return undef if C<parent()> 
is called on the root of the tree.

=head2 container_type()

Returns the type (e.g. C<list> or C<hash> or C<leaf> or C<node> or
C<warped_node>) of the element containing this object. 

=head2 root()

Returns the root node of the configuration tree.

=head2 location()

Returns the node location in the configuration tree. This location
conforms with the syntax defined by L</grab()> method.

=head2 composite_name

Return the element name with its index (if any). I.e. returns C<foo:bar> or
C<foo>.

=head1 Annotation

Annotation is a way to store miscellaneous information associated to
each node. (Yeah... comments) These comments will be saved outside of
the configuration file and restored the next time the command is run.

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
 

=head1 Information management

=head2 grab(...)

Grab an object from the configuration tree.

Parameters are:

=over

=item C<step>

A string indicating the steps to follow in the tree to find the
required item. (mandatory)

=item C<mode>

When set to C<strict>, C<grab> will throw an exception if no object is found
using the passed string. When set to C<adaptative>, the object found at last will
be returned. For instance, for the step C<good_step wrong_step>, only
the object held by C<good_step> will be returned. When set to C<loose>, grab 
will return undef in case of problem. (default is C<strict>)

=item C<type>

Either C<node>, C<leaf>, C<hash> or C<list>. Returns only an object of
requested type. Depending on C<strict> value, C<grab> will either
throw an exception or return the last found object of requested type.
(optional, default to C<undef>, which means any type of object)

=item C<autoadd>

When set to 1, C<hash> or C<list> configuration element are created
when requested by the passed steps. (default is 1). 

=item grab_non_available

When set to 1, grab will return an object even if this one is not
available. I.e. even if this element was warped out. (default is 0).

=back

The C<step> parameters is made of the following items separated by
spaces:

=over 8

=item -

Go up one node

=item !

Go to the root node.

=item !Foo

Go up the configuration tree until the C<Foo> configuration class is found. Raise an exception if 
no C<Foo> class is found when root node is reached.

=item xxx

Go down using C<xxx> element.

=item xxx:yy

Go down using C<xxx> element and id C<yy> (valid for hash or list elements)

=item ?xxx

Go up the tree until a node containing element C<xxx> is found. Then go down
the tree like item C<xxx>.

If C<?xxx:yy>, go up the tree the same way. But no check is done to
see if id C<yy> actually exists or not. Only the element C<xxx> is 
considered when going up the tree.

=back

=head2 grab_value(...)

Like L</grab(...)>, but will return the value of a leaf or check_list object, not
just the leaf object.

Will raise an exception if following the steps ends on anything but a
leaf or a check_list.

=head2 grab_annotation(...)

Like L</grab(...)>, but will return the annotation of an object.

=head2 grab_root()

Returns the root of the configuration tree.

=head2 grab_ancestor( Foo )

Go up the configuration tree until the C<Foo> configuration class is found. Returns 
the found node or undef.

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
