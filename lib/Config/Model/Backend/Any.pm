package Config::Model::Backend::Any;

use Carp;
use strict;
use warnings;
use Config::Model::Exception;
use Mouse;

use File::Path;
use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger("Backend");

has 'name' => ( is => 'ro', default => 'unknown', );
has 'annotation' => ( is => 'ro', isa => 'Bool', default => 0 );
has 'node' => (
    is       => 'ro',
    isa      => 'Config::Model::Node',
    weak_ref => 1,
    required => 1,
    handles => [ qw/show_message instance get_element_names/],
);

sub skip_open { return 0; }

sub read {
    my $self = shift;
    my $err  = "Internal error: read not defined in backend $self->{name}.";
    $logger->error($err);
    croak $err;
}

sub write {
    my $self = shift;
    my $err  = "Internal error: write not defined in backend $self->{name}.";
    $logger->error($err);
    croak $err;
}

sub read_global_comments {
    my $self  = shift;
    my $lines = shift;
    my $cc    = shift;    # comment character(s)

    my $cc_re = length $cc > 1 ? "[$cc]" : $cc;
    my @global_comments;
    my @global_comment_lines;

    while ( defined( my $l = shift @$lines ) ) {
        next if $l =~ /^$cc_re{2}/;    # remove comments added by Config::Model
        unshift @$lines, $l;
        last;
    }
    while ( defined( my $l = shift @$lines ) ) {
        next if $l =~ /^\s*$/;      # remove empty lines
        unshift @$lines, $l;
        last;
    }

    while ( defined( my $l = shift @$lines ) ) {
        chomp $l;

        my ( $data, $comment ) = split /\s*$cc_re\s?/, $l, 2;

        if (defined $comment) {
            push @global_comment_lines, $l;
            push @global_comments, $comment;
        }

        if ( $l =~ /^\s*$/ ) {
            # we indeed had global comments which are now finished by
            # a blank line.  Store them and bail out
            if (@global_comments) {
                $self->node->annotation(@global_comments);
                $logger->debug("Setting global comment with @global_comments on ", $self->node->name);
            }
            # stop global comment at first blank line
            last;
        }
        if ( $data ) {
            # The comment found is not global, put back line and any captured comment
            unshift @$lines, @global_comment_lines, $l;

            # stop global comment
            last;
        }
    }
}

sub associates_comments_with_data {
    my $self  = shift;
    my $lines = shift;
    my $cc    = shift;    # comment character(s)

    my $cc_re = length $cc > 1 ? "[$cc]" : $cc;
    my @result;
    my @comments;
    foreach my $l (@$lines) {
        next if $l =~ /^$cc_re{2}/;    # remove comments added by Config::Model
        chomp $l;

        my ( $data, $comment ) = split /\s*$cc_re\s?/, $l, 2;
        push @comments, $comment if defined $comment;

        next unless defined $data;
        $data =~ s/^\s+//g;
        $data =~ s/\s+$//g;

        if ($data) {
            my $note = '';
            $note = join( "\n", @comments ) if @comments;
            $logger->trace("associates_comments_with_data: '$note' with '$data'");
            push @result, [ $data, $note ];
            @comments = ();
        }
    }

    return wantarray ? @result : \@result;

}

sub write_global_comment {
    my $self = shift;
    my ($ioh, $cc);
    if (ref($_[0])) {
        $logger->warn("write_global_comment: io_handle parameter is deprecated");
        ($ioh, $cc) = @_;
    }
    else {
        ( $cc ) = @_;
    }

    croak "write_global_comment: no comment char specified" unless $cc;

    # no need to mention 'cme list' if current application is found
    my $app = $self->node->instance->application ;
    my $extra = '' ;
    if (not $app) {
        $extra = "$cc$cc Run 'cme list' to get the list of applications"
            . " available on your system\n";
        $app = '<application>';
    }

    my $res = "$cc$cc This file was written by cme command.\n"
        . "$cc$cc You can run 'cme edit $app' to modify this file.\n"
        . $extra
        . "$cc$cc You may also modify the content of this file with your favorite editor.\n\n";

    # write global comment
    my $global_note = $self->node->annotation;
    if ($global_note) {
        map { $res .= "$cc $_\n" } split /\n/, $global_note;
        $res .= "\n";
    }

    $ioh->print($res) if defined $ioh;
    return $res;
}

