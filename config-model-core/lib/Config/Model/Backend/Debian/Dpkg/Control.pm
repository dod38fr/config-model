
package Config::Model::Backend::Debian::Dpkg::Control ;

use Moose ;

extends 'Config::Model::Backend::Any';

with 'Config::Model::Backend::Debian::DpkgSyntax';

use Carp;
use Config::Model::Exception ;
use File::Path;
use Log::Log4perl qw(get_logger :levels);



my $logger = get_logger("Backend::Debian::Dpkg::Control") ;

sub suffix { return '' ; }

sub read {
    my $self = shift ;
    my %args = @_ ;

    # args is:
    # object     => $obj,         # Config::Model::Node object 
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path 
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf' 
    # io_handle  => $io           # IO::File object

    return 0 unless defined $args{io_handle} ;

    $logger->info("Parsing $args{file} control file");
    # load dpkgctrl file
    my $c = $self -> parse_dpkg_file ($args{io_handle}) ;
    
    my $root = $args{object} ;
    my $file;
    my $object = $root ;
    
    $logger->info("Read info from $args{file} control file");
    # first section is source package, following sections are binary package
    my @section_nodes = map { $root->fetch_element($_); } qw/source binary/ ;
    my $node ;
    
    foreach my $section (@$c) {
        $node = shift @section_nodes if @section_nodes ;

        for (my $i=0; $i < @$section ; $i += 2 ) {
            my $key = $section->[$i];
            my $v = $section->[$i+1];
            $logger->info("reading key '$key' from $args{file} control file");
            $logger->debug("$key value: $v");
            if (my $found = $object->find_element($key, case => 'any')) { 
                $node->fetch_element($found)->store($v) ;
            }
            else {
                # try anyway to trigger an error message
                $node->fetch_element($key)->store($v) ;
            }
        }
    }

    return 1 ;
}

sub write {
    my $self = shift ;
    my %args = @_ ;

    # args is:
    # object     => $obj,         # Config::Model::Node object 
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path 
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf' 
    # io_handle  => $io           # IO::File object

    croak "Undefined file handle to write"
      unless defined $args{io_handle} ;

    my $node = $args{object} ;
    my $ioh = $args{io_handle} ;
    my @section1 ;

    # handle data in 2 passes to handle correctly sections
    # here, we fill first section
    foreach my $elt ($node->get_element_name ) {
        my $type = $node->element_type($elt) ;
        my $elt_obj = $node->fetch_element($elt) ;

        if ($type eq 'hash') {
            # handled in 2nd passes
            next ;
        }
        elsif ($type eq 'list') {
            my @v = $elt_obj->fetch_all_values ;
            push @section1, $elt , \@v if @v;
        }
        else {
            my $v = $node->fetch_element_value($elt) ;
            push @section1, $elt , $v if $v ;
        }
    }

    my @sections = (\@section1) ;
    foreach my $elt ($node->get_element_name ) {
        my $type = $node->element_type($elt) ;
        my $elt_obj = $node->fetch_element($elt) ;

        if ($type eq 'hash') {
            push @sections, $self->licenses($ioh,$elt_obj) if $elt eq 'License';
            push @sections, $self->files($ioh,$elt_obj)    if $elt eq 'Files';
        }
    }

    $self->write_dpkg_file($ioh, \@sections ) ;
    
    return 1;
}

sub licenses {
    my ($self, $ioh, $hash_obj) = @_ ;

    my @res ;
    foreach my $name ($hash_obj->get_all_indexes) {
        my @lic_section = qw/License/;
        push @lic_section , "$name\n" . $hash_obj->fetch_with_id($name)->fetch ;
        push @res, \@lic_section ;
    }
    return @res ;
}

sub files {
    my ($self, $ioh, $hash_obj) = @_ ;

    my @res ;
    foreach my $name ($hash_obj->get_all_indexes) {
        my @file_section = (Files => $name );

        my $node = $hash_obj->fetch_with_id($name) ;
        push @file_section, 'Copyright', [ $node -> fetch_element('Copyright') -> fetch_all_values ] ;
        
        my $lic_node = $node -> fetch_element('License') ;
        my $lic_text = $lic_node->fetch_element_value('abbrev') ;
        my $exception = $lic_node->fetch_element_value('exception') ;
        $lic_text .= " with $exception exception" if defined $exception ;
        
        my $full_lic_text = $lic_node->fetch_element_value('full_license') ;
        $lic_text .= $full_lic_text if defined $full_lic_text ;
        push @file_section, License => $lic_text ;

        push @res, \@file_section ;
    }
    return @res ;
}


1;

__END__

=head1 NAME

Config::Model::Backend::Debian::Dpkg::Control - Read and write Debian Dpkg control information

=head1 SYNOPSIS

  # model declaration
  name => 'FooConfig',

  read_config  => [
                    { backend => 'Debian::Dpkg::Control' , 
                      config_dir => 'debian',
                      file  => 'control',      # optional
                      auto_create => 1,         # optional
                    }
                  ],

   element => ...
  ) ;


=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with Debian Dpkg syntax in
C<Config::Model> configuration tree. This syntax is used to specify 
license information in Debian source package format.

=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => 'Debian::Dpkg::Control' ) ;

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
