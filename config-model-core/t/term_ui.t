# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-06-15 12:04:05 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

use ExtUtils::testlib;
use Test::More tests => 15 ;
use Config::Model;
use Config::Model::TermUI ;

use warnings;
no warnings qw(once);

use strict;

use Data::Dumper;

use vars qw/$model/;

$model = Config::Model -> new ;

my $file = 't/big_model.pm';

my $return ;
unless ($return = do $file) {
    warn "couldn't parse $file: $@" if $@;
    warn "couldn't do $file: $!"    unless defined $return;
    warn "couldn't run $file"       unless $return;
}



my $trace = shift || 0;
$::verbose          = 1 if $trace =~ /v/;
$::debug            = 1 if $trace =~ /d/;
Config::Model::Exception::Any->Trace(1) if $trace =~ /e/;

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
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

my $expected_prompt = $prompt.':$' ;

ok($term_ui,"Created term_ui") ;
is($term_ui->prompt, $expected_prompt ,'test prompt at root') ;

my @test = ( 
	    [ 'vf std_id:ab', "Unexpected command 'vf'", $expected_prompt  ],
	    [ 'ls', 
	      'std_id lista listb hash_a olist tree_macro warp string_with_def a_string int_v', 
	      $expected_prompt  ],
	    [ 'cd std_id:ab', "", $prompt.': std_id:ab $'  ],
	    [ 'set X=Av',"", $prompt.': std_id:ab $' ],
	    [ 'display X',"Av", $prompt.': std_id:ab $' ],
	   ) ;

foreach my $a_test (@test) {
    my ($cmd,$expect,$expect_prompt) = @$a_test ;

    is($term_ui->run($cmd),$expect ,"exec $cmd, expect $expect") ;

    is($term_ui->prompt,$expect_prompt,"test prompt is $expect_prompt") ;
}
