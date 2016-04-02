package Config::Model::WarpedNode;

use Mouse;
with "Config::Model::Role::NodeLoader";

use Carp qw(cluck croak);

use Config::Model::Exception;
use Config::Model::Warper;
use Data::Dumper ();
use Log::Log4perl qw(get_logger :levels);
use Storable qw/dclone/;
use Scalar::Util qw/weaken/;

extends qw/Config::Model::AnyThing/;

my $logger = get_logger("Tree::Node::Warped");

# don't authorize to warp 'morph' parameter as it may lead to
# difficult maintenance

# status is not warpable either as an obsolete parameter must stay
# obsolete

my @allowed_warp_params = qw/config_class_name level/;

has [qw/backup follow/] => ( is => 'rw', isa => 'HashRef', default => sub { {}; } );
has [qw/rules/] => ( is => 'rw', isa => 'ArrayRef', required => 1 );

has [qw/warp help/] => ( is => 'rw', isa => 'Maybe[HashRef]' );
has morph => ( is => 'ro', isa => 'Bool', default => 0 );

has warper => ( is => 'rw', isa => 'Config::Model::Warper' );

my @backup_list = @allowed_warp_params;

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = @_;
    my %h     = map { ( $_ => $args{$_} ); } grep { defined $args{$_} } @backup_list;
    return $class->$orig( backup => dclone( \%h ), @_ );
};

sub BUILD {
    my $self = shift;

    # WarpedNode will register this object in a Value object (the
    # warper).  When the warper gets a new value, it will modify the
    # WarpedNode according to the data passed by the user.

    my $w = Config::Model::Warper->new(
        warped_object => $self,
        rules         => $self->rules,
        follow        => $self->follow,
        allowed       => \@allowed_warp_params
    );

    $self->warper($w);
    return $self;
}

sub config_model {
    my $self = shift;
    return $self->parent->config_model;
}

# Forward selected methods (See man perltootc)
foreach my $method (
    qw/fetch_element config_class_name copy_from get_element_name
    has_element is_element_available element_type load
    fetch_element_value get_type get_cargo_type dump_tree
    describe get_help children get set accept_regexp/
    ) {
    # to register new methods in package
    no strict "refs";

    *$method = sub {
        my $self = shift;

        # return undef if no class was warped in
        $self->check or return undef;
        return $self->{data}->$method(@_);
    };
}

sub name {
    my $self = shift;
    return $self->location;
}

sub is_accessible {
    my $self = shift;
    return defined $self->{data} ? 1 : 0;
}

sub get_actual_node {
    my $self = shift;
    $self->check;
    return $self->{data};    # might be undef
}

sub check {
    my $self = shift;
    my $check = shift || 'yes ';

    # must croak if element is not available
    if ( not defined $self->{data} ) {

        # a node can be retrieved either for a store operation or for
        # a fetch.
        if ( $check eq 'yes' ) {
            Config::Model::Exception::User->throw(
                object  => $self,
                message => "Object '$self->{element_name}' is not accessible.\n\t"
                    . $self->warp_error
            );
        }
        else {
            return 0;
        }
    }
    return 1;
}

sub set_properties {
    my $self = shift;

    my %args = ( %{ $self->backup }, @_ );

    # mega cleanup
    map( delete $self->{$_}, @allowed_warp_params );

    $logger->debug( $self->name . " set_properties called with ",
        Data::Dumper->Dump( [ \%args ], ['set_properties_args'] ) );

    my $config_class_name = delete $args{config_class_name};
    my $node_class = delete $args{class} || 'Config::Model::Node';

    my @prop_args = ( qw/property level element/, $self->element_name );

    my $original_level = $self->config_model->get_element_property(
        class => $self->parent->config_class_name,
        @prop_args,
    );

    my $next_level =
          defined $args{level}       ? $args{level}
        : defined $config_class_name ? $original_level
        :                              'hidden';

    $self->parent->set_element_property( @prop_args, value => $next_level )
        unless defined $self->index_value;

    unless ( defined $config_class_name ) {
        $self->clear;
        return;
    }

    my @args;
    ( $config_class_name, @args ) = @$config_class_name
        if ref $config_class_name;

    # check if some action is needed (ie. create or morph node)
    return
        if defined $self->{config_class_name}
        and $self->{config_class_name} eq $config_class_name;

    my $old_object            = $self->{data};
    my $old_config_class_name = $self->{config_class_name};

    # create a new object from scratch
    my $new_object = $self->create_node( $config_class_name, @args );

    $self->{config_class_name} = $config_class_name;
    $self->{data}              = $new_object;

    if ( defined $old_object and $self->{morph} ) {

        # there an old object that we need to translate
        $logger->debug( "WarpedNode: morphing ", $old_object->name, " to ", $new_object->name )
            if $logger->is_debug;

        $new_object->copy_from( from => $old_object, check => 'skip' );
    }

    # bringing a new object does not really modify the content of the config tree.
    # only changes underneath will change the tree. And these changes below will trigger
    # their own change notif. SO there's no need to call notify_change when transitioning
    # from an undef object into a real object. On the other hand, warping out an object will
    # NOT trigger notify_changes from below. So notify_change must be called
    if ( defined $old_object ) {
        my $from = $old_config_class_name // '<undef>';
        my $to   = $config_class_name     // '<undef>';
        $self->notify_change( note => "warped node from $from to $to" );
    }

    # need to call trigger on all registered objects only after all is setup
    $self->trigger_warp;
}

