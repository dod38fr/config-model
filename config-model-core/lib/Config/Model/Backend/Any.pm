
#    Copyright (c) 2010 Dominique Dumont.
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

package Config::Model::Backend::Any ;

use Carp;
use strict;
use warnings ;
use Config::Model::Exception ;
use UNIVERSAL ;
use File::Path;
use Log::Log4perl qw(get_logger :levels);


my $logger = get_logger("Backend::Any") ;

sub new {
    my $type = shift ;
    bless { name => 'unknown', @_ }, $type ;
}

sub suffix {
    my $self = shift ;
    $logger->error("Internal error: suffix called for backend $self->{name}. But this method should be overloaded") ;
}

sub read {
    my $self = shift ;
    my $err = "Internal error: read not defined in backend $self->{name}." ;
    $logger->error($err) ;
    croak $err;
}

sub write {
    my $self = shift ;
    my $err = "Internal error: write not defined in backend $self->{name}." ;
    $logger->error($err) ;
    croak $err;
}

1;

__END__

=head1 NAME

Config::Model::Backend::Any - Virtual class for other backends

=head1 SYNOPSIS

 package Config::Model::Backend::Foo ;
 use base qw/Config::Model::Backend::Any/;

 sub suffix { 
   # optional
   return '.foo';
 }

 sub read {
   # mandatory
 }

 sub write {
   # mandatory
 }

=head1 DESCRIPTION

This module is to be inherited by other backend plugin classes

See L<Config::Model::AutoRead/"read callback"> and
L<Config::Model::AutoRead/"write callback"> for more details on the
method that must be provided by any backend classes.

=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => backend_name )

The constructor should be used only by
L<Config::Model::Node>.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::AutoRead>, 
L<Config::Model::Node>, 
L<Config::Model::Backend::Yaml>, 

=cut
