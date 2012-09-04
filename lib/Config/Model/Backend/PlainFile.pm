#    Copyright (c) 2011 Dominique Dumont.
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

package Config::Model::Backend::PlainFile;

use Carp;
use Any::Moose;
use Config::Model::Exception;
use UNIVERSAL;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

extends 'Config::Model::Backend::Any';

my $logger = get_logger("Backend::PlainFile");

sub suffix { return ''; }

sub annotation { return 0; }

sub skip_open { 1; }

sub read {
    my $self = shift;
    my %args = @_;

    # args are:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    my $check = $args{check} || 'yes';
    my $dir   = $args{config_dir};
    my $node  = $args{object};
    $logger->debug( "called on node", $node->name );

    # read data from leaf element from the node
    foreach my $elt ( $node->get_element_name() ) {
        my $file = $args{root} . $dir . $elt;
        $logger->trace("looking for plainfile $file");

        my $obj = $args{object}->fetch_element( name => $elt );
        my $type = $obj->get_type;

        if ( $type eq 'leaf' ) {
            $self->read_leaf ($obj, $elt, $check,$file,\%args);
        }
        elsif ( $type eq 'list' ) {
            $self->read_list ($obj, $elt, $check,$file,\%args);
        }
        elsif ( $type eq 'hash' ) {
            $self->read_hash ($obj, $elt, $check,$file,\%args);
        }
        else {
            $logger->debug("PlainFile read skiped $type $elt");
        }

    }

    return 1;
}

#
# New subroutine "open_for_read" extracted - Thu Jul 21 13:36:52 2011.
#
sub open_for_read {
    my ($self, $file,$elt) = @_ ;

    return unless -e $file;

    my $fh = new IO::File;
    $fh->open($file) or die "Cannot open $file:$!";
    $fh->binmode(":utf8");
    $logger->trace("found file $file for element $elt");

    return ($fh);
}

#
# New subroutine "read_leaf" extracted - Thu Jul 21 12:58:06 2011.
#
sub read_leaf {
    my ($self,$obj,$elt, $check,$file,$args) = @_;

    my $fh = $self->open_for_read ($file,$elt) or return ;

    my $v = join( '', $fh->getlines );
    chomp $v unless $obj->value_type eq 'string';
    $obj->store( value => $v, check => $check );
}

#
# New subroutine "read_list" extracted - Thu Jul 21 12:58:36 2011.
#
sub read_list {
    my ($self,$obj,$elt, $check,$file,$args) = @_;

    my $fh = $self->open_for_read ($file,$elt) or return ;

    my @v = $fh->getlines;
    chomp @v;
    $obj->store_set(@v);
}

#
# New subroutine "read_hash" extracted - Thu Jul 21 12:58:50 2011.
#
sub read_hash {
    my ($self,$obj,$elt, $check,$file,$args) = @_;
    $logger->debug("PlainFile read skipped hash $elt");
}

sub write {
    my $self = shift;
    my %args = @_;

    # args are:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path read
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    my $check = $args{check} || 'yes';
    my $dir = $args{root} . $args{config_dir};
    mkpath( $dir, { mode => 0755 } ) unless -d $dir;
    my $node = $args{object};
    $logger->debug( "PlainFile write called on node ", $node->name );

    # write data from leaf element from the node
    foreach my $elt ( $node->get_element_name() ) {
        my $file = $dir . $elt;

        my $obj = $args{object}->fetch_element( name => $elt );
        my $type = $obj->get_type;
        my @v;

        if ( $type eq 'leaf' ) {
            $v[0] = $obj->fetch( check => $args{check} );
            $v[0] .= "\n" unless $obj->value_type eq 'string';
        }
        elsif ( $type eq 'list' ) {
            @v = map { "$_\n" } $obj->fetch_all_values;
        }
        else {
            $logger->debug("PlainFile write skipped $type $elt");
        }

        if (@v) {
            $logger->trace("PlainFile write opening $file to write");
            my $fh = new IO::File;
            $fh->open( $file, '>' ) or die "Cannot open $file:$!";
            $fh->binmode(":utf8");
            $fh->print(@v);
            $fh->close;
        }
    }

    return 1;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Config::Model::Backend::PlainFile - Read and write config as plain file

=head1 SYNOPSIS

 use Config::Model;
 use Log::Log4perl qw(:easy);
 Log::Log4perl->easy_init($WARN);

 my $model = Config::Model->new;

 my $inst = $model->create_config_class(
    name => "WithPlainFile",
    element => [ 
        [qw/source new/] => { qw/type leaf value_type uniline/ },
    ],
    read_config  => [ 
        { 
            backend => 'plain_file', 
            config_dir => '/tmp',
        },
    ],
 );
 
 my $inst = $model->instance(root_class_name => 'WithPlainFile' );
 my $root = $inst->config_root ;

 $root->load('source=foo new=yes' );

 $inst->write_back ;

Now C</tmp> directory will contain 2 files: C<source> and C<new> 
with C<foo> and C<yes> inside.

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written in several files. 
Each element of the node is written in a plain file.

This module supports currently only leaf and list elements.  
In the case of C<list> element, each line of the file is a value of the list.


=head1 Methods

=head2 read_leaf (obj,elt,check,file,args);

Called by L<read> method to read the file of a leaf element. C<args>
contains the arguments passed to L<read> method.

=head2 read_hash (obj,elt,check,file,args);

Like L<read_leaf> for hash elements.

=head2 read_list (obj,elt,check,file,args);

Like L<read_leaf> for list elements.

=head2 write ( )

C<write()> will write a file for each element of the calling class. Works only for 
leaf and list elements. Other element type are skipped. Always return 1 (unless it died before).

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::AutoRead>, 
L<Config::Model::Backend::Any>, 

=cut
