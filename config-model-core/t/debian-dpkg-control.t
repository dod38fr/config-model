# -*- cperl -*-
BEGIN {
    # dirty trick to create a Memoize cache so that test will use this instead
    # of getting values through the internet
    my $sep = chr(28);
    no warnings 'once' ;
    %Config::Model::Debian::Dependency::cache = (
        'clustalw' => 'etch/non-free 1.83-1.2 lenny/non-free 2.0.9-1 squeeze/non-free 2.0.12-1 wheezy 2.1+lgpl-2 sid 2.1+lgpl-2 sid 2.1+lgpl-2+b1',
        'gdm' => 'etch 2.16.4-1 lenny 2.20.7-4lenny1 squeeze 2.20.11-4 wheezy 2.20.11-4',
        'hal' => 'lenny 0.5.11-8 squeeze 0.5.14-3 wheezy 0.5.14-5 sid 0.5.14-5',
        'libcpan-meta-perl' => 'squeeze 2.101670-1 sid 2.102400-1',
        'libdist-zilla-perl' => 'squeeze 4.101900-1 sid 4.200000-1',
        'libdmx-dev' => 'etch 1:1.0.2-2 lenny 1:1.0.2-3 squeeze 1:1.1.0-2 wheezy 1:1.1.1-1 sid 1:1.1.1-1',
        'libfile-homedir-perl' => 'lenny 0.64-1.1 squeeze 0.86-1 sid 0.93-2',
        'libfltk1.1-dev' => 'etch 1.1.7-3 lenny 1.1.9-6 squeeze 1.1.10-2+b1 wheezy 1.1.10-4 sid 1.1.10-4 wheezy 1.1.10-4+b1 sid 1.1.10-4+b1',
        'libfontenc-dev' => 'etch 1:1.0.2-2 lenny 1:1.0.4-3 squeeze 1:1.0.5-2 wheezy 1:1.1.0-1 sid 1:1.1.0-1',
        'libfs-dev' => 'etch 2:1.0.0-4 lenny 2:1.0.1-1 squeeze 2:1.0.2-1 squeeze 2:1.0.2-1+b1 wheezy 2:1.0.3-1 sid 2:1.0.3-1',
        'libgl1' => '',
        'libgl1-mesa-dev' => 'etch 6.5.1-0.6 lenny 7.0.3-7 squeeze 7.7.1-4 wheezy 7.7.1-4 sid 7.10-4',
        'libgl1-mesa-dri' => 'etch 6.5.1-0.6 lenny 7.0.3-7 squeeze 7.7.1-4 wheezy 7.7.1-4 sid 7.10-4',
        'libgl1-mesa-glx' => 'etch 6.5.1-0.6 lenny 7.0.3-7 squeeze 7.7.1-4 wheezy 7.7.1-4 sid 7.10-4',
        'libglu1-mesa-dev' => 'etch 6.5.1-0.6 lenny 7.0.3-7 squeeze 7.7.1-4 wheezy 7.7.1-4 sid 7.10-4',
        'libglu1-mesa' => 'etch 6.5.1-0.6 lenny 7.0.3-7 squeeze 7.7.1-4 wheezy 7.7.1-4 sid 7.10-4',
        'libice-dev' => 'etch 1:1.0.1-2 lenny 2:1.0.4-1 squeeze 2:1.0.6-2 wheezy 2:1.0.7-1 sid 2:1.0.7-1',
        'libjpeg62-dev' => 'etch 6b-13 lenny 6b-14 squeeze 6b1-1 wheezy 6b1-1 sid 6b1-1',
        'libmoose-autobox-perl' => 'squeeze 0.11-1 sid 0.11-1',
        'libmoose-perl' => 'lenny 0.54-1 backports/lenny 1.05-1~bpo50+1 squeeze 1.09-2 sid 1.21-1',
        'libpath-class-perl' => 'etch 0.15-1 lenny 0.16-0.1 squeeze 0.19-1 wheezy 0.23-1 sid 0.23-1',
        'libpng12-dev' => 'etch-security 1.2.15~beta5-1+etch2 etch 1.2.15~beta5-1+etch2 lenny-security 1.2.27-2+lenny4 lenny 1.2.27-2+lenny4 squeeze 1.2.44-1 wheezy 1.2.44-2 sid 1.2.44-2',
        'libsm-dev' => 'etch 1:1.0.1-3 lenny 2:1.0.3-2 squeeze 2:1.1.1-1 wheezy 2:1.2.0-1 sid 2:1.2.0-1',
        'libx11-dev' => 'etch 2:1.0.3-7 lenny 2:1.1.5-2 squeeze 2:1.3.3-4 wheezy 2:1.4.1-5 sid 2:1.4.1-5',
        'libxau-dev' => 'etch 1:1.0.1-2 lenny 1:1.0.3-3 squeeze 1:1.0.6-1 wheezy 1:1.0.6-1 sid 1:1.0.6-1',
        'libxaw7-dev' => 'etch 1:1.0.2-4 lenny 2:1.0.4-2 squeeze 2:1.0.7-1 wheezy 2:1.0.9-2 sid 2:1.0.9-2',
        'libxcomposite-dev' => 'etch 1:0.3-3 lenny 1:0.4.0-3 squeeze 1:0.4.2-1 wheezy 1:0.4.3-1 sid 1:0.4.3-1',
        'libxcursor-dev' => 'etch 1.1.7-4 lenny 1:1.1.9-1 squeeze 1:1.1.10-2 wheezy 1:1.1.11-1 sid 1:1.1.11-1',
        'libxdamage-dev' => 'etch 1:1.0.3-3 lenny 1:1.1.1-4 squeeze 1:1.1.3-1 wheezy 1:1.1.3-1 sid 1:1.1.3-1',
        'libxdmcp-dev' => 'etch 1:1.0.1-2 lenny 1:1.0.2-3 squeeze 1:1.0.3-2 wheezy 1:1.1.0-1 sid 1:1.1.0-1',
        'libxext-dev' => 'etch 1:1.0.1-2 lenny 2:1.0.4-2 squeeze 2:1.1.2-1 wheezy 2:1.2.0-2 sid 2:1.2.0-2',
        'libxfixes-dev' => 'etch 1:4.0.1-5 lenny 1:4.0.3-2 squeeze 1:4.0.5-1 wheezy 1:4.0.5-1 sid 1:4.0.5-1 experimental 1:5.0-1',
        'libxfont-dev' => 'etch-security 1:1.2.2-2.etch1 etch 1:1.2.2-2.etch1 lenny 1:1.3.3-1 squeeze 1:1.4.1-2 wheezy 1:1.4.3-2 sid 1:1.4.3-2',
        'libxft-dev' => 'etch 2.1.8.2-8 lenny 2.1.12-3 squeeze 2.1.14-2 wheezy 2.2.0-2 sid 2.2.0-2',
        'libxi-dev' => 'etch 1:1.0.1-4 lenny 2:1.1.4-1 squeeze 2:1.3-6 wheezy 2:1.4.1-1 sid 2:1.4.1-1',
        'libxinerama-dev' => 'etch 1:1.0.1-4.1 lenny 2:1.0.3-2 squeeze 2:1.1-3 wheezy 2:1.1.1-1 sid 2:1.1.1-1',
        'libxkbfile-dev' => 'etch 1:1.0.3-2 lenny 1:1.0.5-1 squeeze 1:1.0.6-2 wheezy 1:1.0.7-1 sid 1:1.0.7-1',
        'libxmu-dev' => 'etch 1:1.0.2-2 lenny 2:1.0.4-1 squeeze 2:1.0.5-2 wheezy 2:1.1.0-1 sid 2:1.1.0-1',
        'libxmuu-dev' => 'etch 1:1.0.2-2 lenny 2:1.0.4-1 squeeze 2:1.0.5-2 wheezy 2:1.1.0-1 sid 2:1.1.0-1',
        'libxpm-dev' => 'etch 1:3.5.5-2 lenny 1:3.5.7-1 squeeze 1:3.5.8-1 wheezy 1:3.5.9-1 sid 1:3.5.9-1',
        'libxrandr-dev' => 'etch 2:1.1.0.2-5 lenny 2:1.2.3-1 squeeze 2:1.3.0-3 wheezy 2:1.3.1-1 sid 2:1.3.1-1',
        'libxrender-dev' => 'etch 1:0.9.1-3 lenny 1:0.9.4-2 squeeze 1:0.9.6-1 wheezy 1:0.9.6-1 sid 1:0.9.6-1',
        'libxres-dev' => 'etch 2:1.0.1-2 lenny 2:1.0.3-1 squeeze 2:1.0.4-1 wheezy 2:1.0.5-1 sid 2:1.0.5-1',
        'libxss-dev' => 'etch 1:1.1.0-1 lenny 1:1.1.3-1 squeeze 1:1.2.0-2 wheezy 1:1.2.1-1 sid 1:1.2.1-1',
        'libxt-dev' => 'etch 1:1.0.2-2 lenny 1:1.0.5-3 squeeze 1:1.0.7-1 wheezy 1:1.1.1-1 sid 1:1.1.1-1',
        'libxtst-dev' => 'etch 1:1.0.1-5 lenny 2:1.0.3-1 squeeze 2:1.1.0-3 wheezy 2:1.2.0-1 sid 2:1.2.0-1 experimental 2:1.2.0-2',
        'libxv-dev' => 'etch 1:1.0.2-1 lenny 2:1.0.4-1 squeeze 2:1.0.5-1 wheezy 2:1.0.6-1 sid 2:1.0.6-1',
        'libxvmc-dev' => 'etch 1:1.0.2-2 lenny 1:1.0.4-2 squeeze 2:1.0.5-1 wheezy 2:1.0.6-1 sid 2:1.0.6-1',
        'libxxf86dga-dev' => 'etch 2:1.0.1-2 lenny 2:1.0.2-1 squeeze 2:1.1.1-2 wheezy 2:1.1.2-1 sid 2:1.1.2-1',
        'libxxf86vm-dev' => 'etch 1:1.0.1-2 lenny 1:1.0.2-1 squeeze 1:1.1.0-2 wheezy 1:1.1.1-1 sid 1:1.1.1-1',
        'lsb-base' => 'lenny 3.2-20 squeeze-p-u 3.2-23.2squeeze1 squeeze 3.2-23.2squeeze1 sid 3.2-27',
        'muscle' => 'etch 3.60-1 lenny 3.70+fix1-2 squeeze 3.70+fix1-2 wheezy 3.70+fix1-2 sid 3.70+fix1-2',
        'perl' => 'lenny 5.10.0-19lenny3 squeeze 5.10.1-17 sid 5.10.1-17 experimental 5.12.0-2 experimental 5.12.2-2',
        'phyml' => 'squeeze 2:20100123-1 wheezy 2:20100720-1 sid 2:20100720-1',
        'po-debconf' => 'etch 1.0.8 lenny 1.0.15 squeeze 1.0.16+nmu1 wheezy 1.0.16+nmu1 sid 1.0.16+nmu1',
        'x11-apps' => 'lenny 7.3+4 squeeze 7.5+5 wheezy 7.6+4 sid 7.6+4',
        'x11-common' => 'etch 1:7.1.0-19 lenny 1:7.3+20 squeeze 1:7.5+8 wheezy 1:7.5+8 sid 1:7.6+4',
        'x11proto-bigreqs-dev' => 'etch 1.0.2-4 lenny 1:1.0.2-5 squeeze 1:1.1.0-1 wheezy 1:1.1.1-1 sid 1:1.1.1-1',
        'x11proto-composite-dev' => 'etch 0.3.1-2 lenny 1:0.4-2 squeeze 1:0.4.1-1 wheezy 1:0.4.2-1 sid 1:0.4.2-1',
        'x11proto-core-dev' => 'etch 7.0.7-2 backports/etch 7.0.12-1~bpo40+1 lenny 7.0.12-1 squeeze 7.0.16-1 wheezy 7.0.20-1 sid 7.0.20-1',
        'x11proto-damage-dev' => 'etch 1.0.3-4 lenny 1.1.0-2 squeeze 1:1.2.0-1 wheezy 1:1.2.1-1 sid 1:1.2.1-1',
        'x11proto-dmx-dev' => 'etch 2.2.2-4 lenny 1:2.2.2-5 squeeze 1:2.3-2 wheezy 1:2.3.1-1 sid 1:2.3.1-1',
        'x11proto-fixes-dev' => 'etch 4.0-2 lenny 1:4.0-3 squeeze 1:4.1.1-2 wheezy 1:5.0-1 sid 1:5.0-1',
        'x11proto-fonts-dev' => 'etch 2.0.2-5 lenny 2.0.2-6 squeeze 2.1.0-1 wheezy 2.1.1-1 sid 2.1.1-1',
        'x11proto-gl-dev' => 'etch 1.4.8-1 lenny 1.4.9-2 squeeze 1.4.11-1 wheezy 1.4.12-1 sid 1.4.12-1',
        'x11proto-input-dev' => 'etch 1.3.2-4 lenny 1.4.3-2 squeeze 2.0-2 wheezy 2.0.1-1 sid 2.0.1-1',
        'x11proto-kb-dev' => 'etch 1.0.3-2 lenny 1.0.3-3 squeeze 1.0.4-1 wheezy 1.0.5-1 sid 1.0.5-1',
        'x11proto-randr-dev' => 'etch 1.1.2-4 lenny 1.2.2-1 squeeze 1.3.1-1 wheezy 1.3.2-1 sid 1.3.2-1 experimental 1.3.99.1-1',
        'x11proto-record-dev' => 'etch 1.13.2-4 lenny 1.13.2-5 squeeze 1.14-2 wheezy 1.14.1-1 sid 1.14.1-1',
        'x11proto-render-dev' => 'etch 2:0.9.2-4 lenny 2:0.9.3-2 squeeze 2:0.11-1 wheezy 2:0.11.1-1 sid 2:0.11.1-1',
        'x11proto-resource-dev' => 'etch 1.0.2-4 lenny 1.0.2-5 squeeze 1.1.0-1 wheezy 1.1.1-1 sid 1.1.1-1',
        'x11proto-scrnsaver-dev' => 'etch 1.1.0.0-1 lenny 1.1.0.0-2 squeeze 1.2.0-2 wheezy 1.2.1-1 sid 1.2.1-1',
        'x11proto-video-dev' => 'etch 2.2.2-4 lenny 2.2.2-5 squeeze 2.3.0-1 wheezy 2.3.1-1 sid 2.3.1-1',
        'x11proto-xcmisc-dev' => 'etch 1.1.2-4 lenny 1.1.2-5 squeeze 1.2.0-1 wheezy 1.2.1-1 sid 1.2.1-1',
        'x11proto-xext-dev' => 'etch 7.0.2-5 lenny 7.0.2-6 squeeze 7.1.1-2 wheezy 7.1.2-1 sid 7.1.2-1 experimental 7.2.0-1',
        'x11proto-xf86bigfont-dev' => 'etch 1.1.2-4 lenny 1.1.2-5 squeeze 1.2.0-2 wheezy 1.2.0-2 sid 1.2.0-2',
        'x11proto-xf86dga-dev' => 'etch 2.0.2-4 lenny 2.0.3-1 squeeze 2.1-2 wheezy 2.1-2 sid 2.1-2',
         'x11proto-xf86dri-dev' => 'etch 2.0.3-4 lenny 2.0.4-1 squeeze 2.1.0-1 wheezy 2.1.1-1 sid 2.1.1-1',
        'x11proto-xf86vidmode-dev' => 'etch 2.2.2-4 lenny 2.2.2-5 squeeze 2.3-2 wheezy 2.3.1-1 sid 2.3.1-1',
        'x11proto-xinerama-dev' => 'etch 1.1.2-4 lenny 1.1.2-5 squeeze 1.2-2 wheezy 1.2.1-1 sid 1.2.1-1',
        'x11-session-utils' => 'lenny 7.3+1 squeeze 7.5+1 wheezy 7.6+1 sid 7.6+1',
        'x11-utils' => 'lenny 7.3+2+nmu1 squeeze 7.5+4 wheezy 7.6+1 sid 7.6+1',
        'x11-xfs-utils' => 'lenny 7.3+1 squeeze 7.4+1 wheezy 7.6+1 sid 7.6+1',
        'x11-xkb-utils' => 'lenny 7.4+1 squeeze 7.5+5 wheezy 7.6+2 sid 7.6+2',
        'x11-xserver-utils' => 'lenny 7.3+5 squeeze 7.5+2 wheezy 7.6+1 sid 7.6+1',
        'xauth' => 'lenny 1:1.0.3-2 squeeze 1:1.0.4-1 wheezy 1:1.0.5-1 sid 1:1.0.5-1',
        'x-common' => '',
        'xfonts-100dpi' => 'lenny 1:1.0.0-4 squeeze 1:1.0.1 wheezy 1:1.0.3 sid 1:1.0.3',
        'xfonts-75dpi' => 'lenny 1:1.0.0-4 squeeze 1:1.0.1 wheezy 1:1.0.3 sid 1:1.0.3',
        'xfonts-base' => 'lenny 1:1.0.0-5 squeeze 1:1.0.1 wheezy 1:1.0.3 sid 1:1.0.3',
        'xfonts-scalable' => 'lenny 1:1.0.0-6 squeeze 1:1.0.1-1 wheezy 1:1.0.3-1 sid 1:1.0.3-1',
        'xfonts-utils' => 'etch 1:1.0.1-1 lenny 1:7.4+1 squeeze 1:7.5+2 wheezy 1:7.6~1 sid 1:7.6~1',
        'xfree86-common' => '',
        'xinit' => 'lenny 1.0.9-2 squeeze 1.2.0-2 wheezy 1.3.0-1 sid 1.3.0-1',
        'xkb-data' => 'lenny 1.3-2 squeeze 1.8-2 sid 1.8-2 experimental 2.1-1',
        'xorg-common' => '',
        'xorg-docs-core' => 'squeeze 1:1.5-1 wheezy 1:1.6-1 sid 1:1.6-1',
        'xorg-docs' => 'etch 1:1.2+git20061105-3 lenny 1:1.4-4 squeeze 1:1.5-1 wheezy 1:1.6-1 sid 1:1.6-1',
        'xserver-common' => 'squeeze 2:1.7.7-13 wheezy 2:1.7.7-13 sid 2:1.9.4.901-1 experimental 2:1.9.99.903-1',
        'xserver-xfree86' => 'etch 1:7.1.0-19',
        'xserver-xorg-core' => 'lenny 2:1.4.2-10.lenny3 squeeze 2:1.7.7-11 wheezy 2:1.7.7-11 squeeze-p-u 2:1.7.7-13 sid 2:1.9.4-3 experimental 2:1.9.99.902-2 experimental 2:1.9.99.902-3',
        'xserver-xorg-dev' => 'etch-security 2:1.1.1-21etch5 etch 2:1.1.1-21etch5 lenny 2:1.4.2-10.lenny3 squeeze 2:1.7.7-13 wheezy 2:1.7.7-13 sid 2:1.9.4.901-1 experimental 2:1.9.99.903-1',
        'xserver-xorg-driver-all' => '',
        'xserver-xorg' => 'etch 1:7.1.0-19 lenny 1:7.3+20 squeeze 1:7.5+8 wheezy 1:7.5+8 sid 1:7.6+4',
        'xserver-xorg-input-7' => '',
        'xserver-xorg-input-all' => 'etch 1:7.1.0-19 lenny 1:7.3+20 squeeze 1:7.5+8 wheezy 1:7.5+8 sid 1:7.6+4',
        'xserver-xorg-input-evdev' => 'etch 1:1.1.2-6 lenny 1:2.0.8-1 squeeze 1:2.3.2-6 wheezy 1:2.3.2-6 sid 1:2.6.0-2 experimental 1:2.6.0-3',
        'xserver-xorg-video-6' => '',
        'xserver-xorg-video-all' => 'etch 1:7.1.0-19 lenny 1:7.3+20 squeeze 1:7.5+8 wheezy 1:7.5+8 sid 1:7.6+4',
        'xterm' => 'etch-security 222-1etch4 etch 222-1etch4 lenny-security 235-2 lenny 235-2 squeeze 261-1 wheezy 269-1 sid 269-1',
        'x-terminal-emulator' => '',
        'xtrans-dev' => 'etch 1.0.1-3 lenny 1.2-2 squeeze 1.2.5-1 wheezy 1.2.6-1 sid 1.2.6-1',
        'zlib1g-dev' => 'etch 1:1.2.3-13 lenny 1:1.2.3.3.dfsg-12 squeeze 1:1.2.3.4.dfsg-3 wheezy 1:1.2.3.4.dfsg-3 sid 1:1.2.3.4.dfsg-3 experimental 1:1.2.5.dfsg-1',
);
}


