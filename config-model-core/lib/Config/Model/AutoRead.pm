# $Author$
# $Date$
# $Revision$

#    Copyright (c) 2005-2008 Dominique Dumont.
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
                       class => 'ProcessRead' 
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

  # use with Augeas
  $model->create_config_class 
  (
   config_class_name => 'OpenSsh::Sshd',

   # try Augeas and fall-back with custom method
   read_config  => [ { backend => 'augeas' , 
                       config_file => '/etc/ssh/sshd_config',
                       # declare "seq" Augeas elements 
                       lens_with_seq => [/AcceptEnv AllowGroups [etc]/],
                     },
                     { backend => 'custom' , # dir hardcoded in custom class
                       class => 'Config::Model::Sshd' 
                     }
                   ],
   # write_config will be written using read_config specifications


   element => ...
  ) ;

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

Use Augeas library

=back

=head2 Custom backend

Custom backend must be specified with a class name that will features
the methods used to write and read the configuration files:

  read_config  => [ { backend => 'custom' , class => 'MyRead' } ]

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

=head2 Augeas backend limitation

The structure and element names of the Config::Model tree must match the
structure defined in Augeas lenses.

Sometimes, the structure of a file loaded by Augeas starts directly
with a list of items. For instance C</etc/hosts> structure starts with
a list of lines that specify hosts and IP adresses. The C<set_in>
parameter specifies an element name in Config::Model root class that
will hold the configuration data retrieved by Augeas.

=head1 Configuration class with auto read or auto write

=head2 read and write specification

