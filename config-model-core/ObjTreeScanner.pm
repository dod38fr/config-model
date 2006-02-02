# $Author: ddumont $
# $Date: 2006-02-02 12:59:55 $
# $Name: not supported by cvs2svn $
# $Revision: 1.2 $

#    Copyright (c) 2006 Dominique Dumont.
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

package Config::Model::ObjTreeScanner ;
use strict ;
use Config::Model::Exception ;
use Carp;
use warnings ;
use UNIVERSAL qw( isa can );

our $VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

use Carp qw/croak confess cluck/;

=head1 NAME

Config::Model::ObjTreeScanner - Scan config tree and perform call-backs

=head1 SYNOPSIS

 use Config::Model::ObjTreeScanner ;

 # define tree object
 my $root = ... ;

 # defined call-backs

 $scan = Config::Model::ObjTreeScanner-> new
  (
   # node callback
   list_cb => \&disp_hash ,
   hash_cb => \&disp_hash,
   element_cb => \&disp_obj ,
   node_cb => \&disp_obj_elt ,

   # leaf callback
   leaf_cb => \&disp_leaf,
   enum_value_cb => \&disp_leaf,
   enum_integer_value_cb => \&disp_leaf,
   integer_value_cb => \&disp_leaf,
   number_value_cb => \&disp_leaf,
   boolean_value_cb => \&disp_leaf,
   string_value_cb => \&disp_leaf
  ) ;

 $scan->scan_node($root) ;

=head1 DESCRIPTION

This module creates an object that will explore (depth first) a
configuration tree object.

For each node or leaf encountered, the ObjTreeScanner object will
call-back one of the subroutine reference passed during construction.

To continue the exploration, these call-backs must also call the
scanner. (i.e. perform another call-back). In other words the user's
subroutine and the scanner plays a game of ping-pong until the
tree is completely explored.

The scanner provides a set of default callback for the nodes. This
way, the user only have to provide call-backs for the leaves.

=head1 CONSTRUCTOR

=head2 new ( ... )

One way or another, the ObjTreeScanner object must be able to find all
callback for all the items of the tree:

=over

=item leaf callback:

C<leaf_cb>, C<enum_value_cb>, C<enum_integer_value_cb>,
C<integer_value_cb>, C<number_value_cb>, C<boolean_value_cb>,
C<string_value_cb>

=item node callback:

C<list_cb>, C<hash_cb>, C<element_cb>, C<node_cb>.

=back

The user may specify all of them by passing the sub ref to the
constructor:

   $scan = Config::Model::ObjTreeScanner-> new
  (
   # node callback
   list_cb => sub ,
   ...
  )

Or use some default callback using the fallback parameter. Note that
at least one callback must be provided: C<leaf_cb>.

Optional parameter:

=over

=item *

fallback: if set to 'node', the scanner will provide default call-back
for node items. If set to 'leaf', the scanner will set all leaf
callback (like enum_integer_value_cb, enum_value_cb ...) to
string_value_cb or to the mandatory leaf_cb value. "fallback" callback
will not override callbacks provided by the user.

If set to 'all', equivalent to 'node' and 'leaf'.

=back

=over

=head1 Callbacks prototypes

The leaf callbacks will be called with the following parameters:

 ($object,$element,$index, $obj_object) 

where:

=over

=item *

C<$object> is the node that contain the leaf.

=item *

C<$element> is the element (or attribute) that contain the leaf.

=item *

C<$index> is the index (or hash key) used to get the leaf. This may
be undefined if the element type is scalar.

=item *

C<$obj> is the L<Config::Model::Value> object.

=back

Others :

=over

=item C<list_cb> : 

 ($object,$element,@indexes)

C<@indexes> is an list containing all the indexes of the array.

=item C<hash_cb>:

 ($object,$element,@keys)

C<@keys> is an list containing all the keys of the hash.

=item C<element_cb>: 

 ($object,@element_list)

C<@element_list> contains all the elements of the node.

=item C<node_cb>

 ($object,$element)

=back

=back

=cut

sub new {
    my $type = shift ;
    my %args = @_;

    my $self = { role => 'intermediate' , auto_vivify => 1 } ;
    bless $self,$type ;

    $self->{leaf_cb} = delete $args{leaf_cb} or
      croak __PACKAGE__,"->new: missing leaf_cb parameter" ;

    # we may use leaf_cb
    $self->create_fallback(delete $args{fallback}) ;

    # get all call_backs
    my @value_cb = map {$_.'_value_cb'} 
      qw/boolean enum enum_integer string integer number/; 

    foreach my $param (qw/element_cb hash_cb list_cb node_cb
                          role auto_vivify up_cb/, @value_cb) {
        $self->{$param} = delete $args{$param} if defined $args{$param};
        croak __PACKAGE__,"->new: missing $param parameter"
          unless defined $self->{$param} ;
    }

    croak __PACKAGE__,"->new: unexpected parameter: ",join (' ',keys %args)
      if scalar %args ;

    return $self ;
}