use ExtUtils::testlib;
use Test::More ;
use Config::Model ;
use Log::Log4perl qw(:easy) ;
use File::Path ;
use File::Copy ;
use Config::Model::Value ;

use warnings;
use strict;

eval { require AptPkg::Config ;} ;
if ( $@ ) {
    plan skip_all => "AptPkg::Config is not installed (not a Debian system ?)";
}
else {
    plan tests => 32;
}

my $arg = shift || '';

my ($log,$show) = (0) x 3 ;
my $do ;

my $trace = $arg =~ /t/ ? 1 : 0 ;
$::debug            = 1 if $arg =~ /d/;
$log                = 1 if $arg =~ /l/;
$show               = 1 if $arg =~ /s/;
$do                 = $1 if $arg =~ /(\d+)/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

my $log4perl_user_conf_file = $ENV{HOME}.'/.log4config-model' ;

if ($log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init($arg =~ /l/ ? $DEBUG: $WARN);
}

my $model = Config::Model -> new ( ) ;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;
$Config::Model::Value::nowarning =  1 unless $trace ;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root';

# cleanup before tests
rmtree($wr_root);
mkpath($wr_root, { mode => 0755 }) ;

my @tests ;
my $i = 0;
$tests[$i]{text} = <<'EOD' ;
Source: libdist-zilla-plugins-cjm-perl
Section: perl
Priority: optional
Build-Depends: debhelper (>= 7)
Build-Depends-Indep: libcpan-meta-perl (>= 2.101550), libdist-zilla-perl (>= 3),
 libfile-homedir-perl (>= 0.81), libmoose-autobox-perl (>= 0.09),
 libmoose-perl (>= 0.65), libpath-class-perl, perl (>= 5.10.1)
