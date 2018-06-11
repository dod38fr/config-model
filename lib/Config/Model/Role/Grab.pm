package Config::Model::Role::Grab;

# ABSTRACT: Role to grab data from elsewhere in the tree

use Mouse::Role;
use strict;
use warnings;
use Carp;

use List::MoreUtils qw/any/;
use Mouse::Util;
use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger("Grab");

## Navigation

# accept commands like
# item:b -> go down a node, create a new node if necessary
# - climbs up
# ! climbs up to the top

# Now return an object and not a value !

sub grab {
    my $self = shift;
    my ( $steps, $mode, $autoadd, $type, $grab_non_available, $check ) =
        ( undef, 'strict', 1, undef, 0, 'yes' );

    my %args = @_ > 1 ? @_ : ( steps => $_[0] );

    $steps               = delete $args{steps} // delete $args{step};
    $mode               = delete $args{mode} if defined $args{mode};
    $autoadd            = delete $args{autoadd} if defined $args{autoadd};
    $grab_non_available = delete $args{grab_non_available}
        if defined $args{grab_non_available};
    $type  = delete $args{type};                           # node, leaf or undef
    $check = $self->_check_check( delete $args{check} );

    if ( defined $args{strict} ) {
        carp "grab: deprecated parameter 'strict'. Use mode";
        $mode = delete $args{strict} ? 'strict' : 'adaptative';
    }

    Config::Model::Exception::User->throw(
        object  => $self,
        message => "grab: unexpected parameter: " . join( ' ', keys %args ) ) if %args;

    Config::Model::Exception::Internal->throw(
        error => "grab: steps parameter must be a string " . "or an array ref" )
        unless ref $steps eq 'ARRAY' || not ref $steps;

    # accept commands, grep remove empty items left by spurious spaces
    my $huge_string = ref $steps ? join( ' ', @$steps ) : $steps;
    my @command = (
        $huge_string =~ m/
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
    );

    my @saved = @command;

    $logger->trace(
        "grab: executing '",
        join( "' '", @command ),
        "' on object '",
        $self->name, "'"
    );

    my @found = ($self);

COMMAND:
    while (@command) {
        last if $mode eq 'step_by_step' and @saved > @command;

        my $cmd = shift @command;

        my $obj = $found[-1];
        $logger->trace( "grab: executing cmd '$cmd' on object '", $obj->name, "($obj)'" );

        if ( $cmd eq '!' ) {
            push @found, $obj->grab_root();
            next;
        }

        if ( $cmd =~ /^!([\w:]*)/ ) {
            my $ancestor = $obj->grab_ancestor($1);
            if ( defined $ancestor ) {
                push @found, $ancestor;
                next;
            }
            else {
                Config::Model::Exception::AncestorClass->throw(
                    object => $obj,
                    info   => "grab called from '"
                        . $self->name
                        . "' with steps '@saved' looking for class $1"
                ) if $mode eq 'strict';
                return;
            }
        }

        if ( $cmd =~ /^\?(\w[\w-]*)/ ) {
            push @found, $obj->grab_ancestor_with_element_named($1);
            $cmd =~ s/^\?//;    #remove the go up part
            unshift @command, $cmd;
            next;
        }

        if ( $cmd eq '-' ) {
            if ( defined $obj->parent ) {
                push @found, $obj->parent;
                next;
            }
            else {
                $logger->debug( "grab: ", $obj->name, " has no parent" );
                return $mode eq 'adaptative' ? $obj : undef;
            }
        }

        unless ( $obj->isa('Config::Model::Node')
            or $obj->isa('Config::Model::WarpedNode') ) {
            Config::Model::Exception::Model->throw(
                object  => $obj,
                message => "Cannot apply command '$cmd' on leaf item"
                    . " (full command is '@saved')"
            );
        }

        my ( $name, $action, $arg ) =
            ( $cmd =~ /(\w[\-\w]*)(?:(:)((?:"[^\"]*")|(?:[\w:\/\.\-\+]+)))?/ );

        if ( defined $arg and $arg =~ /^"/ and $arg =~ /"$/ ) {
            $arg =~ s/^"//;    # remove leading quote
            $arg =~ s/"$//;    # remove trailing quote
        }

        {
            no warnings "uninitialized";
            $logger->debug("grab: cmd '$cmd' -> name '$name', action '$action', arg '$arg'");
        }

        unless ( $obj->has_element($name) ) {
            if ( $mode eq 'step_by_step' ) {
                return wantarray ? ( undef, @command ) : undef;
            }
            elsif ( $mode eq 'loose' ) {
                return;
            }
            elsif ( $mode eq 'adaptative' ) {
                last;
            }
            else {
                Config::Model::Exception::UnknownElement->throw(
                    object   => $obj,
                    element  => $name,
                    function => 'grab',
                    info     => "grab called from '" . $self->name . "' with steps '@saved'"
                );
            }
        }

        unless (
            $grab_non_available
            or $obj->is_element_available(
                name       => $name,
            )
            ) {
            if ( $mode eq 'step_by_step' ) {
                return wantarray ? ( undef, @command ) : undef;
            }
            elsif ( $mode eq 'loose' ) {
                return;
            }
            elsif ( $mode eq 'adaptative' ) {
                last;
            }
            else {
                Config::Model::Exception::UnavailableElement->throw(
                    object   => $obj,
                    element  => $name,
                    function => 'grab',
                    info     => "grab called from '" . $self->name . "' with steps '@saved'"
                );
            }
        }

        my $next_obj = $obj->fetch_element(
            name          => $name,
            check         => $check,
            accept_hidden => $grab_non_available
        );

        # create list or hash element only if autoadd is true
        if (    defined $action
            and $autoadd == 0
            and not $next_obj->exists($arg) ) {
            return if $mode eq 'loose';
            Config::Model::Exception::UnknownId->throw(
                object   => $obj->fetch_element($name),
                element  => $name,
                id       => $arg,
                function => 'grab'
            ) unless $mode eq 'adaptative';
            last;
        }

        if ( defined $action and not $next_obj->isa('Config::Model::AnyId') ) {
            return if $mode eq 'loose';
            Config::Model::Exception::Model->throw(
                object  => $obj,
                message => "Cannot apply command '$cmd' on non hash or non list item"
                    . " (full command is '@saved'). item is '"
                    . $next_obj->name . "'"
            );
            last;
        }

        # action can only be :
        $next_obj = $next_obj->fetch_with_id(index => $arg, check => $check) if defined $action;

        push @found, $next_obj;
    }

    # check element type
    if ( defined $type ) {
        my @allowed = ref $type ? @$type : ($type);
        while ( @found and not any {$found[-1]->get_type eq $_} @allowed ) {
            Config::Model::Exception::WrongType->throw(
                object        => $found[-1],
                function      => 'grab',
                got_type      => $found[-1]->get_type,
                expected_type => $type,
                info          => "requested with steps '$steps'"
            ) if $mode ne 'adaptative';
            pop @found;
        }
    }

    my $return = $found[-1];
    $logger->debug( "grab: returning object '", $return->name, "($return)'" );
    return wantarray ? ( $return, @command ) : $return;
}

