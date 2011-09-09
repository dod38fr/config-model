#
#    Copyright (c) 2005-2011 Dominique Dumont.
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

package Config::Model::BackendMgr ;

use Any::Moose ;

use Carp;

use Config::Model::Exception ;
use Data::Dumper ;
use File::Path ;
use File::HomeDir ;
use IO::File ;
use Storable qw/dclone/ ;
use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger('Data') ;

# one BackendMgr per file

has 'node'       => ( is => 'ro', isa => 'Config::Model::Node', 
		      weak_ref => 1, required => 1 ) ;
has 'file_backup' => ( is => 'rw') ;
has 'backend' => ( is => 'rw', ) ;
has 'backend_obj' => ( is => 'rw', isa => 'Config::Model::Backend::Any' ) ;


sub get_cfg_file_path {
    my $self = shift ; 
    my %args = @_;

    my $w = $args{write} || 0 ;

    Config::Model::Exception::Model -> throw
        (
         error=> "auto_". ($w ? 'write' : 'read') 
                 ." error: empty 'config_dir' parameter",
         object => $self->node
        ) unless $args{config_dir};

    my $dir = $args{config_dir} ;
    if ($dir =~ /^~/) { 
        # also works also on Windows. Not that I care, just trying to be nice
        my $home = File::HomeDir->my_data; 
        $dir =~ s/^~/$home/;
    }
    
    $dir = $args{root}.$dir ;
    
    $dir .= '/' unless $dir =~ m!/$! ;
    if (not -d $dir and $w and $args{auto_create}) {
        $logger->info("get_cfg_file_path:{ite create directory $dir" );
        mkpath ($dir,0, 0755);
    }

    unless (-d $dir) { 
        $logger->info( "get_cfg_file_path: auto_". ($w ? 'write' : 'read') 
                      ." $args{backend} no directory $dir" );
        return;
    }

    if (defined $args{file}) {
        my $res = $dir.$args{file} ;
        $logger->trace("get_cfg_file_path: returns $res"); 
        return $res ;
    }

    if (not defined $args{suffix}) {
        $logger->trace("get_cfg_file_path: returns undef (no suffix, no file argument)"); 
        return ;
    }

    my $i = $self->node->instance ;
    my $name = $dir. $i->name ;

    # append ":foo bar" if not root object
    my $loc = $self->node->location ; # not very good
    if ($loc) {
        if (($w and not -d $name and $args{auto_create})) {
          $logger->info("get_cfg_file_path: auto_write create subdirectory ",
                        "$name (location $loc)" );
          mkpath ($name,0, 0755);
        }
        $name .= '/'.$loc ;
    }

    $name .= $args{suffix} ;

    $logger->trace("get_cfg_file_path: auto_". ($w ? 'write' : 'read') 
                  ." $args{backend} target file is $name" );

    return $name;
}

sub open_read_file {
    my $self = shift ;
    my %args = @_ ;

    my $file_path = $self->get_cfg_file_path(%args);

    # not very clean
    return if $args{backend} =~ /_file$/
        and (not defined $file_path or not -r $file_path) ;

    my $fh = new IO::File;
    if (defined $file_path and -e $file_path) {
        $logger->debug("open_read_file: open $file_path for read");
        $fh->open($file_path);
        $fh->binmode(":utf8");
        # store a backup in memory in case there's a problem
        $self->{file_backup} = [ $fh-> getlines ] ;
        $fh->seek(0,0) ; # go back to beginning of file
        return ($file_path,$fh) ;
    }
    else {
        return $file_path ;
    }
}