Maintainer: Debian Perl Group <pkg-perl-maintainers@lists.alioth.debian.org>
Uploaders: Dominique Dumont <dominique.dumont@hp.com>
Standards-Version: 3.9.1
Homepage: http://search.cpan.org/dist/Dist-Zilla-Plugins-CJM/

Package: libdist-zilla-plugins-cjm-perl
Architecture: all
Depends: ${misc:Depends}, ${perl:Depends}, libcpan-meta-perl (>= 2.101550),
 libdist-zilla-perl (>= 3), libfile-homedir-perl (>= 0.81),
 libmoose-autobox-perl (>= 0.09), libmoose-perl (>= 0.65), libpath-class-perl,
 perl (>= 5.10.1)
Description: Collection of CJM's plugins for Dist::Zilla
 Collection of Dist::Zilla plugins. This package features the 
 following Perl modules:
   * Dist::Zilla::Plugin::ArchiveRelease
     Move the release tarball to an archive directory
   * Dist::Zilla::Plugin::GitVersionCheckCJM
     Ensure version numbers are up-to-date
   * Dist::Zilla::Plugin::ModuleBuild::Custom
     Allow a dist to have a custom Build.PL   
   * Dist::Zilla::Plugin::TemplateCJM
     Process templates, including version numbers & changes
   * Dist::Zilla::Plugin::VersionFromModule
     Get distribution version from its main_module
   * Dist::Zilla::Role::ModuleInfo
     Create Module::Build::ModuleInfo object from Dist::Zilla::File  
