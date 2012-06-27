# -*- cperl -*-

BEGIN {
    # dirty trick to create a Memoize cache so that test will use this instead
    # of getting values through the internet
    no warnings 'once';
    my $sep = chr(28);
    %Config::Model::Debian::Dependency::cache = (
        'perl' => 'lenny 5.10.0-19lenny3 squeeze 5.10.1-17 sid 5.10.1-17 experimental 5.12.0-2 experimental 5.12.2-2',
        'debhelper' => 'etch 5.0.42 backports/etch 7.0.15~bpo40+2 lenny 7.0.15 backports/lenny 8.0.0~bpo50+2 squeeze 8.0.0 wheezy 8.1.2 sid 8.1.2',
        'libcpan-meta-perl' => 'squeeze 2.101670-1 wheezy 2.110580-1 sid 2.110580-1',
        'libmodule-build-perl' => 'etch 0.26-1 backports/etch 0.2808.01-2~bpo40+1 lenny 0.2808.01-2 squeeze 0.360700-1 wheezy 0.380000-1 sid 0.380000-1', 
        'xserver-xorg-input-evdev' => 'etch 1:1.1.2-6 lenny 1:2.0.8-1 squeeze 1:2.3.2-6 wheezy 1:2.3.2-6 sid 1:2.6.0-2 experimental 1:2.6.0-3',
        'lcdproc' => 'etch 0.4.5-1.1 lenny 0.4.5-1.1 squeeze 0.5.2-3 wheezy 0.5.2-3.1 sid 0.5.2-3.1',
        'libsdl1.2' => '', # only source
    );
}

use ExtUtils::testlib;
use Test::More ;
use Test::Memory::Cycle;
use Config::Model ;
use Config::Model::Value ;
#use Config::Model::Debian::Dependency ;
use Log::Log4perl qw(:easy) ;
use File::Path ;
use File::Copy ;
use Test::Warn ;

eval { require AptPkg::Config ;} ;
if ( $@ ) {
    plan skip_all => "AptPkg::Config is not installed";
}
elsif ( -r '/etc/debian_version' ) {
    plan tests => 27;
}
else {
    plan skip_all => "Not a Debian system";
}

use warnings;

use strict;

my $arg = shift || '';
my ($log,$show,$one) = (0) x 3 ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$log                = 1 if $arg =~ /l/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
my $home = $ENV{HOME} || "";
my $log4perl_user_conf_file = "$home/.log4config-model";

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($ERROR);
}
$show               = 1 if $arg =~ /s/;
$one                = 1 if $arg =~ /1/;

my $model = Config::Model -> new ( ) ;

{
    no warnings qw/once/ ;
    $Debian::Dependency::test_filter='lenny'; 
}

my $control_text = <<'EOD' ;
Source: libdist-zilla-plugins-cjm-perl
Section: perl
Priority: optional
Build-Depends: debhelper, libsdl1.2
Build-Depends-Indep: libcpan-meta-perl, perl (>= 5.10) | libmodule-build-perl,
Maintainer: Debian Perl Group <pkg-perl-maintainers@lists.alioth.debian.org>
Uploaders: Dominique Dumont <dominique.dumont@hp.com>
Standards-Version: 3.9.3
Homepage: http://search.cpan.org/dist/Dist-Zilla-Plugins-CJM/

Package: libdist-zilla-plugins-cjm-perl
Architecture: all
Depends: ${misc:Depends}, ${perl:Depends}, libcpan-meta-perl ,
 perl (>= 5.10.1)
Description: collection of CJM's plugins for Dist::Zilla
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

my $inst = $model->instance (
    root_class_name => 'Debian::Dpkg::Control',
    root_dir        => $wr_dir,
    instance_name   => "deptest",
);
warning_like { $inst->config_root->init ; ; }
 [ qr/is unknown/, (qr/dual life/) , qr/unnecessary/, ( qr/dual life/) x 2] , "test BDI warn";

ok($inst,"Read $control_file and created instance") ;

my $control = $inst -> config_root ;

if ($trace) {
    my $dump =  $control->dump_tree ();
    print $dump ;
}

my $perl_dep = $control->grab("binary:libdist-zilla-plugins-cjm-perl Depends:3");
is($perl_dep->fetch,"perl (>= 5.10.1)","check dependency value from config tree");

my @ret = $perl_dep->check_dep('perl','>=','5.28.1') ;
is($ret[0],1,"check perl (>= 5.28.1) dependency: has older version");

@ret = $perl_dep->check_dep('perl','>=','5.6.0') ;
is($ret[0],0,"check perl (>= 5.6.0) dependency: no older version");

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
is(scalar @msgs,1,"check nb of warning with store with old version");
like($msgs[0],qr/unnecessary versioned dependency/,"check store with old version");

$control->load(q{binary:libdist-zilla-plugins-cjm-perl Depends:4="perl [!i386] | perl [amd64] "}) ;
ok( 1, "check_depend on arch stuff rule");

$control->load(
    "binary:libdist-zilla-plugins-cjm-perl ".
    q{Depends:5="xserver-xorg-input-evdev [alpha amd64 arm armeb armel hppa i386 ia64 lpia m32r m68k mips mipsel powerpc sparc]"}
);
ok( 1, "check_depend on xorg arch stuff rule");

$control->load(q{binary:libdist-zilla-plugins-cjm-perl Depends:6="lcdproc (= ${binary:Version})"});
ok( 1, "check_depend on lcdproc where version is a variable");

# reset change tracker
$inst-> clear_changes ;

# test fixes
is($perl_dep->has_fixes,1, "test presence of fixes");
$perl_dep->apply_fixes;
is($perl_dep->has_fixes,0, "test that fixes are gone");
@msgs = $perl_dep->warning_msg ;
is_deeply(\@msgs,[],"check that warnings are gone");

is($inst->c_count, 1,"check that fixes are tracked with notify changes") ;

my $perl_bdi = $control->grab("source Build-Depends-Indep:1");

my $bdi_val ;
# since warnings were already issued during config_root->init, we don;t
# get warnings here
warning_like { $bdi_val = $perl_bdi->fetch ; } [ ], "check that no BDI warn are shown";

is($bdi_val,"perl (>= 5.10) | libmodule-build-perl","check B-D-I dependency value from config tree");
my $msgs = $perl_bdi->warning_msg ;
like($msgs,qr/dual life/,"check store with old version: trap perl | libmodule");
like($msgs,qr/unnecessary versioned dependency/,"check store with old version: trap version");

$inst-> clear_changes ;

# test fixes
is($perl_bdi->has_fixes,2, "test presence of fixes");

{
    local $Config::Model::Value::nowarning = 1 ;
    $perl_bdi->apply_fixes;
}

is($perl_bdi->has_fixes,0, "test that fixes are gone");
@msgs = $perl_bdi->warning_msg ;
is_deeply(\@msgs,[],"check that warnings are gone");

is($inst->c_count, 2,"check that fixes are tracked with notify changes") ;

memory_cycle_ok($model);
