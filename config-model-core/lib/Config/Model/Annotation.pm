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

package Config::Model::Annotation;

use Moose ;

use File::Path;
#use Log::Log4perl qw(get_logger :levels);

use Config::Model::Exception ;
use Config::Model::Node ;
use Config::Model::ObjTreeScanner;

#use strict ;
use Carp;
#use warnings FATAL => qw(all);

our $VERSION="1.202";

use Carp qw/croak confess cluck/;

#my $logger = get_logger("Annotation") ;

=head1 NAME

Config::Model::Annotation - Read and write configuration annotations

=head1 SYNOPSIS

 my $arw = Config::Model::Annotation->new($instance) ;

 $arw->load;

 $arw->save;

=head1 DESCRIPTION

This module provides an object that read and write annotations (a bit
like comments) to and from a configuration tree.

Depending on the effective id of the process, the annotation will be
saved in:

=over 

=item * 

C<< /var/lib/config-model/annotation/<model_name> >> for root (EUID == 0)

=item *

C<< ~/.config-model/annotation/<model_name> >> for normal user (EUID > 0)

=head1 CONSTRUCTOR

Quite standard. The constructor is passed a L<Config::Model::Instance>
object.


=cut

has 'instance' => ( is => 'ro', isa => 'Config::Model::Instance' );

#sub new {
#    my $proto = shift ;
#    my $class = ref($proto) || $proto ;
#    my $instance = shift ;
#
#    my $self 
#      = {
#	 instance => $instance ,
#	};
#
#    bless $self, $class;
#
#}
#

=head1 METHODS

=head2 save()

Save annotations

=cut

sub get_annotation_hash {
    my $self = shift ;

    my %data ;
    my $scanner = Config::Model::ObjTreeScanner
      ->new(
	    leaf_cb         => \&my_leaf_cb ,
	    hash_element_cb => \&my_hash_element_cb,
	    fallback        => 'all',
	   ) ;
    my $root = $self->{instance}->config_root ;

    $scanner->scan_node(\%data,$root) ;
    return \%data ;
}

# WARNING: not a method
sub my_hash_element_cb {
    my ($scanner, $data_ref,$node,$element_name,@keys) = @_ ;

    # custom code using $data_ref
    my $obj = $node->fetch_element($element_name) ;
    my $note = $obj -> annotation ;
    if ($note) {
	my $key = $obj -> location ;
	$data_ref->{$key} = $note ;
    }

    # resume exploration
    map {$scanner->scan_hash($data_ref,$node,$element_name,$_)} @keys ;
}


# WARNING: not a method
sub my_leaf_cb {
    my ($scanner, $data_ref,$node,$element_name,$index, $leaf_object) = @_ ;
    my $note = $leaf_object -> annotation ;
    if ($note) {
	my $key = $leaf_object -> location ;
	$data_ref->{$key} = $note ;
    }
}

no Moose ;

__PACKAGE__ -> meta->make_immutable;

1;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::Node>, 
L<Config::Model::Loader>,
L<Config::Model::Searcher>,
L<Config::Model::Value>,

=cut

