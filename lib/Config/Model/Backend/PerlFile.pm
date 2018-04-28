package Config::Model::Backend::PerlFile;

use 5.10.1;
use Carp;
use strict;
use warnings;
use Config::Model::Exception;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

use base qw/Config::Model::Backend::Any/;

my $logger = get_logger("Backend::PerlFile");

sub read {
    my $self = shift;
    my %args = @_;

    # args is:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # check      => yes|no|skip

    my $file_path = $args{file_path};
    return 0 unless -r $file_path;
    $file_path = "./$file_path" unless $file_path =~ m!^\.?/!;
    $logger->info("Read Perl data from $file_path");

    my $pdata = do $file_path || die "Cannot open $file_path:$?";
    $self->node->load_data($pdata);
    return 1;
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
    # check      => yes|no|skip

    my $file_path = $args{file_path};
    $logger->info("Write perl data to $file_path");

    my $p_data = $self->node->dump_as_data(
        skip_auto_write => 'perl_file',
        check => $args{check}
    );
    my $dumper = Data::Dumper->new( [$p_data] );
    $dumper->Terse(1);

    $args{file_path}->spew_utf8( $dumper->Dump, ";\n" );

    return 1;
}

1;

# ABSTRACT: Read and write config as a Perl data structure

__END__

=head1 SYNOPSIS

 use Config::Model ;
 use Data::Dumper ;

 # define configuration tree object
 my $model = Config::Model->new ;
 $model ->create_config_class (
    name => "MyClass",
    element => [
        [qw/foo bar/] => {
            type => 'leaf',
            value_type => 'string'
        },
        baz => {
            type => 'hash',
            index_type => 'string' ,
            cargo => {
                type => 'leaf',
                value_type => 'string',
            },
        },
    ],
  rw_config  => {
     backend => 'perl_file' ,
     config_dir => '/tmp',
     file  => 'foo.pl',
     auto_create => 1,
  },
 ) ;

 my $inst = $model->instance(root_class_name => 'MyClass' );

 my $root = $inst->config_root ;

 my $steps = 'foo=yada bar="bla bla" baz:en=hello
             baz:fr=bonjour baz:hr="dobar dan"';
 $root->load( steps => $steps ) ;
 $inst->write_back ;

Now, C</tmp/foo.pl> contains:

 {
   bar => 'bla bla',
   baz => {
     en => 'hello',
     fr => 'bonjour',
     hr => 'dobar dan'
   },
   foo => 'yada'
 }

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with Perl syntax in
C<Config::Model> configuration tree.

Note:

=over 4

=item *

Undefined values are skipped for list element. I.e. if a
list element contains C<('a',undef,'b')>, the data structure
contains C<'a','b'>.

=item *

Perl file is not created (and may be deleted) when no data is to be
written.

=back

=head1 backend parameter

=head2 config_dir

Mandoatory parameter to specify where is the Perl configuration file.

=head1 CONSTRUCTOR

=head2 new

Inherited from L<Config::Model::Backend::Any>. The constructor is
called by L<Config::Model::BackendMgr>.

=head2 read

Of all parameters passed to this read call-back, only C<ifile_path> is
used. This parameter must be L<IO::File> object already opened for
read.

It can also be undef. In which case C<read()> returns 0.

When a file is read,  C<read()> returns 1.

=head2 write

Of all parameters passed to this write call-back, only C<file_path> is
used. This parameter must be a L<Path::Tiny> object.

C<write()> returns 1.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,
L<Config::Model::BackendMgr>,
L<Config::Model::Backend::Any>,

=cut
