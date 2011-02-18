#    Copyright (c) 2010-2011 Dominique Dumont.
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

package Config::Model::Backend::ShellVar ;

use Carp;
use Moose;
use Config::Model::Exception ;
use UNIVERSAL ;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

extends 'Config::Model::Backend::Any';

my $logger = get_logger("Backend::ShellVar") ;

sub suffix { return '.conf' ; }

sub annotation { return 1 ;}

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

    return 0 unless defined $args{io_handle} ; # no file to read
    my $check = $args{check} || 'yes' ;

    my @lines = $args{io_handle}->getlines ;
    # try to get global comments (comments before a blank line)
    $self->read_global_comments(\@lines,'#') ;

    my @assoc = $self->associates_comments_with_data( \@lines, '#' ) ;
    foreach my $item (@assoc) {
        my ($data,$c) = @$item;
        my $load = qq!$data! ;
        $load .= qq!#"$c"! if $c ;
        $logger->debug("Loading:$load\n");
        $self->node->load(step => $load, check => $check) ;
    }

    return 1 ;
}

sub write {
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

    my $ioh = $args{io_handle} ;
    my $node = $args{object} ;

    croak "Undefined file handle to write" unless defined $ioh;

    $self->write_global_comment($ioh,'#') ;

    # Using Config::Model::ObjTreeScanner would be overkill
    foreach my $elt ($node->get_element_name) {
        my $obj =  $node->fetch_element($elt) ;
        my $v = $node->grab_value($elt) ;

        next unless defined $v ;

        $self->write_data_and_comments($ioh,'#',qq!$elt="$v"!, $obj->annotation) ;
    }

    return 1;
}

no Moose ;
__PACKAGE__->meta->make_immutable ;

1;

__END__

=head1 NAME

Config::Model::Backend::ShellVar - Read and write config as a C<SHELLVAR> data structure

=head1 SYNOPSIS

 use Config::Model;
 use Log::Log4perl qw(:easy);
 Log::Log4perl->easy_init($WARN);

 my $model = Config::Model->new;
 $model->create_config_class (
    name    => "MyClass",
    element => [ 
        [qw/foo bar/] => {qw/type leaf value_type string/}
    ],

   read_config  => [
        { 
            backend => 'ShellVar',
            config_dir => '/tmp',
            file  => 'foo.conf',
            auto_create => 1,
        }
    ],
 );

 my $inst = $model->instance(root_class_name => 'MyClass' );
 my $root = $inst->config_root ;

 $root->load('foo=FOO1 bar=BAR1' );

 $inst->write_back ;

File C<foo.conf> now contains:

 ## This file was written by Config::Model
 ## You may modify the content of this file. Configuration 
 ## modifications will be preserved. Modifications in
 ## comments may be mangled.
 ##
 foo="FOO1"

 bar="BAR1"

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with C<SHELLVAR> syntax in
C<Config::Model> configuration tree.

Note that undefined values are skipped for list element. I.e. if a
list element contains C<('a',undef,'b')>, the data structure will
contain C<'a','b'>.


=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => 'shellvar' ) ;

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
