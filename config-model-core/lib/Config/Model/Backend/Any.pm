# $Author: ddumont $
# $Date: 2010-02-03 16:34:07 +0100 (Wed, 03 Feb 2010) $
# $Revision: 1071 $

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

package Config::Model::Backend::Any ;

use Carp;
use strict;
use warnings ;
use Config::Model::Exception ;
use UNIVERSAL ;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

our $VERSION = sprintf "1.%04d", q$Revision: 1071 $ =~ /(\d+)/;

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


=head1 CONSTRUCTOR

=head2 new ( node => $node_obj)

The constructor should be used only by
L<Config::Model::Node>.

