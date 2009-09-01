# -*- cperl -*-
# $Author: ddumont $
# $Date: 2009-06-29 14:41:07 +0200 (Mon, 29 Jun 2009) $
# $Revision: 994 $
use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 5 ;
use Tk;
use Config::Model::TkUI;
use Config::Model ;
use Log::Log4perl qw(get_logger :levels) ;


use strict;

my $arg = shift || '';

my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s|i/;

print "You can play with the widget if you run the test with 's' argument\n";

my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;
if (-r $log4perl_user_conf_file) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($log ? $TRACE: $WARN);
}

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

# use Tk::ObjScanner; Tk::ObjScanner::scan_object($root) ;

my $toto ;


# TBD eval this and skip test in case of failure.
SKIP: {

    my $mw = eval {MainWindow-> new ; };

    # cannot create Tk window
    skip "Cannot create Tk window",1 if $@;

    $mw->withdraw ;

    my $cmw = $mw->ConfigModelWizard (-root => $root, 
				      -store_cb => sub{},
				     ) ;

    my $delay = 1000 ;

    sub inc_d { $delay += 500 } ;

    my @test ;
    foreach (1 .. 4 ) {
	push @test, sub {$cmw->{keep_wiz} = 0 ; $cmw->{wizard}->go_forward; } ;
    }
    foreach (1 .. 2 ) {
	push @test, sub {$cmw->{keep_wiz} = 0 ; $cmw->{wizard}->go_backward;} ;
    }
    # no problem if too many subs are defined: programs will exit
    foreach (1 .. 100 ) {
	push @test, sub {$cmw->{keep_wiz} = 0 ; $cmw->{wizard}->go_forward; } ;
    }


    unless ($show) {
 	foreach my $t (@test) {
 	    $mw->after($delay, $t);
 	    inc_d ;
 	}
    }

    $cmw->_start_wizard('master') ;

    ok(1,"wizard done") ;

}
