
# test plainfile backend

# specify where is the example file
$conf_dir = '';

# specify the name of the class to test
$model_to_test = "MiniPlain";

{
    package Config::Model::Backend::MyReader;
    use Path::Tiny;
    use Test::More;
    use Mouse ;

    extends 'Config::Model::Backend::Any';

    sub my_log {
        note("plainfile backend test: @_");
    }

    sub read {
        my $self = shift;
        my %args = @_;

        my $dir = $args{root}->child($args{config_dir});
        foreach my $file ($dir->children()) {
            my_log("dummy read file $file");
            my ($key,$elt) = split /\./,$file->basename;
            $args{object}->load("$elt:$key");
        }
        return 1;
    }

    sub write {
        my $self = shift;
        my_log("dummy write called");
        return 1;
    }
}

# create minimal model to test plain file backend.

# this class is used by MiniPlain class below
$model->create_config_class(
    element => [
        list => {
            cargo => {
                type => 'leaf',
                value_type => 'uniline'
            },
            type => 'list'
        },
        a_string => {
            type => 'leaf',
            value_type => 'string'
        }
    ],
    name => 'PlainTest::Class',
    rw_config => {
        auto_create => '1',
        auto_delete => '1',
        backend => 'PlainFile',
        config_dir => 'debian',
        file_mode => '0755',
        file => '&index(-).&element(-).&element'
    }
);

$model->create_config_class(
    name => 'MiniPlain',
    element => [
        [qw/install move/] => {
            type  => 'hash',
            index_type => 'string',
            cargo => {
                type       => 'node',
                value_type => 'uniline',
                config_class_name => 'PlainTest::Class'
            },
            default_keys => [qw/foo bar/],
        },
    ],

    rw_config => {
        backend    => 'MyReader',
        config_dir => 'debian',
        auto_delete => '1',
    },
);


# the test suite
@tests = (
    {
        name  => 'with-index',
        check => [
            # check a specific value stored in example file
            'install:foo list:0' => "foo val1",
            'move:bar list:0' => "bar val1",
            'move:bar list:2' => "bar val3",
        ],
        file_mode => {
            'debian/bar.install.list' => 0755,
            'debian/bar.move.list' => 0755,
            'debian/foo.install.list' => 0755,
        }
    },
    {   # test file removal
        name  => 'with-index-and-content-removal',
        data_from  => 'with-index',
        load => 'install:bar list:.clear',
        file_check_sub => sub { shift @{$_[0]}; },
        load2 => 'install:bar',
    },
    {   # test file removal
        name  => 'with-index-and-removal',
        data_from  => 'with-index',
        # push a value to force loading of install.bar file
        load => 'install:bar list:.push(pushed) - install~bar',
        file_check_sub => sub { shift @{$_[0]}; },
    },

);

1;
