
package Config::Model::Backend::Debian::Dpkg::Copyright ;

use Any::Moose ;

extends 'Config::Model::Backend::Any';

with 'Config::Model::Backend::Debian::DpkgSyntax';

use Carp;
use Config::Model::Exception ;
use Config::Model::ObjTreeScanner ;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger("Backend::Debian::Dpkg::Copyright") ;

sub suffix { return '' ; }

my %store_dispath = (
    list    => \&_store_line_based_list,
    #string  => \&_store_line,
    string  => \&_store_text_no_synopsis,
    uniline => \&_store_line,
);

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

    my $check = $args{check} || 'yes';

    $logger->info("Parsing $args{file} control file");

    # load dpkgctrl file
    my $c = $self -> parse_dpkg_file ($args{io_handle}, $check) ;
    return 0 unless @$c ; # no sections in file
    
    my $root = $args{object} ;
    my $file;
    my %license_paragraph ;
    my @license_names ;
    my %file_paragraph ;
    my @file_names ;

    my @header = @{ shift @$c } ;

    my $section_nb = 1 ; # header was already done
    foreach my $section (@$c) {
        $section_nb ++ ;
        $logger->info("Classifying section $section_nb");
        my %h = @$section ;

        # normalise
        my %section = map { (lc($_),$h{$_}) ; } keys %h ;
        $logger->debug("section $section_nb keys: ".join(' ',keys %section)) ;

        if ( defined $section{copyright} and not defined $section{files}
             and not defined $file_paragraph{'*'} 
            ) {
            # Some legacy files can have a header and one paragraph with License tag
            # more often than not, this is an implied "File: *"  section
            my $str = "Missing 'Files:' specification in section $section_nb.";
            Config::Model::Exception::Syntax -> throw ( object => $self, error => $str ) 
                if $check eq 'yes' ;
            warn("$str Adding 'Files: *' spec\n") ;
            $section{files} = '*' ;
            # tell root node that read data was altered and needs to be written back
            $root->needs_save(1) ;
        }

        if (defined $section{licence}) {
            $logger->warn("Found UK spelling for license. It will be converted to US spellingLicense");
            $section{license} = delete $section{licence} ;
        } 

        if (defined $section{files}) {
            my $v = $section{files} ;
            $logger->debug("Found Files paragraph ($v)");
            $file_paragraph{$v} = $section ;
            push @file_names, $v ;
        }
        elsif (defined $section{license}) {
            my $v = $section{license} ;
            # need to extract license name from license text
            my ($lic_name) = ($v =~ /^(\S+)/) ;
            $lic_name = 'other' unless defined $lic_name ;
            $logger->debug("Found license paragraph for '$lic_name'");
            $license_paragraph{$lic_name} = $section ;
            push @license_names, $lic_name ;
        }
        else {
            my $str = "Unknow paragraph in section $section_nb. Is is a Files or a License section ?";
            Config::Model::Exception::Syntax -> throw ( object => $self, error => $str ) 
                if $check eq 'yes' ;
            $logger->warn("Dropping unknown paragraph from section $section_nb");
        }
    }
    
    $logger->info("First pass to read pure license sections from $args{file} control file");
    foreach my $lic_name (@license_names) {
        my $object = $root->grab(step => qq!License:"$lic_name"!, check => $check);

        my $section = $license_paragraph{$lic_name} ;
        for (my $i=0; $i < @$section ; $i += 2 ) {
            my $key = $section->[$i];
            my $v = $section->[$i+1];
            $logger->info("reading key $key from $args{file} control file for ".$object->name);
            $logger->debug("$key value: '$v'");
            
            if ($key =~ /licen[sc]e/i) {
                my @lic_text = split /\n/,$v ;
                my ($lic_name) = shift @lic_text ;
                # get rid of potential 'with XXX exception'
                $lic_name =~ s/\s+with\s+\w+\s+exception//g ;
                $logger->debug("adding license text for '$lic_name': '@lic_text'");

                # lic_obj may not be defined in -force mode
                next unless defined $object ;

                $object->fetch_element('text')->store(value => join("\n", @lic_text), check => $check) ;
            }
            else {
                # store other sections thanks to 'accept' clause
                $object->fetch_element($key)->store($v) ;
            }
        }
    }   

    $logger->info("Second pass to header section from $args{file} control file");
    my $object = $root ;
   
    for (my $i=0; $i < @header ; $i += 2 ) {
        my $key = $header[$i];
        my $v = $header[$i+1];

        $logger->info("reading key $key from header for ".$object->name);
        $logger->debug("$key value: '$v'");

        if ($key =~ /^licen[sc]e$/i) {
            $logger->warn("Found UK spelling for $key: $v. $key will be converted to License")
                if $key =~ /license/ ;
            my $lic_node = $root->fetch_element('Global-License') ;
            _store_file_license ($lic_node, $v ,$check);
        }
        elsif (my $found = $object->find_element($key, case => 'any')) { 
            my $target = $object->fetch_element($found) ;
            my $type = $target->get_type ;
            my $dispatcher = $type eq 'leaf' ? $target->value_type : $type ;
            my $f =  $store_dispath{$dispatcher} || die "unknown dispatcher for $key";
            $f->($target,$v,$check) ;
        }
        else {
            # try anyway to trigger an error message
            $object->fetch_element($key)->store($v) ;
        }
    }
    
    $logger->info("Third pass to read Files sections from $args{file} control file");
    foreach my $file_name (@file_names) {
        $logger->debug("Creating Files:'$file_name' element");
        my $object =  $root->fetch_element('Files')->fetch_with_id(index => $file_name, check => $check) ;
   
        my $section = $file_paragraph{$file_name} ;
        for (my $i=0; $i < @$section ; $i += 2 ) {
            my $key = $section->[$i];
            my $v = $section->[$i+1];
            #$v =~ s/^\s+//; # remove all leading spaces 
            $logger->info("reading key $key from file paragraph '$file_name' for ".$object->name);
            $logger->debug("$key value: '$v'");

            next if $key =~ /^files$/i; # already done just before this loop

            if ($key =~ /^licen[sc]e$/i) {
                $logger->warn("Found UK spelling for $key: $v. $key will be converted to License")
                    if $key =~ /license/ ;
                my $lic_node = $object->fetch_element('License') ;
                _store_file_license ($lic_node, $v ,$check);
            }
            elsif (my $found = $object->find_element($key, case => 'any')) { 
                my $target = $object->fetch_element($found) ;
                my $type = $target->get_type ;
                my $dispatcher = $type eq 'leaf' ? $target->value_type : $type ;
                my $f =  $store_dispath{$dispatcher} || die "unknown dispatcher for $key";
                $f->($target,$v,$check) ;
            }
            else {
                # try anyway to trigger an error message
                $object->fetch_element($key)->store($v) ;
            }
        }
    }

    return 1 ;
}

