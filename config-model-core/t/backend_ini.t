# -*- cperl -*-

use ExtUtils::testlib;
use Test::More ;
use Test::Memory::Cycle;
use Config::Model;
use File::Path;
use File::Copy ;
use Data::Dumper ;
use Log::Log4perl qw(:easy) ;

use warnings;
no warnings qw(once);

use strict;


my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
my $log   = $arg =~ /l/ ? 1 : 0 ;;

my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($log ? $WARN: $ERROR);
}
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

plan tests => 61 ;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root/';

# set_up data
my @with_semi_column_comment = my @with_hash_comment = <DATA> ;
# change delimiter comments
map {s/#/;/;} @with_semi_column_comment ;
my %test_setup = ( IniTest  => [ \@with_hash_comment , 'class1' ], 
                   IniTest2 => [ \@with_semi_column_comment, 'class1' ],
                   AutoIni  => [ \@with_hash_comment, 'class1' ],
                   MyClass  => [ \@with_hash_comment, 'any_ini_class:class1' ]
                 );

foreach my $test_class (sort keys %test_setup) {
    my $model = Config::Model -> new () ;
    my @orig = @{$test_setup{$test_class}[0]} ;
    my $test_path = $test_setup{$test_class}[1] ;

    # cleanup before tests
    rmtree($wr_root);

    ok(1,"Starting $test_class tests");

    my $test1 = 'ini1' ;
    my $wr_dir = $wr_root.'/'.$test1 ;
    my $conf_file = "$wr_dir/etc/test.ini" ;

    mkpath($wr_dir.'/etc', { mode => 0755 }) 
        || die "can't mkpath: $!";
    open(CONF,"> $conf_file" ) || die "can't open $conf_file: $!";
    print CONF @orig ;
    close CONF ;

    my $i_test = $model->instance(  instance_name    => 'test_inst',
                                    root_class_name  => $test_class,
                                    root_dir    => $wr_dir ,
                                    model_file       => 't/test_ini_backend_model.pl',
                                 );

    ok( $i_test, "Created $test_class instance" );


    my $i_root = $i_test->config_root ;
   
    $i_root->load("bar:0=\x{263A}") ; # utf8 smiley

    is($i_root->annotation,"some global comment","check global comment");
    is($i_root->grab($test_path)->annotation,"class1 comment",
        "check $test_path comment");

    my $lista_obj = $i_root->grab($test_path)->fetch_element('lista');
    is($lista_obj->annotation, '',"check $test_path lista comment"); 

    foreach my $i (1 .. 3) {
        my $elt = $lista_obj->fetch_with_id($i - 1) ;
        is($elt->fetch,"lista$i","check lista[$i] content");
        is($elt->annotation,
            "lista$i comment","check lista[$i] comment");
    } 

    my $orig = $i_root->dump_tree ;
    print $orig if $trace ;

    $i_test->write_back ;
    ok(1,"IniFile write back done") ;

    my $ini_file      = $wr_dir.'/etc/test.ini';
    ok(-e $ini_file, "check that config file $ini_file was written");

    # create another instance to read the IniFile that was just written
    my $wr_dir2 = $wr_root.'/ini2' ;
    mkpath($wr_dir2.'/etc',{ mode => 0755 })   || die "can't mkpath: $!";
    copy($wr_dir.'/etc/test.ini',$wr_dir2.'/etc/') 
        or die "can't copy from test1 to test2: $!";

    my $i2_test = $model->instance(instance_name    => 'test_inst2',
                                   root_class_name  => $test_class,
                                   root_dir    => $wr_dir2 ,
                                  );

    ok( $i2_test, "Created instance" );


    my $i2_root = $i2_test->config_root ;

    my $p2_dump = $i2_root->dump_tree ;

    is($p2_dump,$orig,"compare original data with 2nd instance data") ;

}

__DATA__
#some global comment


# foo1 comment
foo = foo1

foo = foo2 # foo2 comment

bar = bar1

baz = bazv

# class1 comment
[class1]
lista=lista1 #lista1 comment
# lista2 comment
lista    =    lista2 
# lista3 comment
lista    =    lista3 
memory_cycle_ok($model);
