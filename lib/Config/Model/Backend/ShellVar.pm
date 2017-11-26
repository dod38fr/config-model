package Config::Model::Backend::ShellVar;

use Carp;
use Mouse;
use Config::Model::Exception;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

extends 'Config::Model::Backend::Any';

my $logger = get_logger("Backend::ShellVar");

sub suffix { return '.conf'; }

sub annotation { return 1; }

sub read {
    my $self = shift;
    my %args = @_;

    # args are:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    return 0 unless defined $args{io_handle};    # no file to read
    my $check = $args{check} || 'yes';

    my @lines = $args{io_handle}->getlines;

    # try to get global comments (comments before a blank line)
    $self->read_global_comments( \@lines, '#' );

    my @assoc = $self->associates_comments_with_data( \@lines, '#' );
    foreach my $item (@assoc) {
        my ( $data, $c ) = @$item;
        my ($k,$v) = split /\s*=\s*/, $data, 2; # make reader quite tolerant
        $v =~ s/^["']|["']$//g;
        if ($logger->is_debug) {
            my $msg = "Loading key '$k' value '$v'";
            $msg .= " comment: '$c'" if $c;
            $logger->debug($msg);
        }
        my $obj = $self->node->fetch_element($k);
        $obj->store( value => $v, check => $check );
        $obj->annotation($c) if $c;
    }

    return 1;
}

sub write {
    my $self = shift;
    my %args = @_;

    # args are:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    my $ioh  = $args{io_handle};
    my $node = $args{object};

    croak "Undefined file handle to write" unless defined $ioh;

    my @to_write;

    # Using Config::Model::ObjTreeScanner would be overkill
    foreach my $elt ( $node->get_element_name ) {
        my $obj = $node->fetch_element($elt);
        my $v   = $node->grab_value($elt);

        next unless defined $v;

        push @to_write, [ qq!$elt="$v"!, $obj->annotation ];
    }

    if (@to_write) {
        $self->write_global_comment( $ioh, '#' );
        map { $self->write_data_and_comments( $ioh, '#', @$_ ); } @to_write;
    }

    return 1;
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Read and write config as a C<SHELLVAR> data structure

__END__

=head1 SYNOPSIS

 use Config::Model;

 my $model = Config::Model->new;
 $model->create_config_class (
    name    => "MyClass",
    element => [ 
        [qw/foo bar/] => {qw/type leaf value_type string/}
    ],

   rw_config  => {
     backend => 'ShellVar',
     config_dir => '/tmp',
     file  => 'foo.conf',
     auto_create => 1,
   }
 );

 my $inst = $model->instance(root_class_name => 'MyClass' );
 my $root = $inst->config_root ;

 $root->load('foo=FOO1 bar=BAR1' );

 $inst->write_back ;

File C<foo.conf> now contains:

 ## This file was written by Config::Model
 ## You may modify the content of this file. Configuration 
 ## modifications will be preserved. Modifications in
 ## comments may be mangled.
 ##
 foo="FOO1"

 bar="BAR1"

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with C<SHELLVAR> syntax in
C<Config::Model> configuration tree.

Note that undefined values are skipped for list element. I.e. if a
list element contains C<('a',undef,'b')>, the data structure
contains C<'a','b'>.


=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => 'shellvar' ) ;

Inherited from L<Config::Model::Backend::Any>. The constructor is
called by L<Config::Model::BackendMgr>.

=head2 read ( io_handle => ... )

Of all parameters passed to this read call-back, only C<io_handle> is
used. This parameter must be L<IO::File> object already opened for
read. 

It can also be undef. In which case C<read()> returns 0.

When a file is read,  C<read()> returns 1.

=head2 write ( io_handle => ... )

Of all parameters passed to this write call-back, only C<io_handle> is
used. This parameter must be L<IO::File> object already opened for
write. 

C<write()> returns 1.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::BackendMgr>, 
L<Config::Model::Backend::Any>, 

=cut
