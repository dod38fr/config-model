package Config::Model::Backend::Xorg ;
use Any::Moose ;
use Carp ;
use Log::Log4perl qw(get_logger :levels);
 
extends 'Config::Model::Backend::Any';

with 'Config::Model::Backend::Xorg::Read'; 
with 'Config::Model::Backend::Xorg::Write'; 

my $logger = get_logger("Backend::Xorg") ;

sub suffix { return 'conf' ; }

sub annotation { return 0 ;}


sub read {
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

    return 0 unless defined $args{io_handle} ; # no file to read
    my $check = $args{check} || 'yes' ;

    my @lines = $args{io_handle}->getlines ;

    my $idx = 0 ;
    # store also input line number
    map {s/#.*$//; s/^\s*//; s/\s+$//; $_ = [ "line ".$idx++ ,$_ ]} @lines ;
    my @raw_xorg_conf = grep { $_->[1] !~ /^\s*$/ ;} @lines;
    chomp @raw_xorg_conf ;

    #print Dumper(\@raw_xorg_conf); exit ;
    my $data = parse_raw_xorg(\@raw_xorg_conf) ;

    #return $data if $test ;
    #print Dumper($data); exit ;

    parse_all($data, $args{object}) ;
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

    my $a_ref = write_all( $args{object} ) ;
    $ioh->say( map {"$_\n"} @$a_ref )  ;
 
    return 1;
}

no Any::Moose ;
__PACKAGE__->meta->make_immutable ;

1;

__END__

=head1 NAME

Config::Model::Backend::Xorg - Read and write config from fstab file

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
