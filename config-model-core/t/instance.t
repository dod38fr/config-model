# -*- cperl -*-

use warnings FATAL => qw(all);

use ExtUtils::testlib;
use Test::More;
use Test::Warn ;
use Config::Model;

BEGIN { plan tests => 12; }

use strict;

my $arg = shift || '';

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"Compilation done");

my $model = Config::Model->new(legacy => 'ignore',) ;
$model->create_config_class(
    name    => "Master",
    element => [
        warn_if => {
            type          => 'leaf',
            value_type    => 'string',
            warn_if_match => { 'foo' => { fix => '$_ = uc;' } },
        },
        warn_unless => {
            type       => 'leaf',
            value_type => 'string',
            warn_unless_match =>
              { foo => { msg => '', fix => '$_ = "foo".$_;' } },
        },
    ]
);

my $inst = $model->instance (root_class_name => 'Master', 
			     instance_name   => 'test1',
			     root_dir        => 'foobar' );
ok($inst,"created dummy instance") ;

isa_ok( $inst->config_root , 'Config::Model::Node',"test config root class" );

is( $inst->data('test'),undef,"test empty private data ..." );
is( $inst->data( 'test', 'coucou' ), '', "store private data" );
is( $inst->data( 'test'), 'coucou', "retrieve private data" );

is( $inst->read_root_dir,  'foobar/', "test read directory") ;
is( $inst->write_root_dir, 'foobar/', "test write directory") ;

# test if fixes can be applied through the instance
my $root = $inst -> config_root ;
my $wip = $root->fetch_element('warn_if') ;
my $wup = $root->fetch_element('warn_unless') ;
warning_like {$wip->store('foobar');} qr/should not match/, "test warn_if condition (instance test)" ;
warning_like {$wup->store('bar');} qr/should match/, "test warn_unless condition (instance test)" ;
$inst->apply_fixes ;
is($wup -> fetch,'foobar',"test if fixes were applied (instance test)") ;
is($wup -> fetch,'foobar',"test if fixes were applied (instance test)") ;

