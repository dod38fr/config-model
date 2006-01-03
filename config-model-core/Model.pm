# $Author: ddumont $
# $Date: 2006-01-03 12:11:45 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

#    Copyright (c) 2005 Dominique Dumont.
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

package Config::Model ;
require Exporter;
use Carp;
use strict;
use warnings FATAL => qw(all);
use vars qw/@ISA @EXPORT @EXPORT_OK $VERSION/;

use Config::Model::Instance ;

# this class holds the version number of the package
use vars qw($VERSION @status @level @permission_list %permission_index) ;

$VERSION = '0.001';

=head1 NAME

Config::Model - Model to create configuration trees

=head1 DESCRIPTION

This set of modules provides a framework to set up a model of a
configuration using a description based on a tree structure.

Using a tree structure has several advantages:

=over

=item *

Unique path to get to a node or a leaf.

=item *

Simpler exploration and query

=item *

Simple hierarchy. Deletion of configuration items is simpler to grasp:
when you cut a branch, all the leaves attaches to that branch go down.

=back

But using a tree has also some drawbacks:

=over 4

=item *

A complex configuration cannot be mapped on a simple tree.  Some more
relation between nodes and leaves must be added.

=item *

Some configuration part are actually graph instead of a tree (for
instance, any configuration that will map a service to a
resource). The graph relation must be decomposed in a tree with
special I<reference> relation. See L<Config::Model::Value/Value Reference>

=back

Note: a configuration tree is a tree of objects. The model is declared
with classes. The classes themselves have relations that closely match
the relation of the object of the configuration tree. But the class
need not to be declared in a tree structure (always better to reuse
classes). But they must be declared as a DAG (directed acyclic graph).

=begin html

<a href="http://en.wikipedia.org/wiki/Directed_acyclic_graph">More on DAGs</a>

=end html

=head1 Configuration tree

A configuration tree is made of:

=over

=item nodes

A node is a junction between the trunk and a branch or between
branches. See L<Config::Model::Node>.

=item elements

Elements are the attributes (or a set of attributes) of a node.  An
element can contain one item (scalar element), several items (array
element) or a collection of identified items (hash elements).
Each item can be another node or a leaf.

=item leaves

A leaf is the actual container of the configuration parameters (nodes
and elements only define the structure). The leaves can be plain
(unconstrained value) or be strongly typed (values are checked against
a set of rules).

=back

Each element of a node has several properties:

=over

=item permission

By using the C<permission> parameter, you can change the permission
level of each element. Authorized privilege values are C<master,
advanced> and C<intermediate>.

=cut

# permission
@permission_list = qw/intermediate advanced master/;

=item level

Level is C<important>, C<normal> or C<hidden>. 

The level is used to set how configuration data is presented to the
user in browsing mode. C<Important> elements will be shown to the user
no matter what. C<hidden> elements will be explained with the E<warp>
notion.

=cut

# level: Important, normal
@level = qw/hidden normal important/;

=item status

Status is C<obsolete>, C<deprecated> or C<standard> (default).

Using a deprecated element will issue a warning. Using an obsolete
element will raise an exception.

=cut

@status = qw/obsolete deprecated standard/;

=item description

Description of the element. This description will be used when
generating user interfaces.

=back

=cut

my %default_property =
  (
   status     => 'standard',
   level      => 'normal',
   permission => 'intermediate',
   description=> ''
  );

my %check;

{
  my $idx = 0 ;
  map ($check{level}{$_}=$idx++, @level);
  $idx = 0 ;
  map ($check{status}{$_}=$idx++, @status);
  $idx = 0 ;
  map ($permission_index{$_}=$idx++, @permission_list);
}

$check{permission}=\%permission_index ;

sub new {
    my $type = shift ;
    bless {},$type;
}

sub create_config_class {
    my $self=shift ;

    if (ref($_[0]) eq 'HASH') {
	map {$self->create_one_config_class(%$_)} @_ ;
    }
    elsif (ref($_[0]) eq 'ARRAY') {
	map {$self->create_one_config_class(@$_)} @_ ;
    }
    else {
	$self->create_one_config_class(@_);
    }
};

