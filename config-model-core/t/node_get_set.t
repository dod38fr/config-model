# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 6;
use Config::Model;

use warnings;
no warnings qw(once);

use strict;

my $model = Config::Model -> new(legacy => 'ignore',)  ;

my $arg = shift || '' ;
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

# check with embedded \n
my $step = qq!std_id:ab X=Bv - std_id:bc X=Av - a_string="titi and toto" !;
ok( $root->load( step => $step, experience => 'advanced' ),
  "load '$step'");

foreach (["/std_id/cc/X","Bv" ],
	) {
    my ($path,$exp) = @$_ ;
    is($root->set($path,$exp),$exp,"Test set $path") ;
}

foreach (["/std_id/bc/X","Av" ],
	 ["/std_id/cc/X","Bv" ],
	) {
    my ($path,$exp) = @$_ ;
    is($root->get($path),$exp,"Test get $path") ;
}