# called at configuration node creation
#
# New subroutine "load_backend_class" extracted - Thu Aug 12 18:32:37 2010.
#
sub load_backend_class {
    my $backend = shift;
    my $function = shift ;

    $logger->debug("load_backend_class: called with backend $backend, function $function");
    my %c ;

    my $k = "Config::Model::Backend::".ucfirst($backend) ;
    my $f = $k.'.pm';
    $f =~ s!::!/!g;
    $c{$k} = $f ;
    
    # try another class
    $k =~ s/_(\w)/uc($1)/ge;
    $f =~ s/_(\w)/uc($1)/ge;
    $c{$k} = $f ;

    foreach my $c (keys %c) { 
        if ($c->can($function)) {
            # no need to load class  
            $logger->debug("load_backend_class: $c is already loaded (can $function)");
            return $c ;
        } 
    }

        
    # look for file to load 
    my $class_to_load ;
    foreach my $c (keys %c) { 
        $logger->debug("load_backend_class: looking to load class $c");
        foreach my $prefix (@INC) {
            my $realfilename = "$prefix/$c{$c}";
            $class_to_load = $c if -f $realfilename ;
        }
    }

    return unless defined $class_to_load ;
    my $file_to_load = $c{$class_to_load} ;

    $logger->debug("load_backend_class: loading class $class_to_load, $file_to_load");
    eval {require $file_to_load; } ;

    if ($@) {
            die "Could not parse $file_to_load: $@\n";
    } 
    return $class_to_load ;
}

