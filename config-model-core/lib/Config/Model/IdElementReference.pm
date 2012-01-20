package Config::Model::IdElementReference;

use Any::Moose;
use namespace::autoclean;

use Carp;
use Config::Model::ValueComputer;
use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger("Tree::Element::IdElementReference");

# config_elt is a reference to the object that called new
has config_elt =>
  ( is => 'ro', isa => 'Config::Model::AnyThing', required => 1, weak_ref => 1 );
has refer_to => ( is => 'ro', isa => 'Maybe[Str]' );
has computed_refer_to => ( is => 'ro', isa => 'Maybe[HashRef]' );

sub BUILD {
    my $self = shift;

    my $found =
      scalar grep { defined $self->$_; } qw/refer_to computed_refer_to/;

    if ( not $found ) {
        Config::Model::Exception::Model->throw(
            object  => $self->config_elt,
            message => "missing " . "refer_to or computed_refer_to parameter"
        );
    }
    elsif ( $found > 1 ) {
        Config::Model::Exception::Model->throw(
            object  => $self->config_elt,
            message => "cannot specify both "
              . "refer_to and computed_refer_to parameters"
        );
    }

    my $rft    = $self->{refer_to};
    my $crft   = $self->{computed_refer_to} || {};
    my %c_args = %$crft;

    my $refer_path =
      defined $rft
      ? $rft
      : delete $c_args{formula};

    # split refer_path on + then create as many ValueComputer as
    # required
    my @references = split /\s+\+\s+/, $refer_path;

    foreach my $single_path (@references) {
        push @{ $self->{compute} }, Config::Model::ValueComputer->new(
            formula   => $single_path,
            variables => {},
            %c_args,
            value_object => $self->{config_elt},
            value_type   => 'string'            # a reference is always a string
        );
    }

    return $self;
}

# internal

# FIXME: do not call back value object -> may recurse
sub get_choice_from_refered_to {
    my $self = shift;

    my $config_elt  = $self->{config_elt};
    my @enum_choice = $config_elt->get_default_choice;

    foreach my $compute_obj ( @{ $self->{compute} } ) {
        my $user_spec = $compute_obj->compute;

        next unless defined $user_spec;

        my @path = split( /\s+/, $user_spec );

        $logger->debug("path: @path");

        my $refered_to = eval { $config_elt->grab("@path"); };

        if ($@) {
            my $e = $@;

            # don't use $e->full_description as it will recurse badly
            my $msg = $e ? $e->description : '';
            Config::Model::Exception::Model->throw(
                object => $config_elt,
                error  => "'refer_to' parameter with path '@path': " . $msg
            );
        }

        my $element = pop @path;
        my $obj     = $refered_to->parent;
        my $type    = $obj->element_type($element);

        my @choice;
        if ( $type eq 'check_list' ) {
            @choice = $obj->fetch_element($element)->get_checked_list();
        }
        elsif ( $type eq 'hash' ) {
            @choice = $obj->fetch_element($element)->get_all_indexes();
        }
        elsif ( $type eq 'list' ) {
            my $list_obj = $obj->fetch_element($element);
            my $ct       = $list_obj->get_cargo_type;
            if ( $ct eq 'leaf' ) {
                @choice = $list_obj->fetch_all_values();
            }
            else {
                Config::Model::Exception::Model->throw(
                    object  => $obj,
                    message => "element '$element' cargo_type is $ct. "
                      . "Expected 'leaf'"
                );
            }
        }
        else {
            Config::Model::Exception::Model->throw(
                object  => $obj,
                message => "element '$element' type is $type. "
                  . "Expected hash or list or check_list"
            );
        }

        # use a hash so choices are unique
        push @enum_choice, @choice;
    }

    # prune out repeated items
    my %h;
    my @unique =
      grep { my $found = $h{$_} || 0; $h{$_} = 1; not $found; } @enum_choice;

    my @res;
    if ( $config_elt->value_type eq 'check_list' and $config_elt->ordered ) {
        @res = @unique;
    }
    else {
        @res = sort @unique;
    }

    $logger->debug( "Setting choice to '", join( "','", @res ), "'" );

    $config_elt->setup_reference_choice(@res);
}

sub reference_info {
    my $self = shift;
    my $str  = "choice was retrieved with: ";

    foreach my $compute_obj ( @{ $self->{compute} } ) {
        my $path = $compute_obj->formula;
        $path = defined $path ? "'$path'" : 'undef';
        $str .= "\n\tpath $path";
        $str .= "\n\t" . $compute_obj->compute_info;
    }
    return $str;
}

sub compute_obj {
    my $self = shift;
    return @{ $self->{compute} };
}

