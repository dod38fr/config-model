#    Copyright (c) 2008 Dominique Dumont.
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

my $aug_libs   = `pkg-config --libs   augeas` ;
my $aug_cflags = `pkg-config --cflags augeas` ;

if (not defined $aug_libs or not defined $aug_cflags) {
    die "could not run 'pkg-config' to determine compiler/linker",
      "flags for augeas library: $!\n";
}

if (not $aug_libs or not $aug_cflags) {
    die "'pkg-config' didn't report any compiler/linker flags for",
      "augeas library\n";
}

chomp($aug_cflags, $aug_libs) ;

print "Using $aug_libs and $aug_cflags to compile\n" ;


my $build = Module::Build->new
  (
   module_name   => 'Config::Augeas',
   license       => 'lgpl',
   dist_version_from  => 'lib/Config/Augeas.pm' ,
   dist_author   => "Dominique Dumont (ddumont at cpan dot org)",
   dist_abstract => "Edit configuration files through Augeas C library",

   dynamic_config       => 1,
   extra_compiler_flags => $aug_cflags,
   extra_linker_flags   => $aug_libs,

   add_to_cleanup => [qw!wr_test _build lib/Config/Augeas.c lib/Config/Augeas.o! ] ,
  );


# $build->add_build_element('pl');
$build->create_build_script;
