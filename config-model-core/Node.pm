# $Author: ddumont $
# $Date: 2006-10-02 11:35:48 $
# $Name: not supported by cvs2svn $
# $Revision: 1.8 $

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

package Config::Model::Node;
use Carp;
use strict;
use warnings;
use Config::Model::Exception;
use Config::Model::Loader;
use Config::Model::Dumper;
use Config::Model::Report;
use Config::Model::Describe;
# use Log::Log4perl ;
use UNIVERSAL;
use Scalar::Util qw/weaken/;
use Storable qw/dclone/ ;

use base qw/Config::Model::AutoRead/;

use vars qw($VERSION $AUTOLOAD @status @level
@permission_list %permission_index );

$VERSION = sprintf "%d.%03d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/;

*status           = *Config::Model::status ;
*level            = *Config::Model::level ;
*permission_list  = *Config::Model::permission_list ;
*permission_index = *Config::Model::permission_index ;

my @legal_properties= qw/status level permission/;

=head1 NAME

Config::Model::Node - Class for configuration tree node

=head1 SYNOPSIS

 $model->create_config_class 
  (
   name              => 'OneConfigClass',
   element           => [
                          [qw/X Y Z/] 
                          => {
                               type => 'leaf',
                               value_type => 'enum',
                               choice     => [qw/Av Bv Cv/]
                             }
                        ],
   permission        => [ Y => 'intermediate', 
                          X => 'master' 
                        ],
   status            => [ X => 'deprecated' ],
   description       => [ X => 'X-ray' ],
   class_description => "OneConfigClass detailed description",

  );

 my $instance = $model->instance (root_class_name => 'OneConfigClass', 
                                  instance_name => 'test1');
 my $root_node = $instance -> config_root ;

=head1 DESCRIPTION

This class provides the nodes of a configuration tree. When created, a
node object will get a set of rules that will define its properties
within the configuration tree.

Each node contain a set of elements. An element can contain:

=over

=item *

A leaf element implemented with L<Config::Model::Value>. A leaf can be
plain (unconstrained value) or be strongly typed (values are checked
against a set of rules).

=item *

Another node.

=item *

A collection of items: a list element, implemented with
L<Config::Model::ListId>. Each item can be another node or a leaf.

=item *

A collection of identified items: a hash element, implemented with
L<Config::Model::HashId>.  Each item can be another node or a leaf.

=back

=head1 Configuration class declaration

A class declaration is made of the following parameters:

=over

=item B<name> 

Mandatory C<string> parameter. This config class name can be used by a node
element in another configuration class.

=item B<class_description> 

Optional C<string> parameter. This description will be used when
generating user interfaces.

=item B<element> 

Mandatory C<list ref> of elements of the configuration class : 

  element => [ foo => { type = 'leaf', ... },
               bar => { type = 'leaf', ... }
             ]

Element names can be grouped to save typing:

  element => [ [qw/foo bar/] => { type = 'leaf', ... } ]

See below for details on element declaration.

=item B<permission>

Optional C<list ref> of the elements whose permission are different
from default value (C<intermediate>). Possible values are C<master>,
C<advanced> and C<intermediate>.

  permission   => [ Y => 'intermediate', 
                    [qw/foo bar/] => 'master' 
                  ],

=item B<level>

Optional C<list ref> of the elements whose level are different from
default value (C<normal>). Possible values are C<important>, C<normal>
or C<hidden>.

The level is used to set how configuration data is presented to the
user in browsing mode. C<Important> elements will be shown to the user
no matter what. C<hidden> elements will be explained with the I<warp>
notion.

  level  => [ [qw/X Y/] => 'important' ]

=item B<status>

Optional C<list ref> of the elements whose status are different from
default value (C<standard>). Possible values are C<obsolete>,
C<deprecated> or C<standard>.

