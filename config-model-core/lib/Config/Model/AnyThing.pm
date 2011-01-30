#    Copyright (c) 2005-2010 Dominique Dumont.
#
#    This file is part of Config-Model.
#
#    Config-Model is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Model is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

package Config::Model::AnyThing;
use Scalar::Util qw(weaken);
use Carp;
use strict;
use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger("Anything") ;

=head1 NAME

Config::Model::AnyThing - Base class for configuration tree item

=head1 SYNOPSIS

 package Config::Model::Node ;
 use base qw/Config::Model::AnyThing/ ;

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

=cut 

foreach my $datum (qw/element_name parent instance/) {
    no strict "refs";       # to register new methods in package
    *$datum = sub {
	my $self = shift;
	return $self->{$datum};
    } ;
}

# index_value can be written to when move method is called. But let's
# not advertise this feature.
sub index_value {
    my $self = shift;
    $self->{index_value} = shift if @_;
    return $self->{index_value} ;
}

=head2 get_container_type()

Returns the type (e.g. C<list> or C<hash> or C<leaf> or C<node> or
C<warped_node>) of the element containing this object. 

=cut 

sub get_container_type {
    my $self = shift;
    my $p = $self->parent ;
    return defined $p ? $p->element_type($self->element_name)
                      : 'node' ; # root node

}

sub _set_parent {
    my ($self,$parent) = @_ ;

    croak ref($self)," new: no 'parent' defined" unless $parent;
    croak ref($self)," new: Wrong class for parent : '",
      ref($parent),"'. Expected 'Config::Model::Node'" 
	unless $parent->isa('Config::Model::Node') ;

    $self->{parent} =  $parent ;
    weaken ($self->{parent}) ;
}

=head2 root()

Returns the root node of the configuration tree.

=cut

sub root {
    my $self = shift;

    return $self->parent || $self;
}

=head2 location()

Returns the node location in the configuration tree. This location
conforms with the syntax defined by L</grab()> method.

=cut

sub location {
    my $self = shift;

    my $str = '';
    $str .= $self->parent->location
        if defined $self->parent;

    $str .= ' ' if $str;

    $str .= $self->composite_name ;

    return $str;
}

=head2 composite_name

Return the element name with its index (if any). I.e. returns C<foo:bar> or
C<foo>.

=cut