# unpacked model is:
# {
#   element_list => [ ... ],
#   permission   => { element_name => <permission> },
#   status       => { element_name => <status>     },
#   description  => { element_name => <string> },
#   element      => { element_name => element_data (left as is)    },
#   class_description => <class description string>,
#   level        => { element_name => <level like important or normal..> },
# }



sub create_one_config_class {
    my $self=shift ;
    my %raw_model = @_ ;

    my $config_class_name = delete $raw_model{name} or
      croak "create_one_config_class: no config class name" ;

    if (exists $self->{model}{$config_class_name}) {
	Config::Model::Exception::ModelDeclaration->throw
	    (
	     error=> "create_one_config_class: attempt to clobber $config_class_name".
	     "config class name "
	    );
    }

    $self->{raw_model}{$config_class_name} = \%raw_model ;

    # perform some syntax and rule checks and expand compacted
    # elements ie ( [qw/foo bar/] => {...}
    #  foo => {...} , bar => {...}

    my %raw_copy = %raw_model ;
    my @element_list ;

    # first get the element list
    my @compact_list = @{$raw_copy{element}} ;
    while (@compact_list) {
	my ($item,$info) = splice @compact_list,0,2 ;
	# store the order of element as declared in 'element'
	push @element_list, ref($item) ? @$item : ($item) ;
    }

    my %model = (element_list => \@element_list);

    my @legal_params = qw/permission status description element level/;

    foreach my $info_name (@legal_params) {
	# fill default info
	map {$model{$info_name}{$_} = $default_property{$info_name}; }
	  @element_list 
	    if defined $default_property{$info_name};

	my $compact_info = delete $raw_copy{$info_name} ;
	next unless defined $compact_info ;

	my @info = @$compact_info ; 
	while (@info) {
	    my ($item,$info) = splice @info,0,2 ;
	    my @element_names = ref($item) ? @$item : ($item) ;

	    Config::Model::Exception::ModelDeclaration->throw
		(
		 error=> "create class $config_class_name: unknown ".
		 "value for $info_name: '$info'. Expected '".
		 join("', '",keys %{$check{$info_name}})."'"
		)
		  if defined $check{$info_name} 
		    and not defined $check{$info_name}{$info} ;

	    foreach my $name (@element_names) {
		$model{$info_name}{$name} = $info ;
	    }
	}
    }

    # copy description of configuration class
    $model{class_description} = delete $raw_copy{class_description} ;

    my @left_params = keys %raw_copy ;
    Config::Model::Exception::ModelDeclaration->throw
        (
         error=> "create class $config_class_name: unknown ".
	 "parameter '" . join("', '",@left_params)."', expected '".
	 join("', '",@legal_params,qw/description important_elements/)."'"
        )
	  if @left_params ;


    $self->{model}{$config_class_name} = \%model ;

    return $self ;
}

sub get_model {
    my $self =shift ;
    my $config_class_name = shift ;

    return $self->{model}{$config_class_name} ||
      croak "get_model error: unknown config class name: $config_class_name";
}

sub instance {
    my $self = shift ;
    my %args = @_ ;
    my $root_class_name =  $args{root_class_name}
      or croak "Model: can't create instance without root_class_name ";
    my $instance_name =  $args{instance_name}
      or croak "Model: can't create instance without instance_name ";

    if (defined $self->{instance}{$instance_name}{$root_class_name}) {
	return $self->{instance}{$instance_name}{$root_class_name} ;
    }

    my $i = Config::Model::Instance 
      -> new (config_model => $self,
	      root_class_name => $root_class_name) ;

    $self->{instance}{$instance_name}{$root_class_name} = $i ;
    return $i ;
}

