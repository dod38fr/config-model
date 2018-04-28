package Config::Model::Backend::Json;

use Carp;
use strict;
use warnings;
use Config::Model::Exception;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

use base qw/Config::Model::Backend::Any/;
use JSON;

my $logger = get_logger("Backend::Json");

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

    return 0 unless defined $args{file_path}->exists;    # no file to read

    # load Json file
    my $json = $args{file_path}->slurp_utf8;

    # convert to perl data
    my $perl_data = decode_json $json ;
    if ( not defined $perl_data ) {
        $logger->warn("No data found in Json file $args{file_path}");
        return 1;
    }

    # load perl data in tree
    $self->{node}->load_data( data => $perl_data, check => $args{check} || 'yes' );
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

    my $perl_data = $self->{node}->dump_as_data( full_dump => $args{full_dump} );
    my $json = to_json( $perl_data, { pretty => 1 } );

    $args{file_path}->spew_utf8($json);

    return 1;
}

1;

# ABSTRACT: Read and write config as a JSON data structure

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
    backend => 'Json' ,
    config_dir => '/tmp',
    file  => 'foo.json',
    auto_create => 1,
  }
 ) ;

 my $inst = $model->instance(root_class_name => 'MyClass' );

 my $root = $inst->config_root ;

 my $steps = 'foo=yada bar="bla bla" baz:en=hello
             baz:fr=bonjour baz:hr="dobar dan"';
 $root->load( steps => $steps ) ;
 $inst->write_back ;

Now, C</tmp/foo.yml> contains:

 {
   "bar" : "bla bla",
   "foo" : "yada",
   "baz" : {
      "hr" : "dobar dan",
      "en" : "hello",
      "fr" : "bonjour"
   }
 }

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with Json syntax in
C<Config::Model> configuration tree.

Note that undefined values are skipped for list element. I.e. if a
list element contains C<('a',undef,'b')>, the data structure only
contains C<'a','b'>.


=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => 'Json' ) ;

Inherited from L<Config::Model::Backend::Any>. The constructor is
called by L<Config::Model::BackendMgr>.

=head2 read

Of all parameters passed to this read call-back, only C<file_path> is
used. This parameter must be a L<Path::Tiny>.

When a file is read,  C<read()> returns 1.

=head2 write

Of all parameters passed to this write call-back, only C<file_path> is
used. This parameter must be L<Path::Tiny> object.

C<write()> returns 1.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,
L<Config::Model::BackendMgr>,
L<Config::Model::Backend::Any>,

=cut