sub composite_name {
    my $self = shift;

    my $element = $self->element_name;
    $element = '' unless defined $element;

    my $idx = $self->index_value;
    $idx = '"'.$idx.'"' if defined $idx && $idx =~ /\s/ ;

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

=head1 Annotation

Annotation is a way to store miscellaneous information associated to
each node. (Yeah... comments) These comments will be saved outside of
the configuration file and restored the next time the command is run.

=head2 annotation( [ note1, [ note2 , ... ] ] )

Without argument, return a string containing the object's annotation.

With several arguments, join the arguments with "\n", store the annotations 
and return the resulting string.

=cut

sub annotation {
    my $self = shift ;
    $self->{annotation} = join("\n", grep (defined $_,@_)) if @_;
    return $self->{annotation} ;
}

=head1 Information management

=head2 grab(...)

Grab an object from the configuration tree.

Parameters are:

=over

=item C<step>

A string indicating the steps to follow in the tree to find the
required item. (mandatory)

=item C<strict>

When set to 1, C<grab> will throw an exception if no object is found
using the passed string. When set to 0, the object found at last will
be returned. For instance, for the step C<good_step wrong_step>, only
the object held by C<good_step> will be returned. (default is 1)

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


=cut

## Navigation

# accept commands like
# item:b -> go down a node, create a new node if necessary
# - climbs up
# ! climbs up to the top 

# Now return an object and not a value !

sub grab {
    my $self = shift ;
    my ($step,$strict,$autoadd, $type, $grab_non_available,$check)
      = (undef, 1, 1, undef, 0, 'yes' ) ;
    if ( @_ > 1 ) {
	my %args = @_;
	$step    = $args{step};
	$strict  = $args{strict}  if defined $args{strict};
	$autoadd = $args{autoadd} if defined $args{autoadd};
	$grab_non_available = $args{grab_non_available} 
	  if defined $args{grab_non_available};
	$type    = $args{type} ; # node, leaf or undef
	$check = $self->_check_check($args{check}) ;
    }
    elsif (@_ == 1) {
	$step = shift ;
    }
    else {
	confess "grab: no step passed";
    }

    Config::Model::Exception::Internal
	->throw (
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
	my $cmd = shift @command ;
	my $obj = $found[-1] ;
        $logger->debug( "grab: executing cmd '$cmd' on object '",$obj->name, "($obj)'");

        if ($cmd eq '!') { 
            push @found, $obj->grab_root ;
            next ;
          }

        if ($cmd =~ /^\?(\w+)/) {
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
                return $strict ? undef : $obj ;
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
	  = ($cmd =~ /([\-\w]+)(?:(:)((?:"[^\"]*")|(?:[\w:\/\.\-\+]+)))?/);

	if (defined $arg and $arg =~ /^"/ and $arg =~ /"$/) {
	    $arg =~ s/^"// ; # remove leading quote
	    $arg =~ s/"$// ; # remove trailing quote
	}

	{
	  no warnings "uninitialized" ;
	  $logger->debug("grab: cmd '$cmd' -> name '$name', action '$action', arg '$arg'");
	}

        unless ($obj->has_element($name)) {
            Config::Model::Exception::UnknownElement
		->throw (
			 object => $obj,
			 element => $name,
			 function => 'grab',
			 info => "grab called from '".$self->name.
			 "' with steps '@saved'"
			) if $strict ;
	    last ;
	}

        unless ($grab_non_available 
		or $obj->is_element_available(name => $name, 
					      experience => 'master')) {
            Config::Model::Exception::UnavailableElement
		->throw (
			 object => $obj,
			 element => $name,
			 function => 'grab',
			 info => "grab called from '".$self->name.
			 "' with steps '@saved'"
			) if $strict;
	   last ;
	}

	my $next_obj = $obj->fetch_element( name => $name,
	    experience => 'master', check => $check, accept_hidden => $grab_non_available) ;

	# create list or hash element only if autoadd is true
        if (defined $action and $autoadd == 0
	    and not $next_obj->exists($arg)) 
	  {
            Config::Model::Exception::UnknownId
		->throw (
			 object => $obj->fetch_element($name),
			 element => $name,
			 id => $arg,
			 function => 'grab'
			)  if $strict;
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
			) if $strict ;
	    pop @found;
	}
    }

    my $return = $found[-1] ;
    $logger->debug("grab: returning object '",$return->name, "($return)'");
    return $return;
}

=head2 grab_value(...)

Like L</grab(...)>, but will return the value of a leaf object, not
just the leaf object.

Will raise an exception if following the steps ends on anything but a
leaf.

=cut

sub grab_value {
    my $self = shift ;
    my @args = scalar @_ == 1 ? ( step => $_[0], type => 'leaf')
      : ( @_ , type => 'leaf') ;

    my $obj = $self->grab(@args) ;

    Config::Model::Exception::User
	-> throw (
		  object => $self,
		  message => "grab_value: cannot get value of non-leaf "
		  ."item with '".join("' '",@_)."'"
		 ) 
	  unless ref $obj && $obj->isa("Config::Model::Value");

    return $obj->fetch ;
}

=head2 grab_annotation(...)

Like L</grab(...)>, but will return the annotation of an object.

=cut

sub grab_annotation {
    my $self = shift ;
    my @args = scalar @_ == 1 ? ( step => $_[0] ) : @_ ;

    my $obj = $self->grab(@args) ;

    return $obj->annotation ;
}

=head2 grab_root()

Returns the root of the configuration tree.

=cut

sub grab_root {
    my $self = shift ;
    return defined $self->{parent} ? $self->{parent}->grab_root 
      : $self ;
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

=head2 searcher ()

Returns an object dedicated to search an element in the configuration
model (respecting privilege level).

This method returns a L<Config::Model::Searcher> object. See
L<Config::Model::Searcher> for details on how to handle a search.

=cut

sub searcher {
    my $self = shift ;
    my %args = @_ ;

    my $model = $self->instance->config_model ;
    return Config::Model::Searcher
      -> new(model => $model, node => $self, %args ) ;
}

=head2 dump_as_data ( )

Dumps the configuration data of the node and its siblings into a perl
data structure. 

Returns a hash ref containing the data. See
L<Config::Model::DumpAsData> for details.

=cut

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


1;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::Node>, 
L<Config::Model::Loader>, 
L<Config::Model::Dumper>

=cut