sub get_element_name {
    my $self = shift ;
    my %args = @_ ;

    my $class = $args{class} || 
      croak "get_element_name: missing 'class' parameter" ;
    my $for = $args{for} || 'master' ;

    croak "get_element_name: wrong 'for' parameter. Expected ", 
      join (' or ', @permission_list) 
	unless defined $permission_index{$for} ;

    my @catalogs 
      = ( @permission_list[ $permission_index{$for} .. $#permission_list ] );
    my @array
      = $self->get_element_with_permission($class,@catalogs);

    return wantarray ? @array : join( ' ', @array );
}

sub get_element_with_permission {
    my $self      = shift ;
    my $class     = shift ;

    my $model = $self->get_model($class) ;
    my @result ;

    # this is a bit convoluted, but the order of the returned element
    # must respect the order of the elements declared in the model by
    # the user
    foreach my $elt (@{$model->{element_list}}) {
	foreach my $permission (@_) {
	    push @result, $elt
	      if $model->{level}{$elt} ne 'hidden' 
		and $model->{permission}{$elt} eq $permission ;
	}
    }

    return @result ;
}

sub get_element_property {
    my $self = shift ;
    my %args = @_ ;

    my $elt = $args{element} || 
      croak "get_element_property: missing 'element' parameter";
    my $prop = $args{property} || 
      croak "get_element_property: missing 'property' parameter";
    my $class = $args{class} || 
      croak "get_element_property:: missing 'class' parameter";

    return $self->{model}{$class}{$prop}{$elt} ;
}


__END__





=head1 Tree nodes

B<Warning: doc below is outdated.>

=head2 Customized nodes

TBD re-write doc to explain how to declare a node

The L<Config::Model::AnyNode|Config::Model::AnyNode> base class provides
a constructor whose parameters can overrides the setting of the object
contained in the elements of the node.

For instance, the default value of a value in a element can be changed,
or the possible values of an enumerated type.

See L<AnyNode constructor documentation|Config::Model::AnyNode/CONSTRUCTOR>

=head2 AutoRead nodes

As configuration model are getting bigger, the load time of a tree
gets longer. The L<Config::Model::AutoRead|Config::Model::AutoRead> class provides a way to
load the configuration informations only when needed.

To use this features, the node must 
L<inherit|Config::Model::AutoRead/INHERITANCE> this class.

=head1 Tree leaf

The leaves of the tree contain the actual configuration
values. Depending on the declaration, the leaf will have different
properties.

=head2 Plain leaf

An unconstrained leaf may be implemented with:

=over

=item *

The L<get_set|Class::IntrospectionMethods/get_set> method.

=item *

The L<tie_scalar|Class::IntrospectionMethods/tie_scalar> method using
L<Config::Model::Value|Config::Model::Value> as a tied class. For an
unconstrained value, the 
L<value_type|Config::Model::Value/"VALUE TYPES"> must be set to C<string>.

=back

You may need to use C<tie_scalar> instead of C<get_set> if you want to
add special relation to this leaf (e.g. use this value as 
L<warp|Config::Model::Value/"Warp: dynamic value configuration">
master
or L<computation|Config::Model::Value/"Compute a Value"> variable).

=head2 Specialized leaf

You can declare a leaf with special property:

=over

=item strong type

Declare a specific L<value_type|Config::Model::Value/"VALUE TYPES">
like integer, number, boolean, enum (...) with the 
L<Value constructor|Config::Model::Value/CONSTRUCTOR>.

=item default value

Use C<default> parameter with the 
L<Value constructor|Config::Model::Value/CONSTRUCTOR>

=item mandatory

Use C<mandatory> parameter with the 
L<Value constructor|Config::Model::Value/CONSTRUCTOR>

=item privilege level

Use C<catalog> parameter in the warp declaration with the 
L<Value constructor|Config::Model::Value/CONSTRUCTOR>.

=item bounded integer or number

Use C<min> and C<max> parameter with the 
L<Value constructor|Config::Model::Value/CONSTRUCTOR>

=item computation

The value is computed from the values of other leaves in the tree. See
L<Value constructor|Config::Model::Value/"Compute a Value">

=item auto-increment

Use the L<Config::Model::AutoIncrement|Config::Model::AutoIncrement> class
with C<tie_scalar>.

=back

If none of these possibilities fits your needs, you will have to write
your own tie class to fit your needs.

See:

=over

=item *

L<perltie>.

=item *

L<Tie::Scalar>

=back


=head2 Warped leaf

A warped leaf is a special case where the above properties can be
modified at run time (e.g. "warped") depending on the value of another
leaf in the tree (nicknamed the "warp master"). See 
L<"dynamic value configuration"|Config::Model::Value/"Warp: dynamic value configuration"> for details.

=head1 Warped nodes

Just like the warped leaf, a node can also be warped depending on the
value of another leaf in the tree. In this case the object's class can
be changed at run-time. The privilege of the element can also be
warped. See L<Config::Model::WarpObject> for details.

=head1 Tree relations

In other words, how leaves are tied to nodes and how nodes
are tied between them.

=head2 simple relation

The most simple: a one to one relation. Achieved with
L<get_set|Class::IntrospectionMethods/get_set> (plain storage),
L<tie_scalar|Class::IntrospectionMethods/tie_scalar> (customized storage), or
L<object|Class::IntrospectionMethods/object> (item is an object) methods from
Class::IntrospectionMethods.

=head2 simple list relation

A element contains a list of a items. The user does not really care about
an identifier. Achieved with L<list|Class::IntrospectionMethods/list> (plain
storage), L<object_list|Class::IntrospectionMethods/object_list> (item is an
object) methods from Class::IntrospectionMethods.

This relation is not practical to handle with CLI, hence it is not
really used and should be considered as experimental.

=head2 customized list relation

The list behavior can be customized with a tied array (See
L<Tie::Array>). Currently, L<Config::Model::Id|Config::Model::Id> can be
used as a tied array.

Achieved with L<tie_list|Class::IntrospectionMethods/tie_list> (plain storage),
or L<object_tie_list|Class::IntrospectionMethods/object_tie_list> (item is an
object) methods from Class::IntrospectionMethods.

Not (yet) used. experimental.

=head2 hash relation

A element contains a set of a items. Each item has an identifier.

Achieved with L<hash|Class::IntrospectionMethods/hash> (plain storage),
L<object_tie_hash|Class::IntrospectionMethods/object_tie_hash> (item is an
object)or L<tie_tie_hash|Class::IntrospectionMethods/tie_tie_hash> (customized
item) methods from Class::IntrospectionMethods.

To use C<object_tie_hash> and C<tie_tie_hash> with a plain hash, just
omit the C<tie_hash> parameter.

=head2 customized hash relation

In some hairy case, the hash relation can be customized by using
L<Config::Model::Id|Config::Model::Id>. Use the C<tie_hash> parameter
with the methods listed below.

Achieved with L<tie_hash|Class::IntrospectionMethods/tie_hash> (plain storage),
L<object_tie_hash|Class::IntrospectionMethods/object_tie_hash> (item is an
object)or L<tie_tie_hash|Class::IntrospectionMethods/tie_tie_hash> (both
relation and item are customized) methods from Class::IntrospectionMethods.


=head1 Error handling

Errors are handled with an exception mechanism (See
L<Exception::Class>).

When a strongly typed Value object gets an authorized value, it raises
an exception. If this exception is not catched, the programs exits.

See L<Config::Model::Exception|Config::Model::Exception> for details on
the various exception classes provided with the framework.

=head1 Log and Traces

Currently a rather lame trace mechanism is provided:

=over

=item *

Set C<$::debug> to 1 to get debug messages on STDOUT.

=item *

Set C<$::verbose> to 1 to get verbose messages on STDOUT.

=back

Depending on available time, a better log/error system may be
implemented.

=head1 SEE ALSO

L<Config::Model::AnyNode>, L<Config::Model::AnyThing>,
L<Config::Model::AnyWriter>, L<Config::Model::AutoIncrement>,
L<Config::Model::AutoRead>, L<Config::Model::Exception>,
L<Config::Model::FileUtils>, L<Config::Model::Framework>,
L<Config::Model::Id>, L<Config::Model::Instance>,
L<Config::Model::LicToolParser>, L<Config::Model::ObjTreeScanner>,
L<Config::Model::OcIniRefinery>, L<Config::Model::TreeIf>,
L<Config::Model::Value>, L<Config::Model::WarpArray>,
L<Config::Model::WarpHash>, L<Config::Model::WarpObject>,
L<Config::Model::WarpThing>


=cut
