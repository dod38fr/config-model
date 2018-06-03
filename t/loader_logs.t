# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test/;

use strict;
use warnings;

use lib "t/lib";
use Test::Log::Log4perl;
$::_use_log4perl_to_warn = 1;

my ($model, $trace) = init_test();

# See caveats in Test::More doc
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $inst = $model->instance(
    root_class_name => 'Master',
    model_file      => 'dump_load_model.pl',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;
my $t_load = Test::Log::Log4perl->get_logger("Verbose.Logger");
my $t_value = Test::Log::Log4perl->get_logger("Tree.Element.Value");

sub xlog {
    my ($root,$cmd, @expected) = @_;
    Test::Log::Log4perl->start(ignore_priority => "debug");
    foreach my $exp (@expected) {
        if (ref($exp)) {
            $exp->[0]->info($exp->[1]);
        }
        else {
            $t_load->info($exp);
        }
    }
    $root->load($cmd);
    Test::Log::Log4perl->end("test log of '$cmd'");
}

subtest "test no logs during initial_load" => sub {
    $root->instance->initial_load_start;
    xlog($root, '!');
    $root->instance->initial_load_stop;
};

subtest "test navigation logs" => sub {
    xlog($root, '!', "command '!': Going from root node to root node");
    xlog(
        $root, 'plain_object - -',
        "command 'plain_object': Going down from root node to node 'plain_object'",
        "command '-': Going up from node 'plain_object' to root node",
        "command '-': Going up from root node to exit Loader."
    );
    xlog(
        $root, 'ordered_hash_of_node:blah',
        "command 'ordered_hash_of_node:blah': Going down from root node to node 'ordered_hash_of_node:blah'",
    );
    xlog(
        $root, 'olist:0',
        "command 'olist:0': Going down from root node to node 'olist:0'",
    );
};

subtest "test search logs" => sub {
    xlog(
        $root, '/plain_object',
        "command '/plain_object': Element 'plain_object' found in current node (root node).",
        "command 'plain_object': Going down from root node to node 'plain_object'",
    );

    xlog(
        $root, 'olist:0 /plain_object',
        "command 'olist:0': Going down from root node to node 'olist:0'",
        "command '/plain_object': Going up from node 'olist:0' to root node to search for element 'plain_object'.",
        "command '/plain_object': Element 'plain_object' found in current node (root node).",
        "command 'plain_object': Going down from root node to node 'plain_object'",
    );
};

subtest "test annotation logs" => sub {
    xlog(
        $root, '#"root comment "',
        q!command '#"root comment "': Setting root node annotation to 'root comment '!
    );
    xlog(
        $root, 'plain_object#"obj comment"',
        q!command 'plain_object#"obj comment"': Setting node 'plain_object' annotation to 'obj comment'!,
        q!command 'plain_object#"obj comment"': Going down from root node to node 'plain_object'!,
    );
};

subtest "test assignment logs" => sub {
    xlog(
        $root, 'a_string=blah',
        q!command 'a_string=blah': Setting leaf 'a_string' string to 'blah'.!
    );
    xlog(
        $root, 'a_string.=blah',
        q!command 'a_string.=blah': Appending 'blah' to leaf 'a_string' string. Result is 'blahblah'.!
    );
    xlog(
        $root, 'a_string=~s/ahbl//',
        q!command 'a_string=~s/ahbl//': Applying regexp 's/ahbl//' to leaf 'a_string' string. Result is 'blah'.!
    );
    xlog(
        $root, 'int_v=14',
        q!command 'int_v=14': Setting leaf 'int_v' integer to '14'.!
    );
    xlog(
        $root, 'int_v~',
        q!command 'int_v~': Deleting leaf 'int_v'.!
    );
    xlog(
        $root, 'hash_a:foo=bar',
        q!command 'hash_a:foo=bar': Setting leaf 'hash_a:foo' string to 'bar'.!
    );
    xlog(
        $root, 'lista:0=foo lista:1=bar',
        q!command 'lista:0=foo': Setting leaf 'lista:0' string to 'foo'.!,
        q!command 'lista:1=bar': Setting leaf 'lista:1' string to 'bar'.!,
    );
    xlog(
        # change list value to avoid log like 'skip storage of lista:0 unchanged value: foo2'
        $root, 'lista=foo2,bar2',
        q!command 'lista=foo2,bar2': Setting list 'lista' values to 'foo2,bar2'.!,
    );
    xlog(
        # change list value to avoid log like 'skip storage of lista:0 unchanged value: foo2'
        $root, 'lista:=foo3,bar3',
        q!command 'lista:=foo3,bar3': Setting list 'lista' values to 'foo3,bar3'.!,
    );
    xlog(
        $root, 'alpha_check_list=a,c,f,g',
        q!command 'alpha_check_list=a,c,f,g': Setting check_list 'alpha_check_list' items 'a,c,f,g'.!,
    );
};

subtest "test dispatched operator" => sub {
    my $expect = q!Running 'push' on list 'lista' with "z", "x".!;

    xlog(
        $root, 'lista:.push(z,x)',
        qq!command 'lista:.push(z,x)': $expect!
    );
    xlog(
        $root, 'lista:<(z,x)',
        qq!command 'lista:<(z,x)': $expect!
    );

    $root->load("ordered_hash:bkey=bv ordered_hash:dkey=dv");
    xlog(
        $root, 'ordered_hash:.insort(ckey,cv)',
        qq!command 'ordered_hash:.insort(ckey,cv)': Running 'insort' on hash 'ordered_hash' with "ckey", "cv".!,
    )
};

subtest "test creation of empty elements" => sub {
    xlog(
        $root, 'hash_a:foo',
        q!command 'hash_a:foo': Creating empty leaf 'hash_a:foo'.!
    );
};

subtest "test hash of loop" => sub {
    xlog(
        $root, 'hash_a:.clear',
        q!command 'hash_a:.clear': Running 'clear' on hash 'hash_a' with "".!
    );
    $root->load("hash_a:foo1=foov1_x hash_a:foo2=foov2_x hash_a:bar=barv_x");
    my $loop = 'hash_a:~/foo/=~s/_x//';
    xlog(
        $root, $loop,
        map {(
            qq!command '$loop': Running foreach_map loop on leaf 'hash_a:foo$_'.!,
            qq!command '$loop': Applying regexp 's/_x//' to leaf 'hash_a:foo$_' string. Result is 'foov$_'.!
        )} qw/1 2/
    );
};

done_testing;
