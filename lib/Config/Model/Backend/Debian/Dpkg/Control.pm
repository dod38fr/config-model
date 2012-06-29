
package Config::Model::Backend::Debian::Dpkg::Control ;

use Any::Moose ;

extends 'Config::Model::Backend::Any';

with 'Config::Model::Backend::Debian::DpkgSyntax';

use Carp;
use Config::Model::Exception ;
use File::Path;
use Log::Log4perl qw(get_logger :levels);
use AnyEvent ;

my $logger = get_logger("Backend::Debian::Dpkg::Control") ;

has condvar => (is => 'ro', isa => 'Ref', writer => '_cv') ;

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
    # check      => yes|no|skip  

    return 0 unless defined $args{io_handle} ;

    $logger->info("Parsing $args{file_path}");
    # load dpkgctrl file
    my $c = $self -> parse_dpkg_file ($args{io_handle}, $args{check}, 1 ) ;
    
    my $root = $args{object} ;
    my $check = $args{check} ;
    my $file;
    
    $logger->debug("Reading control source info");

    $self->_cv( AnyEvent->condvar );
    $self->condvar->begin( sub { shift->send }) ; # make sure begin is called at least once

    # first section is source package, following sections are binary package
    my $node = $root->fetch_element(name => 'source', check => $check) ;
    $self->read_sections ($node, shift @$c, shift @$c, $check);

    $logger->debug("Reading binary package names");
    # we assume that package name is the first item in the section data
    
    
    while (@$c ) {
        my ($section_line,$section) = splice @$c,0,2 ;
        my $package_name;
        foreach (my $i = 0; $i < $#$section; $i += 2) {
            next unless $section->[$i] =~ /^package$/i;
            $package_name = $section->[ $i+1 ][0];
            splice @$section,$i,2 ;
            last ;
        }
        
        if (not defined $package_name) {
            my $msg = "Cannot find package_name in section beginning at line $section_line";
            Config::Model::Exception::Syntax
	    -> throw (object => $root,  error => $msg, parsed_line => $section_line) ;
        } 
        
        $node = $root->grab("binary:$package_name") ;
        $self->read_sections ($node, $section_line, $section, $args{check});
    }

    $self->condvar->end ; # matches the begin above

    $self->condvar->recv ;
    my $dump_to_check = $root->dump_tree(mode => 'full') ;
    
    return 1 ;
}

#
# New subroutine "read_section" extracted - Tue Sep 28 17:19:44 2010.
#
sub read_sections {
    my $self = shift ;
    my $node = shift;
    my $section_line = shift ;
    my $section = shift;
    my $check = shift || 'yes';

    my %sections ;
    for (my $i=0; $i < @$section ; $i += 2 ) {
        my $key = $section->[$i];
        my $lc_key = lc($key); # key are not key sensitive
        $sections{$lc_key} = [ $key , $section->[$i+1] ]; 
    }

    foreach my $key ($node->get_element_name) {
        my $ref = delete $sections{lc($key)} ;
        next unless defined $ref ;
        $self->store_section_in_tree ($node,$check, @$ref);
    }
    
    # leftover sections should be either accepted or rejected
    foreach my $lc_key (keys %sections) {
        my $ref = delete $sections{$lc_key} ;
        $self->store_section_in_tree ($node,$check, @$ref);
    }
}

#
# New subroutine "store_section_in_tree" extracted - Mon Jul  4 13:35:50 2011.
#
sub store_section_in_tree {
    my $self  = shift;
    my $node  = shift;
    my $check = shift;
    my $key   = shift;
    my $v_ref = shift;

    $logger->info( "reading key '$key' from control file (for node "
          . $node->location
          . ")" );

    my ($v,$l,$a,@c) = @$v_ref;

    $logger->debug("$key value: $v");
    my $type = $node->element_type($key);
    my $elt_obj = $node->fetch_element( name => $key, check => $check );

    $elt_obj->annotation(join("\n",@c)) if @c ;
    $elt_obj->notify_change(note => $a, really => 1) if $a ;

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
    foreach my $binary_name ( $binary_hash -> fetch_all_indexes ) {
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
    my $description_ref ;
    foreach my $elt ($node->get_element_name ) {
        my $type = $node->element_type($elt) ;
        my $elt_obj = $node->fetch_element($elt) ;

        my $c = $elt_obj->annotation ;
        push @section, map {'# '.$_} split /\n/,$c if $c ;

        if ($type eq 'hash') {
            die "package_spec: unexpected hash type in ".$node->name." element $elt\n" ;
        }
        elsif ($type eq 'list') {
            my @v = $elt_obj->fetch_all_values ;
            push @section, $elt , \@v if @v;
        }
        elsif ($elt eq 'Synopsis') {
            my $v = $node->fetch_element_value($elt) ;
            push @section, 'Description' , $v ; # mandatory field
            $description_ref = \$section[$#section] ;
        }
        elsif ($elt eq 'Description') {
            $$description_ref .= "\n".$node->fetch_element_value($elt) ; # mandatory field
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

No synopsis. This class is dedicated to configuration class C<Debian::Dpkg::Control>

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of Debian C<control> file.

All C<control> files keyword are read in a case-insensitive manner.

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
