package Config::Model::Value::UpdateFromFile;

use v5.20;
use Mouse;
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);
use Mouse::Util::TypeConstraints;
use Path::Tiny;

use Config::Model::Exception;

use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;

my $logger = get_logger("Tree::Element::Value");
my $user_logger = get_logger("User");

my %update_dispatch = (
    ini => sub ($self, $file, $subpath)  {
        _lazy_load("INI", "Config::INI::Reader");
        my $data = Config::INI::Reader->read_file($file);
        return $self->__data_from_path($data, $subpath, 2);
    },
    json => sub ($self, $file, $subpath) {
        _lazy_load("JSON", "JSON");
        JSON->import();
        # utf8 decode is done by JSON module, so slurp_raw must be used
        my $data = decode_json(path($file)->slurp_raw);
        return $self->__data_from_path($data, $subpath);
    },
    yaml => sub ($self, $file, $subpath) {
        _lazy_load("YAML", "YAML::PP");
        my $data = YAML::PP->new()-> load_file($file);
        return $self->__data_from_path($data, $subpath);
    },
    toml => sub ($self, $file, $subpath) {
        _lazy_load("TOML", "TOML::Tiny");
        my $data = TOML::Tiny->new()-> decode(path($file)->slurp_utf8);
        return $self->__data_from_path($data, $subpath);
    },
);

has [qw/file type subpath location/] => (is => 'rw', isa => 'Str');

sub get_info ($self) {
    return $self->file.':'.$self->subpath;
}

sub __data_from_path ($self, $data, $path, $limit = 0) {
    # negative look behing assertion to skip \. in subpath
    foreach my $step (split /(?<!\\)\./, $path, $limit) {
        $step =~ s/\\\././g; # convert \. to .
        $data = (ref($data) eq 'HASH') ? $data->{$step} : $data->[$step];
        return $data if not ref $data;
    }
    $user_logger->warn("Did not get scalar value with $path: got $data");
    return;
}

sub _lazy_load ($type, $module) {
    my $file = ($module =~ s!::!/!gr).".pm";
    eval { require $file };
    if ($@) {
        $user_logger->logdie(
            "Error: Value update from $type file requires ".
            "$module module. Please install this module."
        );
    }
    return;
}

# returns (value, undef) or (undef, error)
sub get_update_value ($self) {
    my $type    = $self->type;
    my $file    = $self->file;
    my $subpath = $self->subpath;

    $logger->debug("update called on type $type, file $file, path $subpath");
    if ( !-e $file ) {
        return ( undef, "Cannot update value: $file does not exist" );
    }
    my $update_sub = $update_dispatch{$type};
    if ( not defined $update_sub ) {
        $logger->logdie(
            "Unexpected ", $self->location,
            "Value update type $type. Allowed values are ",
            join( ', ', keys %update_dispatch )
        );
        return;
    }
    my $v   = $update_sub->( $self, $file, $subpath );
    my $err = defined $v ? '' : "No value found in file $file, path $subpath";
    return ( $v, $err );
}


1;

# ABSTRACT: Retrieve data from external file

=head1 SYNOPSIS

    # in a model declaration:
    element => [
        data_from_some_file => {
            type => 'leaf',
            value_type => 'uniline',
            update => {
                # handled by Config::Model::Value::Update
                when_missing => 'warn',
                files => [
                    {
                        # handled by this module, Config::Model::Value::UpdateFromFile
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

This class retrieves data from external file. Caller must specify the file
path, the file type (e.g. JSON, Yaml...) and the
path inside the file to retrieve data.

Depending on the file type configured in the model, some modules must be installed.

Supported file types and modules to be installed are:

=over

=item JSON

L<JSON>

=item Yaml

L<YAML::PP>

=item INI file

L<Config::INI::Reader>

=item Toml

L<TOML::Tiny>

=back

=cut

=head1 Constructor

Constructor parameters are:

=over

=item file

File path from currrent directory.

=item type

File type in lower case, either C<ini>, C<json>, C<yaml> or C<toml>. 

=item subpath

Path to extract data. See examples below.

=item location

location of the calling value element. This is used to log messages.

=back

=cut

=head1 methods

=head2 get_info

Return file and subpath used to extract data.

=head2 get_update_value

This method open the file and return the data using subpath.

=cut

=head1 Examples

=head2 INI file

Using the C<dist.ini> file:

  [MetaResources]
  homepage          = https://github.com/dod38fr/config-model/wiki
  repository.url    = git://github.com/dod38fr/config-model.git

C<homepage> can be retrieved with:

   update => [{
    type => 'ini',
    file => 'dist.ini',
    subpath => 'MetaResources.homepage'
  }]

and C<url> with:

   update => [{
    type => 'ini',
    file => 'dist.ini',
    subpath => 'MetaResources.repository\.url'
  }]

=head2 YAML file

    update => {
        when_missing => 'warn',
        files => [{
             type => 'yaml',
             file => 'META.yml',
             subpath => 'resources.homepage'}
        ]
    }

=head2 Try several files

If may be necessary to try several files:

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

L<Config::Model::Value>, L<Config::Model::Value::Update>

=cut

