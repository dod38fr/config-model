package Config::Model::Backend::Fstab ;
use Moose ;
use Carp ;
use Log::Log4perl qw(get_logger :levels);
 
extends 'Config::Model::Backend::Any';

my $logger = get_logger("Backend::Fstab") ;


sub annotation { return 1 ;}

my %opt_r_translate 
  = (
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

    # try to get global comments (comments before a blank line)
    $self->read_global_comments($args{io_handle},'#') ;

    my @comments ;
    foreach ($args{io_handle}->getlines) {
        next if /^##/ ;		  # remove comments added by Config::Model
        chomp ;

        my ($data,$comment) = split /\s*#\s?/ ;

        push @comments, $comment        if defined $comment ;

        if (defined $data and $data ) {
            my ($device,$mount_point,$type,$options, $dump, $pass) = split /\s+/,$data ;

            my ($dev_name) = ($device =~ /(\w+)$/) ;
            my $label = $type eq 'swap' ? "swap-on-$dev_name" : $mount_point; 

            my $fs_obj = $self->node->fetch_element('fs')->fetch_with_id($label) ;

            if (@comments) {
                $logger->debug("Annotation: @comments\n");
                $fs_obj->annotation(join("\n",@comments));
            }

            my $load_line = "fs_vfstype=$type fs_spec=$device fs_file=$mount_point "
                          . "fs_freq=$dump fs_passno=$pass" ;
            $logger->debug("Loading:$load_line\n");
            $fs_obj->load(step => $load_line, check => $check) ;

            # now load fs options
            $logger->trace("fs_type $type options is $options");
            my @options = split /,/,$options ;
            map {
                $_ = $opt_r_translate{$_} if defined $opt_r_translate{$_};
                s/no(.*)/$1=0/ ;
                $_ .= '=1' unless /=/ ;
            } @options ;
            
            $logger->debug("Loading:@options");
            $fs_obj->fetch_element('fs_mntopts')->load (step => \@options, check => $check) ;

            @comments = () ;
        }
    }

    return 1 ;
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
    foreach my $elt ($node->get_element_name) {
        my $obj =  $node->fetch_element($elt) ;
        my $v = $node->grab_value($elt) ;

        # write some documentation in comments
        my $help = $node->get_help(summary => $elt);
        my $upstream_default = $obj -> fetch('upstream_default') ;
        $help .=" ($upstream_default)" if defined $upstream_default;
        $ioh->print("## $elt: $help\n") if $help;


        # write annotation
        my $note = $obj->annotation ;
        if ($note) {
            map { $ioh->print("# $_\n") } split /\n/,$note ;
        }

        # write value
        $ioh->print(qq!$elt="$v"\n!) if defined $v ;
        $ioh->print("\n") if defined $v or $help;
    }

    return 1;
}

no Moose ;
__PACKAGE__->meta->make_immutable ;

1;

__END__

=head1 NAME

Config::Model::Backend::ShellVar - Read and write config as a SHELLVAR data structure

=head1 SYNOPSIS

  # model declaration
  name => 'FooConfig',

  read_config  => [
                    { backend => 'shellvar' , 
                      config_dir => '/etc/foo',
                      file  => 'foo.conf',      # optional
                      auto_create => 1,         # optional
                    }
                  ],

   element => ...
  ) ;


=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with SHELLVAR syntax in
C<Config::Model> configuration tree.

Note that undefined values are skipped for list element. I.e. if a
list element contains C<('a',undef,'b')>, the data structure will
contain C<'a','b'>.


=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => 'shellvar' ) ;

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
used. This parameter must be L<IO::File> object alwritey opened for
write. 

C<write()> will return 1.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::AutoRead>, 
L<Config::Model::Backend::Any>, 

=cut
