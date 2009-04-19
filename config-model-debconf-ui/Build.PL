# $Author: ddumont $
# $Date: 2009-03-31 13:41:21 +0200 (mar 31 mar 2009) $
# $Revision: 910 $

#    Copyright (c) 2007-2009 Dominique Dumont.
#
#    This file is part of Config-Model-DebconfUI.
#
#    Config-Model-DebconfUI is free software; you can redistribute it
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

require 5.006 ;

my $build = Module::Build->new
  (
   module_name => 'Config::Model::DebconfUI',
   license => 'lgpl',
   dist_abstract => "Debian Debconf wizard to edit config data",
   dist_author  => "Dominique Dumont (ddumont at cpan dot org)",
   requires => {
		'Config::Model'    => '0.635',
		'Exception::Class' => 0,
		'Debconf::Client::ConfModule'               => 0,
		'Log::Log4perl'    => '1.11', # for TRACE log level
	       },
   add_to_cleanup => [qw/stderr.log wr_data/] ,
  );

$build->add_build_element('png');
$build->create_build_script;
