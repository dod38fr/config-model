# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 9 ;
use Config::Model;
use Log::Log4perl qw(:easy) ;
use Data::Dumper ;
use File::Path ;
use File::Copy ;
use File::Find ;
use Config::Model::Itself ;
use Test::File::Contents ;

use warnings;
no warnings qw(once);

use strict;

my $arg = $ARGV[0] || '' ;
my ($log,$show) = (0) x 2 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;

my $home = $ENV{HOME} || "";
my $log4perl_user_conf_file = "$home/.log4config-model";

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($log ? $WARN: $ERROR);
}

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

my $wr_test = 'wr_test' ;
my $wr_model1 = "$wr_test/wr_model1";
my $wr_snippet = "$wr_test/wr_snippet";

my $meta_model = Config::Model -> new ( ) ;# model_dir => '.' );

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

rmtree($wr_test) if -d $wr_test ;

# "modern" API of File::Path does not work with perl 5.8.8
mkpath( [$wr_model1] , 0, 0755) ;

# copy test model
my $wanted = sub { 
    return if /svn|data$|~$/ ;
    s!data/!! ;
    -d $File::Find::name && mkpath( ["$wr_model1/$_"], 0, 0755) ;
    -f $File::Find::name && copy($File::Find::name,"$wr_model1/$_") ;
};
find ({ wanted =>$wanted, no_chdir=>1} ,'data') ;




# test model snippets, read model in layered mode
my $meta_snippet_inst = $meta_model
  -> instance (root_class_name   => 'Itself::Model', 
               instance_name     => 'itself_snippet',
               root_dir          => $wr_model1,
              );
ok($meta_snippet_inst,"Read Itself::Model and created instance for model snippet") ;

my $meta_snippet_root = $meta_snippet_inst -> config_root ;

my $snippet_rw_obj = Config::Model::Itself -> new(model_object => $meta_snippet_root) ;

$meta_snippet_inst->layered_start ;

$snippet_rw_obj -> read_all( 
                              model_dir => 'data',
                              root_model => 'MasterModel',
                              legacy => 'ignore',
                             ) ;

ok(1,"Read all models in data dir in layered mode") ;

$meta_snippet_inst->layered_stop ;

# modify model, X_base_class2 is not a mistake
$meta_snippet_root->load(q!class:MasterModel::X_base_class2 element:X#"X note" help:Cv="Mighty help for Cv"!);
$meta_snippet_root->load(q!class:MasterModel element:a_string warn_if_match:meh msg="said meh"!);

$snippet_rw_obj->write_model_snippet(model_dir => $wr_snippet, model_file=> 'snippet.pl') ;

my %expected_snippet;
$expected_snippet{MasterModel} = << "EOS" ;
[
  {
    'name' => 'MasterModel',
    'element' => [
      'a_string',
      {
        'warn_if_match' => {
          'meh' => {
            'msg' => 'said meh'
          }
        }
      }
    ]
  }
]
;

EOS

$expected_snippet{"MasterModel/X_base_class2"} = << "EOS" ;
[
  {
    'name' => 'MasterModel::X_base_class2',
    'element' => [
      'X',
      {
        'help' => {
          'Cv' => 'Mighty help for Cv'
        }
      }
    ]
  }
]
;

=head1 Annotations

=over

=item class:"MasterModel::X_base_class2" element:X

X note

=back

EOS

map {
  file_contents_eq_or_diff $wr_snippet."/$_.d/snippet.pl",  $expected_snippet{$_},  "genereted $_ snippet file";
} keys %expected_snippet ;

my $meta_snippet_inst2 = $meta_model
  -> instance (root_class_name   => 'Itself::Model', 
               instance_name     => 'itself_snippet',
               root_dir          => $wr_model1,
              );
ok($meta_snippet_inst2,"Read Itself::Model and created instance for model snippet") ;

my $meta_snippet_root2 = $meta_snippet_inst2 -> config_root ;

my $snippet_rw_obj2 = Config::Model::Itself -> new(model_object => $meta_snippet_root2) ;

$meta_snippet_inst2->layered_start ;

$snippet_rw_obj2 -> read_all( 
                              model_dir => 'data',
                              root_model => 'MasterModel',
                              legacy => 'ignore',
                             ) ;

ok(1,"Read all models in data dir in layered mode") ;

$meta_snippet_inst->layered_stop ;

$snippet_rw_obj2->read_model_snippet(model_dir => $wr_snippet, model_file=> 'snippet.pl') ;

$snippet_rw_obj2->write_model_snippet(model_dir => $wr_snippet, model_file=> 'snippet2.pl') ;

map {
  file_contents_eq_or_diff $wr_snippet."/$_.d/snippet2.pl",  $expected_snippet{$_},  "regenerated $_ snippet file";
}  keys %expected_snippet  ;
