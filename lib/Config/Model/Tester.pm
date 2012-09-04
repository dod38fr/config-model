package Config::Model::Tester;

use Test::More;
use Config::Model;
use Config::Model::Value;
use Log::Log4perl qw(:easy :levels);
use File::Path;
use File::Copy;
use File::Copy::Recursive qw(fcopy rcopy dircopy);
use File::Find;
use File::Spec ;
use Test::Warn;
use Test::Exception;
use Test::File::Contents ;
use Test::Differences;
use Test::Memory::Cycle ;
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

    my $wr_dir    = $wr_root . '/test-' . $t_name.'/';
    my $conf_file ;
    $conf_file = "$wr_dir/$conf_dir/$conf_file_name" if defined $conf_file_name;

    my $ex_data = "t/model_tests.d/$model_test-examples/$t_name";
    my @file_list;
    if ( -d $ex_data ) {

        # copy whole dir
        my $debian_dir = "$wr_dir/" ;
        $debian_dir .= $conf_dir if $conf_dir;
        dircopy( $ex_data, $debian_dir )
          || die "dircopy $ex_data -> $debian_dir failed:$!";
        @file_list = list_test_files ($debian_dir);
    }
    else {

        # just copy file
        fcopy( $ex_data, $conf_file )
          || die "copy $ex_data -> $conf_file failed:$!";
    }
    ok( 1, "Copied $model_test example $t_name" );

    return ( $wr_dir, $conf_file, $ex_data, @file_list );
}

#
# New subroutine "list_test_files" extracted - Thu Nov 17 17:27:20 2011.
#
sub list_test_files {
    my $debian_dir = shift;
    my @file_list ;

    find(
        {
            wanted => sub { push @file_list, $_ unless -d; },
            no_chdir => 1
        },
        $debian_dir
    );
    map { s!^$debian_dir!/!; } @file_list;
    return sort @file_list;
}

