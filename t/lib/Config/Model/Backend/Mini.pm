package Config::Model::Backend::Mini ;
use strict;
use warnings;

use 5.10.1;
use Mouse;

extends 'Config::Model::Backend::Any';
with 'Config::Model::Role::FileHandler';

use Path::Tiny;
use YAML::Tiny qw/LoadFile Dump/;

sub _get_cfg_dir {
    my ($self,$root) = @_;
    my $dir = $self->get_tuned_config_dir(
        config_dir => 'debian/meta',
        root => $root
    );
    my $file =  $dir->child('test.yml');
    return $file;
}

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

    my $file = $self->_get_cfg_dir($args{root});

    return 0 unless $file->exists;    # no file to read

    my $perl_data = LoadFile($file);

    # load perl data in tree
    $self->node->load_data( data => $perl_data, check => $args{check} || 'yes' );
    return 1;
}

sub write {
    my $self = shift;
    my %args = @_;

    # args is:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, used for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # check      => yes|no|skip

    my $perl_data = $self->node->dump_as_data( full_dump => $args{full_dump} // 0);

    my $file = $self->_get_cfg_dir($args{root});
    $file->parent->mkpath;

    my $yaml = Dump( $perl_data );
    $file->spew_utf8($yaml);

    return 1;
}

1;
