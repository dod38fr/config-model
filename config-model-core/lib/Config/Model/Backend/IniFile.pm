# This is free software, licensed under:
# 
#   The GNU Lesser General Public License, Version 2.1, February 1999
# 
#    Copyright (c) 2010-2011 Dominique Dumont, Krzysztof Tyszecki.
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

package Config::Model::Backend::IniFile ;

use Carp;
use Any::Moose ;
use Config::Model::Exception ;
use UNIVERSAL ;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

use base qw/Config::Model::Backend::Any/;

my $logger = get_logger("Backend::IniFile") ;

sub suffix { return '.ini' ; }

sub annotation { return 1 ;}

sub read {
    my $self = shift;
    my %args = @_;

    # args is:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    return 0 unless defined $args{io_handle};    # no file to read

    my $section;

    my $delimiter  = $args{comment_delimiter}   || '#';
    my $hash_class = $args{store_class_in_hash} || '';
    my $check      = $args{check}               || 'yes';
    my $obj        = $self->node;

    #FIXME: Is it possible to store the comments with their location
    #in the file?  It would be nice if comments that are after values
    #in input file, would be written in the same way in the output
    #file.  Also, comments at the end of file are being ignored now.

    my @lines = $args{io_handle}->getlines ;
    # try to get global comments (comments before a blank line)
    $self->read_global_comments(\@lines,$delimiter) ;

    my @assoc = $self->associates_comments_with_data( \@lines, $delimiter ) ;
    foreach my $item (@assoc) {
        my ($vdata,$comment) = @$item;
        $logger->debug("ini read: reading '$vdata'");

        # Update section name
        if ( $vdata =~ /\[(.*)\]/ ) {
            $section = $1;
            my $prefix = $hash_class ? "$hash_class:" : '';
            $obj = $self->node->grab(
                step  => $prefix . $section,
                check => $check,
                mode => $check eq 'yes' ? 'strict' : 'loose' ,
            );
            if ($logger->is_debug) {
                my $debug_loc = defined $obj ? 'on node '.$obj->location : '' ;
                $logger->debug("ini read: new section '$section' $debug_loc");
            }
            $obj->annotation($comment) if $comment and defined $obj;
        }
        elsif (defined $obj) {
            my ( $name, $val ) = split( /\s*=\s*/, $vdata );
            $logger->debug("ini read: data $name for node ".$obj->location);

            my $elt = $obj->fetch_element( name => $name, check => $check );

            if ( $elt->get_type eq 'list' ) {
                my $idx = $elt->fetch_size ;
                my $list_val = $elt->fetch_with_id($idx);
                $list_val -> store( $val, check => $check );
                $list_val -> annotation($comment) if $comment ;
            }
            elsif ( $elt->get_type eq 'leaf' ) {
                $elt->store( value => $val, check => $check );
                $elt->annotation($comment) if scalar $comment;
            }
            else {
                Config::Model::Exception::ModelDeclaration->throw(
                    error => "element $elt must be list or leaf for INI files",
                    object => $obj
                );
            }
        }
        else {
            $logger->warn("ini read: skipping $vdata");
        }
    }

    return 1;
}


sub write {
    my $self = shift;
    my %args = @_ ;

    # args is:
    # object     => $obj,         # Config::Model::Node object 
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path 
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf' 
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    my $ioh = $args{io_handle} ;
    my $node = $args{object} ;
    my $delimiter = $args{comment_delimiter} || '#' ;

    croak "Undefined file handle to write" unless defined $ioh;
    
    $self->write_global_comment($ioh,$delimiter) ;

    $self->_write(@_) ;
}

sub _write {
    my $self = shift;
    my %args = @_ ;

    my $node = $args{object} ;
    my $delimiter = $args{comment_delimiter} || '#' ;
    my $ioh = $args{io_handle} ;

    # Using Config::Model::ObjTreeScanner would be overkill
    
    # first write list and element, then classes
    foreach my $elt ($node->get_element_name) {
        my $type = $node->element_type($elt) ;
        next if $type =~ /node/ or $type eq 'hash';
        
        my $obj =  $node->fetch_element($elt) ;

        my $obj_note = $obj->annotation;

        if ($node->element_type($elt) eq 'list'){
            foreach my $item ($obj->fetch_all('custom')) {
                my $note = $item->annotation ;
                my $v = $item->fetch ;
                next unless defined $v ;
                $logger->debug("ini write: list elt $elt from ",$obj->location);
                $self->write_data_and_comments($ioh,$delimiter,"$elt=$v",$obj_note.$note) ;
            }
        }
        elsif ($node->element_type($elt) eq 'leaf') {
            my $v = $obj->fetch ;
            $logger->debug("ini write: leaf elt $elt from ",$obj->location);
            $self->write_data_and_comments($ioh,$delimiter,"$elt=$v", $obj_note) 
                if defined $v;
        }
        else {
            $logger->error("ini write: unexpected type $type for leaf elt $elt from ",$obj->location);
        }
    }

    foreach my $elt ($node->get_element_name) {
        my $type = $node->element_type($elt) ;
        next unless $type =~ /node/ or $type eq 'hash';
        my $obj =  $node->fetch_element($elt) ;

        my $obj_note = $obj->annotation ;
        
        if ($type eq 'hash') {
            foreach my $key ($obj->get_all_indexes) {
                my $hash_obj = $obj->fetch_with_id($key) ;
                my $note = $hash_obj->annotation;
                $logger->debug("ini write: hash elt $elt key $key from ",$obj->location);
                $self->write_data_and_comments($ioh,$delimiter,"[$key]",$obj_note.$note) ;
                $self->_write(%args, object => $hash_obj);
                $ioh->print("\n");
            }
        }
        else {
            $logger->debug("ini write: class $elt from ",$obj->location);
            $self->write_data_and_comments($ioh,$delimiter,"[$elt]",$obj_note) ;
            $self->_write(%args, object => $obj);
            $ioh->print("\n");
        }
    }   

    return 1;
}

