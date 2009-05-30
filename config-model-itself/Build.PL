# $Author: ddumont $
# $Date: 2008-02-07 11:29:57 $
# $Revision: 1.3 $

#    Copyright (c) 2007-2009 Dominique Dumont.
#
#    This file is part of Config-Model-Itself.
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
use Data::Dumper ;

use warnings FATAL => qw(all) ;
use strict ;


my $build = Module::Build->new
  (
   module_name   => 'Config::Model::Itself',
   license       => 'lgpl',
   dist_author   => "Dominique Dumont (ddumont at cpan dot org)",
   dist_abstract => "Graphical model editor for Config::Model",
   requires      => {
		     'Config::Model'   => '0.636',
		     'Log::Log4perl'   => 0 ,
		     'Config::Model::TkUI' => '1.209',
		    },
   script_files  => [ 'config-model-edit' ],
   add_to_cleanup => [qw/wr_test/] ,
  );


$build->add_build_element('pl');
$build->create_build_script;
