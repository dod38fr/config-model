#    Copyright (c) 2005-2010 Dominique Dumont.
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

use warnings FATAL => qw(all) ;
use strict ;

require 5.008;

print "\nIf you want to use the TermUI interface, you should install\n",
  "Term::ReadLine::Perl or Term::ReadLine::Gnu\n\n";

my $build = Module::Build->new
  (
   module_name    => 'Config::Model',
   license        => 'lgpl',
   script_files   => [ 'config-edit' ],
   dist_abstract  => 'Describe, edit and validate configuration data',
   dist_author    => 'Dominique Dumont (ddumont at cpan dot org)',
   requires       => {
		      'Term::ReadLine'    => 0,
		      'Log::Log4perl'     => '1.11', # for TRACE log level
		      'Parse::RecDescent' => '1.90.0',
		      'Scalar::Util'      => 0, # provided by perl 5.8.0
		      'Exception::Class'  => 0,
		      'Carp::Assert::More' => 0,
		      # should be part of core perl since perl5.003007
		      # but some do not have it 
		      'IO::File'          => 0, 
		      # YAML backend
		      'YAML::Any'         => '0.303',
		     },
   build_requires => {
		      'Config::Tiny'      => 0,
		      'Test::More'        => 0,
		      'Test::Exception'   => 0,
		      'Test::Warn'        => '0.11', # tests fail with 0.08
		     },
   recommends => {
		  # recommended modules to get more reader/writer
		  'Config::Tiny' => 0,
 		 },
   # cleanup required by t/auto_read.t
   # PreGrammar.pm is created by t/value_computer.t
   add_to_cleanup => [qw/PreGrammar.pm wr_root r_root/],
  );

$build->add_build_element('pl');
$build->create_build_script;
