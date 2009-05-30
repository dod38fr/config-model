# $Author$
# $Date$
# $Revision$

#    Copyright (c) 2005-2009 Dominique Dumont.
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
use warnings FATAL => qw/all/;
use Config::Model::Exception ;
use Data::Dumper ;
use File::Path ;
use UNIVERSAL ;
use Storable qw/dclone/ ;
use Log::Log4perl qw(get_logger :levels);

my $has_augeas = 1;
eval { require Config::Augeas ;} ;
$has_augeas = 0 if $@ ;

use base qw/Config::Model::AnyThing/ ;

our $VERSION = sprintf "1.%04d", q$Revision$ =~ /(\d+)/;

my %suffix_table = qw/cds_file .cds perl_file .pl ini_file .ini xml_file .xml/ ;

sub get_cfg_file_path {
    my $self = shift ; 
    my %args = @_;

    my $w = $args{write} || 0 ;
    Config::Model::Exception::Model -> throw
	(
	 error=> "auto_". ($w ? 'write' : 'read') 
                 ." error: empty 'config_dir' parameter",
	 object => $self
	) unless $args{config_dir};

    my $dir = $args{root}.$args{config_dir} ;
    if (not -d $dir and $w and $args{auto_create}) {
	get_logger('Data::Write')
	  ->info("get_cfg_file_path: auto_write create directory $dir" );
	mkpath ($dir,0, 0755);
    }

    unless (-d $dir) { 
	get_logger($w ? 'Data::Write' : 'Data::Read')
	  ->info("get_cfg_file_path: auto_". ($w ? 'write' : 'read') 
		 ." $args{backend} no directory $dir" );
	return;
    }

    return $dir.$args{file} if $args{file};

    return if not defined $suffix_table{$args{backend}} ;

    my $i = $self->instance ;
    my $name = $dir. $i->name ;

    # append ":foo bar" if not root object
    my $loc = $self->location ; # not good
    if ($loc) {
	if (($w and not -d $name and $args{auto_create})) {
	  get_logger('Data::Write')
	    ->info("get_cfg_file_path: auto_write create subdirectory ",
		   "$name (location $loc)" );
	  mkpath ($name,0, 0755);
	}
	$name .= '/'.$loc ;
    }

    croak "get_cfg_file_path: undefined backend" 
      unless defined $args{backend} ;
    return $name. ( $suffix_table{$args{backend}} );
}

