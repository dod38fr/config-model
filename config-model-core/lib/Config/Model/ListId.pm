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

package Config::Model::ListId ;
use Config::Model::Exception ;
use Scalar::Util qw(weaken) ;
use Log::Log4perl qw(get_logger :levels);

use warnings ;
use Carp;
use strict;
use base qw/Config::Model::AnyId/ ;

my $logger = get_logger("Tree::Element::Id::List") ;

=head1 NAME

Config::Model::ListId - Handle list element for configuration model

=head1 SYNOPSIS

See L<Config::Model::AnyId/SYNOPSIS>

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

    foreach my $wrong (qw/max_nb min_index default_keys/) {
        Config::Model::Exception::Model->throw 
            (
            object => $self,
            error =>  "Cannot use $wrong with ".$self->get_type." element"
        ) if defined $args{$wrong};
    }

    # Supply the mandatory parameter
    $self->handle_args(%args, index_type => 'integer') ;
    return $self;
}

=head1 List model declaration

See
L<model declaration section|Config::Model::AnyId/"Hash or list model declaration">
from L<Config::Model::AnyId>.

=cut

sub set_properties {
    my $self = shift ;

    $self->SUPER::set_properties(@_) ;

    # remove unwanted items
    my $data = $self->{data} ;

    return unless defined $self->{max_index} ;

    # delete entries that no longer fit the constraints imposed by the
    # warp mechanism
    foreach my $k (0 .. $#{$data}) {
        next unless  $k >  $self->{max_index};
        $logger->debug("set_properties: ",$self->name," deleting index $k") ;
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

Returns the number of elements of the list.

=cut

sub fetch_size {
    my $self =shift ;
    confess "Undef data " unless defined $self->{data} ;
    return scalar @{$self->{data}} ;
}

sub _get_all_indexes {
    my $self =shift ;
    my $data = $self->{data} ;
    return scalar @$data ? (0 .. $#$data ) : () ;
}

# fetch without any check 
sub _fetch_with_id {
    my ($self, $idx) = @_ ;
    return $self->{data}[$idx];
}

=head2 load(string, [ check => 'no' ] )

Store a set of values passed as a comma separated list of values. 
Values can be quoted strings. (i.e C<"a,a",b> will yield
C<('a,a', 'b')> list). 

C<check> can be yes, no or skip

=cut

sub load {
    my ($self, $string, %args) = @_ ;
    my $check = $self->_check_check($args{check}) ; # I write too many checks.
    
    my @set ;
    my $cmd = $string ;
    my $regex = qr/^(
                    (?:
                             "
                        (?: \\" | [^"] )*?
                      "
                    )
                    |
                    [^,]+
                   )
                  /x;

    
    while (length($string)) {
        #print "string: $string\n";
        $string =~ s/$regex// or last;
        my $tmp = $1 ;
        #print "tmp: $tmp\n";
        $tmp =~ s/^"|"$//g if defined $tmp; 
        $tmp =~ s/\\"/"/g  if defined $tmp; 
        push @set,$tmp ;

        last unless length($string) ;
    }
    continue {
        $string =~ s/^,// or last ;
    }

    if (length($string)) {
        Config::Model::Exception::Load
            -> throw ( object => $self, 
                       command => $cmd,
                       message => "unexpected load command '$cmd', left '$cmd'" ) ;
    }

    $self->store_set(@set ) ;
}

=head2 store_set( ... )

Store a set of values (passed as list)

If tinkering with check is required, use the following way : 

 store_set ( \@v , check => 'skip' );

=cut

sub store_set {
    my $self = shift ;
    my @v = @_ ;
    my $r = shift ;
    my %args = (check => 'yes');
    
    if (ref $r eq 'ARRAY') {
        @v = @$r ;
        %args = @_; # note that $r was shifted out of @_
    }

    my $idx = 0 ;
    foreach (@v) { 
        if (defined $_) {
            $self->fetch_with_id( $idx++ )->store(%args, value => $_);
        }
        else {
            $self->{data}[$idx] = undef ; # detruit l'objet pas bon!
        }
    } ;

    # and delete unused items
    my $max = scalar @{$self->{data}} ;
    splice @{$self->{data}}, $idx, $max - $idx ;
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

=head2 move ( from_index, to_index, [ check => 'no' )

Move an element within the list. C<check> can be 'yes' 'no' 'skip'

=cut

sub move {
    my ($self,$from, $to,%args) = @_ ;
    my $check = $self->_check_check($args{check}) ;

    my $moved = $self->fetch_with_id($from) ;
    $self->_delete($from);
    delete $self->{warning_hash}{$from} ;

    my $ok = $self->check($to) ;
    if ($ok or $check eq 'no') {
        $self->_store($to, $moved) ;
        $moved->index_value($to) ;
    }
    else {
        # restore moved item where it came from
        $self->_store($from, $moved) ;
        if ($check ne 'skip') {
            Config::Model::Exception::WrongValue 
                -> throw (
                          error => join("\n\t",@{$self->{error}}),
                          object => $self
                         ) ;
        }
    }
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

=head2 swap ( C<ida> , C<idb> )

Swap 2 elements within the array

=cut

sub swap {
    my $self = shift ;
    my $ida  = shift ;
    my $idb  = shift ;

    my $obja = $self->{data}[$ida] ;
    my $objb = $self->{data}[$idb] ;

    # swap the index values contained in the objects
    my $obja_index = $obja->index_value ;
    $obja->index_value( $objb->index_value ) ;
    $objb->index_value( $obja_index ) ;

    # then swap the objects
    $self->{data}[$ida] = $objb ;
    $self->{data}[$idb] = $obja ;
}

#die "check index number after wap";

=head2 remove ( C<idx> )

Remove an element from the list. Equivalent to C<splice @list,$idx,1>

=cut

sub remove {
    my $self = shift ;
    my $idx  = shift ;
    splice @{$self->{data}}, $idx , 1 ;
}

#internal
sub auto_create_elements {
    my $self = shift ;

    my $auto_nb = $self->{auto_create_ids} ;

    Config::Model::Exception::Model
        ->throw (
                 object => $self,
                 error => "Wrong auto_create argument for list: $auto_nb"
                ) unless $auto_nb =~ /^\d+$/;

    my $auto_p = $auto_nb - 1;

    # create empty slots
    map {
        $self->{data}[$_] = undef unless defined $self->{data}[$_];
    }  (0 .. $auto_p ) ;
}

# internal
sub create_default {
    my $self = shift ;

    return if @{$self->{data}} ;

    # list is empty so create empty element for default keys
    my $def = $self->get_default_keys ;

    map {$self->{data}[$_] = undef } @$def ;

    if (defined $self->{default_with_init}) {
        foreach my $def_key (keys %{$self->{default_with_init}}) {
            $self->fetch_with_id($def_key)->load($def->{$def_key}) ;
        }
    }
}

=head2 load_data ( array_ref | data )

Clear and load list from data contained in the array ref. If a scalar
or a hash ref is passed, the list is cleared and the data is stored in
the first element of the list.

=cut

sub load_data {
    my $self = shift ;
    my $raw_data = shift ;
    my $raw_annot = shift ;

    my ($data,$annot) 
        = map {   ref($_) eq 'ARRAY' ? $_ 
                : defined $_         ? [ $_ ] 
                :                  	undef; } ($raw_data,$raw_annot);

    $self->clear ;

    my $idx = 0;
    $logger->info("ListId load_data (",$self->location,") will load idx ",
        "0..$#$data");
    foreach my $item (@$data ) {
        my $obj = $self->fetch_with_id($idx) ;
        my @args = ($item);
        CORE::push (@args,$annot->[$idx]) if defined $annot ;
        $idx++ ;
        $obj -> load_data(@args) ;
    }

    return unless defined $annot ;
    $idx = 0;
    $logger->info("ListId load_data (",$self->location,") will load annotation idx ",
          "0..$#$annot") ;
    foreach my $item (@$annot ) {
        my $obj = $self->fetch_with_id($idx++) ;
        $obj -> annotation($item) if $item ; # do not store undef
    }

    
    
}

1;

__END__

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::AnyId>,
L<Config::Model::HashId>,
L<Config::Model::Value>

=cut
