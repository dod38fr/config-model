package Config::Model::Backend::Debian::DpkgSyntax ;

use Any::Moose '::Role' ;

use Carp;
use Config::Model::Exception ;
use Log::Log4perl qw(get_logger :levels);

use base qw/Config::Model::Backend::Any/;

my $logger = get_logger("Backend::Debian::DpkgSyntax") ;

sub parse_dpkg_file {
    my $self = shift ;
    my $fh = shift;
    my $check = shift || 'yes' ;
    my $comment_allowed = shift || 0 ;

    my @lines = $fh->getlines ;
    chomp @lines ;
    $fh->close ;
    
    $self->parse_dpkg_lines (\@lines, $check, $comment_allowed);
}

#
# New subroutine "parse_dpkg_lines" extracted - Tue Jul 19 17:47:58 2011.
#
sub parse_dpkg_lines {
    my ($self, $lines, $check, $comment_allowed) = @_ ;

    my $field;
    my $store_ref ;       # hold field data
    my @comments;         # hold comment data
    my $store_list = [] ; # holds sections

    my $key = '';
    my $line = 1 ;
    my $section_line = 1 ;
    
    # list of list ( $line_nb, section, ... ) wheere section is
    # [keyword, [ value, line_nb, altered , comment ] ])
    my @res ; 
    
    foreach (@$lines) {
        $logger->trace("Parsing line $line '$_'");
        if (/^#/) { # comment are always located before the keyword (hopefully)
            Config::Model::Exception::Syntax->throw (
                object => $self,
                parsed_line => $line,
                message => "Comments are not allowed",
            ) unless $comment_allowed;
            my $c = $_ ;
            $c =~ s/#\s// ;
            push @comments, $c ;
        }
        elsif (/^([\w\-]+)\s*:/) {  # keyword: 
            my ($field,$text) = split /\s*:\s*/,$_,2 ;
            $key = $field ;
            $logger->trace("line $line start new field $key with '$text'");

            # @$store_list will be used in a hash, where the $field is key
            # store value found, file line number, is value altered (used later, o for now)
            # and comments
            push @$store_list, $field, [ $text , $line, '', @comments ] ;
            @comments = () ;
            $store_ref = \$store_list->[$#$store_list][0] ;
        }
        elsif ($key and /^\s*$/) {     # first empty line after a section
            $logger->trace("empty line: starting new section");
            $key = '';
            push @res, $section_line, $store_list if @$store_list ; # don't store empty sections 
            $store_list = [] ;
            $section_line = $line + 1; # next line, will be clobbered if next line is empty
	    chomp $$store_ref if defined $$store_ref; # remove trailing \n 
            undef $store_ref ; # to ensure that next line contains a keyword
        }
        elsif (/^\s*$/) {     # "extra" empty line
            $logger->trace("extra empty line: skipped");
            # just skip it
        } 
        elsif (/^\s+\.$/) {   # line with a single dot
            $logger->trace("dot line: adding blank line to field $key");
            _store_line($store_ref,"",$check,$line) ;
        }
        elsif (s/^\s//) {     # non empty line
            $logger->trace("text line: adding '$_' to field $key");
            _store_line($store_ref,$_ , $check,$line);
        }
        else {
            my $msg = "DpkgSyntax error: Invalid line (missing ':' ?) : $_" ;
            Config::Model::Exception::Syntax -> throw ( message => $msg, parsed_line => $line ) 
                if $check eq 'yes' ; 
	    $logger->error($msg) if $check eq 'skip';
        }
        $line++;
    }

    # remove trailing \n of last stored value 
    chomp $$store_ref if defined $$store_ref;
    # store last section if not empty
    push @res, $section_line, $store_list if @$store_list;


    if ($logger->is_debug ) {
        for (my $i = 0 ; 2*$i < $#res ; $i++  ) {
            my $l = $res[$i*2];
            my $s = $res[$i*2 + 1];
            my %section_data = @$s;
            
            $logger->debug("Parse result section $i, found:") ;
            foreach my $key (keys %section_data) {
                $logger->debug( "$key: ". substr ($section_data{$key}[0],0,35)) ;
            }
            
        }
    }

    $logger->warn("No section found") unless @res ;
    
    return wantarray ? @res : \@res ;   
}

sub _store_line {
    my ($store_ref,$line,$check,$line_nb) = @_ ;
    
    if (defined $store_ref) {
        $$store_ref .= "\n$line" ;
    }
    else {
        my $msg = "Did not find a keyword before: '$line''";
        Config::Model::Exception::Syntax -> throw ( message => $msg, parsed_line => $line_nb ) 
            if $check eq 'yes' ; 
        $logger->error($msg) if $check eq 'skip';
    }
    
}

# input is [ section [ keyword => value | value_list ] ]
sub write_dpkg_file {
    my ($self, $ioh, $array_ref,$list_sep) = @_ ;

    map { $self->write_dpkg_section($ioh,$_,$list_sep) } @$array_ref ;
}

sub write_dpkg_section {
    my ($self, $ioh, $array_ref,$list_sep) = @_ ;

    my $i = 0;
    foreach (my $i=0; $i < @$array_ref; $i += 2 ) {
        while ($array_ref->[$i] =~ /^#/) {
            # print comment
            $ioh->print($array_ref->[$i++],"\n") ; 
        }
        my $name  = $array_ref->[$i] ;
        my $value = $array_ref->[$i + 1];
        my $label = "$name:" ;
        if (ref ($value)) {
            $label .= ' ';
            my $sep = $list_sep ? $list_sep  : ",\n" ;
            $sep .= ' ' x length ($label) if $sep =~ /\n$/ ;
            $ioh -> print ($label.join( $sep, @$value ) . "\n");
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
    my @lines = split /\n/,$text ;
    $ioh->print ( ' ' . shift (@lines) . "\n" ) ;
    foreach (@lines) {
        $ioh->print ( /\S/ ? " $_\n" : " .\n") ;
    }
}

1;

__END__

=head1 NAME

Config::Model::Backend::Debian::DpkgSyntax - Role to read and write files with Dpkg syntax

=head1 SYNOPSIS

 package MyParser ;
 use Log::Log4perl qw(:easy);
 Log::Log4perl->easy_init($WARN);
 
 use Any::Moose ;
 with 'Config::Model::Backend::Debian::DpkgSyntax';
 
 package main ;
 use IO::File ;
 use Data::Dumper ;
 
 my $data = [ [ qw/Name Foo Version 1.2/ ],
 	      [ qw/Name Bar Version 1.3/ ,
                Files => [qw/file1 file2/] ,
 	        Description => "A very\n\nlong description"
 	     ]
 	   ] ;
 
 my $fhw = IO::File->new ;
 $fhw -> open ( 'dpkg_file' ,'>' ) ;
 my $parser = MyParser->new() ;
 
 $parser->write_dpkg_file($fhw,$data) ;
  
C<dpkg_file> will contain:

 Name: Foo
 Version: 1.2

 Name: Bar
 Version: 1.3
 Files: file1,
        file2
 Description: A very
  .
  long description

=head1 DESCRIPTION

This module is a Moose role to read and write dpkg control files. 

Debian control file are read and transformed in a list of list
matching the control file. The top level list of a list of section.
Each section is mapped to a list made of keywords and values. Since
this explanation is probably too abstract, here's an example of a file
written with Dpkg syntax:


 Name: Foo
 Version: 1.1

 Name: Bar
 # boy, new version
 Version: 1.2
  Description: A very
  . 
  long description

Once parsed, this file will be stored in the following list of list :

 (
   [ Name => 'Foo', Version => '1.1' ],
   [ Name => 'Bar', Version => [ '1.2' 'boy, new version' ], 
     Description => "A very\n\nlong description"
   ]
 )
 
Note: The description is changed into a paragraph without the Dpkg
syntax idiosyncrasies. The leading white space is removed and the single
dot is transformed in to a "\n". These characters will be restored
when the file is written back.

Last not but not least, this module can be re-used outside of C<Config::Model> with some 
small modifications in exception handing. Ask the author
if you want this module shipped in its own distribution.

=head1

=head2 parse_dpkg_file ( file_handle, check, comment_allowed )

Read a control file from the file_handle and returns a nested list (or a list 
ref) containing data from the file.

The returned list is of the form :

 [
   # section 1
   [ keyword1 => value1, # for text or simple values
     keyword2 => value2, # etc 
   ],
   # section 2
   [ ... ]
   # etc ...
 ]

check is C<yes>, C<skip> or C<no>.  C<comment_allowed> is boolean (default 0)

When comments are provided in the dpkg files, the returned list is of
the form :

 [
   [ 
     keyword1 => [ value1, 'value1 comment'] 
     keyword2 => value2, # no comment 
   ],
   [ ... ]
 ]



=head2 parse_dpkg_lines (lines, check, comment_allowed )

Parse the dpkg date from lines (which is an array ref) and return a data 
structure like L<parse_dpkg_file>.

=head2 write_dpkg_file ( io_handle, list_ref, list_sep )

Munge the passed list ref into a string compatible with control files
and write it in the passed file handle.

The input is a list of list in a form similar to the one generated by
L<parse_dpkg_file>:

 [ section [ keyword => value | value_list ] ]

Except that the value may be a SCALAR or a list ref. In case, of a list ref, the list 
items will be joined with the value C<list_sep> before being written. Values will be aligned
in case of multi-line output of a list.

For instance the following code :

 my $ref = [ [ Foo => 'foo value' , Bar => [ qw/v1 v2/ ] ];
 write_dpkg_file ( $ioh, $ref, ', ' )

will yield:

 Foo: foo value
 Bar: v1, v2

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::AutoRead>, 
L<Config::Model::Backend::Any>, 

=cut
