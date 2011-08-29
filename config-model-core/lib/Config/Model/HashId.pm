#    Copyright (c) 2005-2010 Dominique Dumont.
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

use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger("Tree::Element::Id::Hash");

use base qw/Config::Model::AnyId/ ;

=head1 NAME

Config::Model::HashId - Handle hash element for configuration model

=head1 SYNOPSIS

See L<Config::Model::AnyId/SYNOPSIS>

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
    $self->{list} = [] ;

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

sub set_properties {
    my $self = shift ;

    $self->SUPER::set_properties(@_) ;

    my $idx_type = $self->{index_type} ;

    # remove unwanted items
    my $data = $self->{data} ;

    my $idx = 1 ;
    my $wrong = sub {
        my $k = shift ;
        if ($idx_type eq 'integer') {
            return 1 if defined $self->{max_index} and $k > $self->{max_index} ;
            return 1 if defined $self->{min_index} and $k < $self->{min_index} ;
        }
        return 1 if defined $self->{max_nb} and $idx++ > $self->{max_nb};
        return 0 ;
    } ;

    # delete entries that no longer fit the constraints imposed by the
    # warp mechanism
    foreach my $k (sort keys %$data) {
        next unless $wrong->($k) ;
        $logger->debug("set_properties: ",$self->name," deleting id $k");
        delete $data->{$k}  ;
    }
}

=head1 Methods

=head2 get_type

Returns C<hash>.

=cut

sub get_type {
    my $self = shift;
    return 'hash' ;
}

=head2 fetch_size

Returns the number of elements of the hash.

=cut

sub fetch_size {
    my $self = shift;
    return scalar keys %{$self->{data}} ;
}

sub _get_all_indexes {
    my $self = shift;
    return $self->{ordered} ? @{$self->{list}}
      :                    sort keys %{$self->{data}} ;
}

# fetch without any check 
sub _fetch_with_id {
    my ($self,$key) = @_ ;
    return $self->{data}{$key};
}

# store without any check
sub _store {
    my ($self, $key, $value) =  @_ ;
    push @{$self->{list}}, $key 
      unless exists $self->{data}{$key};
    return $self->{data}{$key} = $value ;
}

sub _exists {
    my ($self,$key) = @_ ;
    return exists $self->{data}{$key};
}

sub _defined {
    my ($self,$key) = @_ ;
    return defined $self->{data}{$key} ? 1 : 0;
}

#internal
sub auto_create_elements {
    my $self = shift ;

    my $auto_p = $self->{auto_create_keys} ;
    # create empty slots
    map {
        $self->_store($_, undef) unless exists $self->{data}{$_};
    }  (ref $auto_p ? @$auto_p : ($auto_p)) ;
}

# internal
sub create_default {
    my $self = shift ;
    my @temp = keys %{$self->{data}} ;

    return if @temp ;

    # hash is empty so create empty element for default keys
    my $def = $self->get_default_keys ;
    map {$self->_store($_,undef) } @$def ;
    $self->create_default_with_init ;
}    

sub _delete {
    my ($self,$key) = @_ ;

    # remove key in ordered list
    @{$self->{list}} = grep { $_ ne $key } @{ $self->{list}} ;

    return delete $self->{data}{$key};
}

sub remove {
    goto &_delete ;
}

sub _clear {
    my ($self) = @_ ;
    $self->{list} = [];
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
    my @list = $self->_get_all_indexes ;
    $self->{each_list} = \@list ;
    return shift @list ;
}

=head2 nextkey

Returns the next key of the hash. Behaves like C<each> core perl
function.

=cut

# hash only method
sub nextkey {
    my $self = shift ;

    $self->warp 
      if ($self->{warp} and @{$self->{warp_info}{computed_master}});

    my $res =  shift @{$self->{each_list}} ;

    return $res if defined $res ;

    # reset list for next call to next_keys
    $self->{each_list} = [ $self->_get_all_indexes  ] ;

    return ;
}

=head2 swap ( key1 , key2 )

Swap the order of the 2 keys. Ignored for non ordered hash.

=cut

sub swap {
    my $self = shift ;
    my ($key1,$key2) = @_ ;

    foreach my $k (@_) {
        Config::Model::Exception::User
            -> throw (
                      object => $self,
                      message => "swap: unknow key $k"
                     )
              unless exists $self->{data}{$k} ;
    }

    my @copy = @{$self->{list}} ;
    for (my $idx = 0; $idx <= $#copy; $idx ++ ) {
        if ($copy[$idx] eq $key1) {
            $self->{list}[$idx] = $key2 ;
        }
        if ($copy[$idx] eq $key2) {
            $self->{list}[$idx] = $key1 ;
        }
    }
}

=head2 move ( key1 , key2 )

Rename key1 in key2. 

=cut