EOD

$tests[$i++]{check} 
   = [ 
       'source Source',               "libdist-zilla-plugins-cjm-perl" ,
       'source Build-Depends:0',      "debhelper (>= 7)",
       'source Build-Depends-Indep:0',"libcpan-meta-perl",  # fixed
       'source Build-Depends-Indep:1',"libdist-zilla-perl", # fixed
       'source Build-Depends-Indep:5',"libpath-class-perl",
       'source Build-Depends-Indep:6',"perl (>= 5.10.1)",
       'binary:libdist-zilla-plugins-cjm-perl Depends:0','${misc:Depends}',
     ];

$tests[$i]{text} = <<'EOD2' ;
Source: seaview
Section: non-free/science
Priority: optional
Maintainer: Debian-Med Packaging Team <debian-med-packag...@lists.alioth.debian.org>
Uploaders: Charles Plessy <ple...@debian.org>
Build-Depends: debhelper ( >= 7  ), libfltk1.1-dev, libjpeg62-dev, 
 libpng12-dev, libxft-dev,
 libxext-dev,  zlib1g-dev
Standards-Version: 3.8.1
Vcs-Browser: http://svn.debian.org/wsvn/debian-med/trunk/packages/seaview/trunk/?rev=0&sc=0
Vcs-Svn: svn://svn.debian.org/svn/debian-med/trunk/packages/seaview/trunk/
Homepage: http://pbil.univ-lyon1.fr/software/seaview.html

