# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 36;
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
     ];



my $idx = 0 ;
foreach my $t (@tests) {
   my $wr_dir = $wr_root.'/test-'.$idx ;
   mkpath($wr_dir."/debian/", { mode => 0755 }) ;
   my $license_file = "$wr_dir/debian/control" ;

   open(LIC,"> $license_file" ) || die "can't open $license_file: $!";
   print LIC $t->{text} ;
   close LIC ;

   my $inst = $model->instance (root_class_name   => 'Debian::Dpkg::Control',
                                root_dir          => $wr_dir,
                                instance_name => "deptest".$idx,
                               );  
   ok($inst,"Read $license_file and created instance") ;

   my $lic = $inst -> config_root ;

   my $dump =  $lic->dump_tree ();
   print $dump if $trace ;
   
   while (@{$t->{check}}) { 
     my ($path,$v) = splice @{$t->{check}},0,2 ;
     is($lic->grab_value($path),$v,"check $path value");
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