sub move {
    my $self = shift ;
    my ($from,$to) = @_ ;

    Config::Model::Exception::User
        -> throw (
                  object => $self,
                  message => "move: unknow key $from"
                 )
          unless exists $self->{data}{$from} ;

    my $ok = $self->check_idx($to) ;

    if ($ok) {
        # this may clobber the old content of $self->{data}{$to}
        $self->{data}{$to} = delete $self->{data}{$from} ;
        delete $self->{warning_hash}{$from} ;
        # update index_value attribute in moved objects
        $self->{data}{$to}->index_value($to) ;

        my ($to_idx,$from_idx);
        my $idx = 0 ;
        my $list = $self->{list} ;
        map { $to_idx   = $idx if $list->[$idx] eq $to;
              $from_idx = $idx if $list->[$idx] eq $from;
              $idx ++ ;
          } @$list ;

        if (defined $to_idx) {
            # Since $to is clobbered, $from takes its place in the list
            $list->[$from_idx] = $to ;
            # and the $from entry is removed from the list
            splice @$list,$to_idx,1;
        } else {
            # $to is moved in the place of from in the list
            $list->[$from_idx] = $to ;
        }
    } else {
        Config::Model::Exception::WrongValue 
            -> throw (
                      error => join("\n\t",@{$self->{error}}),
                      object => $self
                     ) ;
    }
}



=head2 move_after ( key_to_move [ , after_this_key ] )

Move the first key after the second one. If the second parameter is
omitted, the first key is placed in first position. Ignored for non
ordered hash.

=cut

sub move_after {
    my $self = shift ;
    my ($key_to_move,$ref_key) = @_ ;

    foreach my $k (@_) {
        Config::Model::Exception::User
            -> throw (
                      object => $self,
                      message => "swap: unknow key $k"
                     )
              unless exists $self->{data}{$k} ;
    }

    # remove the key to move in ordered list
    @{$self->{list}} = grep { $_ ne $key_to_move } @{ $self->{list}} ;

    my $list = $self->{list} ;

    if (defined $ref_key) {
        for (my $idx = 0; $idx <= $#$list; $idx ++ ) {
            if ($list->[$idx] eq $ref_key) {
                splice @$list ,$idx+1,0, $key_to_move ;
                last;
            }
        }
    } else {
        unshift @$list , $key_to_move ;
    }
}

=head2 move_up ( key )

Move the key up in a ordered hash. Attempt to move up the first key of
an ordered hash will be ignored. Ignored for non ordered hash.

=cut

sub move_up {
    my $self = shift ;
    my ($key) = @_ ;

    Config::Model::Exception::User
        -> throw (
                  object => $self,
                  message => "move_up: unknow key $key"
                 )
          unless exists $self->{data}{$key} ;

    my $list = $self->{list} ;
    # we start from 1 as we can't move up idx 0
    for (my $idx = 1; $idx < scalar @$list; $idx ++ ) {
        if ($list->[$idx] eq $key) {
            $list->[$idx]   = $list->[$idx-1];
            $list->[$idx-1] = $key ;
            last ;
        }
    }
}

=head2 move_down ( key )

Move the key down in a ordered hash. Attempt to move up the last key of
an ordered hash will be ignored. Ignored for non ordered hash.

=cut

sub move_down {
    my $self = shift ;
    my ($key) = @_ ;

    Config::Model::Exception::User
        -> throw (
                  object => $self,
                  message => "move_down: unknown key $key"
                 )
          unless exists $self->{data}{$key} ;

    my $list = $self->{list} ;
    # we end at $#$list -1  as we can't move down last idx
    for (my $idx = 0; $idx < scalar @$list - 1 ; $idx ++ ) {
        if ($list->[$idx] eq $key) {
            $list->[$idx]   = $list->[$idx+1];
            $list->[$idx+1] = $key ;
            last ;
        }
    }
}

=head2 load_data ( hash_ref | array_ref )

Load check_list as a hash ref for standard hash. 

Ordered hash should be loaded with an array ref or with a hash
containing a special C<__order> element. E.g. loaded with either:

  [ a => 'foo', b => 'bar' ]

or

  { __order => ['a','b'], b => 'bar', a => 'foo' }

=cut

sub load_data {
    my $self = shift ;
    my $data = shift ;

    if (ref ($data) eq 'HASH') {
        my @load_keys ;
        my $from = ''; ;

        if ($self->{ordered} and defined $data->{__order}) {
            @load_keys = @{ delete $data->{__order} };
            $from = ' with __order' ;
        } elsif ($self->{ordered}) {
            $logger->warn("HashId ".$self->location.": loading ordered "
                          ."hash from hash ref without special key '__order'. Element "
                          ."order is not defined");
            $from = ' without __order' ;
        }

        @load_keys = sort keys %$data unless @load_keys;

        $logger->info("HashId load_data (".$self->location.
                      ") will load idx @load_keys from hash ref".$from);
        foreach my $elt (@load_keys) {
            my $obj = $self->fetch_with_id($elt) ;
            $obj -> load_data($data->{$elt}) ;
        }
    }
    elsif ( $self->{ordered} and ref ($data) eq 'ARRAY') {
        $logger->info("HashId load_data (".$self->location
                      .") will load idx 0..$#$data from array ref") ;
        my $idx = 0 ;
        while ( $idx < @$data ) {
            my $elt = $data->[$idx++];
            my $obj = $self->fetch_with_id($elt) ;
            $obj -> load_data($data->[$idx++]) ;
        }
    }
    elsif (defined $data) {
        # we can skip undefined data
        my $expected = $self->{ordered} ? 'array' : 'hash' ;
        Config::Model::Exception::LoadData
            -> throw (
                      object => $self,
                      message => "load_data called with non $expected ref arg",
                      wrong_data => $data ,
                     ) ;
    }
}

1;

__END__

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::AnyId>,
L<Config::Model::ListId>,
L<Config::Model::Value>

=cut