# called at configuration node creation
sub auto_read_init {
    my ($self, $readlist_orig, $r_dir) = @_ ;
    # r_dir is obsolete
    if (defined $r_dir) {
	warn $self->config_class_name," : read_config_dir is obsolete\n";
    }

    my $readlist = dclone $readlist_orig ;

    my $instance = $self->instance() ;

    # root override is passed by the instance
    my $root_dir = $instance -> read_root_dir || '';
    $root_dir .= '/' if ($root_dir and $root_dir !~ m(/$)) ; 

    croak "auto_read_init: readlist must be array or hash ref\n" 
      unless ref $readlist ;

    my @list = ref $readlist  eq 'ARRAY' ? @$readlist :  ($readlist) ;
    my $pref_backend = $instance->backend || '' ;
    my $read_done = 0;
    my $auto_create = 0;

    foreach my $read (@list) {
	warn $self->config_class_name,
	  " deprecated 'syntax' parameter in auto_read\n" if defined $read->{syntax} ;
	my $backend = delete $read->{backend} || delete $read->{syntax} || 'custom';
	if ($backend =~ /^(perl|ini|cds)$/) {
	    warn $self->config_class_name,
	      " deprecated auto_read backend $backend. Should be '$ {backend}_file'\n";
	    $backend .= "_file" ;
	}

	next if ($pref_backend and $backend ne $pref_backend) ;

	my $read_dir = delete $read->{config_dir} || $r_dir || ''; # $r_dir obsolete
	$read_dir .= '/' if $read_dir and $read_dir !~ m(/$) ; 

	if (defined $read->{allow_empty}) {
	  warn "backend $backend: allow_empty is deprecated. Use auto_create";
	  $auto_create ||= delete $read->{allow_empty} ;
	}

	$auto_create ||= delete $read->{auto_create} if defined $read->{auto_create};

	my $file_path = $self->get_cfg_file_path(%$read,
						 root => $root_dir,
						 config_dir => $read_dir,
						 backend => $backend,
						) ;

	next if $backend =~ /_file$/ 
	        and (not defined $file_path or not -r $file_path) ;

	my $fh = new IO::File;
	$fh->open($file_path) if (defined $file_path and -e $file_path) ;

	my @read_args = (%$read, root => $root_dir, file_path => $file_path,
			 config_dir => $read_dir, io_handle => $fh);

	if ($backend eq 'custom') {
	    my $c = my $file = delete $read->{class} ;
	    $file =~ s!::!/!g;
	    my $f = delete $read->{function} || 'read' ;
	    require $file.'.pm' unless $c->can($f);
	    no strict 'refs';

	    get_logger("Data::Read")
	      ->info("Read with custom backend $ {c}::$f in dir $read_dir");

	    my $res = &{$c.'::'.$f}(@read_args, 
				    conf_dir => $read_dir, # legacy FIXME
				    object => $self) ;
	    if ($res) { 
		$read_done = 1 ;
		last;
	    }
	}
	elsif ($backend eq 'xml_file') {
	    if ($self->read_xml(@read_args)) {
		$read_done = 1 ;
		last;
	    }
	}
	elsif ($backend eq 'perl_file') {
	    if ($self->read_perl(@read_args)) {
		$read_done = 1 ;
		last;
	    }
	}
	elsif ($backend eq 'ini_file') {
	    if ($self->read_ini(@read_args)) {
		$read_done = 1 ;
		last;
	    }
	}
	elsif ($backend eq 'cds_file') {
	    if ($self->read_cds_file(@read_args)) {
		$read_done = 1 ;
		last;
	    }
	}
	else {
	    # try to load a specific Backend class
	    my $c = my $file = "Config::Model::Backend::".ucfirst($backend) ;
	    $file =~ s!::!/!g;
	    my $f = delete $read->{function} || 'read' ;
	    eval {require $file.'.pm' unless $c->can($f); } ;
	    if ($@) {
		warn "auto_read: unknown backend '$backend'".
		     ", cannot load Perl class $c: $@\n";
		next ;
	    }
	    no strict 'refs';
	    my $backend_obj = $self->{backend}{$backend} = $c->new(node => $self) ;
	    get_logger("Data::Read")->info( "Read with $backend $ {c}::$f");

	    if ($backend_obj->$f(@read_args)) {
		$read_done = 1 ;
		last;
	    }
	}
    }

    if (not $read_done) {
	my $msg = "could not read config file with ";
	$msg .= $pref_backend ? "'$pref_backend'" : 'any' ;
	$msg .= " backend";

	Config::Model::Exception::Model -> throw
	    (
	     error => "auto_read error: $msg" ,
	     object => $self,
	    ) unless $auto_create ;

	get_logger("Data::Read")->warn("Warning: $msg");
    }

}

