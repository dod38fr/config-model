# $Author: ddumont $
# $Date: 2006-02-23 13:43:30 $
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

package Config::Model::HashId ;
use Config::Model::Exception ;
use Scalar::Util qw(weaken) ;
use warnings ;
use Carp;
use strict;

use base qw/Config::Model::AnyId/ ;

use vars qw($VERSION) ;
$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

=head1 NAME

Config::Model::HashId - Handle hash element for configuration model

=head1 SYNOPSIS

 $model ->create_config_class 
  (
   ...
   element 
   => [ 
       bounded_hash 
       => { type => 'hash',
            index_type  => 'integer',
            min => 1, 
            max => 123, 
            max_nb => 2 ,
            collected_type => 'leaf',
            element_args => {value_type => 'string'},
          },
      ]
  ) ;

=head1 DESCRIPTION

This class provides hash elements for a L<Config::Model::Node>.

The hash index can either be en enumerated type, a boolean, an integer
or a string.

=cut

=head1 CONSTRUCTOR

HashId object should not be created directly.

=cut

sub new {
    my $type = shift;
    my %args = @_ ;

    my $self = $type->SUPER::new(\%args) ;

    $self->{data} = {} ;

    Config::Model::Exception::Model->throw 
        (
         object => $self,
         error => "Undefined index_type"
        ) unless defined $args{index_type} ;

    $self->handle_args(%args) ;

    return $self;
}

=head1 Hash model declaration

See
L<model declaration section|Config::Model::AnyId/"Hash or list model declaration">
from L<Config::Model::AnyId>.

=cut

sub set {
    my $self = shift ;

    $self->SUPER::set(@_) ;

    my $idx_type = $self->{index_type} ;

    # remove unwanted items
    my $data = $self->{data} ;

    my $idx = 1 ;
    my $wrong = sub {
        my $k = shift ;
        if ($idx_type eq 'integer') {
            return 1 if defined $self->{max} and $k > $self->{max} ;
            return 1 if defined $self->{min} and $k < $self->{min} ;
	}
        return 1 if defined $self->{max_nb} and $idx++ > $self->{max_nb};
        return 0 ;
    } ;

    # delete entries that no longer fit the constraints imposed by the
    # warp mechanism
    foreach my $k (sort keys %$data) {
	next unless $wrong->($k) ;
	print "set: ",$self->name," deleting id $k\n" if $::debug ;
	delete $data->{$k}  ;
    }
}

=head1 Methods

=head2 fetch_size

Returns the nb of elements of the hash.

=cut

sub fetch_size {
    my $self = shift;
    return scalar keys %{$self->{data}} ;
}

sub _get_all_indexes {
    my $self = shift;
    return  keys %{$self->{data}} ;
}

# fetch without any check 
sub _fetch_with_id {
    my ($self,$key) = @_ ;
    return $self->{data}{$key};
}

# store without any check 
sub _store {
    my ($self, $key, $value) =  @_ ;
    return $self->{data}{$key} = $value ;
}

sub _exists {
    my ($self,$key) = @_ ;
    return exists $self->{data}{$key};
}

sub _defined {
    my ($self,$key) = @_ ;
    return defined $self->{data}{$key};
}

# internal
sub create_default {
    my $self = shift ;
    my @temp = keys %{$self->{data}} ;

    return if @temp ;

    # hash is empty so create empty element for default keys
    my $def= $self->{default} ;
    map {$self->{data}{$_} = undef } (ref $def ? @$def : ($def)) ;
}

sub _delete {
    my ($self,$key) = @_ ;
    return delete $self->{data}{$key};
}

sub _clear {
    my ($self) = @_ ;
    $self->{data} = {};
}

=head2 firstkey

Returns the first key of the hash. Behaves like C<each> core perl
function.

=cut

# hash only method
sub firstkey {
    my $self = shift ;

    $self->warp 
      if ($self->{warp} and @{$self->{warp_info}{computed_master}});

    $self->create_default if defined $self->{default};

    # reset "each" iterator (to be sure, map is also an iterator)
    my $temp = keys %{$self->{data}} ;

    return scalar each %{$self->{data}};
}

=head2 firstkey

Returns the next key of the hash. Behaves like C<each> core perl
function.

=cut

# hash only method
sub nextkey {
    my $self = shift ;

    $self->warp 
      if ($self->{warp} and @{$self->{warp_info}{computed_master}});

    return scalar each %{$self->{data}};
}

1;

__END__

=head1 AUTHOR

Dominique Dumont, domi@komarr.grenoble.hp.com

=head1 SEE ALSO

L<Config::Model::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::AnyId>,
L<Config::Model::ListId>,
L<Config::Model::Value>

=cut
