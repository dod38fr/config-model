#
# This file is part of Config-Model
#
# This software is Copyright (c) 2012 by Dominique Dumont, Krzysztof Tyszecki.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
#    Copyright (c) 2005-2012 Dominique Dumont.
#
#    This file is part of Config-Model.
#
#    Config-Model is free software; you can redistribute it and/or
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

use warnings FATAL => qw(all);
use strict;
use File::Slurp qw/slurp/;
use Log::Log4perl qw(:easy) ;

Log::Log4perl->easy_init($WARN);

require 5.010001 ;

print "\nIf you want to use the TermUI interface, you should install\n",
  "Term::ReadLine::Perl or Term::ReadLine::Gnu\n\n";

# check that pod docs are up-to-date
# this is redundant with work done by dzil. But this enable to re-build the 
# docs downstream.
# Use $^X as requested in https://rt.cpan.org/Public/Bug/Display.html?id=74891
system("$^X -Ilib script/gen_class_pod.pl");

my @version_info = @ARGV ? ( dist_version => $ARGV[0] ) : ();

my %appli_files = map { ( $_, $_ ) } glob("lib/Config/Model/*.d/*");

my $build = Module::Build->new(
    module_name => 'Config::Model',
    @version_info,
    license       => 'lgpl',
    script_files  => ['config-edit','script/cme'],
    appli_files   => \%appli_files,
    dist_abstract => 'Describe, edit and validate configuration data',
    dist_author   => 'Dominique Dumont (ddumont at cpan dot org)',

    # Build.PL runs gen_class_pod.pl which loads Config::Model from lib,
    # hence most of the runtime dependencies are in fact 
    # configure_requires. This should improve Perl smoke tests.

  'build_requires' => {
    'File::Copy::Recursive' => '0',
    'Module::Build' => '0.34',
    'Path::Class' => '0',
    'Probe::Perl' => '0',
    'Test::Command' => '0.08',
    'Test::Differences' => '0',
    'Test::Exception' => '0',
    'Test::File::Contents' => '0',
    'Test::Memory::Cycle' => '0',
    'Test::More' => '0',
    'Test::Warn' => '0.11'
  },
  'configure_requires' => {
    'Any::Moose' => '0',
    'Carp::Assert::More' => '0',
    'Exception::Class' => '0',
    'File::HomeDir' => '0',
    'File::Path' => '2.07',
    'File::Slurp' => '0',
    'Hash::Merge' => '0.12',
    'IO::File' => '0',
    'List::MoreUtils' => '0',
    'Log::Log4perl' => '1.11',
    'Module::Build' => '0.34',
    'Mouse' => '0',
    'MouseX::NativeTraits' => '0',
    'MouseX::StrictConstructor' => '0',
    'Parse::RecDescent' => 'v1.90.0',
    'Pod::POM' => '0',
    'Scalar::Util' => '0',
    'Term::ReadLine' => '0',
    'Text::Diff' => '0',
    'YAML::Any' => '0.303',
    'namespace::autoclean' => '0'
  },
  'recommends' => {
    'Fuse' => '0',
    'YAML::Any' => '0.303'
  },
  'requires' => {
    'Any::Moose' => '0',
    'AnyEvent' => '0',
    'AnyEvent::HTTP' => '0',
    'Carp::Assert::More' => '0',
    'DB_File' => '0',
    'Exception::Class' => '0',
    'File::HomeDir' => '0',
    'File::Path' => '2.07',
    'Hash::Merge' => '0.12',
    'IO::File' => '0',
    'List::MoreUtils' => '0',
    'Log::Log4perl' => '1.11',
    'Mouse' => '0',
    'MouseX::NativeTraits' => '0',
    'MouseX::StrictConstructor' => '0',
    'Parse::RecDescent' => 'v1.90.0',
    'Pod::POM' => '0',
    'Scalar::Util' => '0',
    'Term::ReadLine' => '0',
    'Text::Autoformat' => '0',
    'Text::Diff' => '0',
    'namespace::autoclean' => '0'
  },

    meta_merge => {
        resources => {
            homepage => 'https://github.com/dod38fr/config-model/wiki',
            MailingList =>
              'https://lists.sourceforge.net/lists/listinfo/config-model-users',
            repository =>
              'git://github.com/dod38fr/config-model.git',
        },
    },

    # cleanup required by t/auto_read.t
    # PreGrammar.pm is created by t/value_computer.t
    add_to_cleanup => [ qw/PreGrammar.pm wr_root r_root/ ],
);

$build->add_build_element('pl');
$build->add_build_element('appli');

$build->create_build_script;