Package: seaview
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends}
Recommends: clustalw, muscle, phyml
Description: Multiplatform interface for sequence alignment and phylogeny
 SeaView reads and writes various file formats (NEXUS, MSF, CLUSTAL, FASTA,
 PHYLIP, MASE, Newick) of DNA and protein sequences and of phylogenetic trees.
 Alignments can be manually edited. It drives the programs Muscle or Clustal W
 for multiple sequence alignment, and also allows to use any external alignment
 algorithm able to read and write FASTA-formatted files.
 .
 It computes phylogenetic trees by parsimony using PHYLIP's dnapars/protpars
 algorithm, by distance with NJ or BioNJ algorithms on a variety of evolutionary
 distances, or by maximum likelihood using the program PhyML 3.0. SeaView draws
 phylogenetic trees on screen or PostScript files, and allows to download
 sequences from EMBL/GenBank/UniProt using the Internet.

EOD2

$tests[$i++]{check} 
   = [ 
        'binary:seaview Recommends:0','clustalw',
     ];

$tests[$i]{text} = <<'XORG' ;
Source: xorg
Section: x11
Priority: optional
Maintainer: Debian X Strike Force <debian-x@lists.debian.org>
Uploaders: David Nusinow <dnusinow@debian.org>, Drew Parsons <dparsons@debian.org>, Brice Goglin <bgoglin@debian.org>, Cyril Brulebois <kibi@debian.org>
Standards-Version: 3.8.4
Build-Depends: po-debconf, debhelper (>= 7)

