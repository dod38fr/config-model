
package Config::Model::Backend::Debian::Dpkg::Patch;

use Any::Moose;

extends 'Config::Model::Backend::Any';

with 'Config::Model::Backend::Debian::DpkgSyntax';

use Carp;
use Config::Model::Exception;
use Log::Log4perl qw(get_logger :levels);
use IO::File;

my $logger = get_logger("Backend::Debian::Dpkg::Patch");

sub suffix { return ''; }

sub read {
    my $self = shift;
    my %args = @_;

    # args is:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    # io_handle is not defined as no file is specified in model

    my $patch_dir = $args{root} . $args{config_dir};
    my $check     = $args{check};
    my $node      = $args{object};

    my $patch_name = $node->index_value;

    my $patch_file = "$patch_dir/$patch_name";
    $logger->info("Parsing patch $patch_file");
    my $patch_io = IO::File->new($patch_file)
      || Config::Model::Exception::Syntax->throw(
        message => "cannot read patch $patch_file" );

    my ( $header, $diff ) = ( [],[] );
    my $target = $header;
    foreach ( $patch_io->getlines ) {
        $target = $diff if /^---/;    # beginning of patch
        push @$target, $_;
    }
    chomp @$header;

    my $c = $self->parse_dpkg_lines($header,$check);
    Config::Model::Exception::Syntax->throw(
        message => "More than one section in $patch_name header" )
      if @$c > 1;

    my $section = $c->[0];
    foreach ( my $i = 0 ; $i < $#$section ; $i += 2 ) {
        my $key = $section->[$i];
        my $v   = $section->[ $i + 1 ];
        if ( my $found = $node->find_element( $key, case => 'any' ) ) {
            my @elt = ($found);
            my @v = ( $found eq 'Description' ) ? ( split /\n/, $v, 2 ) : ($v);
            unshift @elt, 'Synopsis' if $found eq 'Description';
            foreach (@elt) {
                my $sub_v = shift @v;
                $logger->debug("storing $_  value: $sub_v");
                $node->fetch_element($_)->store( value => $sub_v, check => $check );
            }
        }
    }

    $node->fetch_element('diff')->store(join('',@$diff));

    return 1;
}

#
# New subroutine "store_section_in_tree" extracted - Mon Jul  4 13:35:50 2011.
#
sub store_section_in_tree {
    my $self  = shift;
    my $node  = shift;
    my $check = shift;
    my $key   = shift;
    my $v     = shift;

    return unless defined $v;

    $logger->info( "reading key '$key' from Patch file (for node "
          . $node->location
          . ")" );
    my $elt_name = $logger->debug("$key value: $v");
    my $type     = $node->element_type($key);
    my $elt_obj  = $node->fetch_element( name => $key, check => $check );
    $v =~ s/^\s*\n//;
    chomp $v;

    if ( $type eq 'list' ) {
        my @v = split /[\s\n]*,[\s\n]*/, $v;
        chomp @v;
        $logger->debug( "list $key store set '" . join( "','", @v ) . "'" );
        $elt_obj->store_set( \@v, check => $check );
    }
    elsif ( my $found = $node->find_element( $key, case => 'any' ) ) {
        my @elt = ($found);
        my @v = ( $found eq 'Description' ) ? ( split /\n/, $v, 2 ) : ($v);
        unshift @elt, 'Synopsis' if $found eq 'Description';
        foreach (@elt) {
            my $sub_v = shift @v;
            $logger->debug("storing $_  value: $sub_v");
            $node->fetch_element($_)->store( value => $sub_v, check => $check );
        }
    }
    else {

        # try anyway to trigger an error message
        $node->fetch_element($key)->store( value => $v, check => $check );
    }
}

sub write {
    my $self = shift;
    my %args = @_;

    # args is:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object

    croak "Undefined file handle to write"
      unless defined $args{io_handle};

    my $node     = $args{object};
    my $ioh      = $args{io_handle};
    my @sections = [ $self->package_spec( $node->fetch_element('source') ) ];

    my $binary_hash = $node->fetch_element('binary');
    foreach my $binary_name ( $binary_hash->get_all_indexes ) {
        my $ref = [
            Package => $binary_name,
            $self->package_spec( $binary_hash->fetch_with_id($binary_name) )
        ];

        push @sections, $ref;
    }

    $self->write_dpkg_file( $ioh, \@sections, ",\n" );

    return 1;
}

sub package_spec {
    my ( $self, $node ) = @_;

    my @section;
    my $description_ref;
    foreach my $elt ( $node->get_element_name ) {
        my $type    = $node->element_type($elt);
        my $elt_obj = $node->fetch_element($elt);

        if ( $type eq 'hash' ) {
            die "package_spec: unexpected hash type in "
              . $node->name
              . " element $elt\n";
        }
        elsif ( $type eq 'list' ) {
            my @v = $elt_obj->fetch_all_values;
            push @section, $elt, \@v if @v;
        }
        elsif ( $elt eq 'Synopsis' ) {
            my $v = $node->fetch_element_value($elt);
            push @section, 'Description', $v;    # mandatory field
            $description_ref = \$section[$#section];
        }
        elsif ( $elt eq 'Description' ) {
            $$description_ref .=
              "\n" . $node->fetch_element_value($elt);    # mandatory field
        }
        else {
            my $v = $node->fetch_element_value($elt);
            push @section, $elt, $v if $v;
        }
    }
    return @section;
}

1;

__END__

=head1 NAME

Config::Model::Backend::Debian::Dpkg::Patch - Read and write Debian Dpkg Patch information

=head1 SYNOPSIS

No synopsis. This class is dedicated to configuration class C<Debian::Dpkg::Patch>

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of Debian C<Patch> file.

All C<Patch> files keyword are read in a case-insensitive manner.

=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => 'Debian::Dpkg::Patch' ) ;

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
