package Config::Model::Tester;

use Test::More;
use Config::Model;
use Config::Model::Value;
use Log::Log4perl qw(:easy :levels);
use File::Path;
use File::Copy;
use File::Copy::Recursive qw(fcopy rcopy dircopy);
use File::Find;
use Test::Warn;
use Test::Exception;
use Test::Differences;
use locale;
use utf8;

use warnings;

use strict;

use vars qw/$conf_file_name $conf_dir $model_to_test @tests $skip @ISA @EXPORT/;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(run_tests);

$File::Copy::Recursive::DirPerms = 0755;

sub setup_test {
    my ( $model_test, $t_name, $wr_root ) = @_;

    # cleanup before tests
    rmtree($wr_root);
    mkpath( $wr_root, { mode => 0755 } );

    my $wr_dir    = $wr_root . '/test-' . $t_name;
    my $conf_file = "$wr_dir/$conf_dir/$conf_file_name";

    my $ex_data = "t/model_tests.d/$model_test-examples/$t_name";
    my @file_list;
    if ( -d $ex_data ) {

        # copy whole dir
        my $debian_dir = "$wr_dir/$conf_dir";
        dircopy( $ex_data, $debian_dir )
          || die "dircopy $ex_data -> $debian_dir failed:$!";
        find(
            {
                wanted => sub { push @file_list, $_ unless -d; },
                no_chdir => 1
            },
            $debian_dir
        );
    }
    else {

        # just copy file
        fcopy( $ex_data, $conf_file )
          || die "copy $ex_data -> $conf_file failed:$!";
    }
    ok( 1, "Copied $model_test example $t_name" );

    return ( $wr_dir, $conf_file, $ex_data, @file_list );
}

sub run_model_test {
    my ($model_test, $model_test_conf, $do, $model, $trace, $wr_root) = @_ ;

    $skip = 0;

    note("Beginning $model_test test ($model_test_conf)");

    unless ( my $return = do $model_test_conf ) {
        warn "couldn't parse $model_test_conf: $@" if $@;
        warn "couldn't do $model_test_conf: $!" unless defined $return;
        warn "couldn't run $model_test_conf" unless $return;
    }

    if ($skip) {
        note("Skipped $model_test test ($model_test_conf)");
        next;
    }

    note("$model_test uses $model_to_test model on file $conf_file_name");

    my $idx = 0;
    foreach my $t (@tests) {
        my $t_name = $t->{name} || "t$idx";
        if ( defined $do and $do ne $t_name ) {
            $idx++;
            next;
        } 
        note("Beginning subtest $model_test $t_name");

        my ($wr_dir, $conf_file, $ex_data, @file_list) 
            = setup_test ($model_test, $t_name, $wr_root);

        my $inst = $model->instance(
            root_class_name => $model_to_test,
            root_dir        => $wr_dir,
            instance_name   => "$model_test-" . $t_name,
            check           => $t->{load_check} || 'yes',
        );

        my $root = $inst->config_root;

        if ( exists $t->{load_warnings}
            and not defined $t->{load_warnings} )
        {
            local $Config::Model::Value::nowarning = 1;
            $root->init;
            ok( 1,"Read $conf_file and created instance with init() method without warning check" );
        }
        else {
            warnings_like { $root->init; } $t->{load_warnings},
                "Read $conf_file and created instance with init() method with warning check ";
        }

        if ( $t->{load} ) {
            print "Loading $t->{load}\n" if $trace ;
            $root->load( $t->{load} );
            ok( 1, "load called" );
        }

        if ( $t->{apply_fix} ) {
            local $Config::Model::Value::nowarning = 1;
            $inst->apply_fixes;
            ok( 1, "apply_fixes called" );
        }

        print "dumping tree ...\n" if $trace;
        my $dump  = '';
        my $risky = sub {
            $dump = $root->dump_tree( mode => 'full' );
        };

        if ( defined $t->{dump_errors} ) {
            my $nb = 0;
            my @tf = @{ $t->{dump_errors} };
            while (@tf) {
                my $qr = shift @tf;
                throws_ok { &$risky } $qr,
                  "Failed dump $nb of $model_test config tree";
                my $fix = shift @tf;
                $root->load($fix);
                ok( 1, "Fixed error nb " . $nb++ );
            }
        }

        if ( exists $t->{dump_warnings}
            and not defined $t->{dump_warnings} )
        {
            local $Config::Model::Value::nowarning = 1;
            &$risky;
            ok( 1, "Ran dump_tree (no warning check" );
        }
        else {
            warnings_like { &$risky; } $t->{dump_warnings}, "Ran dump_tree";
        }
        ok( $dump, "Dumped $model_test config tree in full mode" );

        print $dump if $trace;

        $dump = $root->dump_tree();
        ok( $dump, "Dumped $model_test config tree in custom mode" );

        foreach my $path ( sort keys %{ $t->{check} || {} } ) {
            my $v = $t->{check}{$path};
            is( $root->grab_value($path), $v, "check $path value" );
        }

        local $Config::Model::Value::nowarning = $t->{no_warnings} || 0;

        $inst->write_back;
        ok( 1, "$model_test write back done" );

        my @new_file_list;
        if ( -d $ex_data ) {

            # copy whole dir
            my $debian_dir = "$wr_dir/$conf_dir" ;
            find(
                {
                    wanted => sub { push @new_file_list, $_ unless -d; },
                    no_chdir => 1
                },
                $debian_dir
            );
            $t->{file_check_sub}->( \@new_file_list )
              if defined $t->{file_check_sub};
            eq_or_diff( \@new_file_list, \@file_list,
                "check added or removed files" );
        }

        # create another instance to read the conf file that was just written
        my $wr_dir2 = $wr_dir . '-w';
        dircopy( $wr_dir, $wr_dir2 )
          or die "can't copy from $wr_dir to $wr_dir2: $!";

        my $i2_test = $model->instance(
            root_class_name => $model_to_test,
            root_dir        => $wr_dir2,
            instance_name   => "$model_test-$t_name-w",
        );

        ok( $i2_test, "Created instance $model_test-test-$t_name-w" );

        my $i2_root = $i2_test->config_root;
        $i2_root->init;

        my $p2_dump = $i2_root->dump_tree();
        ok( $dump, "Dumped $model_test 2nd config tree in custom mode" );

        eq_or_diff( $p2_dump, $dump,
            "compare original $model_test custom data with 2nd instance custom data"
        );

        ok( -s "$wr_dir2/$conf_dir/$conf_file_name" , 
            "check that original $model_test file was not clobbered" );

        note("End of subtest $model_test $t_name");

        $idx++;
    }
    note("End of $model_test test");

}