Package: x11-common
Architecture: all
Depends: ${misc:Depends}, lsb-base (>= 1.3-9ubuntu2)
Breaks: gdm (<< 2.20.7-5)
Replaces: xfree86-common, xorg-common, xserver-common (<< 7), x-common
Description: X Window System (X.Org) infrastructure
 x11-common contains the filesystem infrastructure required for further
 installation of the X Window System in any configuration; it does not
 provide a full installation of clients, servers, libraries, and utilities
 required to run the X Window System.
 .
 A number of terms are used to refer to the X Window System, including "X",
 "X Version 11", "X11", "X11R6", and "X11R7".  The version of X used in
 Debian is derived from the version released by the X.Org Foundation, and
 is thus often also referred to as "X.Org".  All of the preceding quoted
 terms are functionally interchangeable in an Debian system.

Package: xserver-xorg
Architecture: any
Conflicts: xserver-xfree86 (<< 6.8.2.dfsg.1-1), xserver-common (<< 7), x11-common (<< 1:7.3+11)
Replaces: xserver-common (<< 7), x11-common (<< 1:7.3+11)
Depends:
 xserver-xorg-core (>= 2:1.7),
 xserver-xorg-video-all | xserver-xorg-video-6,
 xserver-xorg-input-all | xserver-xorg-input-7,
 xserver-xorg-input-evdev [alpha amd64 arm armeb armel hppa i386 ia64 lpia m32r m68k mips mipsel powerpc sparc],
 hal (>= 0.5.12~git20090406) [kfreebsd-any],
 ${shlibs:Depends},
 ${misc:Depends},
 xkb-data (>= 1.4),
 x11-xkb-utils
Recommends:
 libgl1-mesa-dri,
Description: the X.Org X server
 This package depends on the full suite of the server and drivers for the
 X.Org X server.  It does not provide the actual server itself.

Package: xserver-xorg-video-all
Architecture: any
Depends:
 ${F:XServer-Xorg-Video-Depends},
 ${misc:Depends},
Replaces: xserver-xorg-driver-all
Conflicts: xserver-xorg-driver-all
Description: the X.Org X server -- output driver metapackage
 This package depends on the full suite of output drivers for the X.Org X server
 (Xorg).  It does not provide any drivers itself, and may be removed if you wish
 to only have certain drivers installed.

Package: xserver-xorg-input-all
Architecture: any
Depends:
 ${F:XServer-Xorg-Input-Depends},
 ${misc:Depends},
Description: the X.Org X server -- input driver metapackage
 This package depends on the full suite of input drivers for the X.Org X server
 (Xorg).  It does not provide any drivers itself, and may be removed if you wish
 to only have certain drivers installed.