sub auto_read_init {
    my ($self, $readlist_orig, $check, $r_dir) = @_ ;
    # r_dir is obsolete
    if (defined $r_dir) {
        warn $self->node->config_class_name," : read_config_dir is obsolete\n";
    }

    my $readlist = dclone $readlist_orig ;

    my $instance = $self->node->instance() ;

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

        my @read_args = (%$read, root => $root_dir, config_dir => $read_dir,
                        backend => $backend, check => $check);

        if ($backend eq 'custom') {
            my $c = my $file = delete $read->{class} ;
            $file =~ s!::!/!g;
            my $f = delete $read->{function} || 'read' ;
            require $file.'.pm' unless $c->can($f);
            no strict 'refs';

            $logger->info("Read with custom backend $ {c}::$f in dir $read_dir");

            my ($file_path,$fh) = $self->open_read_file(@read_args);
            my $res = &{$c.'::'.$f}(@read_args, 
                                    file_path => $file_path,
                                    io_handle => $fh,
                                    object => $self->node) ;
            if ($res) { 
                $read_done = 1 ;
                last;
            }
        }
        elsif ($backend eq 'perl_file') {
            my ($file_path,$fh) = $self->open_read_file(@read_args,
                                                       suffix => '.pl');
            next unless defined $file_path ;
            my $res = $self->read_perl(@read_args, 
                                       file_path => $file_path,
                                       io_handle => $fh);
            if ($res) {
                $read_done = 1 ;
                last;
            }
        }
        elsif ($backend eq 'cds_file') {
            my ($file_path,$fh) = $self->open_read_file(@read_args,
                                                        suffix => '.cds');
            next unless defined $file_path ;
            my $res = $self->read_cds_file(@read_args, 
                                           file_path => $file_path,
                                           io_handle => $fh,);
            if ($res) {
                $read_done = 1 ;
                last;
            }
        }
        else {
            # try to load a specific Backend class
            my $f = delete $read->{function} || 'read' ;
            my $c = load_backend_class ($backend, $f);
            next unless defined $c;

            no strict 'refs';
            my $backend_obj = $self->{backend}{$backend} 
              = $c->new(node => $self->node, name => $backend) ;
            my $suffix ;
            $suffix = $backend_obj->suffix if $backend_obj->can('suffix');
            my ($file_path,$fh) = $self->open_read_file(@read_args,
                                                        suffix => $suffix);
            $logger->info("Read with $backend ".$c."::$f");

            my $res = $backend_obj->$f(@read_args, 
                                       file_path => $file_path,
                                       io_handle => $fh,
                                       object => $self->node,
                                      );
            if ($res) {
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
             error => "auto_read error: $msg. May be add "
                    . "'auto_create' parameter in configuration model" ,
             object => $self->node,
            ) unless $auto_create ;

        $logger->warn("Warning: node '".$self->node->name."' $msg");
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

    my $instance = $self->node->instance() ;

    # root override is passed by the instance
    my $root_dir = $instance -> write_root_dir || '';

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

        $logger->debug("auto_write_init creating write cb ($backend) for ",$self->node->name);

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

            my $node = $self->node ; # provide a closure
            $wb = sub  {  
                no strict 'refs';
                my $file_path ;
                $logger->debug("write cb ($backend) called for ",$self->node->name);
                $file_path = $self-> open_file_to_write($backend,$fh,@wr_args,@_) 
                    unless ($c->can('skip_open') and $c->skip_open) ;
                my $res ;
                $res = eval {
                    # override needed for "save as" button
                    &{$c.'::'.$f}(@wr_args,
                                  file_path => $file_path,
                                  conf_dir => $write_dir, # legacy FIXME
                                  object => $node, 
                                  @_                      # override from user
                                ) ;
                };
                $logger->warn("write backend $c".'::'."$f failed: $@") if $@;
                $self->close_file_to_write($@,$fh,$file_path) ;
                return defined $res ? $res : $@ ? 0 : 1 ;
             };
            $self->{auto_write}{custom} = 1 ;
        }
        elsif ($backend eq 'perl_file') {
            $wb = sub {
                $logger->debug("write cb ($backend) called for ",$self->node->name);
                my $file_path 
                    = $self-> open_file_to_write($backend,$fh,
                                                suffix => '.pl',@wr_args,@_) ;
                my $res ;
                $res = eval {
                    $self->write_perl(@wr_args, file_path => $file_path,  @_) ;
                };
                $self->close_file_to_write($@,$fh,$file_path) ;
                $logger->warn("write backend $backend failed: $@") if $@;
                return defined $res ? $res : $@ ? 0 : 1 ;
            } ;
            $self->{auto_write}{perl_file} = 1 ;
        }
        elsif ($backend eq 'cds_file') {
            $wb = sub {
                $logger->debug("write cb ($backend) called for ",$self->node->name);
                my $file_path 
                   = $self-> open_file_to_write($backend,$fh,
                                                suffix => '.cds',@wr_args,@_) ;
                my $res ;
                $res = eval {
                    $self->write_cds_file(@wr_args, file_path => $file_path, @_) ;
                };
                $logger->warn("write backend $backend failed: $@") if $@;
                $self->close_file_to_write($@,$fh,$file_path) ;
                return defined $res ? $res : $@ ? 0 : 1 ;
            } ;
            $self->{auto_write}{cds_file} = 1 ;
        }
        else {
			my $f = $write->{function} || 'write' ;
			my $c = load_backend_class ($backend, $f);

            my $node = $self->node ; # provide a closure
            $wb = sub {
                no strict 'refs';
                $logger->debug("write cb ($backend) called for ",$self->node->name);
                my $backend_obj =  $self->{backend}{$backend}
                                || $c->new(node => $self->node, name => $backend) ;
                my $file_path ;
                my $suffix ;
                $suffix = $backend_obj->suffix if $backend_obj->can('suffix');
                $file_path = $self-> open_file_to_write($backend,$fh,
                                                         suffix => $suffix,
                                                         @wr_args,@_) 
                    unless ($c->can('skip_open') and $c->skip_open) ;
                my $res ;
                $res = eval {
                    # override needed for "save as" button
                    $backend_obj->$f( @wr_args, 
                                      file_path => $file_path,
                                      object => $node, 
                                      @_                      # override from user
                                    ) ;
                } ;
                $logger->warn("write backend $backend $c".'::'."$f failed: $@") if $@;
                $self->close_file_to_write($@,$fh,$file_path) ;
                return defined $res ? $res : $@ ? 0 : 1 ;
             };
        }

        # FIXME: enhance write back mechanism so that different backend *and* different nodse
        # work as expected
        $logger->debug("registering write $backend in node ".$self->node->name);
        push @{$self->{write_back}}, [$backend, $wb] ;
        $instance->register_write_back($self->node->location) ;
    }
}