sub run_tests {
    my ( $arg, $test_only_model, $do ) = @_;

    my ( $log, $show ) = (0) x 2;

    my $trace = ($arg =~ /t/) ? 1 : 0;
    $log  = 1 if $arg =~ /l/;
    $show = 1 if $arg =~ /s/;

    my $log4perl_user_conf_file = $ENV{HOME} . '/.log4config-model';

    if ( $log and -e $log4perl_user_conf_file ) {
        Log::Log4perl::init($log4perl_user_conf_file);
    }
    else {
        Log::Log4perl->easy_init( $log ? $WARN : $ERROR );
    }

    my $model = Config::Model->new();

    Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

    ok( 1, "compiled" );

    # pseudo root where config files are written by config-model
    my $wr_root = 'wr_root';

    my @group_of_tests = grep { /-test-conf.pl/ } glob("t/model_tests.d/*");

    foreach my $model_test_conf (@group_of_tests) {
        my ($model_test) = ( $model_test_conf =~ m!\.d/([\w\-]+)-test-conf! );
        next if ( $test_only_model and $test_only_model ne $model_test ) ; 
        run_model_test($model_test, $model_test_conf, $do, $model, $trace, $wr_root) ;
    }

    done_testing;

}
1;

=head1 NAME

Config::Model::Tester - Test framework for Config::Model

=head1 SYNOPSIS

 # in t/foo.t
 use warnings;
 use strict;

 use Config::Model::Tester ;
 use ExtUtils::testlib;

 my $arg = shift || '';
 my $test_only_model = shift || '';
 my $do = shift ;

 run_tests($arg, $test_only_model, $do) ;


=head1 DESCRIPTION

This class provides a way to test configuration models with tests files. 
This class was designed to tests several models and severals tests 
cases per model.

A specific layout for test files must be followed

=head2 Test file layout

 t/model_tests.d
 |-- fstab-examples
 |   |-- t0
 |   \-- t1
 |-- fstab-test-conf.pl
 |-- debian-dpkg-examples
 |   \-- libversion
 |       \-- debian
 |           |-- changelog
 |           |-- compat
 |           |-- control
 |           |-- copyright
 |           |-- rules
 |           |-- source
 |           |   \-- format
 |           \-- watch
 \-- debian-dpkg-test-conf.pl

