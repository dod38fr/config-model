
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

    $logger->info("Parsing control file");
    # load dpkgctrl file
    my $c = $self -> parse_dpkg_file ($args{io_handle}) ;
    
    my $root = $args{object} ;
    my $file;
    
    $logger->debug("Reading control source info");

    # first section is source package, following sections are binary package
    my $node = $root->fetch_element('source') ;
    $self->read_section ($node, shift @$c);

    $logger->debug("Reading binary package names");
    # we assume that package name is the first item in the section data
    
    while (my $section = shift @$c ) {
        my $package_name;
        foreach (my $i = 0; $i < $#$section; $i += 2) {
            next unless $section->[$i] =~ /^package$/i;
            $package_name = $section->[$i+1 ];
            splice @$section,$i,2 ;
            last ;
        }
        
        if (not defined $package_name) {
            my $msg = "Cannot find package_name in section @$section";
            Config::Model::Exception::User
	    -> throw (object => $root,  error => $msg) ;
        } 
        
        $node = $root->grab("binary:$package_name") ;
        $self->read_section ($node, $section);
    }

    return 1 ;
}

#
# New subroutine "read_section" extracted - Tue Sep 28 17:19:44 2010.
#
sub read_section {
    my $self = shift ;
    my $node = shift;
    my $section = shift;

    for (my $i=0; $i < @$section ; $i += 2 ) {
        my $key = $section->[$i];
        my $v = $section->[$i+1];
        $logger->info("reading key '$key' from control file (for node " .$node->location.")");
        $logger->debug("$key value: $v");
        my $type = $node->element_type($key) ;
        my $elt_obj = $node->fetch_element($key) ;

        if ($type eq 'list') {
            my @v = split /[\s\n]*,[\s\n]*/, $v ;
            $elt_obj->store_set(@v) ;
        }
        elsif (my $found = $node->find_element($key, case => 'any')) { 
            $logger->debug("found $key value: $v");
            $node->fetch_element($found)->store($v) ;
        }
        else {
            # try anyway to trigger an error message
            $node->fetch_element($key)->store($v) ;
        }
    }
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
    my $ioh  = $args{io_handle} ;
    my @sections = [ $self-> package_spec($node->fetch_element('source')) ];

    my $binary_hash = $node->fetch_element('binary') ;
    foreach my $binary_name ( $binary_hash -> get_all_indexes ) {
        my $ref = [ Package => $binary_name ,
                    $self->package_spec($binary_hash->fetch_with_id($binary_name)) ];
        
        push @sections, $ref ;
    }

    $self->write_dpkg_file($ioh, \@sections,",\n" ) ;
    
    return 1;
}

sub package_spec {
    my ( $self, $node ) = @_ ;

    my @section ;
    foreach my $elt ($node->get_element_name ) {
        my $type = $node->element_type($elt) ;
        my $elt_obj = $node->fetch_element($elt) ;

        if ($type eq 'hash') {
            die "package_spec: unexpected hash type in ".$node->name." element $elt\n" ;
        }
        elsif ($type eq 'list') {
            my @v = $elt_obj->fetch_all_values ;
            push @section, $elt , \@v if @v;
        }
        else {
            my $v = $node->fetch_element_value($elt) ;
            push @section, $elt , $v if $v ;
        }
    }
    return @section ;
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
