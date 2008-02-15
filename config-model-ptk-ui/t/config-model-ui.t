# -*- cperl -*-
# $Author: ddumont $
# $Date: 2008-02-15 12:19:49 $
# $Name: not supported by cvs2svn $
# $Revision: 1.3 $
use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More tests => 98 ;
use Tk;
use Config::Model::TkUi;
use Config::Model ;
use Log::Log4perl qw(:easy) ;


use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
my $log             = 1 if $arg =~ /l/;

Log::Log4perl->easy_init($log ? $TRACE: $WARN);

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"Compilation done");

my $model = Config::Model -> new ;

my $inst = $model->instance (root_class_name => 'Master',
                             model_file => 't/big_model.pm',
                             instance_name => 'test1');

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

#$root->load(step => "tree_macro=XZ", permission => 'advanced') ;

my $toto ;
my $mw = MainWindow-> new ;
$mw->withdraw ;

my $cmu = $mw->ConfigModelUi (-root => $root, 
			     ) ;

my $delay = 200 ;

sub inc_d { $delay += 200 } ;

my $tktree= $cmu->Subwidget('tree') ;
my $mgr   = $cmu->Subwidget('multi_mgr') ;

my @test = (
	    sub { $tktree->open('test1.std_id') },
	    sub { $cmu->reload} ,
	    sub { $cmu->create_modify_widget('test1.std_id')},
	    sub { $root->load(step => "std_id:ab3") ; $cmu->reload ;} ,
	   );

unless ($trace) {
    foreach my $t (@test) {
	#$mw->after($delay, $t);
	inc_d ;
    }
}


MainLoop ; # Tk's

