
package Config::Model::Backend::Debian::DpkgSyntax ;

use Moose::Role ;

use Carp;
use Config::Model::Exception ;
use Log::Log4perl qw(get_logger :levels);

use base qw/Config::Model::Backend::Any/;


my $logger = get_logger("Backend::Debian::Dpkg") ;

sub parse_dpkg_file {
    my $self = shift ;
    my $fh = shift;
    my @res ; # list of list (section, [keyword, value])

    my $field;
    my $store_ref ;
    my $store_list = [] ;

    foreach (<$fh>) {
        if (/^([\w\-]+):/) {
            my ($field,$text) = split /\s*:\s*/,$_,2 ;

	    $text = "other\n" if $field =~ /license/i and $text =~ /^\s*$/;
	    push @$store_list, $field, $text ;
	    chomp $$store_ref if defined $$store_ref; # remove trailing \n 
	    $store_ref = \$store_list->[$#$store_list] ;
        }
        elsif (/^\s*$/) {
            push @res, $store_list ; 
            $store_list = [] ;
        }
        elsif (/^\s+\.$/) {
            $$store_ref .= "\n" ;
        }
        elsif (s/^\s//) {
            $$store_ref .= $_ ;
        }
        else {
            $logger->error("Invalid line: $_\n");
        }
    }

    # store last section if not empty
    push @res, $store_list if @$store_list;
    $fh->close ;

    if ($logger->is_debug ) {
        map { $logger->debug("Parse result section:\n'".join("','",@$_)."'") ;} @res ;
    }
    return \@res ;   
}

# input is [ section [ keyword => value | value_list ] ]
sub write_dpkg_file {
    my ($self, $ioh, $array_ref) = @_ ;

    map { $self->write_dpkg_section($ioh,$_) } @$array_ref ;
}

sub write_dpkg_section {
    my ($self, $ioh, $array_ref) = @_ ;

    my $i = 0;
    foreach (my $i=0; $i < @$array_ref; $i += 2 ) {
        my $name  = $array_ref->[$i] ;
        my $value = $array_ref->[$i + 1];
        my $label = "$name: " ;
        my $l = length ($label) ;
        if (ref ($value)) {
            $ioh -> print ($label.join( "\n". ' ' x $l , @$value ) . "\n");
        }
        else {
            $ioh->print ($label) ;
            $self->write_dpkg_text($ioh,$value) ;
        }
    }
    $ioh->print("\n");
}

sub write_dpkg_text {
     my ($self, $ioh, $text) = @_ ;

    return unless $text ;
    foreach (split /\n/,$text) {
        $ioh->print ( /\S/ ? " $_\n" : " .\n") ;
    }
}

1;

__END__

=head1 NAME

Config::Model::Backend::Debian::DpkgSyntax - Role to read and write files with Dpkg syntax

=head1 SYNOPSIS

  # in Dpkg decicated backend class
  

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with Debian Dep-5 syntax in
C<Config::Model> configuration tree. This syntax is used to specify 
license information in Debian source pacakge format.

=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => 'Debian::Dpkg::Copyright' ) ;

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
