# $Author: ddumont $
# $Date: 2007-03-16 12:21:21 $
# $Name: not supported by cvs2svn $
# $Revision: 1.4 $

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

use base qw/Config::Model::ListId/ ;

use vars qw($VERSION) ;
$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;

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
of the configuration tree. This other hash is indicated by the
C<refer_to> paramater. C<refer_to> uses the syntax of the C<step>
parameter of L<grab(...)|Config::AnyThing/"grab(...)">

=back

=cut

=head1 CONSTRUCTOR

CheckList object should not be created directly.

=cut

sub new {
    my $type = shift;
    my %args = @_ ;

    $args{cargo_type} = 'leaf' ;
    $args{cargo_args}{unique_value} = 1;

    $args{cargo_args}{value_type} 
      = defined $args{refer_to} ? 'reference' : 'enum' ;

    # add actual implementation of check_list
    map { $args{cargo_args}{$_} = delete $args{$_}
	    if defined $args{$_} ;
      }
      qw/choice refer_to help/ ;


    my $self = $type->SUPER::new(%args) ;

    $self->cl_init ;

    return $self; 
}

sub cl_init {
    my $self = shift ;
    $self->{value_book} = { } ;
    $self->{index_book} = { } ;
}

=head1 CheckList model declaration

See
L<model declaration section|Config::Model::AnyId/"Hash or list model declaration">
from L<Config::Model::AnyId>.

=cut

=head1 Methods

=head2 get_type

Returns C<list>.

=cut

sub get_type {
    my $self = shift;
    return 'check_list' ;
}

# remember that CheckList is implemented by a list of enum values. The
# only way to guarantee that all Value object have a different content
# is to query CheckList with the is_value_known method.

# internal. Used by Value object to check if other member of the list
# already have this value. 
sub is_value_known {
    my ($self, $index, $queried_value) = @_;

    # retrieve the index of the Value obj that contains the passed
    # value
    my $res = $self->{value_book}{$queried_value} ;

    # return 1 only if the queried value was found in *another* index
    return (1, $res)  if defined $res && $index ne $res ;

    return (0) ;
}

# internal. Used by value object to store the value they hold (with
# the index)
sub store_value {
    my ($self, $index, $value) = @_;

    # clean up old value
    my $old_value = $self->{index_book}{$index} ;
    delete $self->{value_book}{$old_value} if defined $old_value ;

    if (defined $value) {
	# store new data
	$self->{value_book}{$value} = $index ;
	$self->{index_book}{$index} = $value ;
    }
}

=head2 check ( $choice )

Set choice.

=cut

sub check {
    my ($self, $choice) = @_;
    my $idx = $self->{value_book}{$choice} ;

    if (defined	$idx ) {
	$self->fetch_with_id($idx)->store($choice) ;
    }
    else {
	$self->push($choice) ;
    }
}

=head2 uncheck ( $choice )

Unset choice

=cut

sub uncheck {
    my ($self, $choice) = @_;
    my $idx = $self->{value_book}{$choice} ;

    if (defined	$idx ) {
	$self->delete($idx) ;
    }

    # there's nothing to do if the value was not already checked.
}

=head2 get_choice

Returns an array of all items names that can be checked (i.e.
that can have value 0 or 1).

=cut

sub get_choice {
    my $self = shift ;
    # since this type of object is useless without at least one object
    # defined, there's no harm in retrieving (and potentially
    # creating) the value object at index 0.

    $self->fetch_with_id(0)->get_choice ;
}

# no harm if we filter out undefined values when fetching them....
sub fetch_all_values {
    my $self = shift ;
    my @all      = $self->SUPER::fetch_all_values ;
    my @filtered = grep ( defined $_ ,  @all ) ;
    return wantarray ? @filtered : \@filtered ;
}

=head2 get_help (choice_value)

Return the help string on this choice value

=cut

sub get_help {
    my $self = shift ;
    $self->fetch_with_id(0)->get_help(@_) ;
}

=head2 clear

Reset the check list 

=cut

sub clear {
    my $self = shift ;
    $self->SUPER::clear ;
    $self->cl_init ;
}

=head2 get_checked_list ()

Returns a list (or a list ref) of all checked items (i.e. all items
set to 1). 

=cut

sub get_checked_list {
    my $self = shift ;
    $self->fetch_all_values ;
}

=head2 set_checked_list ( item1, item2, ..)

Set all passed items to checked (1). All other available items
in the check list are set to 0.

Example:

  # set cl to A=0 B=1 C=0 D=1
  $cl->set_checked_list('B','D')

=cut

sub set_checked_list {
    my $self = shift ;
    $self->clear ;
    $self->store_set(@_) ;
}

=head2 get_checked_list_as_hash ()

Returns a hash (or a hash ref) of all items. The boolean value is the
value of the hash.

Example:

 { A => 0, B => 1, C => 0 , D => 1}

=cut

sub get_checked_list_as_hash {
    my $self = shift ;
    my %result = map { $_ => 0 } $self->get_choice ;

    map { $result{$_} = 1 } $self->fetch_all_values ;
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
    my $idx = 0 ;
    map { $self->fetch_with_id($idx++)->store($_) if $check{$_} } keys %check ;
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