# called at configuration node creation, NOT when writing
sub auto_write_init {
    my ($self, $wrlist_orig, $w_dir) = @_ ;

    # w_dir is obsolete
    if (defined $w_dir) {
	warn $self->config_class_name," : write_config_dir is obsolete\n";
    }

    my $wrlist = dclone $wrlist_orig ;

    my $instance = $self->instance() ;

    # root override is passed by the instance
    my $root_dir = $instance -> write_root_dir || '';
    my $registered_backend = 0;

    my @array = ref $wrlist eq 'ARRAY' ? @$wrlist : ($wrlist) ;

    # ensure that one auto_create specified applies to all wr backends
    my $auto_create = 0;
    foreach my $write (@array) {
	$auto_create ||= delete $write->{auto_create} 
	  if defined $write->{auto_create};
    }

    # provide a proper write back function
    foreach my $write (@array) {
	warn $self->config_class_name,
	  " deprecated 'syntax' parameter in auto_write\n" if defined $write->{syntax} ;
	my $backend = delete $write->{backend} || delete $write->{syntax} || 'custom';
	if ($backend =~ /^(perl|ini|cds)$/) {
	    warn $self->config_class_name,
	      " deprecated auto_read backend $backend. Should be '$ {backend}_file'\n";
	    $backend .= "_file" ;
	}

	my $write_dir = delete $write->{config_dir} || $w_dir || ''; # w_dir obsolete
	$write_dir .= '/' if $write_dir and $write_dir !~ m(/$) ; 

	my $fh ;
	$fh = new IO::File ; # opened in write callback

	get_logger("Data::Write")
	  ->debug("init: registering write cb ($backend) for ",$self->name);

	my @wr_args = (%$write,                  # model data
		       auto_create => $auto_create,
		       backend     => $backend,
		       config_dir  => $write_dir, # override from instance
		       io_handle   => $fh,
		       write       => 1,          # for get_cfg_file_path
		       root        => $root_dir,  # override from instance
		      );

	my $wb ;
	if ($backend eq 'custom') {
	    my $c = my $file = $write->{class} ;
	    $file =~ s!::!/!g;
	    my $f = $write->{function} || 'write' ;
	    require $file.'.pm' unless $c->can($f) ;
	    my $safe_self = $self ; # provide a closure
	    $wb = sub 
	      {  no strict 'refs';
		 my $file_path ;
		 $file_path = $self-> open_file_to_write($backend,$fh,@wr_args,@_) 
		   unless ($c->can('skip_open') and $c->skip_open) ;
		 # override needed for "save as" button
		 &{$c.'::'.$f}(@wr_args,
			       file_path => $file_path,
			       conf_dir => $write_dir, # legacy FIXME
			       object => $safe_self, 
			       @_                      # override from user
			      ) ;
		 $fh->close if defined $file_path;
	     };
	    $self->{auto_write}{custom} = 1 ;
	}
	elsif ($backend eq 'xml') {
	    $wb = sub {
		my $file_path 
		   = $self-> open_file_to_write($backend,$fh,@wr_args,@_) ;
		$self->write_xml(@wr_args, file_path => $file_path, @_) ;
		$fh->close if defined $file_path;
	    } ;
	    $self->{auto_write}{xml} = 1 ;
	}
	elsif ($backend eq 'ini_file') {
	    $wb = sub {
		my $file_path 
		   = $self-> open_file_to_write($backend,$fh,@wr_args,@_) ;
		$self->write_ini(@wr_args, file_path => $file_path, @_) ;
		$fh->close if defined $file_path;
	    } ;
	    $self->{auto_write}{ini_file} = 1 ;
	}
	elsif ($backend eq 'perl_file') {
	    $wb = sub {
		my $file_path 
		   = $self-> open_file_to_write($backend,$fh,@wr_args,@_) ;
		$self->write_perl(@wr_args, file_path => $file_path,  @_) ;
		$fh->close if defined $file_path;
	    } ;
	    $self->{auto_write}{perl_file} = 1 ;
	}
	elsif ($backend eq 'cds_file') {
	    $wb = sub {
		my $file_path 
		   = $self-> open_file_to_write($backend,$fh,@wr_args,@_) ;
		$self->write_cds_file(@wr_args, file_path => $file_path, @_) ;
		$fh->close if defined $file_path;
	    } ;
	    $self->{auto_write}{cds_file} = 1 ;
	}
	else {
	    # try to load a specific Backend class
	    my $c = my $file = "Config::Model::Backend::".ucfirst($backend) ;
	    $file =~ s!::!/!g;
	    my $f = $write->{function} || 'write' ;
	    eval {require $file.'.pm' unless $c->can($f); } ;
	    if ($@) {
		warn "auto_write: unknown backend '$backend'".
		     ", cannot load Perl class $c: $@" unless $registered_backend;
		next ;
	    }

	    my $safe_self = $self ; # provide a closure
	    $wb = sub 
	      {  no strict 'refs';
		 my $backend_obj =  $self->{backend}{$backend}
		                 || $c->new(node => $self) ;
		 my $file_path ;
		 $file_path = $self-> open_file_to_write($backend,$fh,@wr_args,@_) 
		   unless ($c->can('skip_open') and $c->skip_open) ;
		 # override needed for "save as" button
		 $backend_obj->$f(@wr_args, 
				  file_path => $file_path,
				  object => $safe_self, 
				  @_                      # override from user
				 ) ;
		 $fh->close if defined $file_path;
	     };
	}

	$instance->register_write_back($backend => $wb) ;
	$registered_backend ++ ;
    }
}

