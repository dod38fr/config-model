# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-03-10 12:57:54 $
# $Revision: 1.5 $

use ExtUtils::testlib;
use Test::More ;
use Config::Model;
use Log::Log4perl qw(:easy) ;
use Data::Dumper ;
use Config::Model::Itself ;
use Tk ;
use File::Path ;
use File::Copy ;
use Config::Model::Itself::TkEditUI;

use warnings;
no warnings qw(once);

use strict;

my ($log,$show) = (0) x 2 ;
my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
$log             = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

print "You can play with the widget if you run the test with 's' argument\n";

my $wr_test = 'wr_test' ;
my $wr_conf1 = "$wr_test/wr_conf1";
my $wr_model1 = "$wr_test/wr_model1";
my $read_dir = 'data' ;

sub wr_cds {
    my ($file,$cds) = @_ ;
    open(CDS,"> $file") || die "can't open $file:$!" ;
    print CDS $cds ;
    close CDS ;
}

# trap warning if Augeas backend is not installed
if (not  eval {require Config::Model::Backend::Augeas; } ) {
    # do not use Test::Warnings with this
    $SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /unknown backend/};
}
else {
    # workaround Augeas locale bug
    no warnings qw/uninitialized/;
    if ($ENV{LC_ALL} ne 'C' or $ENV{LANG} ne 'C') {
	$ENV{LC_ALL} = $ENV{LANG} = 'C';
	my $inc = join(' ',map("-I$_",@INC)) ;
	exec("$^X $inc $0 @ARGV");
    }
}

plan tests => 7 ; # avoid double print of plan when exec is run

Log::Log4perl->easy_init($log ? $DEBUG: $ERROR);

my $meta_model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

rmtree($wr_test) if -d $wr_test ;

mkpath([$wr_conf1, $wr_model1, "$wr_conf1/etc/ssh/"], 0, 0755) ;
copy('augeas_box/etc/ssh/sshd_config', "$wr_conf1/etc/ssh/") ;

my $model = Config::Model->new(legacy => 'ignore',model_dir => $read_dir ) ;
ok(1,"loaded Master model") ;

# check that Master Model can be loaded by Config::Model
my $inst1 = $model->instance (root_class_name   => 'MasterModel', 
			      instance_name     => 'test_orig',
			      root_dir          => $wr_conf1,
			     );
ok($inst1,"created master_model instance") ;

my $root1 = $inst1->config_root ;
my @elt1 = $root1->get_element_name ;

$root1->load("a_string=toto lot_of_checklist macro=AD - "
	    ."! warped_values macro=C where_is_element=get_element "
	    ."                get_element=m_value_element m_value=Cv") ;
ok($inst1,"loaded some data in master_model instance") ;

my $meta_inst = $meta_model->instance (root_class_name   => 'Itself::Model', 
			     instance_name     => 'itself_instance',
			    );
ok($meta_inst,"Read Itself::Model and created instance") ;

my $meta_root = $meta_inst -> config_root ;

my $rw_obj = Config::Model::Itself -> new(model_object => $meta_root) ;

my $map = $rw_obj -> read_all( 
			      model_dir => $read_dir,
			      root_model => 'MasterModel',
			      legacy => 'ignore',
			     ) ;

ok(1,"Read all models in data dir") ;


SKIP: {

    my $mw = eval {MainWindow-> new ; };

    # cannot create Tk window
    skip "Cannot create Tk window",1 if $@;

    $mw->withdraw ;

    my $write_sub = sub { 
	$rw_obj->write_all(model_dir => $wr_model1);
    } ;

    my $cmu = $mw->ConfigModelEditUI (-root => $meta_root,
				      -root_dir => $wr_conf1,
				      -store_sub => $write_sub,
				      -read_model_dir => $read_dir,
				      -write_model_dir => $wr_model1,
				      -model_name => 'MasterModel',
				     ) ;
    my $delay = 200 ;

    sub inc_d { $delay += 1000 } ;

    my $tktree= $cmu->Subwidget('tree') ;
    my $mgr   = $cmu->Subwidget('multi_mgr') ;

    my @test
      = (
         sub { $cmu->create_element_widget('view','itself_instance.class')},
	 sub { $tktree->open('itself_instance.class') },
	 sub { $tktree->open('itself_instance.class.MasterModel') },
	 sub { $cmu -> save ;},
	 sub { $cmu -> test_model ;},
	 sub { $cmu -> test_model ;},
	 #sub { exit; }
        );

    unless ($show) {
        foreach my $t (@test) {
            $mw->after($delay, $t);
            inc_d ;
        }
    }

    ok(1,"window launched") ;

    MainLoop ; # Tk's

}