A configuration class will be declared with optional C<read> or
C<write> parameters:

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
be skipped.

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
    foreach my $read (@list) {
	warn $self->config_class_name,
	  " deprecated 'syntax' parameter in auto_read\n" if defined $read->{syntax} ;
	my $backend = delete $read->{backend} || delete $read->{syntax} || 'custom';
	if ($backend =~ /^(perl|ini|cds)$/) {
	    warn $self->config_class_name,
	      " deprecated auto_read backend $backend. Should be '$ {backend}_file'\n";
	    $backend .= "_file" ;
	}

	my $read_dir = delete $read->{config_dir} || $r_dir || ''; # r_dir obsolete
	$read_dir .= '/' if $read_dir and $read_dir !~ m(/$) ; 

	if ($backend eq 'custom') {
	    my $c = my $file = delete $read->{class} ;
	    $file =~ s!::!/!g;
	    my $f = delete $read->{function} || 'read' ;
	    require $file.'.pm' unless $c->can($f);
	    no strict 'refs';
	    print "Read data with $ {c}::$f\n" if $::verbose;

	    last if &{$c.'::'.$f}(%$read, root => $root_dir, 
				  conf_dir => $read_dir, # legacy FIXME
				   config_dir => $read_dir, object => $self) ;
	}
	elsif ($backend =~ /^augeas$/i) {
	    last if $self->read_augeas(root => $root_dir, 
				       config_dir => $read_dir,
				       %$read,
				      ) ;
	}
	elsif ($backend eq 'xml') {
	    last if $self->read_xml(root => $root_dir, config_dir => $read_dir) ;
	}
	elsif ($backend eq 'perl_file') {
	    last if $self->read_perl(root => $root_dir, config_dir => $read_dir) ;
	}
	elsif ($backend eq 'ini_file') {
	    last if $self->read_ini(root => $root_dir, config_dir => $read_dir) ;
	}
	elsif ($backend eq 'cds_file') {
	    last if $self->read_cds_file(root => $root_dir, config_dir => $read_dir) ;
	}
	else {
	    Config::Model::Exception::Model -> throw
		    (
		     error=> "auto_read error: unknown backend '$backend'",
		     object => $self
		    ) ;
	}
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
	elsif ($backend eq 'augeas') {
	    $wb = sub {$self->write_augeas(root => $root_dir, 
					   config_dir =>  $write_dir, 
					   %$write, @_
					  ) ;
		   } ;
	    $self->{auto_write}{xml} = 1 ;
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
	    Config::Model::Exception::Model -> throw
		    (
		     error=> "auto_write error: unknown backend '$backend'",
		     object => $self
		    ) ;
	}

	$instance->register_write_back($wb) ;
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

=head1 Read and write with Augeas library

You can use L<Config::Augeas> to read and write data back. This way,
the structure and commments of the original configuration file will
preserved.

To use Augeas as a backend, you must specify the following
C<read_config> parameters:

=over

=item backend

Use C<augeas> in this case.

=item save

Either C<backup> or C<newfile>. See L<Config::Augeas/Constructor> for
details.

=item config_file

Name of the config_file.

=item lens_with_seq

This one is tricky. When an Augeas lens use the C<seq> keywords in a
lens, a special type of list element is created (See
L<http://augeas.net/docs/lenses.html> for details on lenses). This
special list element must be declared so that Config::Model can use
the correct Augeas call to write this list values. C<lens_with_seq>
must be passed a list ref of all lens names that contains a C<seq>
statement.

=back

For instance:

   read_config  => [ { backend => 'augeas' , 
                       save   => 'backup',
                       config_file => '/etc/ssh/sshd_config',
                       # declare "seq" Augeas elements 
                       lens_with_seq => [/AcceptEnv AllowGroups/],
                     },
                   ],


=cut

# for tests only
sub _augeas_object {return shift->{augeas_obj} ; } ;

sub read_augeas
  {
    my $self = shift;
    my %args = @_ ; # contains root and config_dir
    return 0 unless $has_augeas ;

    print "Read config data from Augeas\n" if $::verbose;

    $self->{augeas_obj} ||= Config::Augeas->new(root => $args{root}, 
						save => $args{save} ) ;

    if (not defined $args{config_file}) {
	Config::Model::Exception::Model -> throw
	    (
	     error=> "read_augeas error: model "
	     . "does not specify 'config_file' for Augeas ",
	     object => $self
	    ) ;
    }

    my $mainpath = '/files'.$args{config_file} ;

    my @result =  $self->augeas_deep_match($mainpath) ;
    my @cm_path = @result ;

    # cleanup resulting path to remove Augeas '/files', remove the
    # file path and plug the remaining path where it is consistent in
    # the model. I.e if the file "root" matches a list element (like
    # for /etc/hosts), get this element name from "set_in" parameter
    my $set_in = $args{set_in} || '';
    map {
	s!$mainpath!! ;
	$_ = "/$set_in/$_" if $set_in;
	s!/+!/!g;
    } @cm_path ;

    # Create a hash of lens that contain a seq lens
    my %has_seq = map { ( $_ => 1 ) ;} @{$args{lens_with_seq} || []} ;

    my $augeas_obj = $self->{augeas_obj} ;

    # this may break as data will be written in the tree in an order
    # decided by Augeas. This may break complex model with warping as 
    # the best writing order is indicated by the model and not Augeas.
    while (@result) {
	my $aug_p = shift @result;
	my $cm_p  = shift @cm_path;
	my $v = $augeas_obj->get($aug_p) ;
	next unless defined $v ;

	print "read-augeas read $aug_p, set $cm_p with $v\n" if $::debug ;
	$cm_p =~ s!^/!! ;
	# With 'seq' type list, we can get
	# /files/etc/ssh/sshd_config/AcceptEnv[1]/1/ =  LC_PAPER
	# /files/etc/ssh/sshd_config/AcceptEnv[1]/2/ =  LC_NAME
	# /files/etc/ssh/sshd_config/AcceptEnv[2]/3/ =  LC_ADDRESS
	# /files/etc/ssh/sshd_config/AcceptEnv[2]/4/ =  LC_TELEPHONE
	my @cm_steps = split m!/+!, $cm_p ;
	my $obj = $self;

	while (my $step = shift @cm_steps) {
	    my ($label,$idx) = ( $step =~ /(\w+)(?:\[(\d+)\])?/ ) ;

	    # idx will be treated next iteration if needed
	    if (    $obj->get_type eq 'node' 
		and $obj->element_type($label) eq 'list') {
		$idx = 1 unless defined $idx ;
		unshift @cm_steps , $idx unless $has_seq{$label} ;
	    }

	    # augeas list begin at 1 not 0
	    $label -= 1 if $obj->get_type eq 'list';
	    if (@cm_steps) {
		print "read-augeas: get $label ", 
		  ( $has_seq{$label} ? 'seq' : '' ),"\n" if $::debug;
		$obj = $obj->get($label) ;
	    }
	    else {
		# last step
		$obj->set($label,$v) ;
	    }
	}
    }

    return 1 ;
  }

sub augeas_deep_match {
    my ($self,$mainpath) = @_ ;

    # work around Augeas feature where '*' matches only one hierarchy
    # level 
    # See https://www.redhat.com/archives/augeas-devel/2008-July/msg00016.html
    my @worklist = ( $mainpath );
    print "read-augeas on @worklist\n" if $::debug ;

    my $augeas_obj = $self->{augeas_obj} ;
    my @result ;
    while (@worklist) {
	my $p = pop @worklist ;
	my @newpath = $augeas_obj -> match($p . "/*") ;
	print "read-augeas $p/* matches paths: @newpath\n" if $::debug ;
	push @worklist, @newpath ;
	push @result,   @newpath ;
    }

    return @result ;
}

sub write_augeas
  {
    my $self = shift;
    my %args = @_ ; # contains root and config_dir
    return 0 unless $has_augeas ;

    print "Write config data through Augeas\n" if $::verbose;

    if (not defined $args{config_file}) {
	Config::Model::Exception::Model -> throw
	    (
	     error=> "write_augeas error: model "
	     . "does not specify 'config_file' for Augeas ",
	     object => $self
	    ) ;
    }

    my $set_in = $args{set_in} || '';
    my $mainpath = '/files'.$args{config_file} ;
    my $augeas_obj = $self->{augeas_obj} ;

    my %to_set = $self->copy_in_augeas($augeas_obj,$mainpath,$set_in,
				       $args{lens_with_seq}) ;

    # foreach my $path (keys %to_set) {
    # 	my $aug_path = "$mainpath$path" ;
    # 	my $v = $to_set{$path} ;
    # 	print "write-augeas $path, set $aug_path with $v\n" if $::debug ;
    # 	# remove all Augeas paths that are included in the path found in
    # 	# config-model
    # 	map {delete $old_path{$_} if index($aug_path,$_,0) == 0} keys %old_path ;
    # 	$augeas_obj->set($aug_path,$v) ;
    # }

    # remove path no longer present in config-model
    #map { print "deleting aug path $_\n" if $::debug;
    # $augeas_obj->remove($_) } reverse sort keys %old_path ;

    $augeas_obj->save || warn "Augeas save failed";;
}

sub copy_in_augeas {
    my $self = shift ;
    my $augeas_obj = shift ;
    my $mainpath = shift ;
    my $set_in = shift ;
    my $seq_list = shift || [];
    my %has_seq = map { ( $_ => 1 ) ;} @$seq_list ;

    # cleanup the tree. This is not subtle and may be improved when the
    # following bugs are fixed:
    # https://fedorahosted.org/augeas/ticket/23
    # https://fedorahosted.org/augeas/ticket/24

    $augeas_obj->remove("$mainpath/*") ;

    # data_ref = ( current_path ) 
    my $std_cb = sub {
        my ( $scanner, $data_ref, $obj, $element, $index, $value_obj ) = @_;
	my $p = $data_ref->[0] ;
	my $v = $value_obj->fetch () ; 
	if (defined $v) {
	    $augeas_obj->set($p , $v) ;
	    print "copy_in_augeas: set $p = '$v'\n" if $::debug;
	}
    };

    my $hash_element_cb = sub {
	my ($scanner, $data_ref,$node,$element_name,@keys) = @_ ;
	my $p = $data_ref->[0] ;

	map {$scanner->scan_hash([$p."/$_"],$node,$element_name,$_)} @keys ;
    };

    my $list_element_cb = sub {
	my ($scanner, $data_ref,$node,$element_name,@idx) = @_ ;
	my $p = $data_ref->[0] ;

	my $seq_item = $has_seq{$element_name} || 0 ;
	map { my $aug_idx = $_ + 1 ; # Augeas lists begin at 1 not 0
	      my $subpath =  $seq_item ? "[last()]/$aug_idx" : "[$aug_idx]" ;
	      $scanner->scan_list([$p.$subpath], $node,$element_name,$_);
	  } @idx ;
    };

    my $node_content_cb = sub {
	my ($scanner, $data_ref,$node,@element) = @_ ;
	my $p = $data_ref->[0] ;
	map {
	    # Deal with the fact that Augeas tree can start directly into
	    # a list element
	    my $np = (defined $set_in and $set_in eq $_) ? $p : $p."/$_" ;
	    $scanner->scan_element([$np], $node,$_)
	} @element ;
    };

    my @scan_args = (
		     experience            => 'master',
		     fallback              => 'all',
		     auto_vivify           => 0,
		     list_element_cb       => $list_element_cb,
		     check_list_element_cb => $std_cb,
		     hash_element_cb       => $hash_element_cb,
		     leaf_cb               => $std_cb ,
		     node_content_cb       => $node_content_cb,
		    );

    # perform the scan
    my $view_scanner = Config::Model::ObjTreeScanner->new(@scan_args);

    $view_scanner->scan_node([$mainpath] ,$self);
}

1;

__END__

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Instance>,
L<Config::Model::Node>, L<Config::Model::Dumper>, L<Config::Augeas>

=cut

