
package Config::Model::Xorg ;

use Config::Model ;
use Log::Log4perl ;

my $log4perl_conf_file = '/etc/log4config-model.conf' ;
my $fallback_conf = << 'EOC';
log4perl.logger.ConfigModel=WARN, A1
log4perl.appender.A1=Log::Dispatch::File
log4perl.appender.A1.filename=/tmp/ConfigModel.log
log4perl.appender.A1.mode=append
log4perl.appender.A1.layout=Log::Log4perl::Layout::SimpleLayout
EOC

my $log4perl_conf = -e $log4perl_conf_file ? $log4perl_conf_file
                  :                          \$fallback_conf ;

Log::Log4perl::init($log4perl_conf) unless Log::Log4perl->initialized ;

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

=head2 new ()

Returns a Config::Model::Xorg object. This object will load Xorg
configuration model and C<xorg.conf> data.

=cut

sub new {
    my $type = shift ;

    my $model = Config::Model -> new() ;

    my $inst = $model->instance (root_class_name => 'Xorg' ,
				 instance_name   => 'xorg config' ,
				);

    my $root = $inst -> config_root ;

    my $self = { model => $model,
		 root => $root ,
	       } ;
    bless $self,$type ;
}

=head1 Methods

=head2 root

Return Xorg root node. I.e. a L<Config::Model::Node> object.

=cut

sub root {
    my $self = shift;
    return $self->root ;
}

=head2 check

Check if Xorg configuration data is correct. Return 1 if yes.
Raises an exception if some error is found.

=cut

sub check {
    my $self = shift ;

    # this will exit in case of error
    my $str = $self->{root} -> dump_tree () ;

    print "xorg config is fine\n";
    return 1;
}

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

