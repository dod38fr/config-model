
package Config::Model::Xorg ;

# dummy package so CPAN can collect information regarding this module

# use vars qw($VERSION) ;

# $VERSION = '1.104' ;

=head1 NAME

Config::Model::Xorg - Xorg configuration model for Config::Model

=head1 SYNOPSIS

# No synopsis. Config::Model::Xorg is a plugin for Config::Model

=head1 DESCRIPTION

This module provides a configuration model for Xorg.

With this module and Config::Model, you have a tool to tune the
configuration of your favourite X server.

Installing Config::Model::CursesUI is recommended as you'll have a
more user friendly curses based user interface.

Once this module is installed, you can run (as root, but please backup
/etc/X11/xorg.conf before):

  # config-edit -model Xorg

You may want to try it safely first by writing the resulting xorg.conf
elsewhere (in this case you can run this command with your user
account):

  $ config-edit -model Xorg -write_directory test

If config-edit fails with your xorg.conf (See BUGS section below), you
can try config-edit with the provided xorg.conf (but it won't be
useful for you as this file will not match your hardware
configuration). Note that you must run this command where you unpacked
this perl module:

  $ config-edit -model Xorg -read data -write wr_test

If you do not have the curses user interface, be sure to read doc
which explain the basic command of the terminal based interface:
http://search.cpan.org/dist/Config-Model/TermUI.pm#USER_COMMAND_SYNTAX

=head1 CONSTRUCTOR


=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 LICENSE

  Copyright (c) 2005-2009 Dominique Dumont.

  This file is part of Config-Xorg.

  Config-Xorg is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser Public License as
  published by the Free Software Foundation; either version 2.1 of
  the License, or (at your option) any later version.

  Config-Xorg is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser Public License for more details.

  You should have received a copy of the GNU Lesser Public License
  along with Config-Model; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

=head1 SEE ALSO

L<Config::Model>,