sub grab_value {
    my $self = shift;
    my %args = scalar @_ == 1 ? ( steps => $_[0] ) : @_;

    my $obj = $self->grab(%args);

    # Pb: may return a node. add another option to grab ??
    # to get undef value when needed?

    return if ( $args{mode} and $args{mode} eq 'loose' and not defined $obj );

    Config::Model::Exception::User->throw(
        object  => $self,
        message => "grab_value: cannot get value of non-leaf or check_list "
            . "item with '"
            . join( "' '", @_ )
            . "'. item is $obj"
        )
        unless ref $obj
        and ( $obj->isa("Config::Model::Value")
        or $obj->isa("Config::Model::CheckList") );

    my $value = $obj->fetch;
    if ( $logger->is_debug ) {
        my $str = defined $value ? $value : '<undef>';
        $logger->debug( "grab_value: returning value $str of object '", $obj->name );
    }
    return $value;
}

sub grab_annotation {
    my $self = shift;
    my @args = scalar @_ == 1 ? ( steps => $_[0] ) : @_;

    my $obj = $self->grab(@args);

    return $obj->annotation;
}

sub grab_root {
    my $self = shift;
    return defined $self->parent
        ? $self->parent->grab_root
        : $self;
}

sub grab_ancestor {
    my $self = shift;
    my $class = shift || die "grab_ancestor: missing ancestor class";

    return $self if $self->get_type eq 'node' and $self->config_class_name eq $class;

    return $self->{parent}->grab_ancestor($class) if defined $self->{parent};
    return;
}

