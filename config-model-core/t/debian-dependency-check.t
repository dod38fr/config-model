# -*- cperl -*-

BEGIN {

    # dirty trick to create a Memoize cache so that test will use this instead
    # of getting values through the internet
    no warnings 'once';
    my $sep = chr(28);
    %Config::Model::Debian::Dependency::cache = (
        'debhelper' . $sep . '7'                => '',
        'libcpan-meta-perl' . $sep . '2.101550' => '',
        'libdist-zilla-perl' . $sep . '3'       => '',
        'libfile-homedir-perl' . $sep . '0.81'  => 'lenny',
        'libmoose-autobox-perl' . $sep . '0.09' => '',
        'libmoose-perl' . $sep . '0.65'         => 'lenny',
        'perl' . $sep . '5.10'                  => '',
        'perl' . $sep . '5.10.1'                => 'lenny',
        'perl' . $sep . '5.28.1'                => 'lenny',
        'perl' . $sep . '5.6.0'                 => '',
    );
}

use ExtUtils::testlib;
use Test::More ;
use Config::Model ;
use Config::Model::Debian::Dependency ;
use Log::Log4perl qw(:easy) ;
use File::Path ;
use File::Copy ;
use Test::Warn ;

eval { require AptPkg::Config ;} ;
if ( $@ ) {
    plan skip_all => "AptPkg::Config is not installed (not a Debian system ?)";
}
else {
    plan tests => 19;
}

# available only in debian
use AptPkg::Version ;

use warnings;

use strict;

my $arg = shift || '';

my ($log,$show,$one) = (0) x 3 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;
$one                = 1 if $arg =~ /1/;

Log::Log4perl->easy_init($log ? $TRACE: $WARN);

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;


my $control_text = <<'EOD' ;
Source: libdist-zilla-plugins-cjm-perl
Section: perl
Priority: optional
Build-Depends: debhelper
Build-Depends-Indep: libcpan-meta-perl, perl (>= 5.10) | libmodule-build-perl,
Maintainer: Debian Perl Group <pkg-perl-maintainers@lists.alioth.debian.org>
Uploaders: Dominique Dumont <dominique.dumont@hp.com>
Standards-Version: 3.9.1
Homepage: http://search.cpan.org/dist/Dist-Zilla-Plugins-CJM/

Package: libdist-zilla-plugins-cjm-perl
Architecture: all
Depends: ${misc:Depends}, ${perl:Depends}, libcpan-meta-perl ,
 perl (>= 5.10.1)
Description: Collection of CJM's plugins for Dist::Zilla
 Collection of Dist::Zilla plugins. This package features the 
 following [snip]  
EOD

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root';

# cleanup before tests
rmtree($wr_root);
mkpath($wr_root, { mode => 0755 }) ;

my $wr_dir = $wr_root.'/test' ;
mkpath($wr_dir."/debian/", { mode => 0755 }) ;
my $control_file = "$wr_dir/debian/control" ;

open(my $control_h,"> $control_file" ) || die "can't open $control_file: $!";
print $control_h $control_text ;
close $control_h ;

my $inst ;
warning_like {
    $inst = $model->instance(
        root_class_name => 'Debian::Dpkg::Control',
        root_dir        => $wr_dir,
        instance_name   => "deptest",
    );
}
qr/includes libmodule-build-perl/, "test BDI warn";

ok($inst,"Read $control_file and created instance") ;

my $control = $inst -> config_root ;

if ($trace) {
    my $dump =  $control->dump_tree ();
    print $dump ;
}

my $perl_dep = $control->grab("binary:libdist-zilla-plugins-cjm-perl Depends:3");
is($perl_dep->fetch,"perl (>= 5.10.1)","check dependency value from config tree");

my $msg = $perl_dep->check_dep('perl','>=','5.28.1') ;
is($msg,undef,"check perl (>= 5.28.1) dependency: has older version");

$msg = $perl_dep->check_dep('perl','>=','5.6.0') ;
is($msg,"unnecessary versioned dependency: >= 5.6.0","check perl (>= 5.6.0) dependency: no older version");

# check parser and grammer
my $parser = $perl_dep->dep_parser ;
ok($parser,"parser compiled ok");

my $res = $parser->dep_version("( >= 5.10.0 )") ;
is_deeply( $res, ['>=','5.10.0'],"check dep_version rule");

warning_like {
    $perl_dep->store("perl ( >= 5.6.0 )") ;
}
qr/unnecessary versioned/,"check perl (>= 5.6.0) store: no older version warning" ;

my @msgs = $perl_dep->warning_msg ;
is_deeply(\@msgs,["unnecessary versioned dependency: >= 5.6.0"],"check store with old version");

# test fixes
is($perl_dep->has_fixes,1, "test presence of fixes");
$perl_dep->apply_fixes;
is($perl_dep->has_fixes,0, "test that fixes are gone");
@msgs = $perl_dep->warning_msg ;
is_deeply(\@msgs,[],"check that warnings are gone");


my $perl_bdi = $control->grab("source Build-Depends-Indep:1");

my $bdi_val ;
warning_like {
    $bdi_val = $perl_bdi->fetch ;
}
qr/includes libmodule-build-perl/, "test BDI warn";

is($bdi_val,"perl (>= 5.10) | libmodule-build-perl","check B-D-I dependency value from config tree");
my $msgs = $perl_bdi->warning_msg ;
is($msgs,"lenny has perl 5.10 which includes libmodule-build-perl\nunnecessary versioned dependency: >= 5.10","check store with old version");

# test fixes
is($perl_bdi->has_fixes,2, "test presence of fixes");
$perl_bdi->apply_fixes;
is($perl_bdi->has_fixes,0, "test that fixes are gone");
@msgs = $perl_bdi->warning_msg ;
is_deeply(\@msgs,[],"check that warnings are gone");