# $cc can be undef when writing a list on a single line
sub write_data_and_comments {
    my $self = shift;
    my ($ioh, $cc, @data_and_comments);
    if (not defined $_[0] or ref($_[0])) {
        $logger->warn("write_data_and_comments: io_handle parameter is deprecated");
        ($ioh, $cc, @data_and_comments) = @_;
    }
    else {
        ( $cc, @data_and_comments ) = @_;
    }

    my $res = '';
    while (@data_and_comments) {
        my ( $d, $c ) = splice @data_and_comments, 0, 2;
        if ($c) {
            map { $res .= "$cc $_\n" } split /\n/, $c;
        }
        $res .= "$d\n" if defined $d;
    }
    $ioh->print($res) if defined $ioh;
    return $res;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Virtual class for other backends

__END__

=head1 SYNOPSIS

 package Config::Model::Backend::Foo ;
 use Mouse ;

 extends 'Config::Model::Backend::Any';

 # mandatory
 sub read {
    my $self = shift ;
    my %args = @_ ;

    # args are:
    # root       => './my_test',  # fake root directory, used for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object opened for read
    # check      => yes|no|skip

    return 0 unless defined $args{io_handle} ; # or die, your choice

    # read the file line by line
    # we assume the file contain lines like 'key=value'
    foreach ($args{io_handle}->getlines) {
        chomp ;   # remove trailing \n
        s/#.*// ; # remove any comment
        next unless /\S/; # skip blank line

        # $data is 'foo=bar' which is compatible with load 
        $self->node->load(steps => $_, check => $args{check} ) ;
    }
    return 1 ;
 }

 # mandatory
 sub write {
    my $self = shift ;
    my %args = @_ ;

    # args are:
    # root       => './my_test',  # fake root directory, used for tests
    # config_dir => /etc/foo',    # absolute path 
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object opened for write
    # check      => yes|no|skip

    my $ioh = $args{io_handle} ;

    # read the content of the configuration tree
    foreach my $elt ($self->node->children) {
        # read the value from element $elt
        my $v = $self->node->grab_value($elt) ;

        # write value in file
        $ioh->print(qq!$elt="$v"\n!) if defined $v ;
    }

    return 1;
 }


=head1 DESCRIPTION

Some application have configuration files with a syntax which is not
supported by existing C<Config::Model::Backend::*> classes.

In this case a new backend must be
written. C<Config::Model::Backend::Any> was created to facilitate this
task.

The new backend class must use L<Mouse> and must extends (inherit)
C<Config::Model::Backend::Any>.

=head1 How to write your own backend

=head2 Declare the new backend in a node of the model

As explained in L<Config::Model::BackendMgr/"Backend specification">, the
new backend must be declared as an attribute of a
L<Config::Model::Node> specification.

Let's say your new backend is C<Config::Model::Backend::Foo>. This new backend
can be specified with:

 rw_config  => {
    backend    => 'Foo' , # can also be 'foo'
    config_dir => '/etc/cfg_dir'
    file       => 'foo.conf', # optional
 }

(The backend class name is constructed with C<ucfirst($backend_name)>)

C<rw_config> can also have custom parameters that are passed
verbatim to C<Config::Model::Backend::Foo> methods:

 rw_config  => {
    backend    => 'Foo' , # can also be 'foo'
    config_dir => '/etc/cfg_dir'
    file       => 'foo.conf', # optional
    my_param   => 'my_value',
 }

C<Config::Model::Backend::Foo> class must inherit (extend)
L<Config::Model::Backend::Any> and is expected to provide the
following methods:

=over

=item read

C<read()> is called with the following parameters:

 %custom_parameters,       # e.g. my_param   => 'my_value' in the example above
 object     => $obj,         # Config::Model::Node object
 root       => $root_dir,  # fake root directory, used for tests
 backend    => $backend,   # backend name
 config_dir => $read_dir,  # path below root
 file       => 'foo.conf',   # file name
 file_path  => $full_name, # full file name (root+path+file)
 io_handle  => $io_file    # IO::File object opened for read
 check      => [yes|no|skip]

The L<IO::File> object is undef if the file cannot be read.

This method must return 1 if the read was successful, 0 otherwise.

Following the C<my_param> example above, C<%custom_parameters> contains
C< ( 'my_param' , 'my_value' ) >, so C<read()> is called with
C<root>, C<config_dir>, C<file_path>, C<io_handle> B<and>
C<<  my_param   => 'my_value' >>.

=item write

C<write()> is called with the following parameters:

 %$custom_parameters,         # e.g. my_param   => 'my_value' in the example above
 object      => $obj,         # Config::Model::Node object
 root        => $root_dir,    # fake root directory, used for tests
 auto_create => $auto_create, # boolean specified in backend declaration
 auto_delete => $auto_delete, # boolean specified in backend declaration
 backend     => $backend,     # backend name
 config_dir  => $write_dir,   # override from instance
 file        => 'foo.conf',   # file name
 file_path   => $full_name, # full file name (root+path+file)
 io_handle   => $fh,          # IO::File object
 write       => 1,            # always
 check       => [ yes|no|skip] ,
 backup      => [ undef || '' || suffix ] # backup strategy required by user

The L<IO::File> object is undef if the file cannot be written to.

This method must return 1 if the write was successful, 0 otherwise

If C<io_handle> is defined, the backup has already been done before
opening the config file. If C<io_handle> is not defined, there's not
enough information in the model to read the configuration file and
create the backup. Your C<write()> method will have to do the backup
requested by user.

When both C<config_dir> and C<file> are specified,
the L<backend manager|Config::Model::BackendMgr>
opens the configuration file for write (and thus clobbers it) before calling
the C<write> call-back with the file handle with C<io_handle>
parameter. C<write> should use this handle to write data in the target
configuration file.

If this behavior causes problem, the solution is to override
C<skip_open> method in your backend to return C<1>.

=back


=head2 How to test your new backend

Using L<Config::Model::Tester>, you can test your model with your
backend following the instructions given in L<Config::Model::Tester>.

You can also test your backend with a minimal model (and
L<Config::Model::Tester>). In this case, you need to specify
a small model to test in a C<*-test-conf.pl> file.
See the
L<IniFile backend test|https://github.com/dod38fr/config-model/blob/master/t/model_tests.d/backend-ini-test-conf.pl>
for an example and its
L<examples files|https://github.com/dod38fr/config-model/tree/master/t/model_tests.d/backend-ini-examples>.

=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => backend_name )