=head2 write_back ( ... )

Try to run all subroutines registered by L<auto_write_init> 
write the configuration information until one succeeds (returns
true).

You can specify here a pseudo root directory or another config
directory to write configuration data back with C<root> and
C<config_dir> parameters. This will override the model specifications.

You can force to use a backend by specifying C<< backend => xxx >>. 
For instance, C<< backend => 'augeas' >> or C<< backend => 'custom' >>.

You can force to use all backend to write the files by specifying 
C<< backend => 'all' >>.

C<write_back> will croak if no write call-back are known for this node.

=cut

sub write_back {
    my $self = shift ;
    my %args = @_ ; 

    my $force_backend = delete $args{backend} || '' ;

    croak "write_back: no subs registered in node", $self->node->location,". cannot save data\n" 
        unless @{$self->{write_back}} ;

    my @backends = @{$self->{write_back}} ;
    $logger->debug("write_back called on node '",$self->node->name, "' for " , scalar @backends, " backends");


    my $dir = $args{config_dir} ;
    mkpath($dir,0,0755) if $dir and not -d $dir ;

    foreach my $wb_info (@backends) {
	my ($backend,$wb) = @$wb_info ;
	if (not $force_backend 
	    or  $force_backend eq $backend 
	    or  $force_backend eq 'all' ) {
	    # exit when write is successfull
	    my $res = $wb->(%args) ; 
	    $logger->info("write_back called with $backend backend, result is ", defined $res ? $res : '<undef>' );
	    last if ($res and not $force_backend); 
	}
    }
    $logger->debug("write_back on node '",$self->node->name, "' done");
}

sub open_file_to_write {
    my ($self, $backend, $fh, @args) = @_ ;

    my $file_path = $self->get_cfg_file_path(@args);
    if (defined $file_path) {
        $logger->debug("$backend backend opened file $file_path to write");
        $fh ->open("> $file_path") || die "Cannot open $file_path:$!";
        $fh->binmode(':utf8');
    }

    return $file_path ;
}

sub close_file_to_write {
    my ($self,$error,$fh,$file_path) = @_ ;
    
    return unless defined $file_path ;
    
    if ($error) {
        # restore backup and display error
        my $data = $self->{file_backup} || [];
        $logger->debug("Error during write, restoring backup in $file_path with ".scalar @$data." lines");
        $fh->seek(0,0) ; # go back to beginning of file
        $fh->print(@$data);
        $fh->close;
        $error->rethrow if ref ($error);
        die $error ;
    }

    $fh->close;
    
    # check file size and remove empty files
    unlink($file_path) if -z $file_path ;
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
    $logger->info( "Read cds data from $file_path");

    $self->node->load( step => [ $args{io_handle}->getlines ] ) ;
    return 1 ;
}

sub write_cds_file {
    my $self = shift;
    my %args = @_ ;
    my $file_path = $args{file_path} ;
    $logger->info("Write cds data to $file_path");

    my $dump = $self->node->dump_tree(skip_auto_write => 'cds_file', check => $args{check} ) ;
    $args{io_handle}->print( $dump ) ;
    return 1 ;
}

sub read_perl {
    my $self = shift;
    my %args = @_ ;

    my $file_path = $args{file_path} ;
    $logger->info("Read Perl data from $file_path");

    my $pdata = do $file_path || die "Cannot open $file_path:$!";
    $self->node->load_data( $pdata ) ;
    return 1 ;
}

sub write_perl {
    my $self = shift;
    my %args = @_ ;
    my $file_path = $args{file_path} ;
    $logger->info("Write perl data to $file_path");

    my $p_data = $self->node->dump_as_data(skip_auto_write => 'perl_file', check => $args{check} ) ;
    my $dumper = Data::Dumper->new([$p_data]) ;
    $dumper->Terse(1) ;

    $args{io_handle}->print( $dumper->Dump , ";\n");
    return 1 ;
}

1;

__END__

=head1 NAME