#internal. Used by grab with '?xxx' steps
sub grab_ancestor_with_element_named {
    my ( $self, $search, $type ) = @_;

    my $obj = $self;

    while (1) {
        $logger->debug(
            "grab_ancestor_with_element_named: executing cmd '?$search' on object " . $obj->name );

        my $obj_element_name = $obj->element_name;

        if (    $obj->isa('Config::Model::Node')
            and $obj->has_element( name => $search, type => $type ) ) {

            # object contains the search element, we need to grab the
            # searched object (i.e. the '?foo' part is done
            return $obj;
        }
        elsif ( defined $obj->parent ) {

            # going up
            $obj = $obj->parent;
        }
        else {
            # there's no more up to go to...
            Config::Model::Exception::Model->throw(
                object => $self,
                error  => "Error: cannot grab '?$search'" . "from " . $self->name
            );
        }
    }
}

1;

__END__

=head1 SYNOPSIS

  $root->grab('foo:2 bar');
  $root->grab(steps => 'foo:2 bar');
  $root->grab(steps => 'foo:2 bar', type => 'leaf');
  $root->grab_value(steps => 'foo:2 bar');

=head1 DESCRIPTION

Role used to let a tree item (i.e. node, hash, list or leaf) to grab
another item or value from the configuration tree using a path (a bit
like an xpath path with a different syntax).


=head1 METHODS

=head2 grab

Grab an object from the configuration tree.

Parameters are:

=over

=item C<steps> (or C<step>)

A string indicating the steps to follow in the tree to find the
required item. (mandatory)

=item C<mode>

When set to C<strict>, C<grab> throws an exception if no object is found
using the passed string. When set to C<adaptative>, the object found last is
returned. For instance, for the steps C<good_step wrong_step>, only
the object held by C<good_step> is returned. When set to C<loose>, grab
returns undef in case of problem. (default is C<strict>)

=item C<type>

Either C<node>, C<leaf>, C<hash> or C<list> or an array ref containing these
values. Returns only an object of
requested type. Depending on C<strict> value, C<grab> either
throws an exception or returns the last object found with the requested type.
(optional, default to C<undef>, which means any type of object)

Examples:

 $root->grab(steps => 'foo:2 bar', type => 'leaf')
 $root->grab(steps => 'foo:2 bar', type => ['leaf','check_list'])

=item C<autoadd>

When set to 1, C<hash> or C<list> configuration element are created
when requested by the passed steps. (default is 1). 

=item grab_non_available

When set to 1, grab returns an object even if this one is not
available. I.e. even if this element was warped out. (default is 0).

=back

The C<steps> parameters is made of the following items separated by
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

C<?xxx:yy> goes up the tree the same way. But no check is done to see
if id C<yy> key actually exists or not. Only the element C<xxx> is
considered when going up the tree.

=back

=head2 grab_value

Like L</grab>, but returns the value of a leaf or check_list object, not
just the leaf object.

C<grab_value> raises an exception if following the steps ends on anything but a
leaf or a check_list.

=head2 grab_annotation

Like L</grab>, but returns the annotation of an object.

=head2 grab_root

Returns the root of the configuration tree.

=head2 grab_ancestor

Parameter: a configuration class name

Go up the configuration tree until a node using the configuration
class is found. Returns the found node or undef.

Example:

  # returns a Config::Model::Node object for a Systemd::Service config class
  $self->grab('Systemd::Service');

=cut