The constructor should be used only by
L<Config::Model::Node>.

=head1 Methods to override

=head2 annotation

Whether the backend supports reading and writing annotation (a.k.a
comments). Default is 0. Override this method to return 1 if your
backend supports annotations.

=head2 read

Read the configuration file. This method must be overridden.

=head2 write

Write the configuration file. This method must be overridden.

=head1 Methods

=head2 node

Return the node (a L<Config::Model::Node>) holding this backend.

=head2 instance

Return the instance (a L<Config::Model::Instance>) holding this configuration.

=head2 show_message( string )

Show a message to STDOUT (unless overridden). Delegated to L<Config::Model::Instance/"show_message( string )">.

=head2 read_global_comments

Parameters:

=over

=item *

array ref of string containing the lines to be parsed

=item *

A string to specify how a comment is started. Each
character is recognized as a comment starter (e.g 'C<#;>' allow a
comment to begin with 'C<#>' or 'C<;>')

=back

Read the global comments (i.e. the first block of comments until the
first blank or non comment line) and store them as root node
annotation. Note that the global comment must be separated from the
first data line by a blank line.

Example:

 $self->read_global_comments( \@lines, ';');
 $self->read_global_comments( \@lines, '#;');

=head2 associates_comments_with_data

Parameters:

=over

=item *

array ref of string containing the lines to be parsed

=item *

A string to specify how a comment is started. Each
character is recognized as a comment starter (e.g 'C<#;>' allow a
comment to begin with 'C<#>' or 'C<;>')

=back

This method extracts comments from the passed lines and associate
them with actual data found in the file lines. Data is associated with
comments preceding or on the same line as the data. Returns a list of
[ data, comment ].

Example:

  my @lines = (
    '# Foo comments',
    'foo= 1',
    'Baz = 0 # Baz comments'
  );
  my @res = $self->associates_comments_with_data( \@lines, '#')
  # @res is:
  # ( [ 'foo= 1', 'Foo comments' ] , [ 'Baz = 0' , 'Baz comments' ] )

=head2 write_global_comments

Return a string containing global comments using data from
configuration root annotation.

Requires one parameter: comment_char (e.g "#" or '//' )

Example:

  my $str = $self->write_global_comments('#')

=head2 write_data_and_comments

Returns a string containing comments (stored in annotation) and
corresponding data. Comments are written before the data. If a data is
undef, the comment is written on its own line.

Positional parameters are C<( comment_char , data1, comment1, data2, comment2 ...)>

Example:

 print $self->write_data_and_comments('#', 'foo', 'foo comment', undef, 'lone comment','bar')
 # returns "# foo comment\nfoo\n#lon

Use C<undef> as comment char if comments are not supported by the
syntax of the configuration file. Comments will then be dropped.

=head1 Replacing a custom backend

Custom backend are now deprecated and must be replaced with a class inheriting this module.

Please:

=over

=item *

Rename your class to begin with C<Config::Model::Backend::>

=item *

Add C<use Mouse ;> and C<extends 'Config::Model::Backend::Any';> in the header of your custom class.

=item *

Add C<my $self = shift;> as the beginning of C<read> and C<write> functions... well... methods.

=back

Here's an L<example of such a change|https://github.com/dod38fr/config-model/commit/c3b7007ad386cb2356c5ac1499fe51bdf492b19a>.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::BackendMgr>, 
L<Config::Model::Node>, 
L<Config::Model::Backend::Yaml>, 

=cut