Package: xorg
Architecture: any
Depends:
 xserver-xorg,
 libgl1-mesa-glx | libgl1,
 libgl1-mesa-dri,
 libglu1-mesa,
 xfonts-base (>= 1:1.0.0-1),
 xfonts-100dpi (>= 1:1.0.0-1),
 xfonts-75dpi (>= 1:1.0.0-1),
 xfonts-scalable (>= 1:1.0.0-1),
 x11-apps,
 x11-session-utils,
 x11-utils,
 x11-xfs-utils,
 x11-xkb-utils,
 x11-xserver-utils,
 xauth,
 xinit,
 xfonts-utils,
 xkb-data,
 xorg-docs-core,
 xterm | x-terminal-emulator,
 ${misc:Depends},
Provides: x-window-system, x-window-system-core
Suggests: xorg-docs
Description: X.Org X Window System
 This metapackage provides the components for a standalone
 workstation running the X Window System.  It provides the X libraries, an X
 server, a set of fonts, and a group of basic X clients and utilities.
 .
 Higher level metapackages, such as those for desktop environments, can
 depend on this package and simplify their dependencies.
 .
 It should be noted that a package providing x-window-manager should also
 be installed to ensure a comfortable X experience.

Package: xorg-dev
Architecture: all
Depends:
 libdmx-dev,
 libfontenc-dev,
 libfs-dev,
 libice-dev,
 libsm-dev,
 libx11-dev,
 libxau-dev,
 libxaw7-dev,
 libxcomposite-dev,
 libxcursor-dev,
 libxdamage-dev,
 libxdmcp-dev,
 libxext-dev,
 libxfixes-dev,
 libxfont-dev,
 libxft-dev,
 libxi-dev,
 libxinerama-dev,
 libxkbfile-dev,
 libxmu-dev,
 libxmuu-dev,
 libxpm-dev,
 libxrandr-dev,
 libxrender-dev,
 libxres-dev,
 libxss-dev,
 libxt-dev,
 libxtst-dev,
 libxv-dev,
 libxvmc-dev,
 libxxf86dga-dev,
 libxxf86vm-dev,
 x11proto-bigreqs-dev,
 x11proto-composite-dev,
 x11proto-core-dev,
 x11proto-damage-dev,
 x11proto-dmx-dev,
 x11proto-fixes-dev,
 x11proto-fonts-dev,
 x11proto-gl-dev,
 x11proto-input-dev,
 x11proto-kb-dev,
 x11proto-randr-dev,
 x11proto-record-dev,
 x11proto-render-dev,
 x11proto-resource-dev,
 x11proto-scrnsaver-dev,
 x11proto-video-dev,
 x11proto-xcmisc-dev,
 x11proto-xext-dev,
 x11proto-xf86bigfont-dev,
 x11proto-xf86dga-dev,
 x11proto-xf86dri-dev,
 x11proto-xf86vidmode-dev,
 x11proto-xinerama-dev,
 xserver-xorg-dev,
 xtrans-dev,
 ${misc:Depends},
Description: the X.Org X Window System development libraries
 This metapackage provides the development libraries for the X.Org X Window
 System.
 .
 X Window System design documentation, manual pages, library reference
 works, static versions of the shared libraries, and C header files are
 supplied by the packages depended on by this metapackage.
 .
 Note that this is a convenience package for users and is not a package for
 Debian developers to have their package depend on.

Package: xlibmesa-gl
Section: libs
Architecture: all
Depends:
 libgl1-mesa-glx,
 ${misc:Depends},
Description: transitional package for Debian etch
 This package is provided to smooth upgrades from Debian 3.1 ("sarge") to
 Debian etch. It may be safely removed from your system.

Package: xlibmesa-gl-dev
Section: libdevel
Architecture: all
Depends:
 libgl1-mesa-dev,
 ${misc:Depends},
Description: transitional package for Debian etch
 This package is provided to smooth upgrades from Debian 3.1 ("sarge") to
 Debian etch. It may be safely removed from your system.

Package: xlibmesa-glu
Section: libdevel
Architecture: all
Depends:
 libglu1-mesa,
 ${misc:Depends},
Description: transitional package for Debian etch
 This package is provided to smooth upgrades from Debian 3.1 ("sarge") to
 Debian etch. It may be safely removed from your system.

Package: libglu1-xorg
Section: libs
Architecture: all
Depends:
 libglu1-mesa,
 ${misc:Depends},
Description: transitional package for Debian etch
 This package is provided to smooth upgrades from Debian 3.1 ("sarge") to
 Debian etch. It may be safely removed from your system.
 
Package: libglu1-xorg-dev
Section: libdevel
Architecture: all
Depends:
 libglu1-mesa-dev,
 ${misc:Depends},
Description: transitional package for Debian etch
 This package is provided to smooth upgrades from Debian 3.1 ("sarge") to
 Debian etch. It may be safely removed from your system.

Package: xbase-clients
Section: x11
Architecture: all
Depends:
 x11-apps,
 x11-session-utils,
 x11-utils,
 x11-xfs-utils,
 x11-xkb-utils,
 x11-xserver-utils,
 xauth,
 xinit,
 ${misc:Depends},