Config::Model::BackendMgr - Load configuration node on demand

=head1 SYNOPSIS

 # Use BackendMgr to write data in perl data file
 use Config::Model;
 use Log::Log4perl qw(:easy);
 Log::Log4perl->easy_init($WARN);

 # define configuration tree object
 my $model = Config::Model->new;
 $model->create_config_class(
    name    => "Foo",
    element => [
        [qw/foo bar/] => {
            type       => 'leaf',
            value_type => 'string'
        },
    ]
 ); 

 $model->create_config_class(
    name => "MyClass",

    # read_config spec is used by Config::Model::BackendMgr
    read_config => [
        {
            backend     => 'perl_file',
            config_dir  => '/tmp/',
            file        => 'my_class.pl',
            auto_create => 1,
        },
    ],
    
    element => [
        [qw/foo bar/] => {
            type       => 'leaf',
            value_type => 'string'
        },
        hash_of_nodes => {
            type       => 'hash',     # hash id
            index_type => 'string',
            cargo      => {
                type              => 'node',
                config_class_name => 'Foo'
            },
        },
    ],
 );

 my $inst = $model->node->instance( root_class_name => 'MyClass' );

 my $root = $inst->config_root;

 # put data
 my $step = 'foo=FOO hash_of_nodes:fr foo=bonjour -
   hash_of_nodes:en foo=hello ';
 $root->load( step => $step );

 $inst->write_back;

 # now look at file /tmp/my_class.pl

=head1 DESCRIPTION

This class provides a way to specify how to load or store
configuration data within the model (instead of writing dedicated perl
code).

With these specifications, all the configuration information is read
during creation of a node.

=begin comment

This feature is also useful if you want to read configuration class
declarations at run time. (For instance in a C</etc> directory like
C</etc/some_config.d>). In this case, each configuration class must
specify how to read and write configuration information.

Idea: sub-files name could be <instance>%<location>.cds

=end comment

This load/store can be done with different C<backend>:

=over

=item cds_file

Config dump string (cds) in a file. I.e. a string that describes the
content of a configuration tree is loaded from or saved in a text
file. See L<Config::Model::Dumper>.

=item ini_file

