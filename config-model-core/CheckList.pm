# $Author: ddumont $
# $Date: 2007-05-04 11:20:12 $
# $Name: not supported by cvs2svn $
# $Revision: 1.5 $

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

package Config::Model::CheckList ;
use Config::Model::Exception ;
use Scalar::Util qw(weaken) ;
use warnings ;
use Carp;
use strict;



use base qw/Config::Model::WarpedThing/ ;

use vars qw($VERSION) ;
$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/;

=head1 NAME

Config::Model::CheckList - Handle check list element

=head1 SYNOPSIS

 $model ->create_config_class 
  (
   ...
   element 
   => [ 
       check_list 
       => { type => 'check_list',
            choice => [ 'A', 'B', 'C', 'D' ],
            help   => { A => 'A effect is this',
                        D => 'D does that',
                      }
          },
       check_list_refering_to_another_hash 
       => { type => 'check_list',
            refer_to => '- foobar'
          },

      ]
  ) ;

=head1 DESCRIPTION

This class provides a check list element for a L<Config::Model::Node>.
In other words, this class provides a list of booleans items. Each item
can be set to 1 or 0.

The available items in the check list can be :

=over

=item * 

A fixed list (with the C<choice> parameter)

=item *

A dynamic list where the available choise are the keys of another hash
of the configuration tree. See L</"Choice reference"> for details.

=back

=cut

=head1 CONSTRUCTOR

CheckList object should not be created directly.

=cut

my @accessible_params =  qw/default choice/ ;

my @allowed_warp_params = (@accessible_params, qw/level permission/);

sub new {
    my $type = shift;
    my %args = @_ ;

    my $self = { } ;
    bless $self,$type;

    foreach my $p (qw/element_name instance config_model/) {
	$self->{$p} = delete $args{$p} or
	  croak "$type->new: Missing $p parameter for element ".
	    $self->{element_name} || 'unknown' ;
    }

    $self->_set_parent(delete $args{parent}) ;

    my $warp_info = delete $args{warp} ;

    $self->{help} = delete $args{help} ;

    $self->{backup}  = \%args ;

    $self->set() ; # set will use backup data

    if (defined $warp_info) {
	$self->check_warp_args( \@allowed_warp_params, $warp_info) ;
    }

    $self->submit_to_warp($self->{warp}) if $self->{warp} ;

    $self->cl_init ;

    return $self ;
}

sub cl_init {
    my $self = shift ;

    $self->{data} = {} ;

    $self->warp if ($self->{warp});

    if (defined $self->{refer_to}) {
	$self->{ref_object}->get_choice_from_refered_to ;
    }
}

sub name {
    my $self = shift ;
    my $name =  $self->{parent}->name . ' '.$self->{element_name} ;
    return $name ;
}

sub value_type { return 'check_list' ;} 

=head1 CheckList model declaration

A check list element must be declared with the following parameters:

=over

=item type

Always C<checklist>.

=item choice

A list ref containing the check list items (optional)

=item refer_to

This parameters is used when the keys of a hash are used to specify
the possible choices of the check list. See L<Choice reference> for
details. (optional)

=item default

List ref to specify the check list items which are "on" by default.
(optional)

=item help

Hash ref to provide informations on the check list items.

=item warp

Used to provide dynamic modifications of the check list properties
See L<Config::Model::WarpedThing> for details

=back

For example:

=over

=item *

A simple check list with help:

       choice_list
       => { type => 'check_list',
            choice     => ['A' .. 'Z'],
            help => { A => 'A help', E => 'E help' } ,
          },

=item *

A check list with default values:

       choice_list_with_default
       => { type => 'check_list',
            choice     => ['A' .. 'Z'],
            default   => [ 'A', 'D' ],
          },

=item *

A check list whose available choice and default change depending on
the value of the C<macro> parameter:

       'warped_choice_list'
       => { type => 'check_list',
            warp => { follow => '- macro',
                      rules  => { AD => { choice => [ 'A' .. 'D' ], 
                                          default => ['A', 'B' ] },
                                  AH => { choice => [ 'A' .. 'H' ] },
                                }
                    }
          },

=back


=cut