Description: miscellaneous X clients - metapackage
 An X client is a program that interfaces with an X server (almost always via
 the X libraries), and thus with some input and output hardware like a
 graphics card, monitor, keyboard, and pointing device (such as a mouse).
 .
 This package provides a miscellaneous assortment of several dozen X clients
 that ship with the X Window System.
 .
 This package is provided for transition from earlier Debian releases, the
 programs formerly in xutils and xbase-clients having been split out in smaller
 packages.

Package: xutils
Section: x11
Architecture: all
Depends:
 x11-xfs-utils,
 x11-utils,
 x11-xserver-utils,
 x11-session-utils,
 xfonts-utils,
 ${misc:Depends},
Description: X Window System utility programs metapackage
 xutils provides a set of utility programs shipped with the X Window System.
 Many of these programs are useful even on a system that does not have any X
 clients or X servers installed.
 .
 This package is provided for transition from earlier Debian releases, the
 programs formerly in xutils and xbase-clients having been split out in smaller
 packages.


XORG

$tests[$i++]{check} 
   = [ 
      'binary:xserver-xorg-video-all Architecture', 'any',
      'binary:xserver-xorg-video-all Depends:0','${F:XServer-Xorg-Video-Depends}',
      'binary:xserver-xorg-video-all Depends:1','${misc:Depends}',
      'binary:xserver-xorg-video-all Replaces:0', 'xserver-xorg-driver-all',
      'binary:xserver-xorg-video-all Conflicts:0', 'xserver-xorg-driver-all',
     ];

$tests[$i]{text} = <<'EOD' ;
Source: libdist-zilla-plugin-podspellingtests-perl
Section: perl
Priority: optional
Build-Depends: debhelper (>= 7)
Build-Depends-Indep: perl
Maintainer: Debian Perl Group <pkg-perl-maintainers@lists.alioth.debian.org>
Uploaders: Dominique Dumont <dominique.dumont@hp.com>
Standards-Version: 3.9.1
Homepage: http://search.cpan.org/dist/Dist-Zilla-Plugin-PodSpellingTests/
Vcs-Svn: svn://svn.debian.org/pkg-perl/trunk/libdist-zilla-plugin-podspellingtests-perl/
Vcs-Browser: http://svn.debian.org/viewsvn/pkg-perl/trunk/libdist-zilla-plugin-podspellingtests-perl/

Package: libdist-zilla-plugin-podspellingtests-perl
Architecture: all
Depends: ${misc:Depends}, ${perl:Depends}
Description: Release tests for POD spelling
 This is an extension of Dist::Zilla::Plugin::InlineFiles, xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx providing the following file:
 .
 - xt/release/pod-spell.t - a standard Test::Spelling test
EOD

$tests[$i++]{check} 
   = [ 'binary:libdist-zilla-plugin-podspellingtests-perl Synopsis' 
   => "release tests for POD spelling",
    'binary:libdist-zilla-plugin-podspellingtests-perl Description' 
   => "This is an extension of Dist::Zilla::Plugin::InlineFiles,
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx providing the following file:

 - xt/release/pod-spell.t - a standard Test::Spelling test"   ];


my $idx = 0 ;
foreach my $t (@tests) {
    if (defined $do and $do ne $idx) { $idx ++; next; }
   my $wr_dir = $wr_root.'/test-'.$idx ;
   mkpath($wr_dir."/debian/", { mode => 0755 }) ;
   my $control_file = "$wr_dir/debian/control" ;

   open(my $control_h,"> $control_file" ) || die "can't open $control_file: $!";
   print $control_h $t->{text} ;
   close $control_h ;

   my $inst = $model->instance (root_class_name   => 'Debian::Dpkg::Control',
                                root_dir          => $wr_dir,
                                instance_name => "deptest".$idx,
                                check => 'yes',
                               );  
   ok($inst,"Read $control_file and created instance") ;

   my $control = $inst -> config_root ;

   $inst->apply_fixes;
   
   my $dump =  $control->dump_tree ();
   print $dump if $trace ;
   
   while (@{$t->{check}}) { 
     my ($path,$v) = splice @{$t->{check}},0,2 ;
     is($control->grab_value($path),$v,"check $path value");
   }
   
   $inst->write_back ;
   ok(1,"Control file write back done") ;

   # create another instance to read the IniFile that was just written
   my $wr_dir2 = $wr_dir.'-w' ;
   mkpath($wr_dir2.'/debian',{ mode => 0755 })   || die "can't mkpath: $!";
   copy($wr_dir.'/debian/control',$wr_dir2.'/debian/') 
      or die "can't copy from $wr_dir to $wr_dir2: $!";

   my $i2_test = $model->instance(root_class_name   => 'Debian::Dpkg::Control',
                                  root_dir    => $wr_dir2 ,
                                  instance_name => "deptest".$idx."-w",
                                 );

   ok( $i2_test, "Created instance $idx-w" );

   my $i2_root = $i2_test->config_root ;

   my $p2_dump = $i2_root->dump_tree ;

   is($p2_dump,$dump,"compare original data with 2nd instance data") ;
   
   $idx++ ;
}