In the example above, we have 2 models to test: C<fstab> and C<debian-dpkg>.

Each model test has specification in C<*-test-conf.pl> files. Test cases are 
either plain files or directories in C<*-examples> . The former is fine if 
your model deal with one file (e.g. C</etc/fstab>. Complete directories are
required if your model deal with several files (e.g. Debian source package).

=head2 Basic test specification

Each model test is specified in C<< <model>-test-conf.pl >>. This file
contains a set of global variable. (yes, global variables are often bad ideas
in programs, but they are handy for tests):

 # config file name (used to copy test case into test wr_root directory)
 $conf_file_name = "fstab" ;
 # config dir where to copy the file
 #$conf_dir = "etc" ;

Here, C<t0> file will be copied in C<wr_root/test-t0/etc/fstab>.

 # config model name to test
 $model_to_test = "Fstab" ;

 # list of tests
 @tests = (
    { 
     # test name 
     name => 't0',
     # add optional specification here for t0 test
    },
    { 
     name => 't1',
     # add optional specification here for t1 test
     },
 );

 1; # to keep Perl happy
 
=head2 test scenario

Each subtest follow a sequence explained below. Each step of this
sequence may be altered by adding specification in the test case:

=over

=item *

Setup test in C<< wr_root/<subtest name>/ >>

=item *

Create configuration instance, load config data and check its validity. Use
C<< load_check => 'no' >> if your file is not valid.

=item *

Check for config data warning. You should pass the list of expected warnings.
E.g.  

    load_warnings => [ qr/Missing/, (qr/deprecated/) x 3 , ],

=item *

Optionally load configuration data. You should design this config data to 
suppress any error or warning mentioned above. E.g:

    load => 'binary:seaview Synopsis="multiplatform interface for sequence alignment"',

=item *

Optionally, call L<apply_fixes|Config::Model::Instance/apply_fixes>:

    apply_fix => 1,

=item *

Call L<dump_tree|Config::Model::Node/dump_tree ( ... )> to check the validity of the 
data. Use C<dump_errors> if you expect issues:

    dump_errors =>  [ 
        # the issues     the fix that will be applied
        qr/mandatory/ => 'Files:"*" Copyright:0="(c) foobar"',
        qr/mandatory/ => ' License:FOO text="foo bar" ! Files:"*" License short_name="FOO" '
    ],

=item *

Likewise, specify any expected warnings:

        dump_warnings => [ (qr/deprecated/) x 3 ],

You can tolerate any sump warning this way:

        dump_warnings => undef ,
        
=item * 

Run specific content check to verify that configuration data was retrieved 
correctly:

    check => { 
        'fs:/proc fs_spec',           "proc" ,
        'fs:/proc fs_file',           "/proc" ,
        'fs:/home fs_file',          "/home",
    },

=item *

Write back the config data in C<< wr_root/<subtest name>/ >>. 
You can skip warning when writing back with:

    no_warnings => 1,

=item *

Check added or removed configuration files. If you expect changes, 
specify a subref  to alter the file list:

    file_check_sub => sub { 
        my $file_list_ref = shift ; 
        @$r = grep { ! /home/ } @$r ;
    };

=item *

Copy all config data from C<< wr_root/<subtest name>/ >>
to C<< wr_root/<subtest name>-w/ >>. This steps is necessary
to check that configuration written back has the same content as
the original configuration.

=item *

Create another configuration instance to read the conf file that was just copied
(configuration data is checked.)

=item *

Compare data read from original data.


=back

=head2 running the test

Run all tests:

 perl -Ilib t/model_test.t
 
By default, all tests are run on all models. 

You can pass arguments to C<t/model_test.t>:

=over 

=item *

a bunch of letters. 't' to get test traces. 'e' to get stack trace in case of 
errors, 'l' to have logs. All other letters are ignored. E.g.

  # run with log and error traces
  perl -Ilib t/model_test.t el

=item *

The model name to tests. E.g.:

  # run only fstab tests
  perl -Ilib t/model_test.t x fstab

=item * 

The required subtest E.g.:

  # run only fstab tests t0
  perl -Ilib t/model_test.t x fstab t0
  
=back

=head1 Examples

See http://config-model.hg.sourceforge.net/hgweb/config-model/config-model/file/tip/config-model-core/t/model_tests.d/debian-dpkg-copyright-test-conf.pl

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 

