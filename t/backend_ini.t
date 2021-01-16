# -*- cperl -*-

# NOTE: backend can also be tested in model_test.d

#use ExtUtils::testlib;
use Test::More;
use Test::File::Contents;
use Test::Memory::Cycle;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test  setup_test_dir/;

use warnings;

use strict;
use lib "t/lib";

my ($model, $trace) = init_test();

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir();

# set_up data
my @with_semicolon_comment = my @with_one_semicolon_comment = my @with_hash_comment = <DATA>;

# change delimiter comments
for (@with_semicolon_comment) { s/#/;/; } ;
for (@with_one_semicolon_comment) { s/# foo2/; foo2/; } ;

# models are stored in t/lib/test_ini_backend_model.pl
sub init_backend_test {
    my ($test_class, $test_data, $instance_name, $config_dir) = @_;

    my @orig      = @$test_data ;

    ok( 1, "Starting $test_class tests" );

    my $test1     = 'ini1';
    my $wr_dir    = $wr_root->child($test1);
    my $etc_dir   = $wr_dir->child('etc');
    $etc_dir->mkpath;
    my $conf_file = $etc_dir->child("test.ini");
    $conf_file->remove;

    $conf_file->spew_utf8(@orig) if @orig;

    my $i_test = $model->instance(
        instance_name   => $instance_name,
        root_class_name => $test_class,
        root_dir        => $wr_dir,
        model_file      => 'test_ini_backend_model.pl',
        config_dir      => $config_dir, # optional
    );

    ok( $i_test, "Created $test_class instance" );

    my $i_root = $i_test->config_root;
    ok( $i_root, "created $test_class tree root" );
    $i_root->init;
    ok( 1, "$test_class root init done" );

    return ($model, $i_test, $wr_dir, $conf_file);
}

sub finish {
    my ($test_class, $instance_name, $wr_dir, $model, $i_test) = @_;

    my $orig = $i_test->config_root->dump_tree;
    print $orig if $trace;

    $i_test->write_back;
    ok( 1, "IniFile write back done" );

    my $ini_file = $wr_dir->child('etc/test.ini');
    ok( $ini_file->exists, "check that config file $ini_file was written" );
    # create another instance to read the IniFile that was just written
    my $wr_dir2 = $wr_root->child('ini2');
    my $etc2 = $wr_dir2->child('etc');
    $etc2->mkpath;
    my $conf_file2 = $etc2->child('test.ini');
    note "copying $ini_file in $conf_file2";
    $ini_file->copy( $conf_file2 );

    my $i2_test = $model->instance(
        instance_name   =>  $instance_name,
        root_class_name => $test_class,
        root_dir        => $wr_dir2,
        config_dir      => $i_test->config_dir, # propagate from first test instance
    );

    ok( $i2_test, "Created instance" );

    my $i2_root = $i2_test->config_root;

    my $p2_dump = $i2_root->dump_tree;
    print "2nd dump:\n",$p2_dump if $trace;

    is( $p2_dump, $orig, "compare original data with 2nd instance data" );

    return ($ini_file,$conf_file2);
}

my %test_setup = (
    IniTest  => [ \@with_hash_comment,          'class1' ],
    IniTest2 => [ \@with_semicolon_comment,     'class1' ],
    IniTest3 => [ \@with_one_semicolon_comment, 'class1' ],
    AutoIni  => [ \@with_hash_comment,          'class1' ],
    MyClass  => [ \@with_hash_comment,          'any_ini_class:class1' ]
);

foreach my $test_class ( sort keys %test_setup ) {
    my ($model, $i_test, $wr_dir) = init_backend_test($test_class, $test_setup{$test_class}[0], "test_inst_for_$test_class");

    my $test_path = $test_setup{$test_class}[1];

    my $i_root = $i_test->config_root;

    $i_root->load("bar:0=\x{263A}");    # utf8 smiley
    is(
        $i_root->annotation,
        "some global comment with embedded '#' and stuff",
        "check global comment"
    );
    is( $i_root->grab($test_path)->annotation, "class1 comment", "check $test_path comment" );
    is( $i_root->grab($test_path)->backend_support_annotation, 1, "check support annotation " );

    my $lista_obj = $i_root->grab($test_path)->fetch_element('lista');
    is( $lista_obj->annotation, '', "check $test_path lista comment" );

    foreach my $i ( 1 .. 3 ) {
        my $elt = $lista_obj->fetch_with_id( $i - 1 );
        is( $elt->fetch,      "lista$i",         "check lista[$i] content" );
        is( $elt->annotation, "lista$i comment", "check lista[$i] comment" );
    }

    finish ($test_class, "test_inst2_for_$test_class", $wr_dir, $model,$i_test);
}

subtest "test ini file using a check list" => sub {
    #    IniCheck
    my ($model, $i_test, $wr_dir) = init_backend_test(IniCheck => \@with_hash_comment, "test_inst_for_check_list", '/etc/');

    my $i_root = $i_test->config_root;

    ok($i_root->grab('foo')->is_checked('foo1'),"foo foo1 choice is set");
    ok($i_root->grab('foo')->is_checked('bar1') == 0,"foo bar1 choice is not set");
    ok($i_root->grab('bar')->is_checked('bar1'),"bar bar1 choice is set");

    # I'm cheating. To reuse test data, list is actually a check_list in test model
    ok($i_root->grab('class1 lista')->is_checked('nolist') == 0,"class1 lista nolist choice is not set");
    ok($i_root->grab('class1 lista')->is_checked('lista2'),"class1 lista lista1 choice is set");

    $i_root->grab('class1 lista')->check('nolist');

    finish ('IniCheck', "test_inst2_for_check_list", $wr_dir, $model,$i_test);

};

# test start with no ini file and should not write any after
subtest "Test with empty ini file and no ini data" => sub {
    $wr_root->remove_tree;

    my ($model, $i_test, $wr_dir, $conf_file) = init_backend_test(IniTest => [], "test_inst_for_no_data", '/etc/');

    my $i_root = $i_test->config_root;
    # load some data so change notif is triggered
    $i_root->load("baz=blork");

    my $orig = $i_test->config_root->dump_tree;
    print $orig if $trace;

    # delete data and go back to default values, hence the
    # configuration no longer contains valid data
    $i_root->load("baz~");

    print $i_test->config_root->dump_tree if $trace;

    $i_test->write_back;
    ok( 1, "Empty IniFile write back done" );
    isnt($conf_file->exists, 1, "no file was written");

};

# test start with small ini file, delete all data so no file should be
# left
subtest "Test with small ini file and delete data" => sub {
    $wr_root->remove_tree;

    my ($model, $i_test, $wr_dir, $conf_file) = init_backend_test(
        IniTest => ["\n","baz = blork\n"],
        "test_inst_for_one_data", '/etc/'
    );
    is($conf_file->exists, 1, "ini file was written");

    my $i_root = $i_test->config_root;
    is($i_root->grab_value("baz"), 'blork', "check load of small data");

    my $orig = $i_test->config_root->dump_tree;
    print $orig if $trace;

    # delete data and go back to default values, hence the
    # configuration no longer contains valid data
    $i_root->load("baz~");

    print $i_test->config_root->dump_tree if $trace;

    $i_test->write_back;
    ok( 1, "Empty IniFile write back done" );
    isnt($conf_file->exists, 1, "file is gone");

};

subtest "Test handling of double quote" => sub {
    $wr_root->remove_tree;
    my $test_class = "IniDQuotes";

    # TODO: test also quotes in hash/list like values
    my ($model, $i_test, $wr_dir, $conf_file) = init_backend_test(
        $test_class => [
            q!baz = "blork "glop" blork"!."\n",
            q!a_list = "blork blork"!."\n",
            q!a_list = "glop glop"!."\n",
        ],
        "test_double_quotes", '/etc/'
    );
    is($conf_file->exists, 1, "ini file was written");

    my $i_root = $i_test->config_root;
    is($i_root->grab_value("baz"), qq!blork glop blork!, "check load of small data");
    is($i_root->grab_value("a_list:0"), qq!blork blork!, "check load of list 0");
    is($i_root->grab_value("a_list:1"), qq!glop glop!, "check load of list 1");

    my $orig = $i_test->config_root->dump_tree;
    print $orig if $trace;

    $i_test->write_back(force => 1);

    foreach my $item  (
        qq!baz = "blork glop blork"!,
        q!a_list = "blork blork"!,
        q!a_list = "glop glop"!
    ) {
        file_contents_like(
            $conf_file->stringify,
            $item,
            "check content of written file $conf_file with «$item»"
        );
    }
};

memory_cycle_ok( $model, "memory cycle test" );

done_testing;

__DATA__
#some global comment with embedded '#' and stuff


# foo1 comment also with '#' stuff
foo = foo1

foo = foo2 # foo2 comment

bar = bar1

baz = bazv

# class1 comment
[class1]
lista=lista1 #lista1 comment
# lista2 comment
lista    =    lista2
# lista3 comment
lista    =    lista3
