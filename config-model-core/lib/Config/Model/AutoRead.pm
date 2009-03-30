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
use warnings ;
use Config::Model::Exception ;
use Data::Dumper ;
use File::Path ;
use UNIVERSAL ;
use Storable qw/dclone/ ;

my $has_augeas = 1;
eval { require Config::Augeas ;} ;
$has_augeas = 0 if $@ ;

use base qw/Config::Model::AnyThing/ ;

our $VERSION = sprintf "1.%04d", q$Revision$ =~ /(\d+)/;

=head1 NAME

Config::Model::AutoRead - Load configuration node on demand

=head1 SYNOPSIS

  # top level config file name matches instance name
  $model->create_config_class 
  (
   config_class_name => 'OneAutoReadConfigClass',

   read_config  => [ { backend => 'cds_file' , config_dir => '/etc/cfg_dir'},
                     { backend => 'custom' , # dir hardcoded in custom class
                       class => 'ProcessRead' ,
                       allow_empty => 1,     # optional
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

This load/store can be done with:

=over

=item *

Config dump string (cds) in a file. I.e. a string that describes the
content of a configuration tree is loaded from or saved in a text
file. See L<Config::Model::Dumper>.

=item *

Ini files (written with L<Config::Tiny>. See limitations in 
L</"Limitations depending on storage">.

=item *

Perl data structure (perl) in a file. See L<Config::Model::DumpAsData>
for details on the data structure.

=item *

XML. Not yet implemented (ask the author if you're interested)

=item *

Any format when the user provides a dedicated class and function to
read and load the configuration tree.

=item *

Data can be loaded or stored using RedHat's Augeas library.

=back

After loading the data, the object registers itself to the
instance. Then the user can call the C<write_back> method on the
instance (See L<Config::Model::Instance>) to store all configuration
informations back.

=head2 Built-in read write format

Currently, this class supports the following built-in formats:

=over

=item cds_file

Config dump string. See L<Config::Model::Dumper>.

=item ini_file

Ini files written by L<Config::Tiny>.

=item augeas

Use Augeas library. See L<Config::Model::Backend::Augeas> for details.

=back

=head2 Custom backend

Custom backend must be specified with a class name that will features
the methods used to write and read the configuration files:

  read_config  => [ { backend => 'custom' , class => 'MyRead',
                      config_dir => '/etc/foo'
                    } ]

Note that C<config_dir> specification is optional.

The C<MyRead> class that you will provide must have the methods
C<read> and C<write>. Then, C<MyRead::read> will be called with there
parameters:

 (object => config_tree_root, root => 'filesystem root' ,
                              config_dir => 'config dir', )

You can choose to specify yourself the read and write methods:

   read_config => { backend  => 'custom', 
                    class    => 'MyRead', 
                    function => 'my_read' 
                  }

and

   write_config => { backend  => 'custom', 
                     class    => 'MyRead', 
                     function => 'my_write' 
                   }

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

A configuration class will be declared with optional C<read_config> or
C<write_config> parameters:

  read_config  => [ { backend => 'cds_file', config_dir => '/etc/my_cfg/' } , 
                    { backend => 'custom', class => 'Bar' },
                  ],
  write_config => { backend => 'cds_file', config_dir => '/etc/my_cfg/' },

The read backends will be tried in the specified order:

=over

=item *

First the cds file whose name depend on the parameters used in model
creation and instance creation:
C<< <model_config_dir>/<instance_name>.cds >>
The syntax of the C<cds> file is described in  L<Config::Model::Dumper>.

=item * 

A call to C<Bar::read> with these parameters:

 (object => config_tree_root, root => 'filesystem root', config_dir => '...')

=back

When a read operation is successful, the remaining read methods will
be skipped. By default, an exception is thrown if no read was
successfull. This behavior can be overridden by specifying 
C<< allow_empty => 1 >> in one of the backend specification. For instance:

    read_config  => [ { backend => 'cds_file', config_dir => '/etc/my_cfg/' } , 
                    { backend => 'custom', class => 'Bar' ,
                      allow_empty => 1
                    },
                  ],

This feature is necessary if you want to be able to create a
configuration from scratch.

When necessary (or required by the user), all configuration
informations are written back using B<all> the write method passed.

In the example above, only a C<cds> file is written. But, both custom
format and C<cds> file are tried for read. This is also an example of
a graceful migration from a customized format to a C<cds> format.

You can choose also to read and write only customized files:

  read_config  => { backend => 'custom', class => 'Bar'},

Or to read and write only cds files :

  read_config  => { backend => 'cds_file'} ,

You can also specify more paratmeters that must be passed to your
custom class:

  read_config  => { backend => 'custom', class => 'Bar', config_dir => '/etc/foo'},

=begin comment

To migrate from custom format to xml:

  read_config  => [ { backend => 'xml' },
                    { backend => 'custom', class => 'Bar' } ],
  write_config => { backend => 'xml' },

=end comment

To migrate from an old format to a new format:

  read_config  => [ { backend => 'custom', class => 'OldFormat',  function => 'old_read'} ,
                    { backend => 'custom', class => 'NewFormat',  function => 'new_read'} 
                  ],
  write_config => [ { backend => 'custom', class => 'NewFormat' } ],

If C<write_config> is missing, the data provided by C<read_config>
will be used. For instance:

  read_config  => { backend => 'custom', class => 'Bar', config_dir => '/etc/foo'},

In this case, configuration data will be read by C<Bar::read> in
directory C</etc/foo> and will be written back there by C<Bar::write>.

=head2 read write directory

By default, configurations files are read from the directory specified
by C<config_dir> parameter specified in the model. You may override the
C<root> directory for test.

=cut

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
    $root_dir .= '/' if $root_dir and $root_dir !~ m(/$) ; 

    croak "auto_read_init: readlist must be array or hash ref\n" 
      unless ref $readlist ;

    my @list = ref $readlist  eq 'ARRAY' ? @$readlist :  ($readlist) ;
    my $pref_backend = $instance->backend || '' ;
    my $read_done = 0;
    my $allow_empty = 0;

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

	$allow_empty ||= delete $read->{allow_empty} if defined $read->{allow_empty};

	if ($backend eq 'custom') {
	    my $c = my $file = delete $read->{class} ;
	    $file =~ s!::!/!g;
	    my $f = delete $read->{function} || 'read' ;
	    require $file.'.pm' unless $c->can($f);
	    no strict 'refs';
	    print "Read data with $ {c}::$f in dir $read_dir\n" if $::verbose;

	    my $res = &{$c.'::'.$f}(%$read, root => $root_dir, 
				    conf_dir => $read_dir, # legacy FIXME
				    config_dir => $read_dir, object => $self) ;
	    if ($res) { 
		$read_done = 1 ;
		last;
	    }
	}
	elsif ($backend eq 'xml') {
	    if ($self->read_xml(root => $root_dir, config_dir => $read_dir)) {
		$read_done = 1 ;
		last;
	    }
	}
	elsif ($backend eq 'perl_file') {
	    if ($self->read_perl(root => $root_dir, config_dir => $read_dir)) {
		$read_done = 1 ;
		last;
	    }
	}
	elsif ($backend eq 'ini_file') {
	    if ($self->read_ini(root => $root_dir, config_dir => $read_dir)) {
		$read_done = 1 ;
		last;
	    }
	}
	elsif ($backend eq 'cds_file') {
	    if ($self->read_cds_file(root => $root_dir, config_dir => $read_dir)) {
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
	    print "Read data with $ {c}::$f\n" if $::verbose;

	    if ($backend_obj->$f(%$read, root => $root_dir, 
				 config_dir => $read_dir)) {
		$read_done = 1 ;
		last;
	    }
	}
    }

    if (not $read_done and not $allow_empty) {
	Config::Model::Exception::Model -> throw
	    (
	     error => "auto_read error: could not read config file "
	            . ($pref_backend ? "with '$pref_backend' backend" : ''),
	     object => $self,
	    ) ;
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

    # provide a proper write back function
    my @array = ref $wrlist eq 'ARRAY' ? @$wrlist : ($wrlist) ;
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

	print "auto_write_init: registering write cb ($write) for ",$self->name,"\n"
	  if $::verbose ;

	my $wb ;
	if ($backend eq 'custom') {
	    my $c = my $file = $write->{class} ;
	    $file =~ s!::!/!g;
	    my $f = $write->{function} || 'write' ;
	    require $file.'.pm' unless $c->can($f) ;
	    my $safe_self = $self ; # provide a closure
	    $wb = sub 
	      {  no strict 'refs';
		 # override needed for "save as" button
		 &{$c.'::'.$f}(%$write,                # model data
			       root => $root_dir,      #override from instance
			       config_dir => $write_dir, #override from instance
			       conf_dir => $write_dir, # legacy FIXME
			       object => $safe_self, 
			       @_                      # override from use
			      ) ;
	     };
	    $self->{auto_write}{custom} = 1 ;
	}
	elsif ($backend eq 'xml') {
	    $wb = sub {$self->write_xml(root => $root_dir, 
					config_dir =>  $write_dir, @_
				       ) ;
		   } ;
	    $self->{auto_write}{xml} = 1 ;
	}
	elsif ($backend eq 'ini_file') {
	    $wb = sub {$self->write_ini(root => $root_dir, 
					config_dir => $write_dir, @_
				       ) ;
		   } ;
	    $self->{auto_write}{ini_file} = 1 ;
	}
	elsif ($backend eq 'perl_file') {
	    $wb = sub {$self->write_perl(root => $root_dir, 
					 config_dir => $write_dir,  @_
					) ;
		   } ;
	    $self->{auto_write}{perl_file} = 1 ;
	}
	elsif ($backend eq 'cds_file') {
	    $wb = sub {$self->write_cds_file(root => $root_dir, 
					     config_dir => $write_dir, @_,
					    ) ;
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
		 # override needed for "save as" button
		 $backend_obj->$f(%$write,                # model data
			       root => $root_dir,      #override from instance
			       config_dir => $write_dir, #override from instance
			       object => $safe_self, 
			       @_                      # override from use
			      ) ;
	     };
	}

	$instance->register_write_back($backend => $wb) ;
	$registered_backend ++ ;
    }
}

sub is_auto_write_for_type {
    my $self = shift;
    my $type = shift ;
    return $self->{auto_write}{$type} || 0;
}

sub get_cfg_file_name {
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

    my $i = $self->instance ;

    my $name = $dir.$i->name ;
    mkpath ($name,0, 0755) if $w and not -d $name ;

    # append ":foo bar" if not root object
    my $loc = $self->location ; # not good
    if ($loc) {
	mkpath ($name,0, 0755) if $w and not -d $name ;
	$name .= '/'.$loc ;
    }

    return $name ;
}

sub read_cds_file {
    my $self = shift;

    my $file_name = $self->get_cfg_file_name(@_) . '.cds' ;

    print "Trying cds data from $file_name\n" if $::debug;

    return 0 unless -r $file_name ;

    print "Read cds data from $file_name\n" if $::verbose;

    open(IN,$file_name) || die "Cannot open $file_name:$!";
    local $/ ; # slurp mode
    my $text = <IN> ;
    close IN ;

    $self->load( step => $text) ;
    return 1 ;
}

sub write_cds_file {
    my $self = shift;

    my $file_name = $self->get_cfg_file_name(write => 1,@_) . '.cds' ;
    $file_name =~ s!//!/!g;

    print "Write cds data to $file_name\n" if $::verbose;
    open (FOUT, ">$file_name") or die "_write_cds_file: Can't open $file_name: $!";
    print FOUT $self->dump_tree(skip_auto_write => 'cds_file' ) ;
    close FOUT ;
    return 1 ;
}

sub read_perl {
    my $self = shift;
    my $file_name = $self->get_cfg_file_name(@_) . '.pl' ;
    print "Trying Perl data from $file_name\n" if $::debug;
    return 0 unless -r $file_name ;

    print "Read Perl data from $file_name\n" if $::verbose;
    my $pdata = do $file_name || die "Cannot open $file_name:$!";
    $self->load_data( $pdata ) ;
    return 1 ;
}

sub write_perl {
    my $self = shift;

    my $i = $self->instance ;
    my $file_name = $self->get_cfg_file_name(write => 1,@_) . '.pl' ;

    my $p_data = $self->dump_as_data(skip_auto_write => 'perl_file' ) ;

    my $dumper = Data::Dumper->new([$p_data]) ;
    $dumper->Terse(1) ;

    print "Write perl data to $file_name\n" if $::verbose;
    open (FOUT, ">$file_name") or die "_write_perl: Can't open $file_name: $!";
    print FOUT $dumper->Dump , ";\n";
    close FOUT ;

    return 1 ;
}

sub read_ini {
    my $self = shift;
    my $file_name = $self->get_cfg_file_name(@_) . '.ini' ;
    print "Trying Ini data from $file_name\n" if $::debug;
    return 0 unless -r $file_name ;

    print "Read Ini data from $file_name\n" if $::verbose;
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

sub write_ini {
    my $self = shift;

    my $file_name = $self->get_cfg_file_name(write => 1, @_) . '.ini' ;
    print "Write Ini data to $file_name\n" if $::verbose;

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

    print "Write Ini data to $file_name\n" if $::verbose;
    $iniconf -> write($file_name) ;

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

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Instance>,
L<Config::Model::Node>, L<Config::Model::Dumper>, L<Config::Augeas>

=cut

