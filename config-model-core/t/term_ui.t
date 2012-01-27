# -*- cperl -*-
# $Author$
# $Date$
# $Revision$

use ExtUtils::testlib;
use Test::More ;

# this block is necessary to avoid failure on some automatic cpan
# testers setup which fail while loading Term::ReadLine
BEGIN { 
    my $ok 
      = eval { require Term::ReadLine ;
	       my $test = new Term::ReadLine 'Test' ;
	       1;
	   } 
      and (
	      eval {require Term::ReadLine::Gnu  ; 1;} 
	   or eval {require Term::ReadLine::Perl ; 1;} 
	  );


    if ($ok) {
	plan tests => 10 ;
    }
    else {
	plan skip_all => "Cannot load Term::ReadLine" ;
    }
}

use Test::Memory::Cycle;
use Config::Model;
use Config::Model::TermUI ;

use warnings;
no warnings qw(once);

use strict;

use Data::Dumper;

use vars qw/$model/;

$model = Config::Model -> new(legacy => 'ignore',)  ;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file => 't/big_model.pm',
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;

my $step = 'std_id:ab X=Bv - '
         . 'std_id:bc X=Av - '
         . 'std_id:"abc def" X=Av - '
         . 'std_id:"abc hij" X=Av - '
         . 'a_string="toto tata"';

ok( $root->load( step => $step, experience => 'advanced' ),
  "set up data in tree with '$step'");

# this test test only execution of user command, not their actual
# input
my $prompt = 'Test Prompt' ;

my $term_ui = Config::Model::TermUI->new( root => $root ,
					  title => 'Test Title',
					  prompt => $prompt,
					);

my @test 
  = ( # text line start ## expected completions
     [ [ '', '',0 ], [ qw/cd delete desc description display dump help ll ls save set/] ],
     [ [ '', 'cd ',3 ], ['!', '-', 'std_id:', 'olist:', 'warp ', 'slave_y '] ],
     [ [ 's', 'cd s',3 ], ['std_id:', 'slave_y '] ],
     [ [ 'sl', 'cd sl',3 ], [ 'slave_y '] ],
     [ [ '', 'cd std_id:',10 ], [ 'ab ', '"abc def" ', '"abc hij" ','bc ' ] ],
     [ [ '', 'cd std_id:"',11 ], [ 'ab ', 'abc def" ', 'abc hij" ','bc ' ] ],
#     [ [ '"abc', 'cd std_id:"abc',14 ], [ ' def" ', ' hij" ' ] ],
     [ [ 'a', 'cd std_id:a',3 ], [ 'ab '] ],
    ) ;

foreach my $a_test (@test) {
    my ($input,$expect) = @$a_test ;

    my @comp = $term_ui->completion(@$input) ;
    print Dumper (\@comp) if $trace ;
    is_deeply(\@comp,$expect ,"exec '".join("', '",@$input)."'") ;

}
memory_cycle_ok($model);