sub open_file_to_write {
  my ($self, $backend, $fh, @args) = @_ ;

  my $file_path = $self->get_cfg_file_path(@args);
  if (defined $file_path) {
    get_logger("Data::Write")
      ->debug("$backend backend opened file $file_path to write");
    $fh ->open("> $file_path") || die "Cannot open $file_path:$!";
  }
  return $file_path ;
}

sub is_auto_write_for_type {
    my $self = shift;
    my $type = shift ;
    return $self->{auto_write}{$type} || 0;
}

sub read_cds_file {
    my $self = shift;
    my %args = @_ ;

    my $file_path = $args{file_path} ;
    get_logger("Data::Read")->info( "Read cds data from $file_path");

    $self->load( step => [ $args{io_handle}->getlines ] ) ;
    return 1 ;
}

sub write_cds_file {
    my $self = shift;
    my %args = @_ ;
    my $file_path = $args{file_path} ;
    get_logger("Data::Write")->info("Write cds data to $file_path");

    $args{io_handle}->print( $self->dump_tree(skip_auto_write => 'cds_file' )) ;
    return 1 ;
}

sub read_perl {
    my $self = shift;
    my %args = @_ ;

    my $file_path = $args{file_path} ;
    get_logger("Data::Read")->info("Read Perl data from $file_path");

    my $pdata = do $file_path || die "Cannot open $file_path:$!";
    $self->load_data( $pdata ) ;
    return 1 ;
}

sub write_perl {
    my $self = shift;
    my %args = @_ ;
    my $file_path = $args{file_path} ;
    get_logger("Data::Write")->info("Write perl data to $file_path");

    my $p_data = $self->dump_as_data(skip_auto_write => 'perl_file' ) ;
    my $dumper = Data::Dumper->new([$p_data]) ;
    $dumper->Terse(1) ;

    $args{io_handle}->print( $dumper->Dump , ";\n");
    return 1 ;
}

sub read_ini {
    my $self = shift;
    my %args = @_ ;
    my $file_path = $args{file_path} ;

    get_logger("Data::Read")->info("Read Ini data from $file_path");
    require Config::Tiny;
    my $iniconf = Config::Tiny->new();
    my $conf_data = $iniconf -> read($file_path) ;

    # load root properties
    if (defined $conf_data->{_}) {
	my $root_data = delete $conf_data->{_} ;
	$self->load_data($root_data) ;
    }
    $self->load_data($conf_data) ;

    return 1 ;
}

sub write_ini {
    my $self = shift;
    my %args = @_ ;

    my $file_path = $args{file_path} ;
    get_logger("Data::Write")->info("Write Ini data to $file_path");

    require Config::Tiny;
    my $iniconf = Config::Tiny->new() ;

    my $data = $self->dump_as_data(skip_auto_write => 'ini_file' ) ;

    foreach my $k (keys %$data) {
	if (ref( $data->{$k} )) {
	    $iniconf->{$k} = $data->{$k} ;
	}
	else {
	    $iniconf->{_}{$k} = $data->{$k} ;
	}
    }

    # check that iniconf structure is not too complex
    foreach my $class_name (keys %$iniconf) {
	my $class = $iniconf->{$class_name} ;
	foreach my $k (keys %$class) {
	    next unless ref $class->{$k} ;
	    Config::Model::Exception::Model -> throw
		    (
		     error=> "write_ini error: class '$class_name' key '$k' data "
		           . "is not a scalar but '$class->{$k}'. You should setup "
		           . "write_config parameter in '$class_name' model "
		           . "to write '$k' data in its own INI file",
		     object => $self
		    ) ;
	}
    }

    $iniconf -> write($file_path) ;

    return 1 ;
}

sub read_xml {
    my $self = shift;
    die "read_xml: not yet implemented";
}

sub write_xml {
    my $self = shift;
    die "write_xml: not yet implemented";
}

1;

__END__

=head1 NAME

Config::Model::AutoRead - Load configuration node on demand

