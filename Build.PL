#    Copyright (c) 2005-2012 Dominique Dumont.
#
#    This file is part of Config-Model.
#
#    Config-Model is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public License as
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

require 5.010001 ;

print "\nIf you want to use the TermUI interface, you should install\n",
  "Term::ReadLine::Perl or Term::ReadLine::Gnu\n\n";

# check that pod docs are up-to-date this is redundant with work done by
# dzil. But this enable to re-build the docs downstream.
# Use $^X in there as requested in 
# https://rt.cpan.org/Public/Bug/Display.html?id=74891
my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

sub ACTION_build {
    my $self = shift;
    # below requires Config::Model 2.062
    system ($^X, qw!-I lib -MConfig::Model::Utils::GenClassPod -e gen_class_pod();!) == 0
                    or die "gen-class-pod failed: $?";
    $self->SUPER::ACTION_build;
}
SUBCLASS


my @version_info = @ARGV ? ( dist_version => $ARGV[0] ) : ();

my %appli_files = map { ( $_, $_ ) } glob("lib/Config/Model/*.d/*");

my $build = $class->new(
    module_name => 'Config::Model',
    @version_info,
    license       => 'lgpl',
    appli_files   => \%appli_files,
    dist_abstract => 'Describe, edit and validate configuration data',
    dist_author   => 'Dominique Dumont (ddumont at cpan dot org)',

##{ $plugin->get_prereqs ##}

    # cleanup required by t/auto_read.t
    # PreGrammar.pm is created by t/value_computer.t
    add_to_cleanup => [ qw/PreGrammar.pm wr_root/ ],
);

$build->add_build_element('pl');
$build->add_build_element('appli');

$build->create_build_script;