sub reference_path {
    my $self = shift;
    return map { $_->formula } @{ $self->{compute} };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Config::Model::IdElementReference - Refer to id element(s) and extract keys

=head1 SYNOPSIS

 # synopsis shows an example of model of a network to use references
 
 use Config::Model;
 use Log::Log4perl qw(:easy);
 Log::Log4perl->easy_init($WARN);

 my $model = Config::Model->new;

 # model of several hosts with several NICs
 $model->create_config_class(
    name      => 'Host',
    'element' => [
        ip_nic => {
            type       => 'hash',
            index_type => 'string',
            cargo      => {
                type       => 'leaf',
                value_type => 'uniline',
            }
        },
    ]
 );

 # model to choose a master host and a master NIC (whatever that may be)
 # among configured hosts. Once these 2 are configured, the model computes 
 # the master IP

 $model->create_config_class(
    name => "MyNetwork",

    element => [
        host => {
            type       => 'hash',
            index_type => 'string',
            cargo      => {
                type              => 'node',
                config_class_name => 'Host'
            },
        },

        # master_host is one of the configured hosts
        master_host => {
            type       => 'leaf',
            value_type => 'reference', # provided by tConfig::Model::IdElementReference
            refer_to   => '! host'
        },

        # master_nic is one NIC of the master host
        master_nic => {
            type              => 'leaf',
            value_type        => 'reference', # provided by tConfig::Model::IdElementReference
            computed_refer_to => {            # provided by Config::Model::ValueComputer
                formula   => '  ! host:$h ip_nic ',
                variables => { h => '- master_host' }
            }
        },

        # provided by Config::Model::ValueComputer
        master_ip => {
            type       => 'leaf',
            value_type => 'string',
            compute    => {
                formula   => '$ip',
                variables => {
                    h   => '- master_host',
                    nic => '- master_nic',
                    ip  => '! host:$h ip_nic:$nic'
                }
            }
        },

    ],
 );

 my $inst = $model->instance(root_class_name => 'MyNetwork' );

 my $root = $inst->config_root ;

 # configure hosts on my network
 my $step = 'host:foo ip_nic:eth0=192.168.0.1 ip_nic:eth1=192.168.1.1 -
             host:bar ip_nic:eth0=192.168.0.2 ip_nic:eth1=192.168.1.2 -
             host:baz ip_nic:eth0=192.168.0.3 ip_nic:eth1=192.168.1.3 ';
 $root->load( step => $step );

 print "master host can be one of ",
   join(' ',$root->fetch_element('master_host')->get_choice),"\n" ; 
 # prints: master host can be one of bar baz foo

 # choose master host
 $root->load('master_host=bar') ;

 print "master NIC of master host can be one of ",
 join(' ',$root->fetch_element('master_nic')->get_choice),"\n" ; 
 # prints: master NIC of master host can be one of eth0 eth1

 # choose master nic
 $root->load('master_nic=eth1') ;

 # check what is the master IP computed by the model
 print "master IP is ",$root->grab_value('master_ip'),"\n";
 # prints master IP is 192.168.1.2


=head1 DESCRIPTION

This class is user by L<Config::Model::Value> to set up an enumerated
value where the possible choice depends on the key of a
L<Config::Model::HashId> or the content of a L<Config::Model::ListId>
object.

This class is also used by L<Config::Model::CheckList> to define the
checklist items from the keys of another hash (or content of a list).

=head1 CONSTRUCTOR

Construction is handled by the calling object (L<Config::Model::Node>). 

=head1 Config class parameters

=over

=item refer_to

C<refer_to> is used to specify a hash element that will be used as a
reference. C<refer_to> points to an array or hash element in the
configuration tree using the path syntax (See
L<Config::Model::Node/grab> for details).

=item computed_refer_to

When C<computed_refer_to> is used, the path is computed using values
from several elements in the configuration tree. C<computed_refer_to>
is a hash with 2 mandatory elements: C<formula> and C<variables>.

=back

The available choice of this (computed or not) reference value is made
from the available keys of the refered_to hash element or the values
of the refered_to array element.

The example means the the value must correspond to an existing host:

 value_type => 'reference',
 refer_to => '! host' 

This example means the the value must correspond to an existing lan
within the host whose Id is specified by hostname:

 value_type => 'reference',
 computed_refer_to => { formula => '! host:$a lan', 
                        variables => { a => '- hostname' }
                      }

If you need to combine possibilities from several hash, use the "C<+>"
token to separate 2 paths:

 value_type => 'reference',
 computed_refer_to => { formula => '! host:$a lan + ! host:foobar lan', 
                        variables => { a => '- hostname' }
                      }

You can specify C<refer_to> or C<computed_refer_to> with a C<choice>
argument so the possible enum value will be the combination of the
specified choice and the refered_to values.

=head1 Methods

=head2 reference_info

Returns a human readable string with explains how is retrieved the
reference. This method is mostly used to construct an error messages.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Value>,
L<Config::Model::AnyId>, L<Config::Model::CheckList>

=cut