=head1 SYNOPSIS

  # top level config file name matches instance name
  $model->create_config_class 
  (
   config_class_name => 'OneAutoReadConfigClass',

   read_config  => [ { backend => 'cds_file' , config_dir => '/etc/cfg_dir'},
                     { backend => 'custom' , 
                       class => 'ProcessRead' ,
                       config_dir => '/etc/foo', # optional
                       file  => 'foo.conf',      # optional
                       auto_create => 1,         # optional
                     }
                   ],
   # if omitted, write_config will be written using read_config specifications
   # write_config can be array of hash ref to write several syntaxes
   write_config => { backend => 'cds_file', config_dir => '/etc/cfg_dir' } ,


   element => ...
  ) ;

  # config data will be written in /etc/my_config_dir/foo.cds
  # according to the instance name
  my $instance = $model->instance(instance_name => 'foo') ;

=head1 DESCRIPTION

This class provides a way to specify how to load or store
configuration data within the model (instead of writing dedicated perl
code).

With these specifications, all the configuration information are read
during creation of a node.

=begin comment

This feature is also useful if you want to read configuration class
declarations at run time. (For instance in a C</etc> directory like
C</etc/some_config.d>). In this case, each configuration class must
specify how to read and write configuration information.

Idea: sub-files name could be <instance>%<location>.cds

=end comment

This load/store can be done with any of these C<backend>:

=over

=item cds_file

Config dump string (cds) in a file. I.e. a string that describes the
content of a configuration tree is loaded from or saved in a text
file. See L<Config::Model::Dumper>.

=item ini_file

