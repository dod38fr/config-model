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
use strict;
use warnings ;
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

    # try to get global comments (comments before a blank line)
    my @global_comments;
    my @comments;
    my $global_zone = 1;

    my $section;

    my $delimiter  = $args{comment_delimiter}   || '#';
    my $hash_class = $args{store_class_in_hash} || '';
    my $check      = $args{check}               || 'yes';
    my $obj        = $self->node;

    #FIXME: Is it possible to store the comments with their location
    #in the file?  It would be nice if comments that are after values
    #in input file, would be written in the same way in the output
    #file.  Also, comments at the end of file are being ignored now.
    foreach ( $args{io_handle}->getlines ) {
        next
          if /^$delimiter$delimiter/;   # remove comments added by Config::Model
        chomp;

        my ( $vdata, $comment ) = split /\s*$delimiter\s?/;

        push @global_comments, $comment if defined $comment and $global_zone;
        push @comments, $comment if ( defined $comment and not $global_zone );

        if ( $global_zone and /^\s*$/ and @global_comments ) {
            $logger->debug("Setting global comment with '@global_comments'");
            $self->node->annotation(@global_comments);
            $global_zone = 0;
        }

        # stop global comment at first blank line
        $global_zone = 0 if /^\s*$/;

        if ( defined $vdata and $vdata ) {
            $vdata =~ s/^\s+//g;
            $vdata =~ s/\s+$//g;

            # Update section name
            if ( $vdata =~ /\[(.*)\]/ ) {
                $section = $1;
                my $prefix = $hash_class ? "$hash_class:" : '';
                $obj = $self->node->grab(
                    step  => $prefix . $section,
                    check => $check
                );
                $obj->annotation(@comments) if scalar @comments;
            }
            else {
                my ( $name, $val ) = split( /\s*=\s*/, $vdata );

                my $elt = $obj->fetch_element( name => $name, check => $check );

                if ( $elt->get_type eq 'list' ) {
                    my $idx = $elt->fetch_size ;
                    my $list_val = $elt->fetch_with_id($idx);
                    $list_val -> store( $val, check => $check );
                    $list_val -> annotation(@comments) if @comments ;
                }
                elsif ( $elt->element_type eq 'leaf' ) {
                    $elt->store( value => $val, check => $check );
                    $elt->annotation(@comments) if scalar @comments;
                }
                else {
                    Config::Model::Exception::ModelDeclaration->throw(
                        error =>
                          "element $elt must be list or leaf for INI files",
                        object => $obj
                    );
                }
            }
            @comments = ();
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
    
    $ioh->print($delimiter x 2 ." file written by Config::Model\n");
    my $global_comment = $node->annotation ;
    $ioh->print("$delimiter $global_comment\n\n") if $global_comment ;

    $self->_write(@_) ;
}

sub _write {
    my $self = shift;
    my %args = @_ ;

    my $ioh = $args{io_handle} ;
    my $node = $args{object} ;
    my $delimiter = $args{comment_delimiter} || '#' ;

    # Using Config::Model::ObjTreeScanner would be overkill
    
    # first write list and element, then classes
    foreach my $elt ($node->get_element_name) {
        my $type = $node->element_type($elt) ;
        next if $type eq 'node' or $type eq 'hash';
        
        my $obj =  $node->fetch_element($elt) ;

        my $note = $obj->annotation;
        map { $ioh->print("$delimiter $_\n") } $note if $note;

        if ($node->element_type($elt) eq 'list'){
            foreach my $item ($obj->fetch_all('custom')) {
                my $note = $item->annotation;
                my $v = $item->fetch ;
                $ioh->print("$delimiter $note\n") if $note ;
                $ioh->print("$elt=$v\n") ;
                $ioh->print("\n");
            }
        }
        else {
            my $v_obj = $node->grab($elt) ;
            my $note = $v_obj->annotation;
            $ioh->print("$delimiter $note\n") if $note ;
            my $v = $v_obj->fetch ;
            # write value
            $ioh->print("$elt=$v\n") if defined $v ;
            $ioh->print("\n");
        }
    }

    foreach my $elt ($node->get_element_name) {
        my $type = $node->element_type($elt) ;
        next unless $type eq 'node' or $type eq 'hash';
        my $obj =  $node->fetch_element($elt) ;

        my $note = $obj->annotation;
        
        if ($type eq 'hash') {
            foreach my $key ($obj->get_all_indexes) {
                my $hash_obj = $obj->fetch_with_id($key) ;
                my $note = $hash_obj->annotation;
                $ioh->print("$delimiter $note\n") if $note;
                $ioh->print("[$key]\n");
                $self->_write(%args, object => $hash_obj);
            }
        }
        else {
            my $note = $obj->annotation;
            $ioh->print("$delimiter $note\n") if $note;
            $ioh->print("[$elt]\n");
            $self->_write(%args, object => $obj);
        }
    }   

    return 1;
}

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

=head2 new ( node => $node_obj, name => 'shellvar' ) ;

Inherited from L<Config::Model::Backend::Any>. The constructor will be
called by L<Config::Model::AutoRead>.

The constructor will be passed the optional parameters declared in the 
model:

=over

=item comment_delimiter

Change the character that starts comments in the INI file. Default is 'C<#>'.

=back

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
