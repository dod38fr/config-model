package Config::Model::Value::Update;

use v5.20;
use Mouse;
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);
use Mouse::Util::TypeConstraints;
use Config::Model::Value::UpdateFromFile;

use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;

my $logger = get_logger("Tree::Element::Value");
my $user_logger = get_logger("User");

enum ActionWhenMissing => qw/die warn ignore/;

has "when_missing" => (is => 'rw', isa => 'ActionWhenMissing');

has "files" => (
    is => 'ro',
    isa => 'ArrayRef[HashRef]',
    traits  => ['Array'],
    handles => {
        file_specs => 'elements',
        source_count => 'count'
    },
);

has "file_obj" => (
    is => 'rw',
    isa => 'ArrayRef[Config::Model::Value::UpdateFromFile]',
    traits  => ['Array'],
    handles => {
        file_sources   => 'elements',
    },
    # must be lazy, otherwise, $self->location below may be undef
    lazy => 1,
    builder => sub ($self) {
        return [
            map {
                Config::Model::Value::UpdateFromFile->new(%$_, location => $self->location);
            } $self->file_specs
        ];
    }
);

has 'location' => (
    is => 'ro',
    isa => 'Str',
);

sub get_info ($self) {
    my @info;
    foreach my $obj ($self->file_sources) {
        push @info, $obj->get_info;
    }
    return join(", ", @info);
}

sub get_update_value ($self) {
    my @errors;
    foreach my $obj ( $self->file_sources ) {

        # Go style error handling, either $v or $err is set
        my ( $v, $err ) = $obj->get_update_value;
        if ($err) {
            push @errors, $err;
            next;
        }
        return $v;
    }

    # warn when no data was found, e.g. each obj did not find data
    my $when_missing = $self->when_missing;
    my $msg = $self->location . ": " . join( "\n  ", @errors );

    if ( $when_missing eq 'die' ) {
        $user_logger->logdie($msg);
    }
    elsif ( $when_missing eq 'warn' ) {
        $user_logger->warn($msg);
    }
    return;
}

1;

# ABSTRACT: Retrieve data from several external files

=head1 SYNOPSIS

    # in a model declaration:
    element => [
        data_from_some_file => {
            type => 'leaf',
            value_type => 'uniline',
            update => {
                # handled by this module, Config::Model::Value::Update
                when_missing => 'warn',
                files => [
                    {
                        # handled by Config::Model::Value::UpdateFromFile
                        type => 'ini',
                        file => "some_file.ini",
                        subpath => "foo.bar"
                    },
                    {
                        # ...
                    }
                ]
            }
        },
    ],

=head1 DESCRIPTION

This class retrieves data from external files. For each file,
caller must specify the file path, the file type (e.g. JSON, Yaml...) and the
path inside the file to retrieve data.

=head1 Constructor

Constructor parameters are:

=over

=item files

Configuration data to build an array of L<Config::Model::Value::UpdateFromFile> objects.

=item when_missing

Behavior when no data is found in any file. Can be C<ignore>, C<warn> or C<die>.

=item location

location of the calling value element. This is used to log messages.

=back

=cut

=head1 methods

=head2 get_info

Return all files and subpaths used to extract data.

=head2 get_update_value

Try to get data from the external files. The files are tried in the same order as the
C<files> parameter. Data is returned at the first successful try.
If no data can be found, either if all files are missing or all
subpath do not yield data, this function either returns, warns or
die, depending on the value of C<when_missing> parameter.

=cut

=head1 Examples

  update => {
    when_missing => 'ignore',
    files => [
      {
         type => 'yaml',
         file => 'META.yml',
         subpath => 'abstract'
      },
      {
         type => 'json',
         file => 'package.json'
         subpath => 'description'
      }
    ]
  }

=head1 SEE ALSO

L<Config::Model::Value>, L<Config::Model::Value::UpdateFromFile>

=cut

