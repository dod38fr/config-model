# -*- cperl -*-
# $Author$
# $Date$
# $Revision$
use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 5 ;
use Tk;
use Config::Model::TkUI;
use Config::Model ;
use Log::Log4perl qw(:easy) ;


use strict;

my $arg = shift || '';

my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
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
std_id:ab X=Bv -
std_id:ab2 -
std_id:bc X=Av -
std_id:"a b" X=Av -
std_id:"a b.c" X=Av -
tree_macro=mXY
a_string="toto tata"
a_long_string="a very long string with\nembedded return"
hash_a:toto=toto_value
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

ok( $root->load( step => $step, permission => 'advanced' ),
  "set up data in tree");

my $load_fix = "a_mandatory_string=foo1 another_mandatory_string=foo2 
                ordered_hash_of_mandatory:foo=hashfoo 
                warp a_string=warpfoo a_long_string=longfoo another_string=anotherfoo -
                slave_y a_string=slave_y_foo a_long_string=sylongfoo another_string=sy_anotherfoo" ;

#$root->load(step => "tree_macro=XZ", permission => 'advanced') ;

$root->fetch_element('ordered_hash_of_mandatory')->fetch_with_id('foo') ;

# use Tk::ObjScanner; Tk::ObjScanner::scan_object($root) ;

my $toto ;


# TBD eval this and skip test in case of failure.
SKIP: {

    my $mw = eval {MainWindow-> new ; };

    # cannot create Tk window
    skip "Cannot create Tk window",1 if $@;

    $mw->withdraw ;

    my $cmu = $mw->ConfigModelUI (-root => $root, 
			     ) ;

    my $delay = 200 ;
    
    sub inc_d { $delay += 400 } ;

    my $tktree= $cmu->Subwidget('tree') ;
    my $mgr   = $cmu->Subwidget('multi_mgr') ;
    my $widget ; # ugly global variable. Use with care

    my @force_test 
      = (
	 sub { $cmu->reload} ,
	 sub { $cmu->force_element_display($root->grab('std_id:dd DX')) },
	 sub { $cmu->edit_copy('test1.std_id')},
	 sub { $cmu->force_element_display($root->grab('hash_a:titi')) },
	 sub { $cmu->edit_copy('test1.hash_a.titi')},
	 #sub { $cmu->edit_paste('test1.hash_b')},
	 #sub { $cmu->force_element_display($root->grab('hash_b:titi')) },
	) ;

    my @test 
      = (
	 sub { $cmu->create_element_widget('view','test1')},
	 sub { $tktree->open('test1.lista') },
	 sub { $cmu->create_element_widget('edit','test1.std_id');},
	 sub { $cmu->{editor}->add_entry('e')},
	 sub { $tktree->open('test1.std_id') },
	 sub { $cmu->reload} ,
	 sub { $cmu->create_element_widget('view','test1.std_id')},
	 sub { $cmu->create_element_widget('edit','test1.std_id')},
	 sub { $tktree->open('test1.std_id.ab') },
	 sub { $cmu->create_element_widget('view','test1.std_id.ab.Z')},
	 sub { $root->load(step => "std_id:ab Z=Cv") ; $cmu->reload ;},
	 sub { $tktree->open('test1.std_id.ab') },
	 sub { $cmu->create_element_widget('edit','test1.std_id.ab.DX')},
	 sub { $root->load(step => "std_id:ab3") ; $cmu->reload ;} ,
	 sub { $cmu->create_element_widget('view','test1.string_with_def')},
	 sub { $cmu->create_element_widget('edit','test1.string_with_def')},
	 sub { $cmu->create_element_widget('view','test1.a_long_string')},
	 sub { $cmu->create_element_widget('edit','test1.a_long_string')},
	 sub { $cmu->create_element_widget('view','test1.int_v')},
	 sub { $cmu->create_element_widget('edit','test1.int_v')},
	 sub { $cmu->create_element_widget('view','test1.my_plain_check_list')},
	 sub { $cmu->create_element_widget('edit','test1.my_plain_check_list')},
	 sub { $cmu->create_element_widget('view','test1.my_ref_check_list')},
	 sub { $cmu->create_element_widget('edit','test1.my_ref_check_list')},
	 sub { $cmu->create_element_widget('view','test1.my_reference')},
	 sub { $cmu->create_element_widget('edit','test1.my_reference')},

	 sub { $root->load(step => "ordered_checklist=A,Z,G") ; $cmu->reload ;} ,
	 sub { $widget = $cmu->create_element_widget('edit','test1.ordered_checklist')},
	 sub { $widget->Subwidget('notebook')->raise('order') ;},
	 sub { $widget->Subwidget('notebook')->raise('order') ;},
	 sub { $widget->{order_list}->selectionSet(1,1) ;}, # Z
	 sub { $widget->move_selected_down ;},
	 sub { $cmu->save()},
	 sub {
	     for ($cmu->children) { $_->destroy if $_->name =~ /dialog/i; } ;
	     $root->load($load_fix);},
	 sub { $cmu->save()},

	 sub { exit; }
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
