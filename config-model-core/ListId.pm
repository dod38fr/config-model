# $Author: ddumont $
# $Date: 2006-10-02 11:35:48 $
# $Name: not supported by cvs2svn $
# $Revision: 1.4 $

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

package Config::Model::ListId ;
use Config::Model::Exception ;
use Scalar::Util qw(weaken) ;
use warnings ;
use Carp;
use strict;

use base qw/Config::Model::AnyId/ ;

use vars qw($VERSION) ;
$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;

=head1 NAME

Config::Model::ListId - Handle list element for configuration model

=head1 SYNOPSIS

 $model ->create_config_class 
  (
   ...
   element 
   => [ 
       bounded_list 
       => { type => 'list',
            max => 123, 
            max_nb => 2 ,
            cargo_type => 'leaf',
            element_args => {value_type => 'string'},
          },
      ]
  ) ;

=head1 DESCRIPTION

This class provides list elements for a L<Config::Model::Node>.

=cut

=head1 CONSTRUCTOR

ListId object should not be created directly.

=cut

sub new {
    my $type = shift;
    my %args = @_ ;

    my $self = $type->SUPER::new(\%args) ;

    $self->{data} = [] ;

    Config::Model::Exception::Model->throw 
        (
         object => $self,
         error =>  "Cannot use max_nb with list element"
        ) if defined $args{max_nb};

    Config::Model::Exception::Model->throw 
        (
         object => $self,
         error => "Cannot use min with list element"
        ) if defined $args{min};

    # Supply the mandatory parameter
    $self->handle_args(%args, index_type => 'integer') ;
    return $self;
}

=head1 List model declaration

See
L<model declaration section|Config::Model::AnyId/"Hash or list model declaration">
from L<Config::Model::AnyId>.

=cut

sub set {
    my $self = shift ;

    $self->SUPER::set(@_) ;

    # remove unwanted items
    my $data = $self->{data} ;

    # delete entries that no longer fit the constraints imposed by the
    # warp mechanism
    foreach my $k (0 .. $#{$data}) {
	next unless  $k >  $self->{max};
	print "set: ",$self->name," deleting index $k\n" if $::debug ;
	delete $data->[$k] ;
    }
}

=head1 Methods

=head2 get_type

Returns C<list>.

=cut

sub get_type {
    my $self = shift;
    return 'list' ;
}

=head2 fetch_size

Returns the nb of elements of the list.

=cut

sub fetch_size {
    my $self =shift ;
    return scalar @{$self->{data}} ;
}

sub _get_all_indexes {
    my $self =shift ;
    my $data = $self->{data} ;
    return (0 .. $#$data ) ;
}

# fetch without any check 
sub _fetch_with_id {
    my ($self, $idx) = @_ ;
    return $self->{data}[$idx];
}

sub store_set {
    my $self = shift ;
    my $idx = 0 ;
    map { $self->fetch_with_id( $idx++ )->store( $_ ) ; } @_ ;
}

# store without any check 
sub _store {
    my ($self, $idx, $value) =  @_ ;
    return $self->{data}[$idx] = $value ;
}

sub _defined {
    my ($self,$key) = @_ ;
    return defined $self->{data}[$key];
}

sub _exists {
    my ($self, $idx) = @_ ;
    return exists $self->{data}[$idx];
}

sub _delete {
    my ($self,$idx) = @_ ;
    return delete $self->{data}[$idx];
}

sub _clear {
    my ($self)= @_ ;
    $self->{data} = [] ;
}

=head2 push( value )

push some value at the end of the list.

=cut

# list only methods
sub push {
    my $self = shift ;
    my $idx   = scalar @{$self->{data}};

    map { $self->fetch_with_id( $idx++ )->store( $_ ) ; } @_ ;
}

1;

__END__

=head1 AUTHOR

Dominique Dumont, domi@komarr.grenoble.hp.com

=head1 SEE ALSO

L<Config::Model::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::AnyId>,
L<Config::Model::HashId>,
L<Config::Model::Value>

=cut
