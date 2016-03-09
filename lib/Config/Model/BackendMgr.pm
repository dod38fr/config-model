package Config::Model::BackendMgr;

use Mouse;

use Carp;
use 5.10.1;

use Config::Model::Exception;
use Data::Dumper;
use File::Path;
use File::Copy;
use File::HomeDir;
use IO::File;
use Storable qw/dclone/;
use Scalar::Util qw/weaken/;
use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger('BackendMgr');

# used only for tests
my $__test_home = '';
sub _set_test_home { $__test_home = shift; }

# one BackendMgr per file

has 'node' => (
    is       => 'ro',
    isa      => 'Config::Model::Node',
    weak_ref => 1,
    required => 1
);
has 'file_backup' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'backend' => (
    is      => 'rw',
    isa     => 'HashRef[Config::Model::Backend::Any]',
    traits  => ['Hash'],
    default => sub { {} },
    handles => { set_backend => 'set', get_backend => 'get' } );

# Configuration directory where to read and write files. This value
# does not override the configuration directory specified in the model
# data passed to read and write functions.
has config_dir => ( is => 'ro', isa => 'Maybe[Str]', required => 0 );

has support_annotation => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

sub get_tuned_config_dir {
    my ($self, %args) = @_;

    my $dir = $args{os_config_dir}{$^O} || $args{config_dir} || $self->config_dir || '';
    if ( $dir =~ /^~/ ) {
        my $home = $__test_home || File::HomeDir->my_home;
        $dir =~ s/^~/$home/;
    }

    $dir .= '/' if $dir and $dir !~ m(/$);

    return $dir;
}

