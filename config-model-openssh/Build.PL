# $Author: ddumont $
# $Date: 2008-02-07 11:29:57 $
# $Revision: 1.3 $

#    Copyright (c) 2008-2009 Dominique Dumont.
#
#    This file is part of Config-Model-OpenSsh.
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
   module_name   => 'Config::Model::OpenSsh',
   license       => 'lgpl',
   dist_author   => "Dominique Dumont (ddumont at cpan dot org)",
   dist_abstract => "OpenSsh configuration files graphical editor",
   script_files   => [ qw/config-edit-ssh config-edit-sshd/ ],
   requires      => {
		     perl              => '5.8.0',
		     'Config::Model'   => '0.641',
		     'Log::Log4perl'   => 0 ,
		     'Parse::RecDescent' => 0,
		    },
   recommends    => {
                     'Config::Model::CursesUI' => 0, # Curses interface
                     'Config::Model::TkUI'     => 0, # graphical interface
		     # Augeas library to keep /etc/ssh/sshd_config structure and comments
                     'Config::Model::Backend::Augeas' => 0, 
                    },
   add_to_cleanup => [qw/wr_test/] ,
  );


$build->add_build_element('pl');
$build->create_build_script;
