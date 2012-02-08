package Config::Model::Backend::Debian::Dpkg;

use Carp;
use Any::Moose;
use Config::Model::Exception;
use UNIVERSAL;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

extends 'Config::Model::Backend::PlainFile';

my $logger = get_logger("Backend::Debian::Dpkg::Root");

sub read_hash {
    my ( $self, $obj, $elt, $file, $check, $args ) = @_;

    if ( $elt eq 'patches' ) {
        my $patch_dir = $args->{root} . $args->{config_dir} . "patches";
        $logger->info("Checking patches directory ($patch_dir)");

        $self->read_patch_series( $obj, $check, $patch_dir );
    }
    else {
        $self->SUPER::read_hash(@_);
    }
}

sub read_patch_series {
    my ( $self, $hash, $check, $patch_dir ) = @_;

    my $series_files = "$patch_dir/series";

    return unless -d $patch_dir;
    return unless -e $series_files;

    $logger->info("Opening file $series_files");
    my $ser_io = IO::File->new($series_files);

    unless ( defined $ser_io ) {
        my $msg = "Dpkg::Patch error, cannot read $series_files:$!";
        Config::Model::Exception::Syntax->throw( message => $msg )
          if $check eq 'yes';
        $logger->error($msg) if $check eq 'skip';
    }

    # trigger element creation to read patch file_path
    foreach my $pname ( $ser_io->getlines ) {
        chomp $pname;
        next unless $pname =~ /\w/;    # skip empty lines
        my $obj = $hash->fetch_with_id($pname);
        $obj->init;
        my $location = $obj->name;
        $logger->info("found patch $pname, stored in $location ($obj)");
    }

    $ser_io->close;
}

sub write {
    my $self = shift;
    my %args = @_;

    # args are:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path read
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    my $check = $args{check} || 'yes';
    my $dir = $args{root} . $args{config_dir};
    mkpath( $dir, { mode => 0755 } ) unless -d $dir;
    my $node = $args{object};
    $logger->debug( "Debian::Dpkg write called on node ", $node->name );

    # write data from leaf element from the node
    foreach my $elt ( $node->get_element_name() ) {
        my $file = $dir . $elt;

        my $obj = $args{object}->fetch_element( name => $elt );
        my $type = $obj->get_type;
        my @v;

        if ( $type eq 'leaf' ) {
            my $lv = $obj->fetch( check => $args{check} );
            if ( defined $lv ) {
                $lv .= "\n" unless $obj->value_type eq 'string';
                push @v, $lv;
            }
        }
        elsif ( $type eq 'list' ) {
            @v = map { "$_\n" } $obj->fetch_all_values;
        }
        else {
            $logger->debug("Debian::Dpkg write skipped $type $elt");
        }

        if (@v) {
            $logger->trace("Debian::Dpkg write opening $file to write");
            my $fh = new IO::File;
            $fh->open( $file, '>' ) or die "Cannot open $file:$!";
            $fh->binmode(":utf8");
            $fh->print(@v);
            $fh->close;
        }
    }

    return 1;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Config::Model::Backend::Debian::Dpkg - Read and write config as plain file

=head1 SYNOPSIS

 use Config::Model;
 use Log::Log4perl qw(:easy);
 Log::Log4perl->easy_init($WARN);

 my $model = Config::Model->new;

 my $inst = $model->create_config_class(
    name => "WithDebian::Dpkg",
    element => [ 
        [qw/source new/] => { qw/type leaf value_type uniline/ },
    ],
    read_config  => [ 
        { 
            backend => 'plain_file', 
            config_dir => '/tmp',
        },
    ],
 );
 
 my $inst = $model->instance(root_class_name => 'WithDebian::Dpkg' );
 my $root = $inst->config_root ;

 $root->load('source=foo new=yes' );

 $inst->write_back ;

Now C</tmp> directory will contain 2 files: C<source> and C<new> 
with C<foo> and C<yes> inside.

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written in several files. 
Each element of the node is written in a plain file.

This module supports currently only leaf and list elements.  
In the case of C<list> element, each line of the file is a value of the list.


=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => 'plain_file' ) ;

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
used. This parameter must be L<IO::File> object already opened for
write. 

C<write()> will return 1.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::AutoRead>, 
L<Config::Model::Backend::Any>, 

=cut