Ini files (written with L<Config::Tiny>. See limitations in 
L</"Limitations depending on storage">.

=item perl_file

Perl data structure (perl) in a file. See L<Config::Model::DumpAsData>
for details on the data structure.

=item xml_file

XML. Not yet implemented (ask the author if you're interested)

=item custom

Any format when the user provides a dedicated class and function to
read and load the configuration tree.

=item augeas

Data can be loaded or stored using RedHat's Augeas library. See
L<Config::Model::Backend::Augeas> for details.

=back

After loading the data, the object registers itself to the
instance. Then the user can call the C<write_back> method on the
instance (See L<Config::Model::Instance>) to store all configuration
informations back.

=head2 Built-in backend

C<cds_file>, C<ini_file> and C<perl_file> backend must be specified with
mandatory C<config_dir> parameter. For instance:

   read_config  => { backend    => 'cds_file' , 
                     config_dir => '/etc/cfg_dir'},


=head2 Custom backend

Custom backend must be specified with a class name that will features
the methods used to write and read the configuration files:

  read_config  => [ { backend => 'custom' , 
                      class => 'MyRead',
                      config_dir => '/etc/foo', # optional
                      file => 'foo.conf',       # optional
                    } ]

C<custom> backend parameters are:

=over

=item class

Specify the class that contain the read method

=item config_dir

Specify configuration directory. This parameter is optional as the
directory can be hardcoded in the custom class.

=item file

optional. This parameter may not apply if the configuration is stored
in several files. By default, the instance name is used as
configuration file name.

=item function

Function name that will be called back to read the file. 
See L</"read callback"> for details. (default is C<read>)

=item auto_create

By default, an exception is thrown if no read was
successfull. This behavior can be overridden by specifying 
C<< auto_create => 1 >> in one of the backend specification. For instance:

    read_config  => [ { backend => 'cds_file', config_dir => '/etc/my_cfg/' } , 
                      { backend => 'custom', class => 'Bar' ,
                        auto_create => 1
                      },
                    ],

This feature is necessary to create a configuration from scratch

When set in write backend, missing directory and files will be created
with current umask. Default is false.

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

=head2 read specification

A configuration class will be declared with optional C<read_config>
parameter:

  read_config  => [ { backend => 'cds_file', config_dir => '/etc/my_cfg/' } , 
                    { backend => 'custom', class => 'Bar' },
                  ],

The read backends will be tried in the specified order:

=over

=item *

First the cds file whose name depend on the parameters used in model
creation and instance creation:
C<< <model_config_dir>/<instance_name>.cds >>
The syntax of the C<cds> file is described in  L<Config::Model::Dumper>.

=item * 

A callback to C<Bar::read>. See L</"read callback> for details.

=back

When a read operation is successful, the remaining read methods will
be skipped.


=head2 write specification

A configuration class will be declared with optional C<write_config>
parameters (along with C<read_config> parameter):

  write_config => [ { backend => 'cds_file', config_dir => '/etc/my_cfg/',
                      auto_create => 1, },
                    { backend => 'custom', class => 'NewFormat' } ],

When required by the user, all configuration informations are written
back using B<all> the write specifications. See
L<Config::Model::Instance/write_back ( ... )> for details.

The write class declared witn C<custom> backend must provide a call-back.
See L</"write callback"> for details.

=head2 read write directory

By default, configurations files are read from the directory specified
by C<config_dir> parameter specified in the model. You may override the
C<root> directory for test.

=head2 read callback

Read callback function will be called with these parameters:

  object     => $obj,         # Config::Model::Node object 
  root       => './my_test',  # fake root directory, userd for tests
  config_dir => /etc/foo',    # absolute path 
  file       => 'foo.conf',   # file name
  file_path  => './my_test/etc/foo/foo.conf' 
  io_handle  => $io           # IO::File object

The L<IO::File> object is undef if the file cannot be read.

The callback must return 0 on failure and 1 on succesfull read.

=head2 write callback

Write callback function will be called with these parameters:

  object      => $obj,         # Config::Model::Node object 
  root        => './my_test',  # fake root directory, userd for tests
  config_dir  => /etc/foo',    # absolute path 
  file        => 'foo.conf',   # file name
  file_path  => './my_test/etc/foo/foo.conf' 
  io_handle   => $io           # IO::File object opened in write mode
  auto_create => 1             # create dir as needed

The L<IO::File> object is undef if the file cannot be written to.

The callback must return 0 on failure and 1 on succesfull write.

=head1 CAVEATS

When both C<config_dir> and C<file> are specified, this class will
write-open the configuration file (and thus clobber it) before calling
the C<write> call-back and pass the file handle with C<io_handle>
parameter. C<write> should use this handle to write data in the target
configuration file.

If this behavior causes problem (e.g. with augeas backend), the
solution is to:

=over

=item *

Skip either C<file> or C<config_dir> parameter in the C<write_config>
specification.

=item *

Create a C<skip_open> function in your backend class that returns C<1>

=back

=head1 EXAMPLES

In the example below, only a C<cds> file is written. But, both custom
format and C<cds> file are tried for read. This is also an example of
a graceful migration from a customized format to a C<cds> format.

  read_config  => [ { backend => 'cds_file', config_dir => '/etc/my_cfg/' } , 
                    { backend => 'custom', class => 'Bar' },
                  ],
  write_config => { backend => 'cds_file', config_dir => '/etc/my_cfg/' },


You can choose also to read and write only customized files:

  read_config  => { backend => 'custom', class => 'Bar'},

Or to read and write only cds files :

  read_config  => { backend => 'cds_file'} ,

You can also specify more parameters that must be passed to your
custom class:

  read_config  => { backend => 'custom', class => 'Bar', 
                    config_dir => '/etc/foo'},

=begin comment

To migrate from custom format to xml:

  read_config  => [ { backend => 'xml' },
                    { backend => 'custom', class => 'Bar' } ],
  write_config => { backend => 'xml' },

=end comment

To migrate from an old format to a new format:

  read_config  => [ { backend => 'custom',
                      class => 'OldFormat',
                      function => 'old_read'
                    } ,
                    { backend => 'custom',
                      class => 'NewFormat',
                      function => 'new_read'
                    }
                  ],
  write_config => [ { backend => 'custom',
                      class => 'NewFormat'
                     }
                  ],

If C<write_config> is missing, the data provided by C<read_config>
will be used. For instance:

  read_config  => { backend => 'custom',
                    class => 'Bar',
                    config_dir => '/etc/foo'
                  },

In this case, configuration data will be read by C<Bar::read> in
directory C</etc/foo> and will be written back there by C<Bar::write>.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Instance>,
L<Config::Model::Node>, L<Config::Model::Dumper>, L<Config::Augeas>

=cut