sub get_cfg_dir_path {
    my $self = shift;
    my %args = @_;

    my $w = $args{write} || 0;
    my $dir = $self->get_tuned_config_dir(%args);

    $dir = $args{root} . $dir;

    if ( not -d $dir and $w and $args{auto_create} ) {
        $logger->info("creating directory $dir");
        mkpath( $dir, 0, 0755 );
    }

    unless ( -d $dir ) {
        $logger->info( "auto_" . ( $w ? 'write' : 'read' ) . " $args{backend} no directory $dir" );
        return ( 0, $dir );
    }

    $logger->debug( "dir: " . $dir // '<undef>' );

    return ( 1, $dir );
}

sub get_cfg_file_path {
    my $self = shift;
    my %args = @_;

    my $w = $args{write} || 0;

    # config file override
    my $cfo = $args{config_file};

    if ( defined $cfo and $cfo eq '-' and $w == 0 ) {
        $logger->trace("auto_read: $args{backend} override target file is STDIN");
        return ( 1, '-' );
    }

    if ( defined $cfo ) {
        my $override = $args{root} . $args{config_file};
        $logger->trace( "auto_"
                . ( $w ? 'write' : 'read' )
                . " $args{backend} override target file is $override" );
        return ( 1, $args{root} . $args{config_file} );
    }

    Config::Model::Exception::Model->throw(
        error  => "backend error: empty 'config_dir' parameter (and no config_file override)",
        object => $self->node
    ) unless $args{config_dir} or $self->config_dir;

    my ( $dir_ok, $dir ) = $self->get_cfg_dir_path(%args);

    if ( defined $args{file} ) {
        my $file = $args{file};
        $file =~ s/&index/$self->node->index_value/eg;
        my $res = $dir . $file;
        $logger->trace("get_cfg_file_path: returns $res");
        return ( $dir_ok, $res );
    }

    if ( not defined $args{suffix} ) {
        $logger->trace("get_cfg_file_path: returns undef (no suffix, no file argument)");
        return (0);
    }

    my $i    = $self->node->instance;
    my $name = $dir . $i->name;

    # append ":foo bar" if not root object
    my $loc = $self->node->location;    # not very good
    if ($loc) {
        if ( ( $w and not -d $name and $args{auto_create} ) ) {
            $logger->info( "get_cfg_file_path: auto_write create subdirectory ",
                "$name (location $loc)" );
            mkpath( $name, 0, 0755 );
        }
        $name .= '/' . $loc;
    }

    $name .= $args{suffix};

    $logger->trace( "get_cfg_file_path: auto_"
            . ( $w ? 'write' : 'read' )
            . " $args{backend} target file is $name" );

    return ( 1, $name );
}

sub open_read_file {
    my $self = shift;
    my %args = @_;

    my ( $file_ok, $file_path ) = $self->get_cfg_file_path(%args);

    if ( $file_ok and $file_path eq '-' ) {
        my $io = IO::Handle->new();
        if ( $io->fdopen( fileno(STDIN), "r" ) ) {
            return ( 1, '-', $io );
        }
        else {
            return ( 0, '-' );
        }
    }

    # not very clean
    return ( 0, $file_path )
        if $args{backend} =~ /_file$/
        and ( not $file_ok or not -r $file_path );

    my $fh = new IO::File;
    if ( $file_ok and -e $file_path ) {
        $logger->debug("open_read_file: open $file_path for read");
        $fh->open($file_path);
        $fh->binmode(":utf8");

        # store a backup in memory in case there's a problem
        $self->file_backup( [ $fh->getlines ] );
        $fh->seek( 0, 0 );    # go back to beginning of file
        return ( 1, $file_path, $fh );
    }
    else {
        return ( 0, $file_path );
    }
}

# called at configuration node creation
#
# New subroutine "load_backend_class" extracted - Thu Aug 12 18:32:37 2010.
#
sub load_backend_class {
    my $backend  = shift;
    my $function = shift;

    $logger->debug("load_backend_class: called with backend $backend, function $function");
    my %c;

    my $k = "Config::Model::Backend::" . ucfirst($backend);
    my $f = $k . '.pm';
    $f =~ s!::!/!g;
    $c{$k} = $f;

    # try another class
    $k =~ s/_(\w)/uc($1)/ge;
    $f =~ s/_(\w)/uc($1)/ge;
    $c{$k} = $f;

    foreach my $c ( keys %c ) {
        if ( $c->can($function) ) {

            # no need to load class
            $logger->debug("load_backend_class: $c is already loaded (can $function)");
            return $c;
        }
    }

    # look for file to load
    my $class_to_load;
    foreach my $c ( keys %c ) {
        $logger->debug("load_backend_class: looking to load class $c");
        foreach my $prefix (@INC) {
            my $realfilename = "$prefix/$c{$c}";
            $class_to_load = $c if -f $realfilename;
        }
    }

    return unless defined $class_to_load;
    my $file_to_load = $c{$class_to_load};

    $logger->debug("load_backend_class: loading class $class_to_load, $file_to_load");
    eval { require $file_to_load; };

    if ($@) {
        die "Could not parse $file_to_load: $@\n";
    }
    return $class_to_load;
}

sub read_config_data {
    my ( $self, %args ) = @_;

    {
        no warnings 'uninitialized';
        $logger->debug( "called with ", join( ' ', %args ) );
    }

    my $readlist_orig        = delete $args{read_config};
    my $check                = delete $args{check};
    my $r_dir                = delete $args{read_config_dir};
    my $config_file_override = delete $args{config_file};
    my $auto_create_override = delete $args{auto_create};

    croak "unexpected args " . join( ' ', keys %args ) . "\n" if %args;

    # r_dir is obsolete
    if ( defined $r_dir ) {
        die $self->node->config_class_name, " : read_config_dir is obsolete\n";
    }

    my $readlist = dclone $readlist_orig ;

    my $instance = $self->node->instance();

    # root override is passed by the instance
    my $root_dir = $instance->read_root_dir || '';
    $root_dir .= '/' if ( $root_dir and $root_dir !~ m(/$) );

    croak "readlist must be array or hash ref\n"
        unless ref $readlist;

    my @list = ref $readlist eq 'ARRAY' ? @$readlist : ($readlist);
    my $pref_backend = $instance->backend || '';
    my $read_done    = 0;
    my $auto_create  = 0;
    my @tried;

    foreach my $read (@list) {
        warn $self->config_class_name, " deprecated 'syntax' parameter in backend\n"
            if defined $read->{syntax};
        my $backend = delete $read->{backend} || delete $read->{syntax} || 'custom';
        if ( $backend =~ /^(perl|ini|cds)$/ ) {
            warn $self->config_class_name,
                " deprecated  backend $backend. Should be '$ {backend}_file'\n";
            $backend .= "_file";
        }

        next if ( $pref_backend and $backend ne $pref_backend );

        if ( defined $read->{allow_empty} ) {
            warn "backend $backend: allow_empty is deprecated. Use auto_create";
            $auto_create ||= delete $read->{allow_empty};
        }

        $auto_create ||= delete $read->{auto_create} if defined $read->{auto_create};

        if ( $read->{default_layer} ) {
            $self->read_config_sub_layer( $read, $root_dir, $config_file_override, $check,
                $backend );
        }

        my ( $res, $file ) =
            $self->try_read_backend( $read, $root_dir, $config_file_override, $check, $backend );
        push @tried, $file;

        if ($res) {
            $read_done = 1;
            last;
        }
    }

    Config::Model::Exception::ConfigFile::Missing->throw(
        tried_files => \@tried,
        object      => $self->node,
        )
        unless $read_done
        or $auto_create_override
        or $auto_create;

}

sub read_config_sub_layer {
    my ( $self, $read, $root_dir, $config_file_override, $check, $backend ) = @_;

    my $layered_config = delete $read->{default_layer};
    my $layered_read   = dclone $read ;

    map { my $lc = delete $layered_config->{$_}; $layered_read->{$_} = $lc if $lc; }
        qw/file config_dir os_config_dir/;

    Config::Model::Exception::Model->throw(
        error => "backend error: unexpected default_layer parameters: "
            . join( ' ', keys %$layered_config ),
        object => $self->node,
    ) if %$layered_config;

    my $i                  = $self->node->instance;
    my $already_in_layered = $i->layered;

    # layered stuff here
    if ( not $already_in_layered ) {
        $i->layered_clear;
        $i->layered_start;
    }

    $self->try_read_backend( $layered_read, $root_dir, $config_file_override, $check, $backend );

    if ( not $already_in_layered ) {
        $i->layered_stop;
    }
}

# called at configuration node creation, NOT when writing
#
# New subroutine "try_read_backend" extracted - Sun Jul 14 11:52:58 2013.
#
sub try_read_backend {
    my $self                 = shift;
    my $read                 = shift;
    my $root_dir             = shift;
    my $config_file_override = shift;
    my $check                = shift;
    my $backend              = shift;

    my $read_dir = $self->get_tuned_config_dir(%$read);

    my @read_args = (
        %$read,
        root        => $root_dir,
        config_dir  => $read_dir,
        backend     => $backend,
        check       => $check,
        config_file => $config_file_override
    );

    my ( $file_ok, $res, $fh, $file_path );

    if ( $backend eq 'custom' ) {
        my $c = my $file = delete $read->{class};
        $file =~ s!::!/!g;
        my $f = delete $read->{function} || 'read';
        require $file . '.pm' unless $c->can($f);
        no strict 'refs';

        $logger->info("Read with custom backend $ {c}::$f in dir $read_dir");

        ( $file_ok, $file_path, $fh ) = $self->open_read_file(@read_args);
        eval {
            $res = &{ $c . '::' . $f }(
                @read_args,
                file_path => $file_path,
                io_handle => $fh,
                object    => $self->node
            );
        };
    }
    elsif ( $backend eq 'perl_file' ) {
        ( $file_ok, $file_path, $fh ) = $self->open_read_file( @read_args, suffix => '.pl' );
        return ( 0, $file_path ) unless $file_ok;
        eval { $res = $self->read_perl( @read_args, file_path => $file_path, io_handle => $fh ); };
    }
    elsif ( $backend eq 'cds_file' ) {
        ( $file_ok, $file_path, $fh ) = $self->open_read_file( @read_args, suffix => '.cds' );
        return ( 0, $file_path ) unless $file_ok;
        eval {
            $res = $self->read_cds_file(
                @read_args,
                file_path => $file_path,
                io_handle => $fh,
            );
        };
    }
    else {
        # try to load a specific Backend class
        my $f = delete $read->{function} || 'read';
        my $c = load_backend_class( $backend, $f );
        return ( 0, 'unknown' ) unless defined $c;

        no strict 'refs';
        my $backend_obj = $c->new( node => $self->node, name => $backend );
        $self->set_backend( $backend => $backend_obj );
        my $suffix;
        $suffix = $backend_obj->suffix if $backend_obj->can('suffix');
        ( $file_ok, $file_path, $fh ) = $self->open_read_file( @read_args, suffix => $suffix );
        if ($logger->is_info) {
            my $fp = defined $file_path ? " on $file_path":'' ;
            $logger->info( "Read with $backend " . $c . "::$f".$fp);
        }

        eval {
            $res = $backend_obj->$f(
                @read_args,
                file_path => $file_path,
                io_handle => $fh,
                object    => $self->node,
            );
        };

        # only backend based on C::M::Backend::Any can support annotations
        if ($backend_obj->can('annotation')) {
            $self->{support_annotation} ||= $backend_obj->annotation ;
        }

    }

    # catch eval errors done in the if-then-else block before
    my $e = $@;
    if ( ref($e) and $e->isa('Config::Model::Exception::Syntax') ) {

        $e->parsed_file( $file_path) unless $e->parsed_file;
        $e->rethrow;
    }
    elsif ( ref $e ) {
        $e->rethrow ;
    }
    elsif ( $e ) {
        die "Backend error: $e";
    }

    return ( $res, $file_path );
}

sub auto_write_init {
    my ( $self, %args ) = @_;
    my $wrlist_orig = delete $args{write_config};
    my $w_dir       = delete $args{write_config_dir};

    weaken($self);    # avoid leak: $self is stored in write_back closure

    croak "auto_write_init: unexpected args " . join( ' ', keys %args ) . "\n"
        if %args;

    # w_dir is obsolete
    if ( defined $w_dir ) {
        die $self->config_class_name, " : write_config_dir is obsolete\n";
    }

    my $wrlist = dclone $wrlist_orig ;

    my $instance = $self->node->instance();

    # root override is passed by the instance
    my $root_dir = $instance->write_root_dir || '';

    my @array = ref $wrlist eq 'ARRAY' ? @$wrlist : ($wrlist);

    # ensure that one auto_create specified applies to all wr backends
    my $auto_create = 0;
    foreach my $write (@array) {
        $auto_create ||= delete $write->{auto_create}
            if defined $write->{auto_create};
    }

    # provide a proper write back function
    foreach my $write (@array) {
        warn $self->config_class_name, " deprecated 'syntax' parameter in auto_write\n"
            if defined $write->{syntax};
        my $backend = delete $write->{backend} || delete $write->{syntax} || 'custom';
        if ( $backend =~ /^(perl|ini|cds)$/ ) {
            warn $self->config_class_name,
                " deprecated backend $backend. Should be '$ {backend}_file'\n";
            $backend .= "_file";
        }

        my $write_dir = $self->get_tuned_config_dir(%$write);

        $logger->debug( "auto_write_init creating write cb ($backend) for ", $self->node->name );

        my @wr_args = (
            %$write,    # model data
            auto_create => $auto_create,
            backend     => $backend,
            config_dir  => $write_dir,     # override from instance
            write       => 1,              # for get_cfg_file_path
            root        => $root_dir,      # override from instance
        );

        my $wb;
        if ( $backend eq 'custom' ) {
            my $c = my $file = $write->{class};
            $file =~ s!::!/!g;
            my $f = $write->{function} || 'write';
            require $file . '.pm' unless $c->can($f);

            $wb = sub {
                no strict 'refs';
                $logger->debug( "write cb ($backend) called for ", $self->node->name );
                my ( $file_ok, $file_path, $fh ) =
                    $self->open_file_to_write( $backend, @wr_args, @_ )
                    unless ( $c->can('skip_open') and $c->skip_open );
                my $res;
                $res = eval {

                    # override needed for "save as" button
                    &{ $c . '::' . $f }(
                        @wr_args,
                        io_handle => $fh,
                        file_path => $file_path,
                        conf_dir  => $write_dir,    # legacy FIXME
                        object    => $self->node,
                        @_                          # override from user
                    );
                };
                $logger->warn( "write backend $c" . '::' . "$f failed: $@" ) if $@;
                $self->close_file_to_write( $@, $fh, $file_path );
                return defined $res ? $res : $@ ? 0 : 1;
            };
            $self->{auto_write}{custom} = 1;
        }
        elsif ( $backend eq 'perl_file' ) {
            $wb = sub {
                $logger->debug( "write cb ($backend) called for ", $self->node->name );
                my ( $file_ok, $file_path, $fh ) =
                    $self->open_file_to_write( $backend, suffix => '.pl', @wr_args, @_ );
                my $res;
                $res = eval {
                    $self->write_perl( @wr_args, io_handle => $fh, file_path => $file_path, @_ );
                };
                $self->close_file_to_write( $@, $fh, $file_path );
                $logger->warn("write backend $backend failed: $@") if $@;
                return defined $res ? $res : $@ ? 0 : 1;
            };
            $self->{auto_write}{perl_file} = 1;
        }
        elsif ( $backend eq 'cds_file' ) {
            $wb = sub {
                $logger->debug( "write cb ($backend) called for ", $self->node->name );
                my ( $file_ok, $file_path, $fh ) =
                    $self->open_file_to_write( $backend, suffix => '.cds', @wr_args, @_ );
                my $res;
                $res = eval {
                    $self->write_cds_file(
                        @wr_args,
                        io_handle => $fh,
                        file_path => $file_path,
                        @_
                    );
                };
                $logger->warn("write backend $backend failed: $@") if $@;
                $self->close_file_to_write( $@, $fh, $file_path );
                return defined $res ? $res : $@ ? 0 : 1;
            };
            $self->{auto_write}{cds_file} = 1;
        }
        else {
            my $f = $write->{function} || 'write';
            my $c = load_backend_class( $backend, $f );

            $wb = sub {
                no strict 'refs';
                $logger->debug( "write cb ($backend) called for ", $self->node->name );
                my $backend_obj = $self->get_backend($backend)
                    || $c->new( node => $self->node, name => $backend );
                my $suffix = $backend_obj->suffix if $backend_obj->can('suffix');
                my ( $file_ok, $file_path, $fh ) =
                    $self->open_file_to_write( $backend, suffix => $suffix, @wr_args, @_ )
                    unless ( $c->can('skip_open') and $c->skip_open );
                my $res = eval {

                    # override needed for "save as" button
                    $backend_obj->$f(
                        @wr_args,
                        io_handle => $fh,
                        file_path => $file_path,
                        object    => $self->node,
                        @_    # override from user
                    );
                };
                $logger->warn( "write backend $backend $c" . '::' . "$f failed: $@" ) if $@;
                $self->close_file_to_write( $@, $fh, $file_path );

                if (defined $res and $res == 2) {
                    unlink($file_path);
                    return 1;
                }
                return defined $res ? $res : $@ ? 0 : 1;
            };
        }

        # FIXME: enhance write back mechanism so that different backend *and* different nodse
        # work as expected
        $logger->debug( "registering write $backend in node " . $self->node->name );
        push @{ $self->{write_back} }, [ $backend, $wb ];
        $instance->register_write_back( $self->node->location );
    }
}

sub write_back {
    my $self = shift;
    my %args = @_;

    my $force_backend = delete $args{backend} || '';

    croak "write_back: no subs registered in node", $self->node->location, ". cannot save data\n"
        unless @{ $self->{write_back} };

    my @backends = @{ $self->{write_back} };
    $logger->debug(
        "write_back called on node '",
        $self->node->name, "' for ", scalar @backends,
        " backends"
    );

    my $dir = $args{config_dir};
    mkpath( $dir, 0, 0755 ) if $dir and not -d $dir;

    foreach my $wb_info (@backends) {
        my ( $backend, $wb ) = @$wb_info;
        if (   not $force_backend
            or $force_backend eq $backend
            or $force_backend eq 'all' ) {

            # exit when write is successfull
            my $res = $wb->(%args);
            $logger->info( "write_back called with $backend backend, result is ",
                defined $res ? $res : '<undef>' );
            last if ( $res and not $force_backend );
        }
    }
    $logger->debug( "write_back on node '", $self->node->name, "' done" );
}

sub open_file_to_write {
    my ( $self, $backend, %args ) = @_;

    my $backup    = delete $args{backup};
    my $do_backup = defined $backup;
    $backup ||= 'old';    # use old only if defined
    $backup = '.' . $backup unless $backup =~ /^\./;

    my ( $file_ok, $file_path ) = $self->get_cfg_file_path(%args);

    if ( $file_ok and $file_path eq '-' ) {
        my $io = IO::Handle->new();
        if ( $io->fdopen( fileno(STDOUT), "w" ) ) {
            return ( 1, '-', $io );
        }
        else {
            return ( 0, '-' );
        }
    }
    elsif ($file_ok) {
        if ( $do_backup and -r $file_path ) {
            copy( $file_path, $file_path . $backup ) or die "Backup copy failed: $!";
        }
        $logger->debug("$backend backend opened file $file_path to write");
        my $fh = new IO::File;
        $fh->open("> $file_path") || die "Cannot open $file_path:$!";
        $fh->binmode(':utf8');
        return ( $file_ok, $file_path, $fh );
    }
    else {
        return ( 0, $file_path );
    }
}

sub close_file_to_write {
    my ( $self, $error, $fh, $file_path ) = @_;

    return unless defined $file_path;

    if ($error) {

        # restore backup and display error
        my $data = $self->file_backup;
        $logger->debug(
            "Error during write, restoring backup in $file_path with " . scalar @$data . " lines" );
        $fh->seek( 0, 0 );    # go back to beginning of file
        $fh->print(@$data);
        $fh->close;
        $error->rethrow if ref($error);
        die $error;
    }

    $fh->close;

    # check file size and remove empty files
    unlink($file_path) if -z $file_path;
}

sub is_auto_write_for_type {
    my $self = shift;
    my $type = shift;
    return $self->{auto_write}{$type} || 0;
}

sub read_cds_file {
    my $self = shift;
    my %args = @_;

    my $file_path = $args{file_path};
    $logger->info("Read cds data from $file_path");

    $self->node->load( step => [ $args{io_handle}->getlines ] );
    return 1;
}

sub write_cds_file {
    my $self      = shift;
    my %args      = @_;
    my $file_path = $args{file_path};
    $logger->info("Write cds data to $file_path");

    my $dump = $self->node->dump_tree( skip_auto_write => 'cds_file', check => $args{check} );
    $args{io_handle}->print($dump);
    return 1;
}

sub read_perl {
    my $self = shift;
    my %args = @_;

    my $file_path = $args{file_path};
    $logger->info("Read Perl data from $file_path");

    my $pdata = do $file_path || die "Cannot open $file_path:$!";
    $self->node->load_data($pdata);
    return 1;
}

sub write_perl {
    my $self      = shift;
    my %args      = @_;
    my $file_path = $args{file_path};
    $logger->info("Write perl data to $file_path");

    my $p_data = $self->node->dump_as_data( skip_auto_write => 'perl_file', check => $args{check} );
    my $dumper = Data::Dumper->new( [$p_data] );
    $dumper->Terse(1);

    $args{io_handle}->print( $dumper->Dump, ";\n" );
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Load configuration node on demand

__END__

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

=item IniFile

INI files (written with L<Config::Model::Backend::IniFile>. See limitations in 
L</"Limitations depending on storage">.

=item perl_file

Perl data structure (perl) in a file. See L<Config::Model::DumpAsData>
for details on the data structure.

=item custom

Any format when the user provides a dedicated class and function to
read and load the configuration tree.

=back

After loading the data, the object registers itself to the
instance. Then the user can call the C<write_back> method on the
instance (See L<Config::Model::Instance>) to store all configuration
information back.

=head2 Built-in backend

C<cds_file>, C<IniFile> and C<perl_file> backend must be specified with
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

This C<Config::Model::Backend::Foo> class must inherit
L<Config::Model::Backend::Any> and is expected to provide the
following methods:

=over

=item new

Mandatory parameters:

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
 backup      => [ undef || '' || suffix ] # backup strategy required by user

Must return 1 if the write was successful, 0 otherwise

If C<io_handle> is defined, the backup has already been done while
opening the config file. If C<io_handle> is not defined, there's not
enough information in the model to read the configuration file and
create the backup. Your write() method will have to do the backup
requested by user.

=back

=head2 Custom backend

Custom backend is provided to be backward compatible but should not be used
for new project. Using a plugin backend as described above is preferred.

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

=item os_config_dir

Specify alternate location of a configuration directory depending on the OS
(as returned by C<$^O>, see L<perlport/PLATFORMS>).
For instance:

 config_dir => '/etc/ssh',
 os_config_dir => { darwin => '/etc' }


=item file

optional. Configuration file. This parameter may not apply if the
configuration is stored in several files. By default, the instance name
is used as configuration file name.

=item default_layer

Optional. Specifies where to find a global configuration file that
specifies default values. For instance, this is used by OpenSSH to
specify a global configuration file (C</etc/ssh/ssh_config>) that is
overridden by user's file:


	'default_layer' => {
            os_config_dir => { 'darwin' => '/etc' },
            config_dir    => '/etc/ssh',
            file          => 'ssh_config'
        }

Only the 3 above parameters can be specified in C<default_layer>.

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
  root       => './my_test',  # fake root directory, used for tests
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
  root        => './my_test',  # fake root directory, used for tests
  config_dir  => /etc/foo',    # absolute path
  file        => 'foo.conf',   # file name
  file_path  => './my_test/etc/foo/foo.conf' 
  io_handle   => $io           # IO::File object opened in write mode 
                               # with binmode :utf8
  auto_create => 1             # create dir as needed
  check      => [yes|no|skip]

The L<IO::File> object is undef if the file cannot be written to.

The callback must return 0 on failure and 1 on successful write.

Configuration file will be deleted if callback returns 2.

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

=head1 Methods

=head2 write_back ( ... )

Try to run all subroutines registered by L<auto_write_init>
write the configuration information until one succeeds (returns
true).

You can specify here a pseudo root directory or another config
directory to write configuration data back with C<root> and
C<config_dir> parameters. This will override the model specifications.

You can force to use a backend by specifying C<< backend => xxx >>.
For instance, C<< backend => 'perl_file' >> or C<< backend => 'custom' >>.

You can force to use all backend to write the files by specifying
C<< backend => 'all' >>.

You can force a specific config file to write with
C<< config_file => 'foo/bar.conf' >>

C<write_back> will croak if no write call-back are known for this node.

=head2 support_annotation

Returns 1 if at least one of the backends support to read and write annotations
(aka comments) in the configuration file.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Instance>,
L<Config::Model::Node>, L<Config::Model::Dumper>

=cut

