#    Copyright (c) 2008-2009 Dominique Dumont.
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Model is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
#    02110-1301 USA

use Module::Build;

use warnings FATAL => qw(all) ;
use strict ;

# snatched from ExtUtils::PkgConfig
# don't go any further if pkg-config cannot be found.
my $have_pkg_config = eval {`pkg-config --version`; };

if ($have_pkg_config eq "") {
    # Warn and exit with status 0 to indicate (to the user and the CPAN
    # testers infrastructure) that this module won't work on this machine.
warn <<"__EOW__";
***
*** Config::Augeas requires the pkg-config utility, but it doesn't
*** seem to be in your PATH.  Is pkg-config correctly installed?
***  PATH=$ENV{PATH}
***
__EOW__
    exit 0;
}

my $aug_libs   = `pkg-config --libs   augeas` ;
my $aug_cflags = `pkg-config --cflags augeas` ;

if (not defined $aug_libs or not defined $aug_cflags
    or not $aug_libs or not $aug_cflags) {
    warn << "EOW1" ;
***
*** 'pkg-config' did not find augeas lib or augeas header files. Config::Augeas
*** needs both augeas library and augeas header files to be compiled.
***
EOW1
    exit 0;
}

my $aug_version = `pkg-config --modversion augeas` ;
chomp($aug_cflags, $aug_libs, $aug_version) ;

if (   not defined $aug_version or ( $aug_version lt '0.5.0')) {
    warn << "EOW2" ;
***
*** 'pkg-config' did find augeas version $aug_version but 
*** version 0.5.0 minimum is required
***
EOW2
    exit 0;
}

print "Using $aug_libs and $aug_cflags to compile (Augeas version $aug_version)\n" ;


my $build = Module::Build->new
  (
   module_name   => 'Config::Augeas',
   license       => 'lgpl',
   dist_version_from  => 'lib/Config/Augeas.pm' ,
   dist_author   => "Dominique Dumont (ddumont at cpan dot org)",
   dist_abstract => "Edit configuration files through Augeas C library",

   dynamic_config       => 1,
   extra_compiler_flags => $aug_cflags . ' -Wall -Wformat -Werror=format-security',
   extra_linker_flags   => $aug_libs,

   build_requires => {
                      'Test::More'      => 0,
		     },

   add_to_cleanup => [qw!wr_test _build augeas-root lib/Config/Augeas.c lib/Config/Augeas.o! ] ,
  );


# $build->add_build_element('pl');
$build->create_build_script;
