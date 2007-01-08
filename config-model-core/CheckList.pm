# $Author: ddumont $
# $Date: 2007-01-08 12:41:54 $
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

package Config::Model::CheckList ;
use Config::Model::Exception ;
use Scalar::Util qw(weaken) ;
use warnings ;
use Carp;
use strict;

use base qw/Config::Model::ListId/ ;

use vars qw($VERSION) ;
$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

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
          },
       check_list_refering_to_another_hash 
       => { type => 'check_list',
            refer_to => '- foobar'
          },

      ]
  ) ;

=head1 DESCRIPTION

This class provides a check list element for a L<Config::Model::Node>.

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
      qw/choice refer_to/ ;


    my $self = $type->SUPER::new(%args) ;

    $self->{value_book} = { } ;
    $self->{index_book} = { } ;

    return $self; }

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
