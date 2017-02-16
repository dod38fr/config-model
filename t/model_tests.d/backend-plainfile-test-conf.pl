
# test plainfile backend

# specify where is the example file
$conf_dir = '';

# specify the name of the class to test
$model_to_test = "MiniPlain";

{
    package MyReader;
    use Path::Tiny;
    use Test::More;

    sub my_log {
        note("plainfile backend test: @_");
    }

    sub read {
        my %args = @_;
        my $dir = $args{root}.$args{config_dir};
        foreach my $file (path($dir)->children()) {
            my_log("dummy read file $file");
            my ($key,$elt) = split /\./,$file->basename;
            if ($elt =~ /postinst|prerm/) {
                $args{object}->load("package-scripts $elt:$key");
            }
            else {
                $args{object}->load("$elt:$key");
            }
        }
        return 1;
    }

    sub write {
        mylog("dummy write called");
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
      }
    ],
    name => 'PlainTest::Class',
    read_config => [{
        auto_create => '1',
        auto_delete => '1',
        backend => 'PlainFile',
        config_dir => 'debian',
        file => '&index.&element'
    }]
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

    read_config => [{
        backend    => 'custom',
        config_dir => 'debian',
        class      => 'MyReader',
        auto_delete => '1',
    }],
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
        ]
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
