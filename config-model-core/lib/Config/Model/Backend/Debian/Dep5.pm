
package Config::Model::Backend::Debian::Dep5 ;

use Carp;
use strict;
use warnings ;
use Config::Model::Exception ;
use UNIVERSAL ;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

use base qw/Config::Model::Backend::Any/;


my $logger = get_logger("Backend::Debian::Dep5") ;

sub suffix { return '' ; }

sub parse {
    my $self = shift ;
    my $fh = shift;
    my @res ;

    my $field;
    my $store_ref ;

    foreach (<$fh>) {
        if (/^([\w\-]+):/) {
            my ($field,$text) = split /\s*:\s*/,$_,2 ;

	    $text = "other\n" if $field =~ /license/i and $text =~ /^\s*$/;
	    push @res, $field, $text ;
	    $store_ref = \$res[$#res] ;
        }
        elsif (s/^\s//) {
            $$store_ref .= $_ ;
        }
        else {
            $logger->error("Invalid line: $_\n");
        }
    }
    $fh->close ;

    $logger->debug("Parse result:\n'".join("','",@res)."'") ;
    chomp @res ;
    return \@res ;   
}

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
    my $c = $self -> parse ($args{io_handle}) ;
    
    my $root = $args{object} ;
    my $file;
    my $object = $root ;
    
    $logger->info("First pass to read license text from $args{file} control file");
    for (my $i=0; $i < @$c ; $i += 2 ) {
        my $key = $c->[$i];
        if ($key =~ /license/i) {
            my @lic_text = split /\n/,$c->[$i+1] ;
            my $lic_name = shift @lic_text ;
            $logger->debug("adding license text for $lic_name");
            next if $lic_name =~ /\s/ ; # complex license
            next unless @lic_text; # no text to store
            $logger->debug("adding license text '@lic_text'");
            my $lic_obj = $root->grab("License:$lic_name");
            # lic_obj may not be defined in -force mode
            $lic_obj->store(join("\n", @lic_text)) if defined $lic_obj ;
        }
    }

    $logger->info("Second pass to read other info from $args{file} control file");
    for (my $i=0; $i < @$c ; $i += 2 ) {
        my $key = $c->[$i];
        my $v = $c->[$i+1];
        $logger->info("reading key $key from $args{file} control file");
        $logger->debug("$key value: $v");
        if ($key =~ /files/i) {
            $file = $root->fetch_element('Files')->fetch_with_id($v) ;
            $object = $file ;
        }
        elsif ($key =~ /license/i and $object eq $root) {
            # skip license text stored in first pass
        }
        elsif ($key =~ /license/i) {
            $object = $file->fetch_element('License') ;
            my @lic_text = split /\n/,$v ;
            my $lic_line = shift @lic_text ;
            if ($lic_line =~ /with\s+(\w+)\s+exception/) {
                $object->fetch_element('exception')->store($1);
                $lic_line =~ s/\s+with\s+\w+\s+exception//;
            }
            $object->fetch_element('abbrev')->store($lic_line);
            $object = $root ;
        }
        elsif (my $found = $object->find_element($key, case => 'any')) { 
            $object->fetch_element($found)->store($v) ;
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

    my $perl_data = $self->{node}->dump_as_data() ;
    my $dpkgctrl = Dump $perl_data ;

    $args{io_handle} -> print ($dpkgctrl) ;

    return 1;
}

1;

__END__

=head1 NAME

Config::Model::Backend::Debian::Dep5 - Read and write Debian DEP-5 License information

=head1 SYNOPSIS

  # model declaration
  name => 'FooConfig',

  read_config  => [
                    { backend => 'dpkgctrl' , 
                      config_dir => '/etc/foo',
                      file  => 'foo.conf',      # optional
                      auto_create => 1,         # optional
                    }
                  ],

   element => ...
  ) ;


=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with dpkgctrl syntax in
C<Config::Model> configuration tree.

Note that undefined values are skipped for list element. I.e. if a
list element contains C<('a',undef,'b')>, the data structure will
contain C<'a','b'>.


=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => 'dpkgctrl' ) ;

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