INI files (written with L<Config::Model::Backend::IniFile>. See limitations in 
L</"Limitations depending on storage">.

=item perl_file

Perl data structure (perl) in a file. See L<Config::Model::DumpAsData>
for details on the data structure.

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
information back.

=head2 Built-in backend

C<cds_file>, C<ini_file> and C<perl_file> backend must be specified with
mandatory C<config_dir> parameter. For instance:

   read_config  => { backend    => 'cds_file' , 
                     config_dir => '/etc/cfg_dir',
                     file       => 'cfg_file.cds', #optional
                   },

If C<file> is not specified, a file name will be constructed with
C<< <config_class_name>.<suffix> >> where suffix is C<pl> or C<ini> or C<cds>.


=head2 Plugin backend classes

A plugin backend class can also be specified with:

  read_config  => [ { backend    => 'foo' , 
                      config_dir => '/etc/cfg_dir'
                      file       => 'foo.conf', # optional
                    }
                  ]

In this case, this class will try to load C<Config::Model::Backend::Foo>.
(The class name is constructed with C<ucfirst($backend_name)>)

C<read_config> can also have custom parameters that will passed
verbatim to C<Config::Model::Backend::Foo> methods:

  read_config  => [ { backend    => 'foo' , 
                      config_dir => '/etc/cfg_dir',
                      my_param   => 'my_value',
                    } 
                  ]

This C<Config::Model::Backend::Foo> class is expected to provide the
following methods:

=over

=item new

with parameters:

 node => ref_to_config_model_node

C<new()> must return the newly created object

=item read

with parameters:

 %custom_parameters,      # model data
 root => $root_dir,       # mostly used for tests
 config_dir => $read_dir, # path below root
 file_path => $full_name, # full file name (root+path+file)
 io_handle => $io_file    # IO::File object
 check     => [ yes|no|skip] 

Must return 1 if the read was successful, 0 otherwise.

Following the C<my_param> example above, C<%custom_parameters> will contain 
C< ( 'my_param' , 'my_value' ) >, so C<read()> will also be called with
C<root>, C<config_dir>, C<file_path>, C<io_handle> B<and>
C<<  my_param   => 'my_value' >>.

=item write

with parameters:

 %$write,                     # model data
 auto_create => $auto_create, # from model
 backend     => $backend,     # backend name
 config_dir  => $write_dir,   # override from instance
 io_handle   => $fh,          # IO::File object
 write       => 1,            # always
 check       => [ yes|no|skip] ,
 root        => $root_dir,

Must return 1 if the write was successful, 0 otherwise

=back

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
directory can be hardcoded in the custom class. C<config_dir> beginning
with 'C<~>' will be munged so C<~> is replaced by C<< File::HomeDir->my_data >>.
See L<File::HomeDir> for details.

=item file

optional. This parameter may not apply if the configuration is stored
in several files. By default, the instance name is used as
configuration file name. 

=item function

Function name that will be called back to read the file. 
See L</"read callback"> for details. (default is C<read>)

=item auto_create

By default, an exception is thrown if no read was
successful. This behavior can be overridden by specifying 
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

Write specification is similar to read_specification. Except that the
default value for C<function> is C<write>. Here's an example:

   write_config  => [ { backend => 'cds_file', config_dir => '/etc/my_cfg/' } , 
                      { backend => 'custom', class => 'Bar' ,
                        function => 'my_write',
                      },
                    ],


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

First the C<cds> file whose name depend on the parameters used in model
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

By default, the specifications are tried in order, until the first succeeds.

When required by the user, all configuration information is written
back using B<all> the write specifications. See
L<Config::Model::Instance/write_back ( ... )> for details.

The write class declared with C<custom> backend must provide a call-back.
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
  io_handle  => $io           # IO::File object with binmode :utf8
  check      => [yes|no|skip]

The L<IO::File> object is undef if the file cannot be read.

The callback must return 0 on failure and 1 on successful read.

=head2 write callback

Write callback function will be called with these parameters:

  object      => $obj,         # Config::Model::Node object 
  root        => './my_test',  # fake root directory, userd for tests
  config_dir  => /etc/foo',    # absolute path 
  file        => 'foo.conf',   # file name
  file_path  => './my_test/etc/foo/foo.conf' 
  io_handle   => $io           # IO::File object opened in write mode 
                               # with binmode :utf8
  auto_create => 1             # create dir as needed
  check      => [yes|no|skip]

The L<IO::File> object is undef if the file cannot be written to.

The callback must return 0 on failure and 1 on successful write.

=head1 CAVEATS

When both C<config_dir> and C<file> are specified, this class will
write-open the configuration file (and thus clobber it) before calling
the C<write> call-back and pass the file handle with C<io_handle>
parameter. C<write> should use this handle to write data in the target
configuration file.

If this behavior causes problem (e.g. with augeas backend), the
solution is either to:

=over

=item *

Set C<file> to undef or an empty string in the C<write_config>
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
  write_config => [{ backend => 'cds_file', config_dir => '/etc/my_cfg/' }],


You can choose also to read and write only customized files:

  read_config  => [{ backend => 'custom', class => 'Bar'}],

Or to read and write only C<cds> files :

  read_config  => [{ backend => 'cds_file'}] ,

You can also specify more parameters that must be passed to your
custom class:

  read_config  => [{ backend => 'custom', class => 'Bar', 
                    config_dir => '/etc/foo'}],

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

  read_config  => [ { backend => 'custom',
                      class => 'Bar',
                      config_dir => '/etc/foo'
                  } ],

In this case, configuration data will be read by C<Bar::read> in
directory C</etc/foo> and will be written back there by C<Bar::write>.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Instance>,
L<Config::Model::Node>, L<Config::Model::Dumper>, L<Config::Augeas>

=cut

