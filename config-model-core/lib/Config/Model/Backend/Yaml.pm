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

package Config::Model::Backend::Yaml ;

use Carp;
use strict;
use warnings ;
use Config::Model::Exception ;
use UNIVERSAL ;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

use base qw/Config::Model::Backend::Any/;
use YAML::Any ;

our $VERSION = sprintf "1.%04d", q$Revision: 1071 $ =~ /(\d+)/;

my $logger = get_logger("Backend::Yaml") ;

sub suffix { return '.yml' ; }

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

    # load yaml file
    my $yaml = join ('',$args{io_handle}->getlines) ;

    # convert to perl data
    my $perl_data = Load $yaml 
      || croak "No data found in YAML file $args{file_path}";

    # load perl data in tree
    $self->{node}->load_data($perl_data) ;
}

1;

__END__

=head1 NAME

Config::Model::Backend::Yaml - Read and write config as a YAML data structure

=head1 SYNOPSIS

  # model declaration
  name => 'FooConfig',

  read_config  => [
                    { backend => 'yaml' , 
                      config_dir => '/etc/foo',
                      file  => 'foo.conf',      # optional
                      auto_create => 1,         # optional
                    }
                  ],

   element => ...
  ) ;


=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with YAML syntax in
C<Config::Model> configuration tree.

Note that undefined values are skipped for list element. I.e. if a
list element contains C<('a',undef,'b')>, the data structure will
contain C<'a','b'>.


=head1 CONSTRUCTOR

=head2 new ( )

No parameter. The constructor should be used only by
L<Config::Model::Node>.

=cut