# warning : call to 'set' are not cumulative. Default value are always
# restored. Lest keeping track of what was modified with 'set' is
# too hard for the user.
sub set {
    my $self = shift ;

    # cleanup all parameters that are handled by warp
    map(delete $self->{$_}, 
        qw/default choice refer_to/) ;

    # merge data passed to the constructor with data passed to set
    my %args = (%{$self->{backup}},@_ );

    if (defined $args{choice}) {
	my @choice = @{ delete $args{choice} } ;
	$self->{default_choice} = \@choice ;
	$self->setup_choice( @choice ) ;
    }

    if (defined $args{default}) {
	$self->{default} = delete $args{default} ;
	my %h = map { $_ => 1 } @{$self->{default}} ;
	$self->{default_data} = \%h ;
    }
    else {
	$self->{default_data} = {} ;
    }

    if (defined $args{refer_to}) {
	$self->{choice} ||= [] ; # create empty choice
	$self->{refer_to} = delete $args{refer_to} ;
	$self->submit_to_refer_to() ;
    }

    Config::Model::Exception::Model
	-> throw (
		  object => $self,
		  error => "Unexpected parameters :".join(' ', keys %args )
		 ) 
	  if scalar keys %args ;
}

sub setup_choice {
    my $self = shift ;
    my @choice = ref $_[0] ? @{$_[0]} : @_ ;

    print "CheckList: setup_choice with @choice\n" if $::debug ;
    # store all enum values in a hash. This way, checking
    # whether a value is present in the enum set is easier
    delete $self->{choice_hash} if defined $self->{choice_hash} ;
    map {$self->{choice_hash}{$_} =  1;} @choice ;

    $self->{choice}  = \@choice ;

    # cleanup current data if it does not fit current choices
    foreach my $item (keys %{$self->{data}}) {
	delete $self->{data}{$item} unless defined $self->{choice_hash}{$item} ;
    }
}

# Need to extract Config::Model::Reference (used by Value, and maybe AnyId).

=head1 Choice reference

This other hash is indicated by the C<refer_to> parameter. C<refer_to>
uses the syntax of the C<step> parameter of
L<grab(...)|Config::AnyThing/"grab(...)">

See L<refer_to parameter|Config::Model::IdElementReference/"refer_to parameter">.

=head2 Reference examples

=over

=item *

A check list where the available choices are the keys of C<my_hash>
configuration parameter:

       refer_to_list
       => { type => 'check_list',
            refer_to => '- my_hash'
          },

=item *

A check list where the available choices are the keys of C<my_hash>
and C<my_hash2> and C<my_hash3> configuration parameter:


       refer_to_3_lists
       => { type => 'check_list',
            refer_to => '- my_hash + - my_hash2   + - my_hash3'
          },

=item *

A check list where the available choices are the specified choice and
the choice of C<refer_to_3_lists> and a hash whose name is specified
by the value of the C<indirection> configuration parameter (this
example is admitedly convoluted):


       refer_to_check_list_and_choice
       => { type => 'check_list',
            refer_to => [ '- refer_to_2_list + - $var',
                          var => '- indirection ',
                        ],
            choice  => [qw/A1 A2 A3/],
          },

=back

=cut

sub submit_to_refer_to {
    my $self = shift ;

    my $refto = $self->{refer_to} ;
    $self->{ref_object} = Config::Model::IdElementReference 
      -> new ( refer_to   => $refto,
	       config_elt => $self,
	     ) ;
    my ($refer_path,%var) = ref $refto ? @$refto : ($refto) ;

    $self->register_in_other_value(\%var) ;
}

sub setup_reference_choice {
    my $self = shift ;
    $self->setup_choice(@_) ;
}


=head1 Methods

=head2 get_type

Returns C<check_list>.

=cut

sub get_type {
    my $self = shift;
    return 'check_list' ;
}

=head2 cargo_type()

Returns 'leaf'.

=cut

sub get_cargo_type { goto &cargo_type } 

sub cargo_type {
    my $self = shift ;
    return 'leaf' ;
}

=head2 check ( $choice )

Set choice.

=cut

sub check {
    my $self = shift ;
    if (defined $self->{refer_to}) {
	$self->{ref_object}->get_choice_from_refered_to ;
    }

    map {$self->store($_ , 1 ) } @_ ;
}

sub store {
    my ($self, $choice, $value) = @_;

    my $inst = $self->instance ;

    if ($value != 0 and $value != 1) {
        Config::Model::Exception::WrongValue 
	    -> throw ( error => "store: check item value must be boolean, "
		              . "not '$value'.",
		       object => $self) ;
	return ;
    }

    my $ok = $self->{choice_hash}{$choice} || 0 ;

    if ($ok ) {
	$self->{data}{$choice} = $value ;
    }
    elsif ($inst->get_value_check('store'))  {
	my $err_str = "Unknown check_list item '$choice'. Expected '"
                    . join("', '",@{$self->{choice}}) . "'" ;
	$err_str .= "\n\t". $self->{ref_object}->reference_info 
	  if defined $self->{refer_to} ;
        Config::Model::Exception::WrongValue 
	    -> throw ( error =>  $err_str ,
		       object => $self) ;
    }
}