# internal
sub create_fallback {
    my $self = shift ;
    my $fallback = shift;

    return if not defined $fallback or $fallback eq 'none' ;

    my $done = 0 ;

    if ($fallback eq 'node' or $fallback eq 'all') {
        $done ++ ;
        my $element_cb = sub {
            my ($obj,@element) = @_ ;
            map {$self->scan_element($obj,$_)} @element ;
	} ;

        my $node_cb = sub {
            my ($obj,$element,$key) = @_ ;
	    my $next = $obj -> get_element_for($element) ;

            my $type = $obj->element_type($element) ;
            $next = $next->fetch($key) if $type eq 'list' || $type eq 'hash';
            $self->scan_node($next);
	} ;

        my $hash_cb = sub {
            my ($obj,$element,@keys) = @_ ;
            map {$self->scan_hash($obj,$element,$_)} @keys ;
	};

        $self->{list_cb}  = $hash_cb;
        $self->{hash_cb}   = $hash_cb;
        $self->{element_cb}   = $element_cb;
        $self->{node_cb} = $node_cb ;
	$self->{up_cb} = sub {} ; # do nothing
    }

    if ($fallback eq 'leaf' or $fallback eq 'all') {
        $done ++ ;
        my $l = $self->{string_value_cb} ||= $self->{leaf_cb} ;

        $self->{enum_value_cb}         = $l ;
        $self->{enum_integer_value_cb} = $l ;
        $self->{integer_value_cb}      = $l ;
        $self->{number_value_cb}       = $l ;
        $self->{boolean_value_cb}      = $l ;
      }

    croak __PACKAGE__,"->new: Unexpected fallback value '$fallback'. ",
      "Expected 'node', 'leaf', 'all' or 'none'" if not $done;
}

=head1 METHODS

=head2 scan_node ($object)

Explore the object and call C<element_cb> on all elements.

=cut

sub scan_node {
    my ($self,$object) = @_ ;

    #print "scan_node ",$object->name,"\n";
    # get all elements according to catalog

    Config::Model::Exception::Internal
	-> throw (
		  error => "'$object' is not a Config::Model object" 
		 ) 
	  unless isa($object, "Config::Model::AnyThing") ;

    # skip exploration of warped out node
    if ($object->isa('Config::Model::WarpedNode')) {
	$object = $object->get_actual_node ;
	return unless defined $object ;
    }

    my @element_list= $object->get_element_name(for => $self->{role}) ;

    # we could add here a "last element" call-back, but it's not
    # very usefull if the last element is a hash.
    $self->{element_cb}->($object,@element_list) ;

    $self->{up_cb}->($object) ;
}

=head2 scan_element($object,$element)

Explore the element and call either C<hash_cb>, C<list_cb>, C<node_cb>
or a leaf call-back (the leaf call-back called depends on the Value
object properties: enum, string, integer and so on)

=cut

sub scan_element {
    my ($self,$parent,$element) = @_ ;

    my $element_type = $parent->element_type($element);

    return unless defined $element_type; # element may not be initialized

    my $autov = $self->{auto_vivify} ;

    #print "scan_element $element ";
    if ($element_type eq 'hash') {
        #print "type hash\n";
        my @keys = $self->get_keys($parent,$element) ;
        # if hash element grab keys and perform callback
        $self->{hash_cb}->($parent,$element,@keys) if $autov or @keys;
    }
    elsif ($element_type eq 'list') {
        #print "type list\n";
        my @keys = $self->get_keys($parent,$element) ;
        $self->{list_cb}->($parent,$element, @keys) if $autov or @keys ;
    }
    elsif ($element_type eq 'node') {
        #print "type object\n";
        # is a scalar and class, or a WarpedNode

	# avoid auto-vivification
        return unless $autov or $parent->is_element_defined($element) ;

        # if obj element, cb
        $self->{node_cb}-> ($parent,$element) ;
    }
    elsif ($element_type eq 'warped_node') {
        #print "type warped\n";
        # if obj element, cb
        $self->{node_cb}-> ($parent,$element) ;
    }
    elsif ($element_type eq 'leaf') {
        my $obj = $parent->get_element_for($element) ;

	my $type = $obj->value_type ;
	return unless $type;
	my $cb_name = $type.'_value_cb' ;
	my $cb = $self->{$cb_name};
	croak "scan_element: No call_back specified for '$cb_name'" 
	  unless defined $cb ;
	$cb-> ($parent,$element,undef,$obj);
    }
    else {
	croak "Unexpected element_type: $element_type";
    }
}

=head2 scan_hash ($object,$element,$key)

Explore the hash member (or hash value) and call either C<node_cb>
or a leaf call-back.

=cut

sub scan_hash {
    my ($self,$parent,$element,$key) = @_ ;

    #print "scan_hash ",$parent->name," element $element key $key ";
    my $item = $parent -> get_element_for($element) ;
    my $element_type = $item->element_type($element);

    if ($element_type =~ /node$/) {
        #print "type object or warped\n";
        $self->{node_cb}-> ($parent,$element,$key) ;
    }
    elsif ($element_type eq 'leaf') {
        my $obj = $item->fetch($key) ;
	my $cb_name = $obj->value_type.'_value_cb' ;
	my $cb = $self->{$cb_name};
	croak "scan_hash: No call_back specified for '$cb_name'" 
	  unless defined $cb ;
	$cb-> ($parent,$element,$key,$obj);
    }
    else {
	croak "Unexpected element_type: $element_type";
    }
}

=head2 scan_list ($object,$element,$index)

Just like C<scan_hash>: Explore the list member and call either
C<node_cb> or a leaf call-back.

=cut

sub scan_list {
    goto &scan_hash ;
}

=head2 get_keys ($object, $element)

Returns an list containing the sorted keys of a hash element or returns
an list containning (0.. last_index) of an list element.

Throws an exception if element is not an list or a hash element.

=cut

sub get_keys {
    my ($self,$obj,$element) = @_ ;

    my $element_type = $obj->element_type($element);
    my $item = $obj->get_element_for($element) ;

    return sort $item->get_all_indexes 
      if $element_type eq 'hash' || $element_type eq 'list' ;

    Config::Model::Exception::Internal
	->throw (
		 error => "called get_keys on non hash or non list"
		 ." element $element",
		 object => $obj
		) ;

}

1;

=head1 SEE ALSO

L<Config::Model::Value>

=cut