sub run_model_test {
    my ($model_test, $model_test_conf, $do, $model, $trace, $wr_root) = @_ ;

    $skip = 0;
    undef $conf_file_name ;
    undef $conf_dir ;

    note("Beginning $model_test test ($model_test_conf)");

    unless ( my $return = do $model_test_conf ) {
        warn "couldn't parse $model_test_conf: $@" if $@;
        warn "couldn't do $model_test_conf: $!" unless defined $return;
        warn "couldn't run $model_test_conf" unless $return;
    }

    if ($skip) {
        note("Skipped $model_test test ($model_test_conf)");
        return;
    }

    my $note ="$model_test uses $model_to_test model";
    $note .= " on file $conf_file_name" if defined $conf_file_name;
    note($note);

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
            
        if ($t->{config_file}) { 
            my ($v,$local_conf_dir,$f) = File::Spec->splitpath($wr_dir.$t->{config_file}) ;
            mkpath($local_conf_dir,{mode => 0755} );
        }

        my $inst = $model->instance(
            root_class_name => $model_to_test,
            root_dir        => $wr_dir,
            instance_name   => "$model_test-" . $t_name,
            config_file     => $t->{config_file} ,
            check           => $t->{load_check} || 'yes',
        );

        my $root = $inst->config_root;

        if ( exists $t->{load_warnings}
            and not defined $t->{load_warnings} )
        {
            local $Config::Model::Value::nowarning = 1;
            $root->init;
            ok( 1,"Read configuration and created instance with init() method without warning check" );
        }
        else {
            warnings_like { $root->init; } $t->{load_warnings},
                "Read configuration and created instance with init() method with warning check ";
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
            ok( 1, "Ran dump_tree (no warning check)" );
        }
        else {
            warnings_like { &$risky; } $t->{dump_warnings}, "Ran dump_tree";
        }
        ok( $dump, "Dumped $model_test config tree in full mode" );

        print $dump if $trace;

        local $Config::Model::Value::nowarning = $t->{no_warnings} || 0;

        $dump = $root->dump_tree();
        ok( $dump, "Dumped $model_test config tree in custom mode" );

        my $check = $t->{check} || {};
        foreach my $path ( sort keys %$check ) {
                my $v = $check->{$path};
                my $check_v = ref $v ? delete $v->{value} : $v ;
                my @check_args = ref $v ? %$v : ();
                is( $root->grab(step => $path, @check_args)->fetch (@check_args), 
                    $check_v, "check $path value (@check_args)" );
        }

        if (my $annot_check = $t->{verify_annotation}) {
            foreach my $path (keys %$annot_check) {
                my $note = $annot_check->{$path};
                is( $root->grab($path)->annotation, 
                    $note, "check $path annotation" );
            } 
        }

        $inst->write_back( force => 1 );
        ok( 1, "$model_test write back done" );
        
        if (my $fc = $t->{file_content}) {
            foreach my $f (keys %$fc) {
                file_contents_eq_or_diff $wr_dir.$f,  $fc->{$f},  "check content of $f";
            } 
        }

        if (my $fc = $t->{file_contents_like}) {
            foreach my $f (keys %$fc) {
                file_contents_like $wr_dir.$f,  $fc->{$f},  "check that $f matches regexp";
            } 
        }

        if (my $fc = $t->{file_contents_unlike}) {
            foreach my $f (keys %$fc) {
                file_contents_unlike $wr_dir.$f,  $fc->{$f},  "check that $f does not match regexp";
            } 
        }

        my @new_file_list;
        if ( -d $ex_data ) {

            # copy whole dir
            my $debian_dir = "$wr_dir/" ;
            $debian_dir .= $conf_dir if $conf_dir;
            my @new_file_list = list_test_files($debian_dir) ;
            $t->{file_check_sub}->( \@file_list )
              if defined $t->{file_check_sub};
            eq_or_diff( \@new_file_list, [ sort @file_list ],
                "check added or removed files" );
        }

        # create another instance to read the conf file that was just written
        my $wr_dir2 = $wr_dir ;
        $wr_dir2 =~ s!/$!-w/!;
        dircopy( $wr_dir, $wr_dir2 )
          or die "can't copy from $wr_dir to $wr_dir2: $!";

        my $i2_test = $model->instance(
            root_class_name => $model_to_test,
            root_dir        => $wr_dir2,
            config_file     => $t->{config_file} ,
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
            "check that original $model_test file was not clobbered" )
                if defined $conf_file_name ;

        my $wr_check = $t->{wr_check} || {};
        foreach my $path ( sort keys %$wr_check ) {
            my $v          = $wr_check->{$path};
            my $check_v    = ref $v ? delete $v->{value} : $v;
            my @check_args = ref $v ? %$v : ();
            is( $i2_root->grab( step => $path, @check_args )->fetch(@check_args),
                $check_v, "wr_check $path value (@check_args)" );
        }

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

    my $log4perl_user_conf_file = ($ENV{HOME} || '') . '/.log4config-model';

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

    my @group_of_tests = grep { /-test-conf.pl$/ } glob("t/model_tests.d/*");

    foreach my $model_test_conf (@group_of_tests) {
        my ($model_test) = ( $model_test_conf =~ m!\.d/([\w\-]+)-test-conf! );
        next if ( $test_only_model and $test_only_model ne $model_test ) ; 
        run_model_test($model_test, $model_test_conf, $do, $model, $trace, $wr_root) ;
    }

    memory_cycle_ok($model,"test memory cycle") ; 

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
This class was designed to tests several models and several tests 
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
 
=head2 Test specification with arbitrary file names

In some models (e.g. C<Multistrap>, the config file is chosen by the user. 
In this case, the file name must be specified for each tests case:

 $model_to_test = "Multistrap";

 @tests = (
    {
        name        => 'arm',
        config_file => '/home/foo/my_arm.conf',
        check       => {},
    },
 );


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
    
Use an empty array_ref to masks load warnings.

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

Likewise, specify any expected warnings (note the list must contain only C<qr> stuff):

        dump_warnings => [ (qr/deprecated/) x 3 ],

You can tolerate any dump warning this way:

        dump_warnings => undef ,

=item * 

Run specific content check to verify that configuration data was retrieved 
correctly:

    check => { 
        'fs:/proc fs_spec',           "proc" ,
        'fs:/proc fs_file',           "/proc" ,
        'fs:/home fs_file',          "/home",
    },
    
You can run check using different check modes (See L<Config::Model::Value/"fetch( ... )">)
by passing a hash ref instead of a scalar :
    
    check  => {
        'sections:debian packages:0' , { qw/mode layered value dpkg-dev/},
        ''sections:base packages:0',   { qw/mode layered value gcc-4.2-base/},
    },

The whole hash content (except "value") is passed to  L<grab|Config::Model::AnyThing/"grab(...)"> 
and L<fetch|Config::Model::Value/"fetch( ... )">

=item *

Verify annotation extracted from the configuration file comments:

    verify_annotation => {
            'source Build-Depends' => "do NOT add libgtk2-perl to build-deps (see bug #554704)",
            'source Maintainer' => "what a fine\nteam this one is",
        },


=item *

Write back the config data in C<< wr_root/<subtest name>/ >>. 
Note that write back is forced, so the tested configuration files are
written back even if the configuration values were not changed during the test.

You can skip warning when writing back with:

    no_warnings => 1,

=item *

Check the content of the written files(s) with L<Test::File::Contents>:

   file_content => { 
            "/home/foo/my_arm.conf" => "really big string" ,
        }
   
   file_contents_like => {
            "/home/foo/my_arm.conf" => qr/should be there/ ,
   }

   file_contents_unlike => {
            "/home/foo/my_arm.conf" => qr/should NOT be there/ ,
   }

=item *

Check added or removed configuration files. If you expect changes, 
specify a subref to alter the file list:

    file_check_sub => sub { 
        my $list_ref = shift ; 
        # file added during tests
        push @$list_ref, "/debian/source/format" ;
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

=item *

Run specific content check on the B<written> config file to verify that
configuration data was written and retrieved correctly:


    wr_check => { 
        'fs:/proc fs_spec',           "proc" ,
        'fs:/proc fs_file',           "/proc" ,
        'fs:/home fs_file',          "/home",
    },

Like the C<check> item explained above, you can run check using
different check modes.

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

