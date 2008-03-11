# $Author: ddumont $
# $Date: 2008-02-27 13:40:02 $
# $Revision: 1.12 $

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

package Config::Model::AutoRead ;
use Carp;
use strict;
use warnings ;
use Config::Model::Exception ;
use Data::Dumper ;
use File::Path ;
use UNIVERSAL ;

use base qw/Config::Model::AnyThing/ ;

our $VERSION = sprintf "1.%04d", q$Revision: 1.12 $ =~ /(\d+)/;

=head1 NAME

Config::Model::AutoRead - Load on demand base class for configuration node

=head1 SYNOPSIS

  # top level config file name matches instance name
  $model->create_config_class 
  (
   config_class_name => 'OneAutoReadConfigClass',

   read_config  => [ 'cds', { class => 'ProcessRead' ,  function => 'read_it'} ],
   write_config => 'cds';

   config_dir  => '/etc/my_config_dir',

   element => ...
  ) ;

  # config data will be written in /etc/my_config_dir/foo.cds
  my $instance = $model->instance(instance_name => 'foo') ;


=head1 DESCRIPTION

This class provides a way to specify how to read or write configuration
data within the model (instead of writing dedicated perl code).

In other words, when a node object is created, all the configuration
information are read during creation of the node.

=begin comment

This feature is also useful if you want to read configuration class
declarations at run time. (For instance in a C</etc> directory like
C</etc/some_config.d>). In this case, each configuration class must
specify how to read and write configuration information.

Idea: sub-files name could be <instance>%<location>.cds

=end comment

This read/write can be done with:

=over

=item *

Config dump string (cds). I.e. a string that describes the content of
a configuration tree. See L<Config::Model::Dumper>.

=item *

