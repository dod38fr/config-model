# -*- cperl -*-

use ExtUtils::testlib;
use Test::More;
use Test::Exception;
use Test::Memory::Cycle;
use Config::Model;
use File::Path;
use File::Copy;
use Data::Dumper;

use warnings;
no warnings qw(once);

use strict;

use Test::Log::Log4perl;
$::_use_log4perl_to_warn = 1;

use Config::Model::Tester::Setup qw/init_test/;
my ($model, $trace) = init_test();

$model->create_config_class(
    name => 'Host',

    accept => [
        'list.*' => {
            type  => 'list',
            cargo => {
                type       => 'leaf',
                value_type => 'string',
            },
            accept_after => 'id',
        },
        'str.*' => {
            type       => 'leaf',
            value_type => 'uniline'
        },
        'bad.*' => {
            type       => 'leaf',
            value_type => 'uniline',
            warn       => 'gotcha',
        },
        'ot.*' => {
            type       => 'leaf',
            value_type => 'uniline',
        },

        #TODO: Some advanced structures, hashes, etc.
    ],
    element => [
        [qw/id other/] => {
            type       => 'leaf',
            value_type => 'uniline',
        },
        'strhidden' => {
            type       => 'leaf',
            value_type => 'uniline',
            level => 'hidden',
        },
    ] );

ok( 1, "Created new class with accept parameter" );

# set_up data

my $i_hosts = $model->instance(
    instance_name   => 'hosts_inst',
    root_class_name => 'Host',
);

is($model->get_element_property(qw/class Host element otary property value_type/),'uniline',
   "get_element_property on accepted element" );

is($model->get_element_property(qw/class Host element other property value_type/),'uniline',
   "get_element_property on a predefined element matching an accepted one" );

# Test fix where XS-Autobuild did show up with cme edit dpkg-control
is($model->get_element_property(qw/class Host element strhidden property level/),'hidden',
   "get_element_property on hidden accepted element" );
is($model->get_element_property(qw/class Host element strok property level/),'normal',
   "get_element_property on a predefined hidden element matching an accepted one" );

ok( $i_hosts, "Created instance" );

my $i_root = $i_hosts->config_root;

is_deeply( [ $i_root->accept_regexp ], [qw/list.* str.* bad.* ot.*/], "check accept_regexp" );

is_deeply( [ $i_root->get_element_name ], [qw/id other/], "check explicit element list" );

is( $i_root->element_type('otary'),'leaf',"check element_type on accepted element");

my $load = "listA=one,two,three,four
listB=1,2,3,4
listC=a,b,c,d
str1=test
str2=of
str3=accept
str4=parameter -
";

$i_root->load($load);
ok( 1, "Data loaded" );

is_deeply( [ $i_root->fetch_element('listC')->fetch_all_values ],
    [qw/a b c d/], "check accepted list content" );

is_deeply(
    [ $i_root->get_element_name ],
    [qw/id listC listB listA other str1 str2 str3 str4/],
    "check element list with accepted parameters"
);

foreach my $oops (qw/foo=bar vlistB=test/) {
    throws_ok { $i_root->load($oops); }
    "Config::Model::Exception::UnknownElement",
        "caught unacceptable parameter: $oops";
}

my $wt = Test::Log::Log4perl->get_logger("User");

### test always_warn parameter
Test::Log::Log4perl->start(ignore_priority => "info");
my $bad = $i_root->fetch_element('badbad');
$wt->warn(qr/gotcha/);
$bad->store('whatever');
Test::Log::Log4perl->end("test unconditional warn");

eval {require Text::Levenshtein::Damerau} ;
my $has_tld = ! $@ ;

SKIP: {
    skip "Text::Levenshtein::Damerau is not installed", 5 unless $has_tld;

    ### test user typo: accepted element is too close to real element
    my @shaves = qw/oter 1 other2 1 otehr 1 other23 1 oterh23 0/;
    while ( my $close_shave = shift @shaves) {
        Test::Log::Log4perl->start(ignore_priority => "info");
        my $expect = shift @shaves;
        my $msg ;
        if ($expect) {
            $wt->warn(qr/distance/);
            $msg = "test $close_shave too close to 'other'";
        }
        else {
            $msg = "test accept $close_shave, is not too close to 'other'";
        }
        $i_root->fetch_element($close_shave);
        Test::Log::Log4perl->end($msg);
    }
}

memory_cycle_ok($model, "memory cycle");

done_testing;
