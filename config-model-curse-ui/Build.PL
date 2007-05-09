# $Author: ddumont $
# $Date: 2007-05-09 12:19:10 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

#    Copyright (c) 2007 Dominique Dumont.
#
#    This file is part of Config-Model-Curses-UI.
#
#    Config-Model-Curses-UI is free software; you can redistribute it
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

my $build = Module::Build->new
  (
   module_name => 'Config::Model::CursesUI',
   license => 'lgpl',
   dist_version => 0.5 ,
   dist_author  => "Dominique Dumont (ddumont at cpan dot org)",
   dist_abstract => "Curses intraface for Config::Model",
   requires => {
		'Config::Model'   => '0.608',
		'Log::Log4perl'   => 0 ,
	       },
   add_to_cleanup => [qw/stderr.log wr_data/] ,
  );

$build->add_build_element('pl');
$build->create_build_script;