sub create_node {
    my $self              = shift;
    my $config_class_name = shift;

    my @args = (
        config_class_name => $config_class_name,
        instance          => $self->{instance},
        element_name      => $self->{element_name},
        parent            => $self->parent,
        container         => $self->container,
    );

    push @args, index_value => $self->index_value if defined $self->index_value;

    return $self->load_node(@args);
}

sub clear {
    my $self = shift;
    delete $self->{data};
}

sub load_data {
    my $self  = shift;
    my %args  = @_ > 1 ? @_ : ( data => shift );
    my $data  = $args{data};
    my $check = $self->_check_check( $args{check} );

    if ( ref($data) ne 'HASH' ) {
        Config::Model::Exception::LoadData->throw(
            object     => $self,
            message    => "load_data called with non hash ref arg",
            wrong_data => $data,
        );
    }

    $self->get_actual_node->load_data(%args);

}

sub is_auto_write_for_type {
    my $self = shift;
    $self->get_actual_node->is_auto_write_for_type(@_);
}

# register warper that goes through this path when looking for warp master value
sub register {
    my ( $self, $warped, $w_idx ) = @_;

    $logger->debug( "WarpedNode: " . $self->name, " registered " . $warped->name );

    # weaken only applies to the passed reference, and there's no way
    # to duplicate a weak ref. Only a strong ref is created. See
    #  qw(weaken) module for weaken()
    my @tmp = ( $warped, $w_idx );
    weaken( $tmp[0] );
    push @{ $self->{warp_these_objects} }, \@tmp;
}

sub trigger_warp {
    my $self = shift;

    # warp_these_objects is modified by the calls below, so this copy
    # must be done before the loop
    my @list = @{ $self->{warp_these_objects} || [] };

    foreach my $ref (@list) {
        my ( $warped, $warp_index ) = @$ref;
        next unless defined $warped;    # $warped is a weak ref and may vanish

        # pure warp of object
        $logger->debug( "node trigger_warp: from '",
            $self->name, "' warping '", $warped->name, "'" );

        # FIXME: this does not trigger new registration (or removal thereof)...
        $warped->refresh_affected_registrations( $self->location );

        #$warped->refresh_values_from_master ;
        $warped->do_warp;
        $logger->debug( "node trigger_warp: from '",
            $self->name, "' warping '", $warped->name, "' done" );
    }
}

# FIXME: should we un-register ???

1;

# ABSTRACT: Node that change config class properties

__END__

=head1 SYNOPSIS

 use Config::Model;

 my $model = Config::Model->new;
 foreach (qw/X Y/) {
    $model->create_config_class(
        name    => "Class$_",
        element => [ foo => {qw/type leaf value_type string/} ]
    );
 }
 $model->create_config_class(
    name => "MyClass",

    element => [
        master_switch => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/cX cY/]
        },

        'a_warped_node' => {
            type   => 'warped_node',
            follow => { ms => '! master_switch' },
            rules  => [
                '$ms eq "cX"' => { config_class_name => 'ClassX' },
                '$ms eq "cY"' => { config_class_name => 'ClassY' },
            ]
        },

    ],
 );

 my $inst = $model->instance(root_class_name => 'MyClass' );
 my $root = $inst->config_root ;

 print "Visible elements: ",join(' ',$root->get_element_name),"\n" ;
 # Visible elements: master_switch

 $root->load( steps => 'master_switch=cX' );
 print "Visible elements: ",join(' ',$root->get_element_name),"\n" ;
 # Visible elements: master_switch a_warped_node

 my $node = $root->grab('a_warped_node') ;
 print "a_warped_node class: ",$node->config_class_name,"\n" ;
 # a_warped_node class: ClassX

 $root->load( steps => 'master_switch=cY' );
 print "a_warped_node class: ",$node->config_class_name,"\n" ;
 # a_warped_node class: ClassY