=head2 uncheck ( $choice )

Unset choice

=cut

sub uncheck {
    my $self = shift ;
    if (defined $self->{refer_to}) {
	$self->{ref_object}->get_choice_from_refered_to ;
    }

    map {$self->store($_ , 0 ) } @_ ;
}

=head2 get_choice

Returns an array of all items names that can be checked (i.e.
that can have value 0 or 1).

=cut

# get_choice is always called when using check_list, so having a
# warp safety check here makes sense

sub get_choice {
    my $self = shift ;

    if (defined $self->{refer_to}) {
	$self->{ref_object}->get_choice_from_refered_to ;
    }

    if (not defined $self->{choice}) {
        my $msg = "check_list element has no defined choice. " . 
	  $self->warp_error;
	Config::Model::Exception::UnavailableElement
	    -> throw (
		      info => $msg,
		      object => $self->parent,
		      element => $self->element_name,
		     ) ;
    }

    return @{ $self->{choice} } ;
}

sub get_default_choice {
    my $self = shift ;
    return @{$self->{default_choice} || [] } ;
}

=head2 get_help (choice_value)

Return the help string on this choice value

=cut

sub get_help {
    my $self = shift ;
    my $help = $self->{help} ;

    return $help unless @_ ;

    my $on_value = shift ;
    return $help->{$on_value} if defined $help and defined $on_value ;

    return undef ;
}

=head2 clear

Reset the check list 

=cut

sub clear {
    my $self = shift ;
    $self->cl_init ;
}

=head2 get_checked_list ()

Returns a list (or a list ref) of all checked items (i.e. all items
set to 1). 

=cut

sub get_checked_list {
    my $self = shift ;

    my %h = $self->get_checked_list_as_hash(@_) ;
    return  grep { $h{$_} } sort keys %h ;
}

=head2 fetch ()

Returns a string listing the checked items (i.e. "A,B,C")

=cut

sub fetch {
    my $self = shift ;
    return join (',', $self->get_checked_list);
}

sub fetch_custom {
    my $self = shift ;
    return join (',', $self->get_checked_list('custom'));
}

=head2 set_checked_list ( item1, item2, ..)

Set all passed items to checked (1). All other available items
in the check list are set to 0.

Example:

  # set cl to A=0 B=1 C=0 D=1
  $cl->set_checked_list('B','D')

=cut

sub store_set { goto &set_checked_list } 

sub set_checked_list {
    my $self = shift ;
    $self->clear ;
    $self->check (@_) ;
}

=head2 get_checked_list_as_hash ()

Returns a hash (or a hash ref) of all items. The boolean value is the
value of the hash.

Example:

 { A => 0, B => 1, C => 0 , D => 1}

=cut

sub get_checked_list_as_hash {
    my $self = shift ;
    my $type = shift || '';

    if ($type and $type ne 'custom' and $type ne 'standard') {
	croak "get_checked_list_as_hash: expected custom or standard parameter, not $type" ;
    }

    # fill empty hash result missing data
    my %h = map { $_ => 0 } $self->get_choice ;

    # copy hash and return it
    my %result 
      = $type eq 'custom'   ? (%h,%{$self->{data}} )
      : $type eq 'standard' ? (%h,%{$self->{default_data}})
      :                       (%h,%{$self->{default_data}},%{$self->{data}} ) ;

    return wantarray ? %result : \%result;
}

=head2 set_checked_list_as_hash ( A => 1, B => 1 )

Set check_list items. Missing items in the paramaters are set to 0.

The example ( A => 1, B => 1 ) above will give :

 A = 1 , B = 1, C = 0 , D = 0

=cut

sub set_checked_list_as_hash {
    my $self = shift ;
    my %check = ref $_[0] ? %{$_[0]} : @_ ;

    $self->clear ; 

    if (defined $self->{refer_to}) {
	$self->{ref_object}->get_choice_from_refered_to ;
    }

    while (my ($key, $value) = each %check) {
	$self->store($key,$value) ;
    }
}

1;

__END__

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::Node>, 
L<Config::Model::AnyId>,
L<Config::Model::ListId>,
L<Config::Model::HashId>,
L<Config::Model::Value>

=cut