Using a deprecated element will issue a warning. Using an obsolete
element will raise an exception (See L<Config::Model::Exception>.

  status  => [ [qw/X Y/] => 'obsolete' ]

=item B<description>

Optional C<list ref> of element description. These descriptions will
be used when generating user interfaces.

=back

=head1 Element declaration

=head2 Element type

Each element is declared with a list ref that contains all necessary
informations:

  element => [ 
               foo => { ... }
             ]

This most important informations from this hash ref is the mandatory 
B<type> parameter. The I<type> type can be:

=cut

# Here are the legal element types
my %create_sub_for = 
  (
   node => \&create_node,
   leaf => \&create_leaf,
   hash => \&create_id,
   list => \&create_id,
   warped_node => \&create_warped_node,
  ) ;

## Create_* methods are all internal and should not be used directly

sub create_element {
    my $self= shift ;
    my $element_name = shift ;

    my $element_info = $self->{model}{element}{$element_name}  ;

    Config::Model::Exception::UnknownElement->throw(
        object   => $self,
        function => 'create_element',
        where    => $self->location || 'configuration root',
        element     => $element_name,
        )
        unless defined $element_info ;

    Config::Model::Exception::Model->throw
        (
         error=> "element '$element_name' error: "
	       . "passed information is not a hash ref",
         object => $self
        ) 
	  unless ref($element_info) eq 'HASH' ;

    Config::Model::Exception::Model->throw
        (
         error=> "create element '$element_name' error: "
	         . "missing 'type' parameter",
         object => $self
        )
	  unless defined $element_info->{type} ;

    my $method = $create_sub_for{$element_info->{type}} ;

    croak $self->{config_class_name},
      " error: no create method for element type $element_info->{type}"
	unless defined $method ;

    $self->$method($element_name) ;
}



=over 8

=item C<node>

The element is a simple node of a tree instanciated from a 
configuration class (declared with 
L<Config::Model/"create_config_class( ... )">). 
See L</"Node element">.

=cut

sub create_node {
    my $self= shift ;
    my $element_name = shift ;

    my $element_info = dclone($self->{model}{element}{$element_name}) ; 

    Config::Model::Exception::Model->throw
        (
         error=> "create node '$element_name' error: "
	         ."missing config class name parameter",
         object => $self
        )
	  unless defined $element_info->{config_class_name} ;

    my @args = (config_class_name => $element_info->{config_class_name},
		instance          => $self->{instance},
		element_name      => $element_name) ;

    push @args, init_step => $element_info->{init_step} 
      if defined $element_info->{init_step} ;

    $self->{element}{$element_name} = $self->new(@args) ;
}

=item C<warped_node>

The element is a node whose properties (mostly C<config_class_name>)
can be changed (warped) according to the values of one or more leaf
elements in the configuration tree.  See L<Config::Model::WarpedNode>
for details.

=cut

sub create_warped_node {
    my $self= shift ;
    my $element_name = shift ;

    my $element_info = dclone($self->{model}{element}{$element_name}) ; 

    my @args = (instance          => $self->{instance},
		element_name      => $element_name,
		parent            => $self
	       ) ;

    require Config::Model::WarpedNode ;

    $self->{element}{$element_name} 
      = Config::Model::WarpedNode->new(%$element_info,@args) ;
}

=item C<leaf>

The element is a scalar value. See L</"Leaf element">

=cut

sub create_leaf {
    my $self = shift ;
    my $element_name = shift ;

    my $element_info = dclone($self->{model}{element}{$element_name}) ; 

    delete $element_info->{type} ;
    my $leaf_class = delete $element_info->{class} || 'Config::Model::Value' ;

    if (not defined *{$leaf_class.'::'}) {
	my $file = $leaf_class.'.pm';
	$file =~ s!::!/!g;
	require $file ;
    }

    $element_info->{parent}       = $self ;
    $element_info->{element_name} = $element_name ;
    $element_info->{instance}     = $self->{instance} ;

    $self->{element}{$element_name} = $leaf_class->new( %$element_info) ;
}

=item C<hash>

The element is a collection of nodes or values (default). Each 
element of this collection is identified by a string (Just like a regular
hash, except that you can set up constraint of the keys).
See L</"Hash element">

=item C<list> 

The element is a collection of nodes or values (default). Each element
of this collection is identified by an integer (Just like a regular
perl array, except that you can set up constraint of the keys).  See
L</"List element">

=back

=cut

sub create_id {
    my $self = shift ;
    my $element_name = shift ;

    my $element_info = dclone($self->{model}{element}{$element_name}) ; 
    my $type = delete $element_info->{type} ;

    Config::Model::Exception::Model
	->throw (
		 error=> "create $type element '$element_name' error"
		 .": missing 'type' parameter",
		 object => $self
		)
	  unless defined $type ;

    my $id_class = delete $element_info->{$type.'_class'} 
      || 'Config::Model::'.ucfirst($type).'Id';

    if (not defined *{$id_class.'::'}) {
	my $file = $id_class.'.pm';
	$file =~ s!::!/!g;
	require $file ;
    }

    $element_info->{parent}       = $self ;
    $element_info->{element_name} = $element_name ;
    $element_info->{instance}     = $self->{instance} ;
    $element_info->{config_model} = $self->{config_model} ;

    $self->{element}{$element_name} = $id_class->new( %$element_info) ;
}

=head2 Node element

When declaring a C<node> element, you must also provide a
C<config_class_name> parameter. For instance:

 $model ->create_config_class 
   (
   name => "ClassWithOneNode",
   element => [
                the_node => { 
                              type => 'node',
                              config_class_name => 'AnotherClass',
                            },
              ]
   ) ;

=head2 Locally changing properties of node element 

You can provide an C<init_step> parameter with a set of key, value
pair as argument. These arguments are infact a set of targets and
actions.

The targets can be elements of the node itself:

  init_step => [ 'bar' => 'Av' ] # default value of bar is Av

or elements of nodes lower in the tree:

  init_step => [ 'foo X' => 'Bv' ] # default value of X in bar is Av

You can also change the default values of several leaves: 

  init_step => [ 'bar' => 'Av', 'foo X' => 'Bv'  ]

In fact, the target of C<init_step> (C<bar>) is retrieved by the
L</grab(...)> method, so any string accepted by C<grab> can be used with
C<init_step>.

The I<effects> of C<init_step> are applied on the target through a
call to the L<< load|/load ( step => string [, permission => ... ] ) >> 
method.

The effect can be:

=over

=item *

A string: In this case, the target grabed will have a default value
set to the effect. I.e, the C<set()> method will be called with C<<
(default => ... ) >>. In other words, this feature changes locally
only the default value.

=item *

A hash ref. In this case the content of the hash ref will be passed to
the C<set()> method. In other world, this feature changes locally all
properties of the leaf. For instance, the hash ref may contain 
C<< max => XXX >> pair to change the maximum value of the leaf target.

=back

=cut

# this function should be called only by new when dealing with
# init_step parameter
sub perform_init_step {
    my $self = shift ;
    my $step = shift ;

    return unless defined $step ;

    my @steps = @$step ;
    my $class_name = $self->{config_class_name} ;

    while ( my $step_str = shift @steps) {
        my $obj = $self->grab($step_str );

        my $param = shift @steps;
        confess "$class_name new error : don't know what to do with ",
            "object grabed with '$step_str'"
            unless defined $param;

        my @arg   =
              ref($param) eq 'ARRAY' ? @$param
            : ref($param) eq 'HASH'  ? %$param
            : ( default => $param );

        print "$class_name new: initialize '$step_str' with @arg\n" if $::verbose;
        $obj->set(@arg);
    }

    return $self;
}

# check validity of permission declaration. 
# create a list to classify elements by permission
sub check_permission {
    my $self = shift ;

    # this is a bit convoluted, but the order of element for each
    # permission must respect the order of the elements declared in
    # the model by the user

    foreach my $elt_name (@{$self->{model}{element_list}}) {
	my $permission = $self->{model}{permission}{$elt_name} ;

	croak "Config class $self->{config_class_name} error: ",
	  "Unknown permission: $permission. Expected ",
	    join(" or ",@permission_list)
	      unless defined $permission_index{$permission} ;

	push 
	  @{$self->{element_by_permission}{$permission}}, $elt_name ;
    }
}


=head2 Leaf element

When declaring a C<leaf> element, you must also provide a
C<value_type> parameter. See L<Config::Model::Value> for more details.

=head2 Hash element

When declaring a C<hash> element, you must also provide a
C<index_type> parameter.

You can also provide a C<cargo_type> parameter set to C<node> or
C<leaf> (default).

See L<Config::Model::HashId> and L<Config::Model::AnyId> for more
details.

=head2 List element

You can also provide a C<cargo_type> parameter set to C<node> or
C<leaf> (default).

See L<Config::Model::ListId> and L<Config::Model::AnyId> for more
details.

=cut

# Node internal documentation
#
# Since the class holds a significant number of element, here's its
# main structure.
#
# $self 
# = (
#    config_model      : Weak reference to Config::Model object
#    config_class_name
#    model             : model of the config class
#    instance          : Weak reference to Config::Model::Instance object 
#    element_name      : Name of the element containing this node
#                        (undef for root node).
#    parent            : weak reference of parent node (undef for root node)
#    element           : actual storage of configuration elements

#    element_by_permission: {<permission>} = [ list of elements ]
#                          e.g {
#                                master => [ list of master elements ],
#                                advanced => [ ...],
#                                intermediate => [,,,]
#                              }
#  ) ;

sub new {
    my $caller = shift;
    my $type = ref($caller) || $caller ;

    my $self         = {};
    bless $self, $type;

    my @mandatory_parameters = qw/config_class_name instance/;

    if (ref($caller)) {
	$self->_set_parent($caller) ;

	$self->{config_model} = $caller->config_model ;
	push @mandatory_parameters, 'element_name' ;
    } 
    else {
	push @mandatory_parameters, 'config_model' ;
    }

    my %args = @_ ;

    my $init_step = delete $args{init_step} ;

    foreach my $p (@mandatory_parameters) {
	$self->{$p} = delete $args{$p} or
	  croak "Node->new: Missing $p parameter" ;
    }

    weaken($self->{instance}) ;
    weaken($self->{config_model}) ;

    $self->{index_value} = delete $args{index_value} ;

    my @left = keys %args ;
    croak "Node->new: unexpected parameter: @left" if @left ;


    my $caller_class = defined $self->{parent} 
      ? $self->{parent}->name : 'user' ;

    my $class_name = $self->{config_class_name} ;
    print "New $class_name requested by $caller_class\n" if $::verbose;

    my $model 
      = $self->{model} 
	= dclone ( $self->{config_model}->get_model($class_name) );

    $self->check_permission ;

    $self->perform_init_step($init_step) ;

    # setup auto_read
    if (defined $model->{read_config}) {
	$self->auto_read_init($model->{read_config}, 
			      $model->{read_config_dir});
    }

    # setup auto_write
    if (defined $model->{write_config}) {
	$self->auto_write_init($model->{write_config}, 
			       $model->{write_config_dir});
    }

    return $self ;
}

=head1 Introspection methods

=head2 name

Returns the location of the node, or its config class name (for root
node).

=cut

sub name {
    my $self = shift;
    return $self->location($self) || $self->{config_class_name};
}

=head2 get_type

Returns C<node>.

=cut

sub get_type {
    return 'node' ;
}

sub get_cargo_type {
    return 'node' ;
}

=head2 config_model

Returns the B<entire> configuration model.

=head2 model

Returns the configuration model of this node.

=head2 config_class_name

Returns the configuration class name of this node.

=head2 instance

Returns the instance object containing this node. Inherited from 
L<Config::Model::AnyThing>

=cut

for my $datum (qw/config_model model config_class_name/) {
    no strict "refs";       # to register new methods in package
    *$datum = sub {
        my $self= shift; 
        return $self->{$datum};
    } ;
}

=head2 has_element ( element_name )

Returns 1 if the class model has the element declared. 

=cut

# should I autovivify this element: NO
sub has_element {
    my $self= shift ;
    croak "has_element: missing element name" unless @_ ;
    return defined $self->{model}{element}{$_[0]} ? 1 : 0 ;
}

=head2 search_element ( element => <name> [, privilege => ... ] )

From this node (or warped node), search an element (respecting
privilege level). Inherited from L<Config::Model::AnyThing>.

This method returns a L<Config::Model::Searcher> object. See
L<Config::Model::Searcher> for details on how to handle a search.

=cut

=head2 element_model ( element_name )

Returns model of the element. 

=cut

sub element_model {
    my $self= shift ;
    croak "element_model: missing element name" unless @_ ;
    return $self->{model}{element}{$_[0]} ;
}

=head2 element_type ( element_name )

Returns the type (e.g. leaf, hash, list or node) of the element. 

=cut

sub element_type {
    my $self= shift ;
    croak "element_type: missing element name" unless @_ ;
    return $self->{model}{element}{$_[0]}{type} ;
}

=head2 element_name()

Returns the element name that contain this object. Inherited from 
L<Config::Model::AnyThing>

=head2 index_value()

See L<Config::Model::AnyThing/"index_value()">

=head2 parent()

See L<Config::Model::AnyThing/"parent()">

=head2 location()

See L<Config::Model::AnyThing/"location()">

=head1 Element property management

=head2 get_element_name ( for => <permission>, ...  )

Return all elements names available for C<permission>.
If no permission is specified, will return all
slots available at 'master' level (I.e all elements).

Optional paremeters are:

=over

=item *

B<type>: Returns only element of requested type (e.g. C<list>,
C<hash>, C<leaf>,...). By default return elements of any type.

=item *

B<cargo_type>: Returns only element which contain requested type.
 E.g. if C<get_element_name> is called with C<< cargo_type => leaf >>,
 C<get_element_name> will return simple leaf elements, but also hash
 or list element that contain L<leaf|Config::Model::Value> object. By
 default return elements of any type.




=back

Returns an array in array context, and a string 
(e.g. C<join(' ',@array)>) in scalar context.

=cut

sub get_element_name {
    my $self      = shift;
    my %args = @_ ;

    my $for  = $args{for} || 'master' ;
    my $type = $args{type} ; # optional
    my $cargo_type = $args{cargo_type} ; # optional

    croak "get_element_name: wrong 'for' parameter. Expected ", 
      join (' or ', @permission_list) 
	unless defined $permission_index{$for} ;

    my $for_idx = $permission_index{$for} ;

    my @result ;

    my $info = $self->{model} ;
    my @element_list = @{$self->{model}{element_list}} ;

    # this is a bit convoluted, but the order of the returned element
    # must respect the order of the elements declared in the model by
    # the user
    foreach my $elt (@element_list) {
	# create element if they don't exist
	$self->create_element($elt) unless defined $self->{element}{$elt};

	next if $info->{level}{$elt} eq 'hidden' ;
	my $elt_idx =  $permission_index{$info->{permission}{$elt}} ;
	my $elt_type =  $self->{element}{$elt}->get_type ;
	my $elt_cargo = $self->{element}{$elt}->get_cargo_type ;
	if ($for_idx >= $elt_idx 
	    and (not defined $type       or $type       eq $elt_type)
	    and (not defined $cargo_type or $cargo_type eq $elt_cargo)
	   ) {
	    push @result, $elt ;
	}
    }

    print "get_element_name: got @result for level $for\n"
      if $::debug ;

    return wantarray ? @result : join( ' ', @result );
}

=head2 next_element ( element_name, [ permission_index ] )

This method provides a way to iterate through the elements of a node.

Returns the next element name for a given permission (default
C<master>).  Returns undef if no next element is available.

=cut

sub next_element {
    my $self      = shift;
    my $element   = shift;
    my $min_level = shift;

    my @elements = $self->get_element_name(for => $min_level);

    return $elements[0] unless defined $element and $element ;

    my $i     = 0;
    while (@elements) {
        croak "next_element: element $element is unknown. Expected @elements"
            unless defined $elements[$i];
        last if $element eq $elements[ $i++ ];
    }
    return $elements[$i];
}

=head2 get_element_property ( element => ..., property => ... )

Retrieve a property of an element.

I.e. for a model :

  permission => [ X => 'master'],
  status     => [ X => 'deprecated' ]
  element    => [ X => { ... } ]

This call will return C<deprecated>:

  $node->get_element_property ( element => 'X', property => 'status' )

=cut

sub get_element_property {
    my $self = shift ;
    my %args = @_ ;

    my ($prop,$elt) 
      = $self->check_property_args('get_element_property',%args) ;

    return $self->{model}{$prop}{$elt} ;
}

=head2 set_element_property ( element => ..., property => ... )

Set a property of an element.

=cut

sub set_element_property {
    my $self = shift ;
    my %args = @_ ;

    my ($prop,$elt) 
      = $self->check_property_args('set_element_property',%args) ;

    my $new_value = $args{value} || 
      croak "set_element_property:: missing 'value' parameter";

    print "Node ",$self->name,": set $elt property $prop to $new_value\n"
      if $::debug;

   return $self->{model}{$prop}{$elt} = $new_value ;
}

=head2 reset_element_property ( element => ... )

Reset a property of an element according to the model.

=cut

sub reset_element_property {
    my $self = shift ;
    my %args = @_ ;

    my ($prop,$elt) 
      = $self->check_property_args('reset_element_property',%args) ;

    my $original_value = $self->{config_model} 
      -> get_element_property (
			       class => $self->{config_class_name},
			       %args
			      );

    print "Node ",$self->name,
      ": reset $elt property $prop to $original_value\n"
	if $::debug;

    return $self->{model}{$prop}{$elt} = $original_value ;
}

# internal: called by the proterty methods to check their arguments
sub check_property_args {
    my $self = shift;
    my $method_name = shift ;
    my %args = @_ ;

    my $elt = $args{element} || 
      croak "$method_name: missing 'element' parameter";
    my $prop = $args{property} || 
      croak "$method_name: missing 'property' parameter";

    my $ok = 0;
    map {$ok++ if $prop eq $_} @legal_properties ;
    confess "Unknown property in $method_name: $prop, expected status or ",
      "level or permission"
	unless $ok ;

    return ($prop,$elt) ;
}

=head1 Information management

=head2 fetch_element ( name  [ , user_permission ])

Fetch and returns an element from a node.

If user_permission is given, this method will check that the user has
enough privilege to access the element. If not, a C<RestrictedElement>
exception will be raised.

=cut

sub fetch_element {
    my $self = shift ;
    my $element_name = shift ;
    my $user = shift || 'master' ;

    my $model = $self->{model} ;

    # Some element are hidden (level property) because of warp
    # mechanism. Correct error message is not provided at this level
    # but error will be handled below (Value or WarpedNode objects)

    # retrieve element (and auto-vivify if needed)
    if (not defined $self->{element}{$element_name}) {
	$self->create_element($element_name) ;
    }

    # check status
    if ($model->{status}{$element_name} eq 'obsolete') {
	Config::Model::Exception::ObsoleteElement
	    ->throw(
		    object   => $self,
		    element  => $element_name,
		   );
    }

    if ($model->{status}{$element_name} eq 'deprecated' 
	and $self->{instance}->get_value_check('fetch_or_store')
       ) {
	# TBD elaborate more ? or include parameter description ??
	warn "Element $element_name of node ",$self->name," is deprecated\n";
    }

    # check permission
    my $elt_level = $model->{permission}{$element_name};
    my $elt_idx   = $permission_index{$elt_level} ;
    my $user_idx  = $permission_index{$user} ;

    croak "Unexpected permission '$user'" unless defined $user_idx ;

    if ($user_idx < $elt_idx
	and $self->{instance}->get_value_check('fetch_or_store')
       ) {
	Config::Model::Exception::RestrictedElement
	    ->throw(
		    object   => $self,
		    element  => $element_name,
		    level    => $user,
		    req_level => $elt_level,
		   );
    }

    return $self->{element}{$element_name} ;
}

=head2 fetch_element_value ( name  [ , user_permission ])

Fetch and returns the I<value> of a leaf element from a node.

If user_permission is given, this method will check that the user has
enough privilege to access the element. If not, a C<RestrictedElement>
exception will be raised.

=cut

sub fetch_element_value {
    my $self = shift ;
    my $element_name = shift ;
    my $user = shift || 'master' ;

    return $self->fetch_element($element_name,$user)->fetch() ;
}

=head2 store_element_value ( name, value  [ , user_permission ])

Store a I<value> in a leaf element from a node.

If user_permission is given, this method will check that the user has
enough privilege to access the element. If not, a C<RestrictedElement>
exception will be raised.

=cut

sub store_element_value {
    my $self = shift ;
    my $element_name = shift ;
    my $value = shift;
    my $user = shift || 'master' ;

    return $self->fetch_element($element_name,$user)->store( $value ) ;
}

=head2 is_element_available( name => ...,  permission => ... )


Returns 1 if the element C<name> is available for the given
C<permission> ('intermediate' by default). Returns 0 otherwise.

As a syntactic sugar, this method can be called with only one parameter:

   is_element_available( 'element_name' ) ; 

=cut

sub is_element_available {
    my $self = shift;
    my ($elt_name, $user_permission) = (undef, 'intermediate');
    if (@_ == 1) {
	$elt_name = shift ;
    }
    else {
	my %args = @_ ;
	$elt_name = $args{name} ;
	$user_permission = $args{permission} if defined $args{permission} ;
    }

    croak "is_element_available: missing name parameter" 
      unless defined $elt_name ;

    # force the warp to be done (if possible) so the catalog name
    # is updated
    my $element = $self->fetch_element($elt_name) ;

    my $element_level = $self->get_element_property(property => 'level',
						    element => $elt_name) ;
    return 0 if $element_level eq 'hidden' ;

    my $element_perm = $self->get_element_property(property => 'permission',
						   element => $elt_name) ;

    croak "is_element_available: unknown permission for ",
      "user permission: $user_permission"
	unless defined $permission_index{$user_permission} ;

    croak "is_element_available: unknown permission for element",
      " $elt_name: $$element_perm"
	unless defined $permission_index{$element_perm} ;

    return 
      $permission_index{$user_permission}
	>= $permission_index{$element_perm} ? 1 : 0;
}

=head2 is_element_defined( element_name )

Returns 1 if the element is defined.

=cut


sub is_element_defined {
    my $self = shift ;
    return defined $self->{element}{$_[0]}
}

=head2 grab(...)

See L<Config::Model::AnyThing/"grab(...)">.

=head2 grab_value(...)

See L<Config::Model::AnyThing/"grab_value(...)">.


=head2 grab_root()

See L<Config::Model::AnyThing/"grab_root()">.

=head1 Serialisation

=head2 load ( step => string [, permission => ... ] )

Load configuration data from the string into the node and its siblings.

This string follows the syntax defined in L<Config::Model::Loader>.
See L<Config::Model::Loader/"load ( ... )"> for details on parameters.
C<permission> is 'master' by default.

This method can also be called with a single parameter:

  $node->load("some data:to be=loaded");

=cut

sub load {
    my $self = shift ;
    my $loader = Config::Model::Loader->new ;

    my @args = @_ eq 1 ? (step => $_[0]) : @_ ;
    $loader->load(node => $self, @args) ;
}

=head2 dump_tree ( [ full_dump => 1] )

Dumps the configuration data of the node and its siblings into a string.

This string follows the syntax defined in
L<Config::Model::Loader>. The string produced by C<dump_tree> can be
passed to C<load>.

=cut

# TBD explain full_dump
# Does not dump sub-tree below an AutoRead object unless full_dump is
# set to 1.

sub dump_tree {
    my $self = shift ;
    my $dumper = Config::Model::Dumper->new ;
    $dumper->dump_tree(node => $self, @_) ;
}

=head2 describe ()

Provides a decription of the node elements.

=cut

sub describe {
    my $self = shift ;

    my $descriptor = Config::Model::Describe->new ;
    $descriptor->describe(node => $self) ;
}

=head2 report ()

Provides a text report on the content of the configuration below this
node.

=cut

sub report {
    my $self = shift ;
    my $reporter = Config::Model::Report->new ;
    $reporter->report(node => $self) ;
}

=head2 audit ()

Provides a text audit on the content of the configuration below this
node. This audit will show only value different from their default
value.

=cut

sub audit {
    my $self = shift ;
    my $reporter = Config::Model::Report->new ;
    $reporter->report(node => $self, audit => 1) ;
}

=head2 copy_from ( another_node_object )

Copy configuration data from another node into this node and its
siblings. The copy is made in a I<tolerant> mode where invalid data
are simply discarded.

=cut


sub copy_from {
    my $self = shift ;
    my $from = shift ;
    my $dump = $from->dump_tree() ;
    print "node copy with '$dump'\n" if $::debug ;
    $self->load( step => $dump, check_store => 0 ) ;
}


=head1 Help management

=head2 get_help ( [ element_name ] )

If called without element, returns the description of the class
(Stored in C<class_description> attribute of a node declaration).

If called with an element name, returns the description of the
element (Stored in C<description> attribute of a node declaration).

Returns undef if no description was found.

=cut

sub get_help {
    my $self  = shift;
    my $element_name = shift;

    my $help;
    if ( defined $element_name ) {
        $help = $self->{model}{description}{$element_name};
    }
    else {
        $help = $self->{model}{class_description};
    }

    return undef unless defined $help;
    $help =~ s/[\s\n]+/ /g;
    return $help;
}

1;

=head2 AutoRead nodes

As configuration model are getting bigger, the load time of a tree
gets longer. The L<Config::Model::AutoRead> class provides a way to
load the configuration informations only when needed.

TBD

=head1 AUTHOR

Dominique Dumont, domi@komarr.grenoble.hp.com

=head1 SEE ALSO

L<Config::Model::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::HashId>,
L<Config::Model::ListId>,
L<Config::Model::WarpedNode>,
L<Config::Model::Value>

=cut