Ini files (written with L<Config::Tiny>. See limitations in 
L</"Limitations depending on storage">.

=item *

Perl data structure (perl). See L<Config::Model::DumpAsData> for
details on the data structure.

=item *

XML. Not yet implemented (ask the author if you're interested)

=item *

Any format when the user provides a dedicated class and function to
read and load the configuration tree.

=back

When read, the object registers itself to the instance. Then the user
can call the C<write_back> method on the instance (See
L<Config::Model::Instance>) to write all configuration informations.

=head2 Built-in read write format

Currently, this class supports the following built-in formats:

=over

=item cds

Config dumpt string. See L<Config::Model::Dumper>.

=item ini

Ini files written by L<Config::Tiny>.

=back

=head1 Limitations depending on storage

Some storage system will limit the structure of the model you can map
to the file.

=head2 Ini files limitation

Structure of the Config::Model must be very simple. Either:

=over

=item *

A single class with hash of leaves elements.

=item * 

2 levels of classes. The top level has nodes elements. All other
classes have only leaf elements.

=back

=head1 Configuration class with auto read or auto write

=head2 read and write specification

A configuration class will be declared with optional C<read> or
C<write> parameters:

  read_config  => [ 'cds', 
                    read => { class => 'Bar' ,  function => 'read_it'}, ]
  write_config => 'cds';

The various C<read> method will be tried in order specified:

=over

=item *

First the cds file name which depend on the parameters used in model
creation and instance creation:
C<< <model:config_dir>/<instance_name>.cds >>
The syntax of the C<cds> file is described in  L<Config::Model::Dumper>.

=item * 

A call to C<Bar::read_it> with these parameters:

 (object => config_tree_root, conf_dir => config_file_location )

=back

When a read operation is successful, the remaining read methods will
be skipped.

When necessary (or required by the user), all configuration
informations are written back using B<all> the write method passed.

In the example above, only a C<cds> file is written. But, both custom
format and C<cds> file are tried, this example is also an example of a
graceful migration from a customized format to a C<cds> format.

You can choose also to read and write only customized files :

  read_config  => { class => 'Bar' ,  function => 'read_it'},
  write_config => { class => 'Bar' ,  function => 'write_it'};

Or to read and write only cds files :

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

  config_dir => '/etc/my_config_dir',

Or configuration informations can be read from one directory and
written in another directory:

   read_config_dir  => '/etc/old_config_dir',
   write_config_dir => '/etc/new_config_dir',

=cut

# called at configuration node creation
sub auto_read_init {
    my ($self, $readlist, $r_dir) = @_ ;

    my $instance = $self->instance() ;

    # overide is permitted
    $self->{r_dir} = $instance -> read_directory ||$r_dir ; 

    die "auto_read_init: readlist must be array ref or scalar\n" 
      if ref $readlist  eq 'HASH' ;

    my @list = ref $readlist  eq 'ARRAY' ? @$readlist :  ($readlist) ;
    foreach my $read (@list) {
	last if ($read eq 'xml'  and $self->read_xml()) ;
	last if ($read eq 'ini'  and $self->read_ini()) ;
	last if ($read eq 'perl' and $self->read_perl()) ;
	last if ($read eq 'cds'  and $self->read_cds()) ;
	next unless ref($read) eq 'HASH' ;

	my $c = my $file = $read->{class} ;
	$file =~ s!::!/!g;
	my $f = $read->{function} ;
	require $file.'.pm' unless $c->can($f);
	no strict 'refs';
	last if &{$c.'::'.$f}(conf_dir => $self->{r_dir}, object => $self) ;
    }
}

# called at configuration node creation
sub auto_write_init {
    my ($self, $wrlist, $w_dir) = @_ ;

    my $instance = $self->instance() ;

    # overide is permitted
    $self->{w_dir} = $instance -> write_directory || $w_dir ; 

    # provide a proper write back function
    my @array = ref $wrlist eq 'ARRAY' ? @$wrlist : ($wrlist) ;
    foreach my $write (@array) {
	print "auto_write_init: registering write cb ($write) for ",$self->name,"\n"
	  if $::debug ;
	my $wb ;
	if ($write eq 'xml') {
	    $wb = sub {$self->write_xml(shift) ;} ;
	    $self->{auto_write}{xml} = 1 ;
	}
	elsif ($write eq 'ini') {
	    $wb = sub {$self->write_ini(shift) ;} ;
	    $self->{auto_write}{ini} = 1 ;
	}
	elsif ($write eq 'perl') {
	    $wb = sub {$self->write_perl(shift) ;} ;
	    $self->{auto_write}{perl} = 1 ;
	}
	elsif ($write eq 'cds') {
	    $wb = sub {$self->write_cds(shift) ;} ;
	    $self->{auto_write}{cds} = 1 ;
	}
	elsif (ref($write) eq 'HASH') {
	    my $c = my $file = $write->{class} ;
	    $file =~ s!::!/!g;
	    my $f = $write->{function} ;
	    require $file.'.pm' unless $c->can($f) ;
	    my $safe_self = $self ; # provide a closure
	    $wb = sub {  no strict 'refs';
			 my $wr_dir = shift || $self->{w_dir} ;
			 &{$c.'::'.$f}(conf_dir => $wr_dir, 
				       object => $safe_self) ;
		     };
	    $self->{auto_write}{custom} = 1 ;
	}

	$instance->register_write_back($wb) ;
    }
}

sub is_auto_write_for_type {
    my $self = shift;
    my $type = shift ;
    return $self->{auto_write}{$type} || 0;
}

sub get_cfg_file_name
  {
    my $self = shift ;
    my $r_or_w  = shift ;
    my $override_dir = shift ;

    my $i = $self->instance ;
    my $dir = defined $override_dir ? $override_dir
            : $r_or_w eq 'r'        ? $self->{r_dir}
            : $r_or_w eq 'w'        ? $self->{w_dir}
            :                         croak "get_cfg_file_name: expected ",
                                            "r or w not $r_or_w" ;

    croak "get_cfg_file_name: no read/write directory provided by instance"
      unless defined $dir ;

    mkpath ($dir,0, 0755) if $r_or_w eq 'w' and not -d $dir ;

    # TBD should we use sub-directories ?? 

    # append instance name
    my $name = $dir ."/". $i->name ;

    # append ":foo bar" if not root object
    my $loc = $self->location ; # not good
    $name .= ':' . $loc if $loc ;

    return $name ;
  }

sub read_cds
  {
    my $self = shift;
    my $file_name = $self->get_cfg_file_name('r') . '.cds' ;
    return 0 unless -r $file_name ;
    open(IN,$file_name) || die "Cannot open $file_name:$!";
    local $/ ; # slurp mode
    my $text = <IN> ;
    close IN ;
    $self->load( step => $text) ;
    return 1 ;
  }

sub write_cds
  {
    my $self = shift;
    my $wr_dir = shift ; 

    my $i = $self->instance ;
    my $file_name = $self->get_cfg_file_name('w',$wr_dir) . '.cds' ;
    open (FOUT, ">$file_name") or die "_write_cds: Can't open $file_name: $!";
    print FOUT $self->dump_tree(skip_auto_write => 1 ) ;
    close FOUT ;
    return 1 ;
  }

sub read_perl
  {
    my $self = shift;
    my $file_name = $self->get_cfg_file_name('r') . '.pl' ;
    return 0 unless -r $file_name ;

    my $pdata = do $file_name || die "Cannot open $file_name:$!";
    $self->load_data( $pdata ) ;
    return 1 ;
  }

sub write_perl
  {
    my $self = shift;
    my $wr_dir = shift ; 

    my $i = $self->instance ;
    my $file_name = $self->get_cfg_file_name('w',$wr_dir) . '.pl' ;

    my $p_data = $self->dump_as_data(skip_auto_write => 1 ) ;

    my $dumper = Data::Dumper->new([$p_data]) ;
    $dumper->Terse(1) ;

    open (FOUT, ">$file_name") or die "_write_perl: Can't open $file_name: $!";
    print FOUT $dumper->Dump , ";\n";
    close FOUT ;

    return 1 ;
  }

sub read_ini
  {
    my $self = shift;
    my $file_name = $self->get_cfg_file_name('r') . '.ini' ;
    return 0 unless -r $file_name ;
    require Config::Tiny;
    my $iniconf = Config::Tiny->new();
    my $conf_data = $iniconf -> read($file_name) ;

    # load root properties
    if (defined $conf_data->{_}) {
	my $root_data = delete $conf_data->{_} ;
	$self->load_data($root_data) ;
    }
    $self->load_data($conf_data) ;

    return 1 ;
  }

sub write_ini
  {
    my $self = shift;
    my $wr_dir = shift ;

    my $i = $self->instance ;
    my $file_name = $self->get_cfg_file_name('w',$wr_dir) . '.ini' ;

    require Config::Tiny;
    my $iniconf = Config::Tiny->new() ;

    my $data = $self->dump_as_data(skip_auto_write => 1 ) ;

    foreach my $k (keys %$data) {
	if (ref( $data->{$k} )) {
	    $iniconf->{$k} = $data->{$k} ;
	}
	else {
	    $iniconf->{_}{$k} = $data->{$k} ;
	}
    }

    $iniconf -> write($file_name) ;

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

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Instance>,
L<Config::Model::Node>, L<Config::Model::Dumper>

=cut

