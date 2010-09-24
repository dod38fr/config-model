
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
    foreach my $section (@$c) {
        for (my $i=0; $i < @$section ; $i += 2 ) {
            my $key = $section->[$i];
            my $v = $section->[$i+1];
            if ($key =~ /license/i) {
                my @lic_text = split /\n/,$v ;
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
    }

    $logger->info("Second pass to read other info from $args{file} control file");
    foreach my $section (@$c) {
        for (my $i=0; $i < @$section ; $i += 2 ) {
            my $key = $section->[$i];
            my $v = $section->[$i+1];
            $logger->info("reading key $key from $args{file} control file");
            $logger->debug("$key value: $v");
            if ($key =~ /files/i) {
                $file = $root->fetch_element('Files')->fetch_with_id($v) ;
                $object = $file ;
            }
            elsif ($key =~ /copyright/i) {
                my @v = split /\s*\n\s*/,$v ;
                $object->fetch_element('Copyright')->store_set(@v);
            }
            elsif ($key =~ /license/i and $object eq $root) {
                # skip license text stored in first pass
            }
            elsif ($key =~ /license/i) {
                $object = $file->fetch_element('License') ;
                my @lic_text = split /\n/,$v ;
                my $lic_line = shift @lic_text ;
                # too much hackish is bad for health
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
            else {
                # try anyway to trigger an error message
                $object->fetch_element($key)->store($v) ;
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

    # write in 2 passes to handle correctly sections
    foreach my $elt ($node->get_element_name ) {
        my $type = $node->element_type($elt) ;
        my $elt_obj = $node->fetch_element($elt) ;

        if ($type eq 'hash') {
            # handled in 2nd passes
            next ;
        }
        elsif ($type eq 'list') {
            my $label = "$elt: " ;
            my $l = length ($label) ;
            my @v = $elt_obj->fetch_all_values ;
            $ioh->print ("$label ".join( "\n". ' ' x $l , @v ) . "\n") if @v;
        }
        else {
            my $v = $node->fetch_element_value($elt) ;
            if ($v) {
                $ioh->print ("$elt:") ;
                $self->write_text($ioh,$v) ;
            }
        }
    }

    foreach my $elt ($node->get_element_name ) {
        my $type = $node->element_type($elt) ;
        my $elt_obj = $node->fetch_element($elt) ;

        if ($type eq 'hash') {
            $ioh->print ("\n") ; # blank line to separate sections
            $self->write_licenses($ioh,$elt_obj) if $elt eq 'License';
            $self->write_files($ioh,$elt_obj)    if $elt eq 'Files';
        }
    }
    
    return 1;
}

sub write_licenses {
    my ($self, $ioh, $hash_obj) = @_ ;
    foreach my $name ($hash_obj->get_all_indexes) {
        $ioh->print ("License: $name\n") ;
        $self->write_text($ioh,$hash_obj->fetch_with_id($name)->fetch) ;
        $ioh->print ("\n") ;
    }
}

sub write_files {
    my ($self, $ioh, $hash_obj) = @_ ;
    foreach my $name ($hash_obj->get_all_indexes) {
        $ioh->print ("Files: $name\n") ;
        $self->write_file($ioh,$hash_obj->fetch_with_id($name)) ;
    }
}


sub write_file {
    my ($self, $ioh, $node) = @_ ;
    my $label = "Copyright: " ;
    my $l = length ($label) ;
    my @c = $node -> fetch_element('Copyright') -> fetch_all_values ;
    $ioh -> print ("$label ".join( "\n". ' ' x $l , @c ) . "\n");
    $self->write_file_lic($ioh,$node->fetch_element('License')) ;
}

sub write_file_lic {
    my ($self, $ioh, $node) = @_ ;
    
    $ioh->print ("License: ".$node->fetch_element_value('abbrev')) ;
    my $exception = $node->fetch_element_value('exception') ;
    $ioh->print (" with $exception exception" )if defined $exception ;
    $ioh->print ("\n");

    $self->write_text($ioh,$node->fetch_element_value('full_license')) ;
}

sub write_text {
     my ($self, $ioh, $text) = @_ ;

    return unless $text ;
    foreach (split /\n/,$text) {
        $ioh->print ( /\S/ ? " $_\n" : " .\n") ;
    }
  
}

1;

__END__

=head1 NAME

Config::Model::Backend::Debian::Dep5 - Read and write Debian DEP-5 License information

=head1 SYNOPSIS

  # model declaration
  name => 'FooConfig',

  read_config  => [
                    { backend => 'Debian::Dep5' , 
                      config_dir => 'debian',
                      file  => 'copyright',      # optional
                      auto_create => 1,         # optional
                    }
                  ],

   element => ...
  ) ;


=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with Debian Dep-5 syntax in
C<Config::Model> configuration tree.

=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => 'Debian::Dep5' ) ;

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
