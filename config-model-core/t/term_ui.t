# -*- cperl -*-
# $Author: ddumont $
# $Date: 2007-10-19 11:43:42 $
# $Name: not supported by cvs2svn $
# $Revision: 1.8 $

use ExtUtils::testlib;
use Test::More ;

# this block is necessary to avoid failure on some automatic cpan
# testers setup which fail while loading Term::ReadLine
BEGIN { 
    eval { require Term::ReadLine ;
	   my $test = new Term::ReadLine 'Test' ;
       } ;
    if ($@) {
	plan skip_all => "Cannot load Term::ReadLine" ;
    }
    else {
	plan tests => 22 ;
    }


}

use Config::Model;
use Config::Model::TermUI ;

use warnings;
no warnings qw(once);

use strict;

use Data::Dumper;

use vars qw/$model/;

$model = Config::Model -> new ;

my $trace = shift || 0;
$::verbose          = 1 if $trace =~ /v/;
$::debug            = 1 if $trace =~ /d/;
Config::Model::Exception::Any->Trace(1) if $trace =~ /e/;

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file => 't/big_model.pm',
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata"';
ok( $root->load( step => $step, permission => 'intermediate' ),
  "set up data in tree with '$step'");

# this test test only execution of user command, not their actual
# input
my $prompt = 'Test Prompt' ;

my $term_ui = Config::Model::TermUI->new( root => $root ,
					  title => 'Test Title',
					  prompt => $prompt,
					);

my $expected_prompt = $prompt.':$ ' ;

ok($term_ui,"Created term_ui") ;

my $path = $term_ui->list_cd_path ;

is_deeply ($path, 
	   [qw/std_id:ab std_id:bc tree_macro warp slave_y
               string_with_def a_uniline a_string int_v my_check_list my_reference/] ,
	   'check list cd path at root') ;

is($term_ui->prompt, $expected_prompt ,'test prompt at root') ;

my @test = ( 
	    [ 'vf std_id:ab', "Unexpected command 'vf'", $expected_prompt  ],
	    [ 'ls', 
	      'std_id  lista  listb  hash_a  hash_b  ordered_hash  olist  tree_macro  warp  slave_y  string_with_def  a_uniline  a_string  int_v  my_check_list  my_reference', 
	      $expected_prompt  ],
	    [ 'set a_string="some value with space"', "", $expected_prompt],
	    [ 'cd std_id:ab', "", $prompt.': std_id:ab $ '  ],
	    [ 'set X=Av',"", $prompt.': std_id:ab $ ' ],
	    [ 'display X',"Av", $prompt.': std_id:ab $ ' ],
	    [ 'cd !',"",$expected_prompt],
	    [ 'delete std_id:ab',"", $expected_prompt],
	   ) ;

foreach my $a_test (@test) {
    my ($cmd,$expect,$expect_prompt) = @$a_test ;

    is($term_ui->run($cmd),$expect ,"exec $cmd, expect $expect") ;

    is($term_ui->prompt,$expect_prompt,"test prompt is $expect_prompt") ;
}
