# $Author: ddumont $
# $Date: 2006-02-16 13:09:43 $
# $Name: not supported by cvs2svn $
# $Revision: 1.2 $

#    Copyright (c) 2005,2006 Dominique Dumont.
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

use vars qw($VERSION);
$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

=head1 NAME

Config::Model::AnyThing - Base class for configuration tree item

=head1 SYNOPSIS

 package Config::Model::SomeThing ;
 use base qw/Config::Model::AnyThing/ ;

=head1 DESCRIPTION

This class must be inherited by all nodes or leaves of the
configuration tree.

AnyThing provides some methods and no constructor.

=head1 Methods

=head2 element_name()

Returns the element name that contain this object.

=head2 index_value()

For object stored in an array or hash element, returns the index (or key)
containing this object.

=head2 parent()

Returns the node containing this object. May return undef if C<parent()> 
is called on the root of the tree.

=cut 

foreach my $datum (qw/element_name index_value parent/) {
    no strict "refs";       # to register new methods in package
    *$datum = sub {
	my $self= shift;
	return $self->{$datum};
    } ;
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

=head2 location()

Returns the node location in the configuration tree. This location
conforms with the syntax defined by L</grab()> method.

=cut

sub location {
    my $self = shift;

    #print "location called on $self\n" if $::debug ;

    my $element = $self->element_name;
    $element = '' unless defined $element;

    my $idx = $self->index_value;

    my $str = '';
    $str .= $self->parent->location
        if defined $self->parent;

    $str .= ' ' if $str;

    $str .= $element . ( defined $idx ? ':' . $idx : '' );

    return $str;
}

## Fixme: not yet tested 
sub xpath {
    my $self = shift;

    print "xpath called on $self\n" if $::debug;

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

=head2 grab(...)

Grab an object from the configuration tree. The parameter is a string indicating the steps to follow in the tree to find the required item.

The steps are made of the following items separated by spaces:

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

=item xxx%yy

Like C<xxx:yy>, but does not create id C<yy> for element C<xxx>. I.e. grab
will fail if the id C<yy> does not already exsits in element C<xxx>

=back


=cut

## Navigation

# accept commands like
# item:b -> go down a node, create a new node if necessary
# item%b -> go down a node, fail if node creation is necessary
# - climbs up
# ! climbs up to the top 

# Now return an object and not a value !

sub grab {
    my $self = shift ;
    my $step = shift || confess "grab: no step passed";

    confess "grab: too many parameters" if @_ ;

    Config::Model::Exception::Internal
	->throw (
		 error => "grab: step parameter must be a string ".
		 "or an array ref"
		) 
	  unless ref $step eq 'ARRAY' || not ref $step ;

    # accept commands, grep remove empty items left by spurious spaces
    my @command = 
      grep($_, ref $step ? map( split , @$step) : split /[\s\n]+/,$step ) ;

    my @saved = @command ;

    print "grab: executing '",join("' '",@command),
      "' on object '",$self->name, "'\n"
          if $::debug;

    my $obj = $self ;

  COMMAND:
    while( my $cmd = shift @command) {
        print "grab: executing cmd '$cmd' on object '",$obj->name,
          "($obj)'\n" if $::debug;

        if ($cmd eq '!') { 
            $obj = $obj->grab_root ;
            next ;
          }

        if ($cmd =~ /^\?(\w+)/) {
	    $obj = $obj->grab_ancestor_with_element_named($1) ;
	    $cmd =~ s/^\?// ; #remove the go up part
	    unshift @command, $cmd ;
	    next ;
          }

        if ($cmd eq '-') { 
            if (defined $obj->parent) {
                $obj = $obj->parent ; 
                next ;
              } 
            else {
                print "grab: ",$obj->name," has not PARENT\n" 
		  if $::debug;
                return undef ;
              }
          }

        unless ($obj->isa('Config::Model::Node') 
		or $obj->isa('Config::Model::WarpedNode'))
          {
            Config::Model::Exception::Model
		->throw (
			 object => $obj,
			 message => "Cannot apply command '$cmd' on leaf item".
			 " (full command is '@saved')"
			) ;
	}

        my ($name, $action, $arg) 
	  = ($cmd =~ /(\w+)(?:([:%])([\w:\/\.\-]+))?/);

	{
	  no warnings "uninitialized" ;
	  print "grab: cmd '$cmd' -> name '$name', action '$action', arg '$arg'\n" 
	    if $::debug;
	}

        unless ($obj->has_element($name)) {
            Config::Model::Exception::UnknownElement
		->throw (
			 object => $obj,
			 element => $name,
			 function => 'grab',
			 info => "grab called from '".$self->name.
			 "' with steps '@saved'"
			) ;
	}

        unless ($obj->is_element_available(name => $name, 
					   permission => 'master')) {
            Config::Model::Exception::UnavailableElement
		->throw (
			 object => $obj,
			 element => $name,
			 function => 'grab',
			 info => "grab called from '".$self->name.
			 "' with steps '@saved'"
			) ;
	}

	# Not translated below
	# '%' action grab but does not create !
        if (defined $action and $action eq '%' 
	    and not $obj->fetch_element($name)
	    ->fetch_element_key($arg)) 
	  {
            Config::Model::Exception::UnknownId
		->throw (
			 object => $obj,
			 element => $name,
			 id => $arg,
			 function => 'grab'
			) ;
	}

        if (defined $action) {
	    # action can only be % or :
	    $obj = $obj->fetch_element($name) ->fetch($arg)
          }
        else {
	    $obj = $obj->fetch_element($name);
	}
    }

    return $obj ;
}

=head2 grab_value(...)

Like L</grab(...)>, but will return the value of a leaf object, not
just the leaf object.

Will raise an exception if following the steps ends on anything but a
leaf.

=cut

sub grab_value {
    my $self = shift ;

    my $obj = $self->grab(@_) ;

    Config::Model::Exception::User
	-> throw (
		  object => $self,
		  message => "grab_value: cannot get value of non-leaf "
		  ."item with '@_'"
		 ) 
	  unless $obj->isa("Config::Model::Value");

    return $obj->fetch ;
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
    my $self = shift ;
    my $search = shift ;

    my $obj = $self ;

    while (1) { 
	print "grab_ancestor_with_element_named: executing cmd '?$search' on object ",
	  ,$obj->name,"\n" if $::debug;

	my $obj_element_name = $obj->element_name ;

	if ($obj->isa('Config::Model::Node') && $obj->has_element($search)) {
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

=head2 load(...)

Load configuration tree with data passed in the string.

See L<Config::Model::Loader> for details.

=cut

sub load {
    my $self = shift ;
    my $loader = Config::Model::Loader->new ;
    $loader->load(node => $self, @_) ;
}

1;

=head1 AUTHOR

Dominique Dumont, domi@komarr.grenoble.hp.com

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::Node>, 
L<Config::Model::Loader>, 
L<Config::Model::Dumper>

=cut