sub _store_line_based_list {
    my ($object,$v,$check) = @_ ;
    my @v = grep {length($_) } split /\s*\n\s*/,$v ;
    $logger->debug("_store_line_based_list with check $check on ".$object->name." = ('".join("','",@v),"')");
    $object->store_set(\@v, check => $check);
}

sub _store_text_no_synopsis {
    my ($object,$v,$check) = @_ ;
    #$v =~ s/^\s*\n// ;
    chomp $v ;
    $logger->debug("_store_text_no_synopsis with check $check on ".$object->name." = '$v'");
    $object->store(value => $v, check => $check) ; 
}

sub _store_line {
    my ($object,$v,$check) = @_ ;
    $v =~ s/^\s*\n// ; # remove leading blank line for uniline values
    chomp $v ;
    $logger->debug("_store_line with check $check ".$object->name." = $v");
    $object->store(value => $v, check => $check) ; 
}

sub _store_file_license {
    my ($lic_object, $v, $check) = @_ ;

    chomp $v ;
    $logger->debug("_store_file_license check $check called on ".$lic_object->name." = $v");
    my ( $lic_line, $lic_text ) = split /\n/, $v, 2 ;
    $lic_line =~ s/\s+$//;

    # too much hackish is bad for health
    if ( $lic_line =~ /with\s+(\w+)\s+exception/ ) {
        my $exception = $1;
        $lic_object->fetch_element('exception') -> store( value => $exception, check => $check );
        $lic_line =~ s/\s+with\s+\w+\s+exception//;
        $logger->debug("license exception: $exception");
    }
    
    $lic_line =~ s/\s*\|\s*/ or /g; # old way of expressing or condition
    $lic_line ||= 'other' ;
    $logger->debug("license abbrev: $lic_line");
    $logger->debug("license full_license: $lic_text") if $lic_text;
    
    $lic_object->fetch_element('full_license')
      ->store( value => $lic_text, check => $check )
      if $lic_text;
    
    $lic_object->fetch_element('short_name') ->store( value => $lic_line, check => $check );
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

    my $node = $args{object};
    my $ioh  = $args{io_handle};

    my $my_leaf_cb = sub {
        my ( $scanner, $data_ref, $node, $element_name, $key, $leaf_object ) =
          @_;
        my $v = $leaf_object->fetch;
        return unless length($v) ;
        $logger->debug("my_leaf_cb: on $element_name ". (defined $key ? " key $key ":'') . "value $v");
        my $prefix = defined $key ? "$key\n" : '' ;
        push @{$data_ref->{one}}, $element_name, $prefix.$v ;
    };

    my $my_string_cb = sub {
        my ( $scanner, $data_ref, $node, $element_name, $index, $leaf_object ) = @_;
        my $v = $leaf_object->fetch;
        return unless length($v) ;
        $logger->debug("my_string_cb: on $element_name value $v");
        push @{$data_ref->{one}}, $element_name, "\n$v";    # text without synopsis
    };

    my $my_list_element_cb = sub {
        my ( $scanner, $data_ref, $node, $element_name, @idx ) = @_;
        my @v = $node->fetch_element($element_name)->fetch_all_values;
        $logger->debug("my_list_element_cb: on $element_name value @v");
        push @{$data_ref->{one}}, $element_name, \@v if @v;
    };

    my $file_license_cb = sub {
        my ($scanner, $data_ref,$node,@element_list) = @_;

        # your custom code using $data_ref
        $logger->debug("file_license_cb called on ",$node->name);
        my $lic_text  = $node->fetch_element_value('short_name');
        my $exception = $node->fetch_element_value('exception');
        $lic_text .= " with $exception exception" if defined $exception;
        my $full_lic_text = $node->fetch_element_value('full_license');
        $lic_text .= "\n" . $full_lic_text if defined $full_lic_text;
        push @{$data_ref->{one}}, License => $lic_text if defined $lic_text;
    };

    my $global_license_cb = sub {
        my ($scanner, $data_ref,$node,@element_list) = @_;

        # your custom code using $data_ref
        $logger->debug("file_license_cb called on ",$node->name);
        my $lic_text  = $node->fetch_element_value('short_name');
        my $full_lic_text = $node->fetch_element_value('full_license');
        $lic_text .= "\n" . $full_lic_text if defined $full_lic_text;
        push @{$data_ref->{one}}, License => $lic_text if defined $lic_text;
    };

    my $license_spec_cb = sub {
        my ($scanner, $data_ref,$node,@element_list) = @_;

        $logger->debug("license_spec_cb called on ",$node->name);
        my @section = ( 'License' , $node->index_value."\n") ;

        # resume exploration
        my $local_data_ref = { one => \@section, all => $data_ref->{all} } ;
        foreach my $elt (@element_list) { 
            if ($elt eq 'text') {
                $section[1] .= $node->fetch_element_value($elt);
            }
            else {
                $scanner->scan_element($local_data_ref, $node,$elt);
            }
        }
        
        push @{$data_ref->{all}}, \@section;
    };

    my $file_cb = sub {
        my ($scanner, $data_ref,$node,@element_list) = @_;
        my @section = ( $node->element_name, $node->index_value );
        $logger->debug("file_cb called on ",$node->name);
        # resume exploration
        my $local_data_ref = { one => \@section, all => $data_ref->{all} } ;
        foreach (@element_list) { 
            $scanner->scan_element($local_data_ref, $node,$_);
        }
        push @{$data_ref->{all}}, \@section;
    };
    
    my $scan = Config::Model::ObjTreeScanner->new(
        experience      => 'master',              # consider all values
        leaf_cb         => $my_leaf_cb,
        #string_value_cb => $my_string_cb,
        list_element_cb => $my_list_element_cb,
        #hash_element_cb => $my_hash_element_cb,
        #node_element_cb => $my_node_element_cb,
        node_dispatch_cb => {
            'Debian::Dpkg::Copyright::FileLicense' => $file_license_cb ,
            'Debian::Dpkg::Copyright::GlobalLicense' => $global_license_cb ,
            'Debian::Dpkg::Copyright::LicenseSpec' => $license_spec_cb ,
            'Debian::Dpkg::Copyright::Content' => $file_cb,
        }
    );

    my @sections;
    my @section1 ;
    $scan->scan_node( { one => \@section1, all => \@sections } , $node );

    unshift @sections, \@section1 ;
    
    #use Data::Dumper ; print Dumper \@sections ; exit ;
    $self->write_dpkg_file( $ioh, \@sections, "\n" );

    return 1;
}


1;

__END__

=head1 NAME

Config::Model::Backend::Debian::Dpkg::Copyright - Read and write Debian Dpkg License information

=head1 SYNOPSIS

No synopsis. This class is dedicated to configuration class C<Debian::Dpkg::Copyright>

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with Debian C<Dep-5> syntax in
C<Config::Model> configuration tree. This syntax is used to specify 
license information in Debian source package format.

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
