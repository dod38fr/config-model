package Config::Model::Backend::Fstab ;
use Moose ;
use Carp ;
use Log::Log4perl qw(get_logger :levels);
 
extends 'Config::Model::Backend::Any';

my $logger = get_logger("Backend::Fstab") ;

sub suffix { return '' ; }

sub annotation { return 1 ;}

my %opt_r_translate = (
    ro => 'rw=0',
    rw => 'rw=1',
    bsddf => 'statfs_behavior=bsddf',
    minixdf => 'statfs_behavior=minixdf',
) ;

sub read {
    my $self = shift ;
    my %args = @_ ;

    # args are:
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path 
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf' 
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    return 0 unless defined $args{io_handle} ; # no file to read
    my $check = $args{check} || 'yes' ;

    my @lines = $args{io_handle}->getlines ;

    # try to get global comments (comments before a blank line)
    $self->read_global_comments(\@lines,'#') ;

    my @assoc = $self->associates_comments_with_data( \@lines, '#' );
    foreach my $item (@assoc) {
        my ( $data, $comment ) = @$item;
        $logger->trace("fstab read data '$data' comment '$comment'");

        my ( $device, $mount_point, $type, $options, $dump, $pass ) =
          split /\s+/, $data;

        my $swap_idx = 0;
        my $label = $device =~ /LABEL=(\w+)$/ ? $1
          : $type eq 'swap' ? "swap-" . $swap_idx++
          :                   $mount_point;

        my $fs_obj = $self->node->fetch_element('fs')->fetch_with_id($label);

        if ($comment) {
            $logger->debug("Annotation: $comment\n");
            $fs_obj->annotation($comment);
        }

        my $load_line = "fs_vfstype=$type fs_spec=$device fs_file=$mount_point "
          . "fs_freq=$dump fs_passno=$pass";
        $logger->debug("Loading:$load_line\n");
        $fs_obj->load( step => $load_line, check => $check );

        # now load fs options
        $logger->trace("fs_type $type options is $options");
        my @options = split /,/, $options;
        map {
            $_ = $opt_r_translate{$_} if defined $opt_r_translate{$_};
            s/no(.*)/$1=0/;
            $_ .= '=1' unless /=/;
        } @options;

        $logger->debug("Loading:@options");
        $fs_obj->fetch_element('fs_mntopts')
          ->load( step => "@options", check => $check );
    }
    return 1;
}

sub write {
    my $self = shift ;
    my %args = @_ ;

    # args are:
    # object     => $obj,         # Config::Model::Node object 
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path 
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf' 
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

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
    foreach my $line_obj ($node->fetch_element('fs')->fetch_all ) {
        # write line annotation
        my $note = $line_obj->annotation ;
        if ($note) {
            map { $ioh->print("\n# $_") } split /\n/,$note ;
            $ioh->print("\n");
        }

        $ioh->printf("%-30s %-25s %-6s %-10s %d %d\n",
                     map ($line_obj->fetch_element_value($_), qw/fs_spec fs_file fs_vfstype/),
                     $self->option_string($line_obj->fetch_element('fs_mntopts')) ,
                     map ($line_obj->fetch_element_value($_) , qw/fs_freq fs_passno/),
                    );
    }

    return 1;
}

my %rev_opt_r_translate = reverse %opt_r_translate ;

sub option_string {
    my ($self,$obj) = @_ ;
    
    my @options ;
    foreach my $opt ($obj->get_element_name ) {
        my $v = $obj->fetch_element_value($opt) ;
        next unless defined $v ;
        my $key = "$opt=$v" ;
        my $str = defined $rev_opt_r_translate{$key} ? $rev_opt_r_translate{$key} 
                : "$v" eq '0'                        ? 'no'.$opt 
                : "$v" eq '1'                        ? $opt 
                :                                      $key ;
        push @options , $str ;
    }
    
    return join',',@options ;
}

no Moose ;
__PACKAGE__->meta->make_immutable ;

1;

__END__

=head1 NAME

Config::Model::Backend::Fstab - Read and write config from fstab file

=head1 SYNOPSIS

No synopsis. This class is dedicated to configuration class C<Fstab>

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with C<fstab> syntax in
C<Config::Model> configuration tree. Typically this backend will 
be used to read and write C</etc/fstab>.

=head1 Comments in file_path

This backend is able to read and write comments in the C</etc/fstab> file.

=head1 STOP

The documentation below describes methods that are currently used only by 
L<Config::Model>. You don't need to read it to write a model.

=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => 'fstab' ) ;

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
