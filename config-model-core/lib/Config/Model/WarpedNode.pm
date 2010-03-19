
#    Copyright (c) 2005-2007 Dominique Dumont.
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

package Config::Model::WarpedNode ;

use Carp qw(cluck croak);
use strict;
use warnings ;
use Scalar::Util qw(weaken) ;

use base qw/Config::Model::WarpedThing/ ;
use Config::Model::Exception ;
use Data::Dumper ();

# use vars qw($VERSION $AUTOLOAD) ;

=head1 NAME

Config::Model::WarpedNode - Node that change config class properties 

=head1 SYNOPSIS

 $model ->create_config_class 
  (
   name => 'Class_with_one_changing_node',
   element =>
   [
    tree_macro => {type => 'leaf',
                   value_type => 'enum',
                   choice     => [qw/XY XZ mXY W/]
                  },

    'a_warped_node'
    => {
        type => 'warped_node',
        follow  => '! tree_macro',
        morph   => 1,
        rules => {
                  XY  => { config_class_name => ['SlaveY'], },
                  mXY => {
                          config_class_name   => 'SlaveY',
                          experience => 'intermediate'
                         },
                  XZ => { config_class_name => 'SlaveZ' }
                 }
       },

    'another_warped_node'
    => {
        type => 'warped_node',
        follow  => { tm => '! tree_macro'},
        morph   => 1,
        rules => [
                  '$tm eq "XY"'  => { config_class_name => ['SlaveY'], },
                  '$tm eq "mXY"' => {
                                    config_class_name   => 'SlaveY',
                                    experience => 'intermediate'
                                  },
                  '$tm eq "XZ"'  => { config_class_name => 'SlaveZ' }
                 ]
       },

=head1 DESCRIPTION

This class provides a way to change dynamically the configuration
class (or some other properties) of a node. The changes are done
according to the model declaration. 

This declaration will specify one (or several) leaf in the
configuration tree that will trigger the actual property change of the
warped node. This leaf is also refered as I<warp master>.

When the warp master(s) value(s) changes, WarpedNode will create an instance
of the new class required by the warp master. 

If the morph parameter is set, the values held by the old object are
(if possible) copied to the new instance of the object using
L<copy_from|Config::Model::Node/"copy_from ( another_node_object )">
method.

Warped node can alter the following properties:

 config_class_name
 experience
 level

=head1 Constructor

WarpedNode should not be created directly.

=head1 Warped node model declaration

=head2 Parameter overview

A warped node must be declared with the following parameters:

=over

=item type

Always set to C<warped_node>.

=item follow

L<Grab string|Config::Model::AnyThing/"grab(...)"> leading to the
C<Config::Model::Value> warp master.
See L<Config::Model::WarpedThing/"Warp follow argument"> for details.

=item morph

boolean. If 1, WarpedNode will try to recursively copy the value from
the old object to the new object using 
L<copy_from method|Config::Model::Node/"copy_from ( another_node_object )">.
When a copy is not possible, undef values
will be assigned to object elements.

=item rules

Hash or array ref that specify the property change rules according to the
warp master(s) value(s). 
See L<Config::Model::WarpedThing/"Warp rules argument"> for details 
on how to specify the warp master values (or combination of values).

=back

=head2 Effect declaration

For a warped node, the effects are declared with these parameters:

=over 8

=item B<config_class_name>

When requested by the warp master,the WarpedNode will create a new
object of the type specified by this parameter:

  XZ => { config_class_name => 'SlaveZ' }

If you pass an array ref, the array will contain the class name and
constructor arguments :

  XY  => { config_class_name => ['SlaveY', foo => 'bar' ], },

=item B<experience>

Switch the experience of the slot when the object is warped in.

=back

=cut

# don't authorize to warp 'morph' parameter as it may lead to
# difficult maintenance

# status is not warpable either as an obsolete parameter must stay
# obsolete

my @allowed_warp_params = qw/config_class_name experience level/ ;

sub new {
    my $type = shift;
    my $self={} ;
    my %args = @_ ;

    bless $self,$type;

    my @mandatory_parameters = qw/element_name instance/;
    foreach my $p (@mandatory_parameters) {
	$self->{$p} = delete $args{$p} or
	  croak "WarpedNode->new: Missing $p parameter" ;
    }

    $self->_set_parent(delete $args{parent}) ;


    # optional parameter that makes sense only if warped node is held
    # by a hash or an array
    $self->{index_value}  =  delete $args{index_value} ;
    $self->{id_owner}     =  delete $args{id_owner} ;

    $self->{backup} = \%args ;

    # WarpedNode will register this object in a Value object (the
    # warper).  When the warper gets a new value, it will modify the
    # WarpedNode according to the data passed by the user.

    $self->check_warp_args(\@allowed_warp_params, \%args ) ;

    $self->set_properties() ;

    $self->submit_to_warp($self->{warp}) if $self->{warp} ;

    $self->warp 
      if ($self->{warp} and @{$self->{warp_info}{computed_master}});

    return $self ;
}

=head1 Forwarded methods

The following methods are forwared to contained node:

fetch_element config_class_name get_element_name has_element
is_element_available element_type load fetch_element_value get_type
get_cargo_type describe config_model

=cut

# Forward selected methods (See man perltootc)
foreach my $method (qw/fetch_element config_class_name get_element_name
                       has_element is_element_available element_type load
		       fetch_element_value get_type get_cargo_type 
                       describe config_model get_help/
		   ) {
    # to register new methods in package
    no strict "refs"; 

    *$method = sub {
	my $self= shift;
	# return undef if no class was warped in
	$self->check or return undef ; 
	return $self->{data}->$method(@_);
    } ;
}

=head1 Methods

=head2 name

Return the name of the node (even if warped out).

=cut

sub name {
    my $self = shift;
    return $self->location($self) ;
}

=head2 is_accessible

Returns true if the node hidden behind this warped node is accessible,
i.e. the warp master have values so a node was warped in.

=cut

sub is_accessible {
    my $self= shift;
    return defined $self->{data} ? 1 : 0 ;
}

=head2 get_actual_node

Returns the node object hidden behind the warped node. Croaks if the
node is not accessible.

=cut

sub get_actual_node {
    my $self= shift;
    $self->check ;
    return $self->{data} ; # might be undef
}

sub check {
    my $self= shift;

    # must croak if element is not available
    if (not defined $self->{data}) {
	# a node can be retrieved either for a store operation or for
	# a fetch.
	if ($self->instance->get_value_check('fetch_or_store')) {
	    Config::Model::Exception::User->throw
		(
		 object => $self,
		 message => "Object '$self->{element_name}' is not accessible.\n\t".
		 $self->warp_error
		) ;
	}
	else {
	    return 0;
	}
    }
    return 1 ;
}

sub set_properties {
    my $self = shift ;

    my %args = (%{$self->{backup}},@_) ;

    # mega cleanup
    map(delete $self->{$_}, @allowed_warp_params) ;

    print $self->name." set_properties called with \n", 
      Data::Dumper->Dump([\%args],['set_properties_args'])
	  if $::debug ;

    my $config_class_name = delete $args{config_class_name};

    unless (defined $config_class_name) {
	$args{level} = 'hidden' ;
	# cannot delete bluntly {data} for ListId or HashId
        $self->clear ;
    }

    $self->set_owner_element_property(\%args) ;

    return unless defined $config_class_name ;

    my @args ;
    ($config_class_name,@args) = @$config_class_name 
      if ref $config_class_name ;

    # check if some action is needed (ie. create or morph node)
    return if defined $self->{config_class_name} 
      and $self->{config_class_name} eq $config_class_name ;

    my $old_object = $self->{data} ;
    my $morph = $self->{warp}{morph} || 0 ;

    # create a new object from scratch
    my $new_object = $self->create_node($config_class_name,@args) ;

    if (defined $old_object and $morph) {
        # there an old object that we need to translate
        print "morphing ",$old_object->name," to ",$new_object->name,"\n"
          if $::debug ;

        $new_object->copy_from($old_object) ;
    }

    $self->{config_class_name} = $config_class_name ;
    $self->{data} = $new_object ;
}

sub create_node {
    my $self= shift ;
    my $config_class_name = shift ;

    my @args = (config_class_name => $config_class_name,
		instance          => $self->{instance},
		element_name      => $self->{element_name},
		index_value       => $self->{index_value},
	       ) ;

    return  $self->parent->new(@args) ;
}

sub clear {
    my $self = shift ;
    delete $self->{data} ;
}

=head2 load_data ( hash_ref )

Load configuration data with a hash ref. The hash ref key must match
the available elements of the node carried by the warped node.

=cut

sub load_data {
    my $self = shift ;
    my $h = shift ;

    if (ref ($h) ne 'HASH') {
	Config::Model::Exception::LoadData
	    -> throw (
		      object => $self,
		      message => "load_data called with non hash ref arg",
		      wrong_data => $h,
		     ) ;
    }

    $self->get_actual_node->load_data($h) ;

}

sub is_auto_write_for_type {
    my $self = shift ;
    $self->get_actual_node->is_auto_write_for_type(@_) ;
}

1;

__END__

=head1 EXAMPLE


 $model ->create_config_class 
  (
   experience => [ bar => 'advanced'] ,
   element =>
    [
     tree_macro => { type => 'leaf',
                     value_type => 'enum',
                     choice     => [qw/XX XY XZ ZZ/]
                   },
     bar =>  {
               type => 'warped_node',
               follow => '! tree_macro', 
               morph => 1,
               rules => [
                         XX => { config_class_name 
                                   => [ 'ClassX', 'foo' ,'bar' ]}
                         XY => { config_class_name => 'ClassY'},
                         XZ => { config_class_name => 'ClassZ'}
                        ]
             }
    ]
  );

In the example above we see that:

=over

=item *

The 'bar' slot can refer to a ClassX, ClassZ or ClassY object.

=item *

The warper object is the C<tree_macro> attribute of the root of the
object tree.

=item *

When C<tree_macro> is set to C<ZZ>, C<bar> will not be available. Trying to
access bar will raise an exception.

=item *

When C<tree_macro> is changed from C<ZZ> to C<XX>, 
C<bar> will refer to a brand new ClassX 
object constructed with C<< ClassX->new(foo => 'bar') >>

=item *

Then, if C<tree_macro> is changed from C<XX> to C<XY>, C<bar> will
refer to a brand new ClassY object. But in this case, the object will be
initialized with most if not all the attributes of ClassX. This copy
will be done whenever C<tree_macro> is changed.

=back

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model::Instance>, 
L<Config::Model>, 
L<Config::Model::HashId>,
L<Config::Model::ListId>,
L<Config::Model::AnyThing>,
L<Config::Model::WarpedThing>,
L<Config::Model::WarpedNode>,
L<Config::Model::Value>

=cut

