
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
use Moose ;

use File::Path;
use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger("Backend") ;

has 'name'       => ( is => 'ro', default => 'unknown',) ;
has 'annotation' => ( is => 'ro', isa => 'Bool', default => 0 ) ;
has 'node'       => ( is => 'ro', isa => 'Config::Model::Node', 
		      weak_ref => 1, required => 1 ) ;

sub suffix {
    my $self = shift ;
    $logger->warn("Internal warning: suffix called for backend $self->{name}.This method can be overloaded") ;
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

sub read_global_comments {
    my $self = shift ;
    my $lines = shift ;
    my $cc = shift ; # comment character

    my @global_comments ;

    while (defined ( $_ = shift @$lines ) ) {
        next if /^$cc$cc/ ; # remove comments added by Config::Model
        chomp ;

        my ($data,$comment) = split /\s*$cc\s?/ ;

        push @global_comments, $comment if defined $comment ;

        if (/^\s*$/ or $data) {
            if (@global_comments) {
                $self->node->annotation(@global_comments);
                $logger->debug("Setting global comment with @global_comments") ;
            }
            unshift @$lines,$_ unless /^\s*$/ ; # put back any data and comment
            # stop global comment at first blank or non comment line
            last;
        }
    }
}

no Moose ;
__PACKAGE__->meta->make_immutable ;

1;

__END__

=head1 NAME

Config::Model::Backend::Any - Virtual class for other backends

=head1 SYNOPSIS

 package Config::Model::Backend::Foo ;
 use Moose ;
 use Log::Log4perl qw(get_logger :levels);

 extends 'Config::Model::Backend::Any';

 # optional
 sub suffix { 
   return '.foo';
 }

 # mandatory
 sub read {
    my $self = shift ;
    my %args = @_ ;

    # args are:
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path 
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf' 
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    return 0 unless defined $args{io_handle} ; # or die?

    foreach ($args{io_handle}->getlines) {
        chomp ;
        s/#.*/ ;
        next unless /\S/; # skip blank line

        # $data is 'foo=bar' which is compatible with load 
        $self->node->load(step => $_, check => $args{check} ) ;
    }
    return 1 ;
 }

 # mandatory
 sub write {
    my $self = shift ;
    my %args = @_ ;

    # args are:
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path 
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf' 
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    my $ioh = $args{io_handle} ;

    foreach my $elt ($self->node->get_element_name) {
        my $obj =  $self->node->fetch_element($elt) ;
        my $v   = $self->node->grab_value($elt) ;

        # write value
        $ioh->print(qq!$elt="$v"\n!) if defined $v ;
        $ioh->print("\n")            if defined $v ;
    }

    return 1;
 }

 no Moose ;
 __PACKAGE__->meta->make_immutable ;

=head1 DESCRIPTION

This L<Moose> class is to be inherited by other backend plugin classes

See L<Config::Model::AutoRead/"read callback"> and
L<Config::Model::AutoRead/"write callback"> for more details on the
method that must be provided by any backend classes.

=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => backend_name )

The constructor should be used only by
L<Config::Model::Node>.

=head1 Methods to override

=head2 annotation

Whether the backend supports to read and write annotation. Default is
0. Override if your backend supports annotations

=head1 Methods

=head2 read_global_comments( lines , comment_char)

Read the global comments (i.e. the first block of comments until the first blank or non comment line) and
store them as root node annotation. The first parameter (C<lines>)
 is an array ref containing file lines.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::AutoRead>, 
L<Config::Model::Node>, 
L<Config::Model::Backend::Yaml>, 

=cut
