# -*- cperl -*-
BEGIN {
    # dirty trick to create a Memoize cache so that test will use this instead
    # of getting values through the internet
    my $sep = chr(28);
    no warnings 'once' ;
    %Config::Model::Debian::Dependency::cache = (
        'debhelper'.$sep.'7' => '',
        'libcpan-meta-perl' . $sep . '2.101550' => '',
        'libdist-zilla-perl' . $sep . '3'       => '',
        'libfile-homedir-perl' . $sep . '0.81'  => 'lenny',
        'libmoose-autobox-perl' . $sep . '0.09' => '',
        'libmoose-perl' . $sep . '0.65'         => 'lenny',
        'lsb-base' . $sep . '1.3-9ubuntu2'      => '',
        'perl' . $sep . '5.10.1'                => 'lenny',
        'xkb-data' . $sep . '1.4'               => 'lenny',
    );
}


use ExtUtils::testlib;
use Test::More tests => 26;
use Config::Model ;
use Log::Log4perl qw(:easy) ;
use File::Path ;
use File::Copy ;

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
       'source Build-Depends-Indep:0',"libcpan-meta-perl (>= 2.101550)",
       'source Build-Depends-Indep:1',"libdist-zilla-perl (>= 3)",
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

my $idx = 0 ;
foreach my $t (@tests) {
   my $wr_dir = $wr_root.'/test-'.$idx ;
   mkpath($wr_dir."/debian/", { mode => 0755 }) ;
   my $control_file = "$wr_dir/debian/control" ;

   open(my $control_h,"> $control_file" ) || die "can't open $control_file: $!";
   print $control_h $t->{text} ;
   close $control_h ;

   my $inst = $model->instance (root_class_name   => 'Debian::Dpkg::Control',
                                root_dir          => $wr_dir,
                                instance_name => "deptest".$idx,
                               );  
   ok($inst,"Read $control_file and created instance") ;

   my $control = $inst -> config_root ;

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
   last if $one ;
}

