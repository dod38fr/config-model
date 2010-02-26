# $Author$
# $Date$
# $Revision$

#    Copyright (c) 2007-2009 Dominique Dumont.
#
#    This file is part of Config-Model-TkUI.
#
#    Config-Model-TkUI is free software; you can redistribute it
#    and/or modify it under the terms of the GNU Lesser Public License
#    as published by the Free Software Foundation; either version 2.1
#    of the License, or (at your option) any later version.
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

require 5.008 ;

my $build = Module::Build->new
  (
   module_name => 'Config::Model::TkUI',
   license => 'lgpl',
   dist_abstract => "Tk GUI to edit config data through Config::Model",
   dist_author  => "Dominique Dumont (ddumont at cpan dot org)",
   requires => {
		'Config::Model'    => '0.643',
		'Exception::Class' => 0,
		'Tk'               => 0,
		'Tk::DirSelect'    => 0,
		'Tk::Tree'         => 0,
		'Log::Log4perl'    => '1.11', # for TRACE log level
	       },
   recommends => {
		  'Tk::ObjScanner' => 0, # for TkUI debug menu
		 },
   add_to_cleanup => [qw/stderr.log wr_data/] ,
  );

$build->add_build_element('png');
$build->create_build_script;
