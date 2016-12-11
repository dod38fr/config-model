# -*- cperl -*-
use ExtUtils::testlib;
use Test::More;
use Test::Differences;

# this block is necessary to avoid failure on some automatic cpan
# testers setup which fail while loading Term::ReadLine
BEGIN {
    my $ok = eval {
        require Term::ReadLine;
        my $test = new Term::ReadLine 'Test';
        1;
    }
        and ( eval { require Term::ReadLine::Gnu; 1; }
        or eval { require Term::ReadLine::Perl; 1; } );

    if ($ok) {
        plan tests => 13;
    }
    else {
        plan skip_all => "Cannot load Term::ReadLine";
    }
}

use Test::Memory::Cycle;
use Config::Model;
use Config::Model::TermUI;

use warnings;
no warnings qw(once);

use strict;

use Data::Dumper;

use vars qw/$model/;

$model = Config::Model->new( legacy => 'ignore', );

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $arg =~ /l/ ? $TRACE : $WARN );

note("you can run the test in interactive mode by passing 'i' argument, i.e. perl -Ilib t/term_ui.t i");

ok( 1, "compiled" );

my $inst = $model->instance(
    root_class_name => 'Master',
    model_file      => 't/big_model.pm',
    instance_name   => 'test1'
);
ok( $inst, "created dummy instance" );

my $root = $inst->config_root;

my $step =
      'std_id:ab X=Bv - '
    . 'std_id:bc X=Av - '
    . 'std_id:"abc def" X=Av - '
    . 'std_id:"abc hij" X=Av - '
    . 'a_string="toto tata"';

ok( $root->load( step => $step ), "set up data in tree with '$step'" );

# this test test only execution of user command, not their actual
# input
my $prompt = 'Test Prompt';

my $term_ui = Config::Model::TermUI->new(
    root   => $root,
    title  => 'Test Title',
    prompt => $prompt,
);

if ($arg =~ /i/) {
    $term_ui->run_loop;
    exit;
}

my @std_id_list = ('std_id:','std_id:ab','std_id:"abc def"' ,'std_id:"abc hij"', 'std_id:bc') ;
my @test = (    # text line start ## expected completions
    [
        [ '', '', 0 ],
        [qw/cd changes check clear delete desc description display dump fix help ll ls reset save set tree/]
    ],
    [ [ '', 'cd ', 3 ], [ '!', '-', @std_id_list , 'olist:', 'warp','slave_y' ] ],
    [ [ 's', 'cd s', 3 ], [  @std_id_list, 'slave_y' ] ],
    [ [ 'sl', 'cd sl',       3 ],  ['slave_y'] ],
    [ [ 'std_id:',   'cd std_id:',  10 ], \@std_id_list ],
    [ [ 'std_id:"',   'cd std_id:"', 11 ], ['std_id:"abc def"' ,'std_id:"abc hij"'  ] ],

    [ [ 'std_id:"abc', 'cd std_id:"abc',14 ], ['std_id:"abc def"' ,'std_id:"abc hij"' ] ],
    [ [ 'std_id:a', 'cd std_id:a', 3 ], ['std_id:ab'] ],
    [ [ '', 'fix ', 4 ], ['std_id', 'lista', 'listb', 'hash_a', 'hash_b', 'ordered_hash', 'olist', 'tree_macro', 'warp', 'slave_y', 'string_with_def', 'a_uniline', 'a_string', 'int_v', 'my_check_list', 'my_reference', '!']
  ],
);

foreach my $a_test (@test) {
    my ( $input, $expect ) = @$a_test;

    my @comp = $term_ui->completion(@$input);
    print Dumper ( \@comp ) if $trace;
    eq_or_diff( \@comp, $expect, "exec '" . join( "', '", @$input ) . "'" );

}
memory_cycle_ok($model, "memory cycles");

