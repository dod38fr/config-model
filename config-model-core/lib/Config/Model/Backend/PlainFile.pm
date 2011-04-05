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

package Config::Model::Backend::PlainFile ;

use Carp;
use Any::Moose ;
use Config::Model::Exception ;
use UNIVERSAL ;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

extends 'Config::Model::Backend::Any';

my $logger = get_logger("Backend::PlainFile") ;

sub suffix { return '' ; }

sub annotation { return 0 ;}

sub skip_open { 1;}

sub read {
    my $self = shift ;
    my %args = @_ ;

    # args are:
    # object     => $obj,         # Config::Model::Node object 
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path 
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf' 
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    my $check = $args{check} || 'yes' ;
    my $dir = $args{config_dir} ;
    my $node = $args{object} ;
    $logger->debug("PlainFile read called on node", $node->name);

    # read data from leaf element from the node
    foreach my $elt ($node->get_element_name(type => 'leaf') ) {
        my $file = $args{root}.$dir.$elt ;
        $logger->trace("Looking for plainfile $file");
        next unless -e $file ;
        
        my $fh = new IO::File;
        $fh->open($file) or die "Cannot open $file:$!" ;
        $fh->binmode(":utf8");
        my $v = join('',$fh->getlines) ;
        my $leaf = $args{object}->fetch_element(name => $elt) ;
        chomp $v unless $leaf->value_type eq 'string';
        $leaf->store(value => $v, check => $args{check} ) ;
        $fh->close;
    }

    return 1 ;
}

sub write {
    my $self = shift ;
    my %args = @_ ;

    # args are:
    # object     => $obj,         # Config::Model::Node object 
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path read
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf' 
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    my $check = $args{check} || 'yes' ;
    my $dir = $args{root}.$args{config_dir} ;
    mkpath($dir, { mode => 0755 } ) unless -d $dir ;
    my $node = $args{object} ;
    $logger->debug("PlainFile write called on node ", $node->name);

    # write data from leaf element from the node
    foreach my $elt ($node->get_element_name() ) {
        my $file = $dir.$elt ;
        $logger->trace("PlainFile write opening $file to write");
        
        my $fh = new IO::File;
        $fh->open($file , '>') or die "Cannot open $file:$!" ;
        $fh->binmode(":utf8");
        my $leaf = $args{object}->fetch_element(name => $elt) ;
        my $v = $leaf->fetch(check => $args{check} ) ;
        $v .= "\n" unless $leaf->value_type eq 'string';
        $fh->print($v) ;
        $fh->close;
    }

    return 1;
}

no Any::Moose ;
__PACKAGE__->meta->make_immutable ;

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
content of a configuration tree written in several files. In this case 
each leaf element of the node is written in a plain file.



=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => 'plain_file' ) ;

Inherited from L<Config::Model::Backend::Any>. The constructor will be
called by L<Config::Model::AutoRead>.

=head2 read ( io_handle => ... )

Of all parameters passed to this read call-back, only C<io_handle> is
used. This parameter must be L<IO::File> object already opened for
read. 

It can also be undef. In this case, C<read()> will return 0.

When a file is read,  C<read()> will return 1.

=head2 write ( io_handle => ... )

Of all parameters passed to this write call-back, only C<io_handle> is
used. This parameter must be L<IO::File> object already opened for
write. 

C<write()> will return 1.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::AutoRead>, 
L<Config::Model::Backend::Any>, 

=cut
