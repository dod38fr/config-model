# This is free software, licensed under:
# 
#   The GNU Lesser General Public License, Version 2.1, February 1999
# 
#    Copyright (c) 2010 Dominique Dumont, Krzysztof Tyszecki.
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
    my $self = shift ;
    my %args = @_ ;

    # args is:
    # object     => $obj,         # Config::Model::Node object 
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path 
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf' 
    # io_handle  => $io           # IO::File object

    return 0 unless defined $args{io_handle} ; # no file to read


    my %data ;
    my %annot ;
    # try to get global comments (comments before a blank line)
    my @global_comments ;
    my @comments;
    my $global_zone = 1 ;

    my $section;

    #Get the 'right' ref
    my $r = \%data;
    my $a = \%annot;
    my $delimiter = $args{comment_delimiter} || '#' ;

    #FIXME: Is it possible to store the comments with their location
    #in the file?  It would be nice if comments that are after values
    #in input file, would be written in the same way in the output
    #file.  Also, comments at the end of file are being ignored now.
    foreach ($args{io_handle}->getlines) {
        next if /^$delimiter$delimiter/ ;		  # remove comments added by Config::Model
        chomp ;

        my ($vdata,$comment) = split /\s*$delimiter\s?/ ;

        push @global_comments, $comment if defined $comment and $global_zone;
        push @comments, $comment        if (defined $comment and not $global_zone);

        if ($global_zone and /^\s*$/ and @global_comments) {
            $annot{__} = "@global_comments" ;
            $logger->debug("Setting global comment (elt '__') with '@global_comments'") ;
            $global_zone = 0 ;
        }

        # stop global comment at first blank line
        $global_zone = 0 if /^\s*$/ ;

        if (defined $vdata and $vdata ) {
            # Update section name
            if($vdata =~ /\[(.*)\]/){
                $section = $1;
                $r = $data {$section} = {};
                $a = $annot{$section} = {};
                $a->{__} = "@comments" if @comments ;
                @comments = ();
                next;
            }

            my ($name,$val) = split(/\s*=\s*/, $vdata);

            if (defined $r->{$name}){
                map {$_->{$name} = [$_->{$name}] if ref($_->{$name}) ne 'ARRAY';} ( $r,$a ) ;
                
                push @{$r->{$name}}, $val;
                push @{$a->{$name}}, join("\n",@comments) if scalar @comments;
                @comments = ();
            }
            else{
                $r->{$name} = $val;
                # no need to store empty comments
                $a->{$name} = join("\n",@comments) if scalar @comments;
                @comments = ();
            }
        }
    }

    # use Data::Dumper; print Dumper(\%annot) ;

    $self->node->load_data(\%data,\%annot);

    return 1 ;
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
    foreach my $elt ($node->get_element_name) {
        my $obj =  $node->fetch_element($elt) ;

        my $note = $obj->annotation;
        
        map { $ioh->print("$delimiter $_\n") } $note if $note;

        if ($node->element_type($elt) eq 'node'){
            $ioh->print("[$elt]\n");
            my %na = %args;
            $na{object} = $obj;
            $self->_write(%na);
        }

        elsif ($node->element_type($elt) eq 'list'){
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

    return 1;
}

1;

__END__

=head1 NAME

Config::Model::Backend::IniFile - Read and write config as a INI file

=head1 SYNOPSIS

  # model declaration
  name => 'FooConfig',

  read_config  => [
                    { backend => 'IniFile',
                      config_dir => '/etc/foo',
                      file  => 'foo.conf',      # optional
                      auto_create => 1,         # optional
                      comment_delimiter => ';', # optional, default is '#'
                    }
                  ],

   element => ...
  ) ;


=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with INI syntax in
C<Config::Model> configuration tree.

This INI file can have arbitrary comment delimeter. See the example 
in the SYNOPSIS that sets a semi-column as comment delimeter. 
By default the comment delimeter is '#' like in Shell or Perl.

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
used. This parameter must be L<IO::File> object alwritey opened for
write. 

C<write()> will return 1.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org); Krzysztof Tyszecki, (krzysztof.tyszecki at gmail dot com)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::AutoRead>, 
L<Config::Model::Backend::Any>, 

=cut
