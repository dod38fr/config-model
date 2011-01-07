# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 53 ;
use Test::Warn ;
use Tk;
use Config::Model::TkUI;
use Config::Model ;
use Log::Log4perl qw(:easy) ;


use strict;

my $arg = shift || '';

my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s|i/;

print "You can play with the widget if you run the test with 's' argument\n";

Log::Log4perl->easy_init($log ? $TRACE: $WARN);

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"Compilation done");

my $model = Config::Model -> new () ;

my $inst = $model->instance (root_class_name => 'Master',
                             model_file => 't/big_model.pm',
			     instance_name => 'test1',
			     root_dir   => 'wr_data',
			    );

ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;
ok($root,"Config root created") ;


my $step = qq!
#"class comment\nbig\nreally big"
std_id#"std_id comment"
std_id:ab X=Bv -
std_id:ab2 -
std_id:bc X=Av -
std_id:"a b" X=Av -
std_id:"a b.c" X=Av -
tree_macro=mXY#"big lever here"
a_string="utf8 smiley \x{263A}"
a_long_string="a very long string with\nembedded return"
hash_a:toto=toto_value
hash_a:toto#"index comment"
hash_a:titi=titi_value
hash_a:"ti ti"="ti ti value"
ordered_hash:z=1
ordered_hash:y=2
ordered_hash:x=3
ordered_hash_of_nodes:N1 X=Av -
ordered_hash_of_nodes:N2 X=Bv -
lista=a,b,c,d
olist:0 X=Av -
olist:1 X=Bv -
my_ref_check_list=toto 
my_reference="titi"
my_plain_check_list=AA,AC
warp warp2 aa2="foo bar"
!;

ok( $root->load( step => $step, experience => 'advanced' ),
  "set up data in tree");

my $load_fix = "a_mandatory_string=foo1 another_mandatory_string=foo2 
                ordered_hash_of_mandatory:foo=hashfoo 
                warp a_string=warpfoo a_long_string=longfoo another_string=anotherfoo -
                slave_y a_string=slave_y_foo a_long_string=sylongfoo another_string=sy_anotherfoo" ;

#$root->load(step => "tree_macro=XZ", experience => 'advanced') ;

$root->fetch_element('ordered_hash_of_mandatory')->fetch_with_id('foo') ;

# use Tk::ObjScanner; Tk::ObjScanner::scan_object($root) ;

