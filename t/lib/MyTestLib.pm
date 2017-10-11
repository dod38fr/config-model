package MyTestLib;

use strict;
use warnings;
use Exporter 'import';
use Test::More;

use Path::Tiny;

# modify lib path with: use lib -d 't' ? 't/lib' : 'lib';
# this way:
# * flycheck which runs in 't' is happy (use lib)
# * test (run in repo root) are happy (use 't/lib')
# * new perl code can be checked with perl -Ilib t/foo.t
# * old perl code can still be checked with perl t/foo.t

our @EXPORT_OK = qw/init_test setup_test_dir/;

sub init_test {
    my $arg = shift || '';

    my $trace = $arg =~ /t/ ? 1 : 0;
    Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

    use Log::Log4perl qw(:easy);
    my $home = $ENV{HOME} || "";
    my $log4perl_user_conf_file = "$home/.log4config-model";

    Log::Log4perl->easy_init( $ERROR ) unless $arg =~ /l/ ;

    my $model = Config::Model->new( );

    ok( 1, "compiled" );

    return ($model, $trace);
}

sub setup_test_dir {
    my $script = path($0);
    my $name = path($0)->basename('.t');

    my $wr_root = path('wr_root')->child($name);
    note("Running tests in $wr_root");
    $wr_root->remove_tree;
    $wr_root->mkpath;
    # TODO: remove stringify once Instance can handle Path::Tiny
    return $wr_root->stringify.'/';
}

1;
