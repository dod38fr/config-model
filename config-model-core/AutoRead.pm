# $Author: ddumont $
# $Date: 2006-12-08 13:01:55 $
# $Name: not supported by cvs2svn $
# $Revision: 1.6 $

#    Copyright (c) 2005,2006 Dominique Dumont.
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

package Config::Model::AutoRead ;
use Carp;
use strict;
use warnings ;
use Config::Model::Exception ;
use File::Path ;
use UNIVERSAL ;

use base qw/Config::Model::AnyThing/ ;

our $VERSION = sprintf "%d.%03d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/;

=head1 NAME

Config::Model::AutoRead - Load on demand base class for configuration node

=head1 SYNOPSIS

  $model->create_config_class 
  (
   config_class_name => 'OneAutoReadConfigClass',

   read_config  => [ 'cds', { class => 'ProcessRead' ,  function => 'read_it'} ],
   write_config => 'cds';

   config_dir  => '/etc/my_config_dir',

   element => ...
  ) ;

=head1 DESCRIPTION

This class provides a way to read on demand the configuration
informations. 

In other words, when a node object is created, all the configuration
information are read during creation.

This feature is also useful if you want to read configuration class
declarations at run time. (For instance in a C</etc> directory like
C</etc/config_model.d>). In this case, each configuration class must
specify how to read and write configuration information.

This read/write features can be:

=over

=item *

Config dump string (cds). I.e. a string that describes the content of
a configuration tree. See L<Config::Model::Dumper>.

=item *

XML. Not yet implemented (ask the author if you're interested)

=item *

Any format when the user provides a dedicated class and function to
read and load the configuration tree.

=back

When read, the object registers itself to the instance. Then the user
can call the C<write_back> method on the instance (See
L<Config::Model::Instance>) to write all configuration informations.

=head1 Configuration class with auto read or auto write

=head2 read and write specification

A configuration class will be declared with optional C<read> or
C<write> parameters:

  read_config  => [ 'cds', 
                    read => { class => 'Bar' ,  function => 'read_it'}, ]
  write_config => 'cds';

The various C<read> method will be tried in order specified. When a read
operation is successful, the remaining read methods will be skipped.

In the example above, C<AutoRead> will first try to load the "dump
tree string" as defined in L<Config::Model::Dumper>. If successful,
the configuration tree is loaded and the second method is skippped. 

If loading the C<cds> file fails, the following method is tried by
calling C<read_it> function from package C<Bar>.

The second function will be called with these parameters:

 (object => config_tree_root, conf_dir => config_file_location )

When necessary (or required by the user), all configuration
informations are written back using B<all> the write method passed.

In the example above, only a C<cds> file is written. The example above
is an example of a graceful migration from a customized format to a
C<cds> format.

To read and write only customized files :

  read_config  => { class => 'Bar' ,  function => 'read_it'},
  write_config => { class => 'Bar' ,  function => 'write_it'};

To read and write only cds files :

  read_config  => 'cds', 
  write_config => 'cds' ;

=begin comment

To migrate from custom format to xml:

  read_config  => [ 'xml', { class => 'Bar' ,  function => 'read_it'} ],
  write_config => 'xml';

=end comment

To migrate from an old format to a new format:

  read_config  => [ { class => 'OldFormat' ,  function => 'old_read'} ,
                    { class => 'NewFormat' ,  function => 'new_read'} ],
  write_config => [ { class => 'NewFormat' ,  function => 'write'   } ],

=head2 read write directory

You must also specify where to read or write configuration
information. These informations can be read or written in the same
directory :

  conf_dir => '/etc/my_config_dir',

Or configuration informations can be read from one directory and
written in another directory:

   read_config_dir  => '/etc/old_config_dir',
   write_config_dir => '/etc/new_config_dir',

=cut

# called at configuration class creation
sub auto_read_init {
    my ($self, $readlist, $r_dir) = @_ ;

    my $instance = $self->instance() ;

    # overide is permitted
    $self->{r_dir} = $instance -> read_directory ||$r_dir ; 

    foreach my $read (@$readlist) {
	last if ($read eq 'xml' and $self->read_xml()) ;
	last if ($read eq 'cds' and $self->read_cds()) ;
	next unless ref($read) eq 'HASH' ;

	my $c = my $file = $read->{class} ;
	$file =~ s!::!/!g;
	my $f = $read->{function} ;
	require $file.'.pm' unless $c->can($f);
	no strict 'refs';
	last if &{$c.'::'.$f}(conf_dir => $self->{r_dir}, object => $self) ;
    }
}

sub auto_write_init {
    my ($self, $wrlist, $w_dir) = @_ ;

    my $instance = $self->instance() ;

    # overide is permitted
    $self->{w_dir} = $instance -> write_directory || $w_dir ; 

    # provide a proper write back function
    my @array = ref $wrlist eq 'ARRAY' ? @$wrlist : ($wrlist) ;
    foreach my $write (@array) {
	my $wb ;
	if ($write eq 'xml') {
	    $wb = sub {$self->write_xml() ;} ;
	}
	elsif ($write eq 'cds') {
	    $wb = sub {$self->write_cds() ;} ;
	}
	elsif (ref($write) eq 'HASH') {
	    my $c = my $file = $write->{class} ;
	    $file =~ s!::!/!g;
	    my $f = $write->{function} ;
	    require $file.'.pm' unless $c->can($f) ;
	    my $safe_self = $self ; # provide a closure
	    $wb = sub {  no strict 'refs';
			 &{$c.'::'.$f}(conf_dir => $self->{w_dir}, 
				       object => $safe_self) ;
		     };
	}

	$instance->register_write_back($wb) ;
    }
}

sub get_cfg_file_name
  {
    my $self = shift ;
    my $r_or_w  = shift ;
    my $create_dir = shift || 0 ;

    my $i = $self->instance ;
    my $dir = $r_or_w eq 'r' ? $self->{r_dir}
            : $r_or_w eq 'w' ? $self->{w_dir}
            :                  croak "get_cfg_file_name: expected r or w not $r_or_w" ;

    croak "get_cfg_file_name: no read/write directory provided by instance"
      unless defined $dir ;

    $dir .= "/". $i->name ;
    mkpath ($dir,0, 0755) if $create_dir and not -d $dir ;

    my $loc = $self->location ;
    $dir .= '/' . $loc if $loc ;

    return $dir ;
  }

sub read_cds
  {
    my $self = shift;
    my $file_name = $self->get_cfg_file_name('r') . '.cds' ;
    return 0 unless -r $file_name ;
    my $text = slurp($file_name) ;
    walk(object => $self, step => $text) ;
    return 1 ;
  }

sub write_cds
  {
    my $self = shift;

    my $i = $self->instance ;
    my $file_name = $self->get_cfg_file_name('w',1) . '.cds' ;
    open (FOUT, ">$file_name") or die "_write_cds: Can't open $file_name: $!";
    print FOUT $self->dump_tree ;
    close FOUT ;
    return 1 ;
  }

sub read_xml
  {
    my $self = shift;
    die "read_xml: not yet implemented";
  }

sub write_xml
  {
    my $self = shift;
    die "write_xml: not yet implemented";
  }

1;

__END__


=head1 AUTHOR

Dominique Dumont, domi@komarr.grenoble.hp.com

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Instance>,
L<Config::Model::Node>, L<Config::Model::Dumper>

=cut

