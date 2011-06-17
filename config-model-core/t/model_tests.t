# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 22 ;
use Config::Model ;
use Log::Log4perl qw(:easy :levels) ;
use File::Path ;
use File::Copy ;
use Test::Warn ;
use Test::Exception ;
use Test::Differences ;

use warnings;

use strict;

use vars qw/$conf_file_name $model_to_test @tests/ ;

my $arg = shift || '';

my ($log,$show) = (0) x 2 ;
my $do ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;
$do                 = $1 if $arg =~ /(\d+)/;

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

# cleanup before tests
rmtree($wr_root);
mkpath($wr_root, { mode => 0755 }) ;

my @group_of_tests = grep {/-test-conf.pl/} glob("t/model_tests.d/*") ;

foreach my $model_test_conf (@group_of_tests) {
    my ($model_test) = ($model_test_conf =~ m!\.d/(\w+)-! );
    note("Beginning $model_test test ($model_test_conf)");

    unless (my $return = do $model_test_conf ) {
        warn "couldn't parse $model_test_conf: $@" if $@;
        warn "couldn't do $model_test_conf: $!"    unless defined $return;
        warn "couldn't run $model_test_conf"       unless $return;
    }
    note("$model_test uses $model_to_test model on file $conf_file_name");

    my $idx = 0 ;
    foreach my $t (@tests) {
        note("Beginning $model_test subtest $idx");
        if (defined $do and $do ne $idx) { $idx ++; next; }
   
        my $wr_dir = $wr_root.'/test-'.$idx ;
        mkpath($wr_dir."/etc/", { mode => 0755 }) ;
        my $conf_file = "$wr_dir/etc/$conf_file_name" ;

        my $ex_file = "t/model_tests.d/$model_test-examples/t$idx" ;
        copy($ex_file , $conf_file) 
            || die "copy $ex_file -> $conf_file failed:$!";
        ok(1,"Copied lcdd example $idx") ;

        my $inst = $model->instance (root_class_name   => $model_to_test,
                                    root_dir           => $wr_dir,
                                    instance_name      => "$model_test-test".$idx,
                                   ); 

        my $root = $inst -> config_root ;
        warnings_like { $root->init;   } $t->{warnings} , 
            "Read $conf_file and created instance" ;

        print "dumping tree ...\n" if $trace ;
        my $dump = '';
        my $risky = sub {$dump = $root->dump_tree (full_dump => 1); } ;
    
        if (defined $t->{errors} ) {
            my $nb = 0 ;
            my @tf = @{$t->{errors}} ;
            while (@tf) {
                my $qr = shift @tf ;
                throws_ok { &$risky }  $qr , "Failed dump $nb of $model_test config tree" ;
                my $fix = shift @tf;
                $root->load($fix);
                ok(1, "Fixed error nb ".$nb++);
            }
            &$risky; 
        }
        else {
            &$risky ;
            ok($dump, "Dumped $model_test config tree" ) ;
        }
    
        print $dump if $trace ;

        foreach my $path (sort keys %{$t->{check} || {}}) { 
            my $v = $t->{check}{$path} ;
            is($root->grab_value($path),$v,"check $path value");
        }
   
        $inst->write_back ;
        ok(1,"$model_test write back done") ;

        # create another instance to read the conf file that was just written
        my $wr_dir2 = $wr_dir.'-w' ;
        mkpath($wr_dir2.'/etc',{ mode => 0755 })   || die "can't mkpath: $!";
        copy($wr_dir.'/etc/'.$conf_file_name,$wr_dir2.'/etc') 
            or die "can't copy from $wr_dir to $wr_dir2: $!";

        my $i2_test = $model->instance(
            root_class_name => $model_to_test,
            root_dir        => $wr_dir2,
            instance_name   => "lcddtest" . $idx . "-w",
        );

        ok( $i2_test, "Created instance $idx-w" );

        my $i2_root = $i2_test->config_root ;

        my $p2_dump = $i2_root->dump_tree(full_dump => 1) ;

        eq_or_diff($p2_dump,$dump,"compare original $model_test data with 2nd instance data") ;
   
        ok( -s $wr_dir2.'/etc/'.$conf_file_name,
            "check that original $model_test file was not clobbered");

        note("End of $model_test subtest $idx");
   
        $idx++ ;
    }
    note("End of $model_test test");
}