=head1 DESCRIPTION

This class provides a way to change dynamically the configuration
class (or some other properties) of a node. The changes are done
according to the model declaration. 

This declaration will specify one (or several) leaf in the
configuration tree that will trigger the actual property change of the
warped node. This leaf is also referred as I<warp master>.

When the warp master(s) value(s) changes, C<WarpedNode> will create an instance
of the new class required by the warp master. 

If the morph parameter is set, the values held by the old object are
(if possible) copied to the new instance of the object using
L<copy_from|Config::Model::Node/"copy_from ( another_node_object )">
method.

Warped node can alter the following properties:

 config_class_name
 level

=head1 Constructor

C<WarpedNode> should not be created directly.

=head1 Warped node model declaration

=head2 Parameter overview

A warped node must be declared with the following parameters:

=over

=item type

Always set to C<warped_node>.

=item follow

L<Grab string|Config::Model::AnyThing/"grab(...)"> leading to the
C<Config::Model::Value> warp master.
See L<Config::Model::Warper/"Warp follow argument"> for details.

=item morph

boolean. If 1, C<WarpedNode> will try to recursively copy the value from
the old object to the new object using 
L<copy_from method|Config::Model::Node/"copy_from ( another_node_object )">.
When a copy is not possible, undef values
will be assigned to object elements.

=item rules

Hash or array ref that specify the property change rules according to the
warp master(s) value(s). 
See L<Config::Model::Warper/"Warp rules argument"> for details 
on how to specify the warp master values (or combination of values).

=back

=head2 Effect declaration

For a warped node, the effects are declared with these parameters:

=over 8

=item B<config_class_name>

When requested by the warp master,the C<WarpedNode> will create a new
object of the type specified by this parameter:

  XZ => { config_class_name => 'SlaveZ' }

If you pass an array ref, the array will contain the class name and
constructor arguments :

  XY  => { config_class_name => ['SlaveY', foo => 'bar' ], },

=item B<class>

Specify a Perl class to implement the above config class. This Perl Class B<must> inherit
L<Config::Model::Node>.

=back

=head1 Forwarded methods

The following methods are forwarded to contained node:

fetch_element config_class_name get_element_name has_element
is_element_available element_type load fetch_element_value get_type
get_cargo_type describe

=head1 Methods

=head2 name

Return the name of the node (even if warped out).

=head2 is_accessible

Returns true if the node hidden behind this warped node is accessible,
i.e. the warp master have values so a node was warped in.

=head2 get_actual_node

Returns the node object hidden behind the warped node. Croaks if the
node is not accessible.

=head2 load_data ( hash_ref )

Load configuration data with a hash ref. The hash ref key must match
the available elements of the node carried by the warped node.

=head1 EXAMPLE


 $model ->create_config_class 
  (
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

The 'bar' slot can refer to a C<ClassX>, C<ClassZ> or C<ClassY> object.

=item *

The warper object is the C<tree_macro> attribute of the root of the
object tree.

=item *

When C<tree_macro> is set to C<ZZ>, C<bar> will not be available. Trying to
access bar will raise an exception.

=item *

When C<tree_macro> is changed from C<ZZ> to C<XX>, 
C<bar> will refer to a brand new C<ClassX> 
object constructed with C<< ClassX->new(foo => 'bar') >>

=item *

Then, if C<tree_macro> is changed from C<XX> to C<XY>, C<bar> will
refer to a brand new C<ClassY> object. But in this case, the object will be
initialized with most if not all the attributes of C<ClassX>. This copy
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
L<Config::Model::Warper>,
L<Config::Model::WarpedNode>,
L<Config::Model::Value>

=cut
