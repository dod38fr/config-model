# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 34 ;
use Config::Model ;
use Log::Log4perl qw(:easy :levels) ;
use File::Path ;
use File::Copy ;
use File::Copy::Recursive qw(fcopy rcopy dircopy) ;
use Test::Warn ;
use Test::Exception ;
use Test::Differences ;

use warnings;

use strict;

$File::Copy::Recursive::DirPerms = 0755 ;

use vars qw/$conf_file_name $conf_dir $model_to_test @tests/ ;

my $arg = shift || '';
my $test_only_model = shift || '';
my $do = shift ;

my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($log ? $WARN: $ERROR);
}

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root';

my @group_of_tests = grep {/-test-conf.pl/} glob("t/model_tests.d/*") ;

foreach my $model_test_conf (@group_of_tests) {
    my ($model_test) = ($model_test_conf =~ m!\.d/([\w\-]+)-test-conf! );
    next if ($test_only_model and $test_only_model ne $model_test) ;
    
    note("Beginning $model_test test ($model_test_conf)");

    unless (my $return = do $model_test_conf ) {
        warn "couldn't parse $model_test_conf: $@" if $@;
        warn "couldn't do $model_test_conf: $!"    unless defined $return;
        warn "couldn't run $model_test_conf"       unless $return;
    }
    note("$model_test uses $model_to_test model on file $conf_file_name");

    my $idx = 0 ;
    foreach my $t (@tests) {
        if (defined $do and $do ne $idx) { $idx ++; next; }
        note("Beginning $model_test subtest $idx");
   
        # cleanup before tests
        rmtree($wr_root);
        mkpath($wr_root, { mode => 0755 }) ;

        my $wr_dir = $wr_root.'/test-'.$idx ;
        my $conf_file = "$wr_dir/$conf_dir/$conf_file_name" ;

        my $ex_data = "t/model_tests.d/$model_test-examples/t$idx" ;
        if (-d $ex_data) {
            # copy whole dir
            my $debian_dir = "$wr_dir/$conf_dir";
            dircopy($ex_data,$debian_dir)  || die "dircopy $ex_data -> $debian_dir failed:$!";
        }
        else {
            # just copy file
            fcopy($ex_data , $conf_file) 
                || die "copy $ex_data -> $conf_file failed:$!";
        }
        ok(1,"Copied $model_test example $idx") ;

        my $inst = $model->instance (root_class_name   => $model_to_test,
                                    root_dir           => $wr_dir,
                                    instance_name      => "$model_test-test".$idx,
                                   ); 

        my $root = $inst -> config_root ;

        if (exists $t->{load_warnings} and not defined $t->{load_warnings}) {
            $root->init; 
            ok(1,"Read $conf_file and created instance with init() method without warning check");
        }
        else {
            warnings_like { $root->init;   } $t->{load_warnings} , 
                "Read $conf_file and created instance with init() method with warning check " ;
        }
        
        if ($t->{load}) {
            $root->load($t->{load}) ;
            ok (1,"load called");
        }
        
        if ($t->{apply_fix}) {
            $inst->apply_fixes ;
            ok (1,"apply_fixes called");
        }

        print "dumping tree ...\n" if $trace ;
        my $dump = '';
        my $risky = sub {
            $dump = $root->dump_tree (full_dump => 1); 
        } ;
    
        if (defined $t->{dump_errors} ) {
            my $nb = 0 ;
            my @tf = @{$t->{dump_errors}} ;
            while (@tf) {
                my $qr = shift @tf ;
                throws_ok { &$risky }  $qr , "Failed dump $nb of $model_test config tree" ;
                my $fix = shift @tf;
                $root->load($fix);
                ok(1, "Fixed error nb ".$nb++);
            }
        }
        
        if (exists $t->{dump_warnings} and not defined $t->{dump_warnings}) {
            &$risky;
            ok(1,"Ran dump_tree (no warning check");
        }
        else {
            warnings_like { &$risky; } $t->{dump_warnings} , 
                "Ran dump_tree" ;
        }
        ok($dump, "Dumped $model_test config tree" ) ;
    
        print $dump if $trace ;

        foreach my $path (sort keys %{$t->{check} || {}}) { 
            my $v = $t->{check}{$path} ;
            is($root->grab_value($path),$v,"check $path value");
        }
   
        $inst->write_back ;
        ok(1,"$model_test write back done") ;

        # create another instance to read the conf file that was just written
        my $wr_dir2 = $wr_dir.'-w' ;
        dircopy($wr_dir,$wr_dir2) 
            or die "can't copy from $wr_dir to $wr_dir2: $!";

        my $i2_test = $model->instance(
            root_class_name => $model_to_test,
            root_dir        => $wr_dir2,
            instance_name   => "$model_test-test-$idx-w",
        );

        ok( $i2_test, "Created instance $model_test-test-$idx-w" );

        my $i2_root = $i2_test->config_root ;

        my $p2_dump = $i2_root->dump_tree(full_dump => 1) ;

        eq_or_diff($p2_dump,$dump,"compare original $model_test data with 2nd instance data") ;
   
        ok( -s "$wr_dir2/$conf_dir/$conf_file_name",
            "check that original $model_test file was not clobbered");

        note("End of $model_test subtest $idx");
   
        $idx++ ;
    }
    note("End of $model_test test");
}