# TBD eval this and skip test in case of failure.
SKIP: {

    my $mw = eval {MainWindow-> new ; };

    # cannot create Tk window
    skip "Cannot create Tk window",48 unless $mw;

    $mw->withdraw ;

    my $cmu = $mw->ConfigModelUI (-root => $root, 
			     ) ;

    my $delay = 200 ;
    
    sub inc_d { $delay += 500 } ;

    my $tktree= $cmu->Subwidget('tree') ;
    my $mgr   = $cmu->Subwidget('multi_mgr') ;
    my $widget ; # ugly global variable. Use with care
    my $idx = 1 ;

    my @force_test 
      = (
	 sub { $cmu->reload ; ok(1,"forced test: reload") } ,
	) ;

    my @test 
      = (
	 sub { $cmu->create_element_widget('edit','test1'); ok(1,"test ".$idx++)},
	 sub { $cmu->force_element_display($root->grab('std_id:dd DX')) ; ok(1,"test ".$idx++)},
	 sub { $cmu->edit_copy('test1.std_id'); ok(1,"test ".$idx++)},
	 sub { $cmu->force_element_display($root->grab('hash_a:titi')) ; ok(1,"test ".$idx++)},
	 sub { $cmu->edit_copy('test1.hash_a.titi'); ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('view','test1'); ok(1,"test ".$idx++)},
	 sub { $tktree->open('test1.lista') ; ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('edit','test1.std_id');; ok(1,"test ".$idx++)},
	 sub { $cmu->{editor}->add_entry('e'); ok(1,"test ".$idx++)},
	 sub { $tktree->open('test1.std_id') ; ok(1,"test ".$idx++)},
	 sub { $cmu->reload; ok(1,"test ".$idx++)} ,
	 sub { $cmu->create_element_widget('view','test1.std_id'); ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('edit','test1.std_id'); ok(1,"test ".$idx++)},
	 sub { $tktree->open('test1.std_id.ab') ; ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('view','test1.std_id.ab.Z'); ok(1,"test ".$idx++)},
	 sub { $root->load(step => "std_id:ab Z=Cv") ; $cmu->reload ;; ok(1,"test ".$idx++)},
	 sub { $tktree->open('test1.std_id.ab') ; ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('edit','test1.std_id.ab.DX'); ok(1,"test ".$idx++)},
	 sub { $root->load(step => "std_id:ab3") ; $cmu->reload ;; ok(1,"test ".$idx++)} ,
	 sub { $cmu->create_element_widget('view','test1.string_with_def'); ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('edit','test1.string_with_def'); ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('view','test1.a_long_string'); ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('edit','test1.a_long_string'); ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('view','test1.int_v'); ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('edit','test1.int_v'); ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('view','test1.my_plain_check_list'); ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('edit','test1.my_plain_check_list'); ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('view','test1.my_ref_check_list'); ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('edit','test1.my_ref_check_list'); ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('view','test1.my_reference'); ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('edit','test1.my_reference'); ok(1,"test ".$idx++)},

	 sub { $root->load(step => "ordered_checklist=A,Z,G") ; $cmu->reload ;; ok(1,"test ".$idx++)} ,
	 sub { $widget = $cmu->create_element_widget('edit','test1.ordered_checklist'); ok(1,"test ".$idx++)},
	 sub { $widget->Subwidget('notebook')->raise('order') ;; ok(1,"test ".$idx++)},
	 sub { $widget->Subwidget('notebook')->raise('order') ;; ok(1,"test ".$idx++)},
	 sub { $widget->{order_list}->selectionSet(1,1) ;; ok(1,"test ".$idx++)}, # Z
	 sub { $widget->move_selected_down ;; ok(1,"test ".$idx++)},
	 sub { $cmu->save(); ok(1,"test ".$idx++)},
	 sub {
	     for ($cmu->children) { $_->destroy if $_->name =~ /dialog/i; } ;
	     $root->load($load_fix);; ok(1,"test ".$idx++)},
	 sub { $cmu->save(); ok(1,"test ".$idx++)},
	 sub { $cmu->create_element_widget('edit','test1.always_warn');
		$cmu -> force_element_display($root->grab('always_warn')) ; 
	    ; ok(1,"test ".$idx++)},

	 # warn test, 3 warnings: load, fetch for hlist, fetch for editor
	 sub { warnings_like { $root->load("always_warn=foo") ; $cmu->reload ;}
	       [ qr/always/ , qr/always/, qr/always/] ,"warn test ".$idx++ ;
	     },
	 sub { $root->load('always_warn~') ; $cmu->reload ;; ok(1,"test ".$idx++)},

	 sub { $cmu->create_element_widget('edit','test1.warn_unless');
	       $cmu -> force_element_display($root->grab('warn_unless')) ; 
	       ok(1,"test ".$idx++);
	     },

	 sub { warnings_like { $root->load("warn_unless=bar") ; $cmu->reload ;}
	       [ qr/warn_unless/ , qr/warn_unless/, qr/warn_unless/] ,"warn test ".$idx++ ;
	     },
	 sub { $root->load('warn_unless=foo2') ; $cmu->reload ;; ok(1,"test ".$idx++)},

	 sub { $mw->destroy; }
	);

    foreach my $t (@force_test) {
	$mw->after($delay, $t);
	inc_d ;
    }

    unless ($show) {
	foreach my $t (@test) {
	    $mw->after($delay, $t);
	    inc_d ;
	}
    }

    ok(1,"window launched") ;

    MainLoop ; # Tk's

}

ok(1,"All tests are done");