no Any::Moose ;
__PACKAGE__->meta->make_immutable ;


1;

__END__

=head1 NAME

Config::Model::Backend::IniFile - Read and write config as a INI file

=head1 SYNOPSIS

 use Config::Model;
 use Log::Log4perl qw(:easy);
 Log::Log4perl->easy_init($WARN);

 my $model = Config::Model->new;
 $model->create_config_class (
    name    => "IniClass",
    element => [ 
        [qw/foo bar/] => {
            type => 'list',
            cargo => {qw/type leaf value_type string/}
        } 
    ]
 );

 # model for free INI class name and constrained class parameters
 $model->create_config_class(
    name => "MyClass",

    element => [
        'ini_class' => {
            type   => 'hash',
	    index_type => 'string',
	    cargo => { 
		type => 'node',
		config_class_name => 'IniClass' 
		},
	    },
    ],

   read_config  => [
        { 
            backend => 'IniFile',
            config_dir => '/tmp',
            file  => 'foo.conf',
            store_class_in_hash => 'ini_class',
            auto_create => 1,
        }
    ],
 );

 my $inst = $model->instance(root_class_name => 'MyClass' );
 my $root = $inst->config_root ;

 $root->load('ini_class:ONE foo=FOO1 bar=BAR1 - 
              ini_class:TWO foo=FOO2' );

 $inst->write_back ;

Now C</tmp/foo.conf> will contain:

 ## file written by Config::Model
 [ONE]
 foo=FOO1

 bar=BAR1

 [TWO]
 foo=FOO2

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with INI syntax in
C<Config::Model> configuration tree.

This INI file can have arbitrary comment delimiter. See the example 
in the SYNOPSIS that sets a semi-column as comment delimiter. 
By default the comment delimiter is '#' like in Shell or Perl.

Note that undefined values are skipped for list element. I.e. if a
list element contains C<('a',undef,'b')>, the data structure will
contain C<'a','b'>.

=head1 Comments

This backend tries to read and write comments from configuration file. The
comments are stored as annotation within the configuration tree. Bear in mind
that comments extraction is based on best estimation as to which parameter the 
comment may apply. Wrong estimations are possible.

=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => 'inifile' ) ;

Inherited from L<Config::Model::Backend::Any>. The constructor will be
called by L<Config::Model::AutoRead>.

=head1 Parameters

Optional parameters declared in the model:

=over

=item comment_delimiter

Change the character that starts comments in the INI file. Default is 'C<#>'.

=item store_class_in_hash

See L</"Arbitrary class name">

=back

=head1 Mapping between INI structure and model

INI file typically have the same structure with 2 different conventions. 
The class names can be imposed by the application or may be chosen by user.

=head2 Imposed class name

In this case, the class names must match what is expected by the application. 
The elements of each class can be different. For instance:

  foo = foo_v
  [ A ]
  bar = bar_v
  [ B ]
  baz = baz_v

In this case, class C<A> and class C<B> will not use the same configuration class.

The model will have this structure:
   
 Root class 
 |- leaf element foo
 |- node element A of class_A
 |  \- leaf element bar
 \- node element B of class_B
    \-  leaf element baz
    
=head2 Arbitrary class name

In this case, the class names can be chosen by the end user. Each class will have the same 
elements. For instance:

  foo = foo_v
  [ A ]
  bar = bar_v1
  [ B ]
  bar = bar_v2

In this case, class C<A> and class C<B> will not use the same configuration class.
The model will have this structure:
   
 Root class 
 |- leaf foo
 \- hash element my_class_holder
    |- key A (value is node of class_A)
    |  \- element-bar
    \- key B (value is node of class_A)
       \- element-bar

In this case, the C<my_class_holder> name is specified in C<read_config> with C<store_class_in_hash> 
parameter:

    read_config  => [
        { 
            backend => 'IniFile',
            config_dir => '/tmp',
            file  => 'foo.ini',
            store_class_in_hash => 'my_class_holder',
        }
    ],

=head1 Methods

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

Dominique Dumont, (ddumont at cpan dot org); 
Krzysztof Tyszecki, (krzysztof.tyszecki at gmail dot com)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::AutoRead>, 
L<Config::Model::Backend::Any>, 

=cut
