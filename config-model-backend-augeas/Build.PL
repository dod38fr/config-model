# $Author$
# $Date$
# $Revision$

#    Copyright (c) 2008-2010 Dominique Dumont.
#
#    This file is part of Config-Model-Backend-Augead.
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

print "Note: Augeas integration tests require Config::Augeas ",
  "and Augeas library > 0.3.3\n\n";

my $build = Module::Build->new
  (
   module_name    => 'Config::Model::Backend::Augeas',
   license        => 'lgpl',
   dist_abstract  => 'Read and write configuration data through Augeas',
   dist_author    => 'Dominique Dumont (ddumont at cpan dot org)',
   requires       => {
		      'Log::Log4perl'     => '1.11', # for TRACE log level
		      'Exception::Class'  => 0,
		      'Config::Augeas' => '0.303',
		      'Config::Model'  => '1.207',
		     },
   build_requires => {
		      'Test::More'        => 0,
		      'Test::Exception'   => 0,
		      'Test::Warn'        => '0.11', # tests fail with 0.08
		     },

   # cleanup required by t/augeas_backend.t
   add_to_cleanup => [qw/wr_root r_root/],
  );

$build->create_build_script;
