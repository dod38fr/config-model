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

package Config::Model::Backend::ShellVar ;

use Carp;
use strict;
use warnings ;
use Config::Model::Exception ;
use UNIVERSAL ;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

use base qw/Config::Model::Backend::Any/;

my $logger = get_logger("Backend::ShellVar") ;

sub suffix { return '.conf' ; }

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

    # try to get global comments (comments before a blank line)
    my @global_comments ;
    my @comments ;
    my $global_zone = 1 ;

    foreach ($args{io_handle}->getlines) {
	next if /^##/ ; # remove comments added by Config::Model
	chomp ;

	my ($data,$comment) = split /\s*#\s?/ ;

	push @global_comments, $comment if defined $comment and $global_zone;
	push @comments, $comment        if defined $comment and not $global_zone;

	if ($global_zone and /^\s*$/ and @global_comments) {
	    $self->node->annotation(@global_comments);
	    $logger->debug("Setting global comment with @global_comments") ;
	    $global_zone = 0 ;
	}

	# stop global comment at first blank line
	$global_zone = 0 if /^\s*$/ ;

	if (defined $data and $data ) {
	    $global_zone = 0 ;
	    $data .= '#"'.join("\n",@comments).'"' if @comments ;
	    $logger->debug("Loading:$data\n");
	    $self->node->load($data) ;
	    @comments = () ;
	}
    }


    return 1 ;
}

sub write {
    my $self = shift ;
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

    croak "Undefined file handle to write" unless defined $ioh;

    $ioh->print("## This file was written by Config::Model\n");
    $ioh->print("## You may modify the content of this file. Configuration \n");
    $ioh->print("## modifications will be preserved. Modifications in\n");
    $ioh->print("## comments may be mangled.\n##\n");

    # write global comment
    my $global_note = $node->annotation ;
    if ($global_note) {
	map { $ioh->print("# $_\n") } split /\n/,$global_note ;
	$ioh->print("\n") ;
    }

    # Using Config::Model::ObjTreeScanner would be overkill
    foreach my $elt ($node->get_element_name) {
	my $obj =  $node->fetch_element($elt) ;
        my $v = $node->grab_value($elt) ;

        # write some documentation in comments
	my $help = $node->get_help(summary => $elt);
        my $upstream_default = $obj -> fetch('upstream_default') ;
        $help .=" ($upstream_default)" if defined $upstream_default;
        $ioh->print("## $elt: $help\n") if $help;


	# write annotation
	my $note = $obj->annotation ;
	if ($note) {
	    map { $ioh->print("# $_\n") } split /\n/,$note ;
	}

        # write value
        $ioh->print(qq!$elt="$v"\n!) if defined $v ;
        $ioh->print("\n") if defined $v or $help;
    }

    return 1;
}

1;

__END__

=head1 NAME

Config::Model::Backend::Shellvar - Read and write config as a SHELLVAR data structure

=head1 SYNOPSIS

  # model declaration
  name => 'FooConfig',

  read_config  => [
                    { backend => 'shellvar' , 
                      config_dir => '/etc/foo',
                      file  => 'foo.conf',      # optional
                      auto_create => 1,         # optional
                    }
                  ],

   element => ...
  ) ;


=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with SHELLVAR syntax in
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
used. This parameter must be L<IO::File> object alwritey opened for
write. 

C<write()> will return 1.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::AutoRead>, 
L<Config::Model::Backend::Any>, 

=cut
