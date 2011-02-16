
# See license at bottom of pod

package Config::Model::OpenSsh ;


=head1 NAME

Config::Model::OpenSsh - OpenSsh config editor

=head1 SYNOPSIS

=head2 invoke editor

The following will launch a graphical editor (if L<Config::Model::TkUI>
is installed):

 config-edit -application sshd 

=head2 command line

This command will add a C<Host Foo> section in C<~/.ssh/config>: 

 config-edit -application ssh -ui none Host:Foo ForwardX11=yes
 
=head2 programmatic

This code snippet will remove the C<Host Foo> section added above:

 use Config::Model ;
 use Log::Log4perl qw(:easy) ;
 my $model = Config::Model -> new ( ) ;
 my $inst = $model->instance (root_class_name => 'Ssh');
 $inst -> config_root ->load("Host~Foo") ;
 $inst->write_back() ;

=head1 DESCRIPTION

This module provides a configuration editors (and models) for the 
configuration files of OpenSsh. (C</etc/ssh/sshd_config>, F</etc/ssh/ssh_config>
and C<~/.ssh/config>).

This module can also be used to modify safely the
content of these configuration files from a Perl programs.

Once this module is installed, you can edit C</etc/ssh/sshd_config> 
with run (as root) :

 # config-edit -application sshd 

To edit F</etc/ssh/ssh_config>, run (as root):

 # config-edit -application ssh

To edit F<~/.ssh/config>, run as a normal user:

 # config-edit -application ssh

=head1 user interfaces

As mentioned in L<config-edit>, several user interfaces are available:

=over

=item *

A graphical interface is proposed by default if L<Config::Model::TkUI> is installed.

=item *

A Curses interface with option C<-ui curses> if L<Config::Model::CursesUI> is installed.

=item *

A Shell like interface with option C<-ui term>.

=item *

A L<Fuse> virtual file system with option C<< -ui fuse -fuse_dir <mountpoint> >> 
if L<Fuse> is installed (Linux only)

=back

=head1 STOP

The documentation provides on the reader and writer of OpenSsh configuration files.
These details are not needed for the basic usages explained above.

=head1 Functions

These read/write functions are part of OpenSsh read/write backend. They are 
declared in OpenSsh configuration models and are called back when needed to read the 
configuration file and write it back.

=head2 sshd_read (object => <sshd_root>, conf_dir => ...)

Read F<sshd_config> in C<conf_dir> and load the data in the 
C<sshd_root> configuration tree.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 LICENSE

   Copyright (c) 2008-2010 Dominique Dumont.

   This file is part of Config-Model-OpenSsh.

   Config-Model-OpenSsh is free software; you can redistribute it and/or
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

L<config-edit-sshd>, L<config-edit-ssh>, L<Config::Model>,
