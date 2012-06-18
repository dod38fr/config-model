# -*- cperl -*-

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
use File::Copy::Recursive qw(fcopy rcopy dircopy);

use warnings;
no warnings qw(once);

use strict;
$File::Copy::Recursive::DirPerms = 0755;


my ($log,$show) = (0) x 2 ;
my $arg = $ARGV[0] || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /[si]/;

print "You can play with the widget if you run the test with 's' argument\n";

my $wr_test = 'wr_test' ;
my $wr_conf1 = "$wr_test/wr_conf1";
my $wr_model1 = "$wr_test/wr_model1";

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

plan tests => 14 ; # avoid double print of plan when exec is run

my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;

if (-e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($arg =~ /l/ ? $DEBUG: $WARN);
}

my $meta_model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

{
    no warnings "redefine" ;
    sub Tk::Error {
        my ($widget,$error,@locations) = @_;
        die $error ;
    }
}

ok(1,"compiled");

rmtree($wr_test) if -d $wr_test ;

mkpath([$wr_conf1, $wr_model1, "$wr_conf1/etc/ssh/"], 0, 0755) ;
copy('augeas_box/etc/ssh/sshd_config', "$wr_conf1/etc/ssh/") ;
dircopy('data',$wr_model1) || die "cannot copy model data:$!" ;

my $model = Config::Model->new(legacy => 'ignore',model_dir => $wr_model1 ) ;
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

my $meta_inst = $meta_model->instance(
    root_class_name => 'Itself::Model',
    instance_name   => 'itself_instance',
);
ok( $meta_inst, "Read Itself::Model and created instance" );

$meta_inst->initial_load_start ;

my $meta_root = $meta_inst -> config_root ;

my $rw_obj = Config::Model::Itself -> new(
    model_object => $meta_root,
    model_dir => $wr_model1,
) ;



my $map = $rw_obj->read_all(
    root_model => 'MasterModel',
    legacy     => 'ignore',
);
$meta_inst->initial_load_stop ;

ok(1,"Read all models in data dir") ;


SKIP: {

    my $mw = eval {MainWindow-> new ; };

    # cannot create Tk window
    skip "Cannot create Tk window",8 if $@;

    $mw->withdraw ;

    my $write_sub = sub { 
	$rw_obj->write_all();
    } ;

    my $cmu = $mw->ConfigModelEditUI (-root => $meta_root,
				      -root_dir => $wr_conf1,
				      -model_dir => $wr_model1 ,
				      -store_sub => $write_sub,
				      -model_name => 'MasterModel',
				     ) ;
    my $delay = 2000 ;

    my $tktree= $cmu->Subwidget('tree') ;
    my $mgr   = $cmu->Subwidget('multi_mgr') ;

    my @test
      = (
         view => sub { $cmu->create_element_widget('view','itself_instance.class');},
	 open_class => sub { $tktree->open('itself_instance.class');1;},
	 open_instance => sub{$tktree->open('itself_instance.class.MasterModel');1;},
	 # save step is mandatory to avoid interaction
	 save => sub { $cmu -> save ; 1;},
	 'open test window' => sub { $cmu -> test_model ; },
	 'reopen test window' => sub { $cmu -> test_model ; },
	 exit => sub { $cmu->quit ; 1;}
        );

    unless ($show) {
	my $step = 0;

	my $oldsub ;
        while (@test) {
	    # iterate through test list in reverse order
	    my $t = pop @test ;
	    my $k = pop @test ;
	    my $next_sub = $oldsub ;
	    my $s = sub { 
		my $res = &$t; 
		ok($res,"Step ".$step++." $k done");
		$mw->after($delay, $next_sub) if defined $next_sub;
	    };
	    $oldsub = $s ;
        }

	$mw->after($delay, $oldsub) ; # will launch first test
    }

    ok(1,"window launched") ;

    MainLoop ; # Tk's

}


