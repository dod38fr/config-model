
#    Copyright (c) 2009-2011 Dominique Dumont.
#
#    This file is part of Config-Model-Approx.
#
#    Config-Model-Approx is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Model-Approx is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

package Config::Model::Approx ;

use strict ;
use warnings ;

use Carp ;
use Log::Log4perl;
use File::Copy ;
use File::Path ;

our $VERSION = '1.004' ;

my $logger = Log::Log4perl::get_logger(__PACKAGE__);

sub read {
    # keys are object , root,  config_dir, io_handle, file
    my %args = @_ ;

    $logger->info("loading config file $args{file}") if defined $args{file};

    foreach ($args{io_handle}->getlines) {
	chomp;
	s/#.*//;
	s/\s+/=/; # translate file in string loadable by C::M::Loader
	next unless $_;
	my $load = s/^\$// ? $_ 
                 : m!://!  ? "distributions:".$_
                 :           $_ ; # old style parameter
	$args{object}->load($load) ;
    }

    return 1;
}

sub write {
    my %args = @_ ;

    $logger->info("writing config file $args{file}");
    my $node = $args{object} ;
    my $ioh  = $args{io_handle} ;

    $ioh->print("# This file was written by Config::Model with Approx model\n");
    $ioh->print("# You may modify the content of this file. Configuration \n");
    $ioh->print("# modifications will be preserved. Modifications in the comments\n");
    $ioh->print("# will be discarded\n\n");

    # Using Config::Model::ObjTreeScanner would be overkill
    foreach my $elt ($node->get_element_name) {
	next if $elt eq 'distributions';

	# write some documentation in comments
	$ioh->print("# $elt:", $node->get_help(summary => $elt));
	my $upstream_default = $node->fetch_element($elt) -> fetch('upstream_default') ;
	$ioh->print(" ($upstream_default)") if defined $upstream_default;
	$ioh->print("\n") ;

	# write value
	my $v = $node->grab_value($elt) ;
	$ioh->printf("\$%-10s %s\n",$elt,$v) if defined $v ;
	$ioh->print("\n") ;
    }

    my $h = $node->fetch_element('distributions') ;
    $ioh->print("# ", $node->get_help(summary => 'distributions'),"\n");
    foreach my $dname ($h->get_all_indexes) {
	$ioh->printf("%-10s %s\n",$dname,
		     $node->grab_value("distributions:$dname")
		    ) ;
    }
    return 1;

}

1;

=head1 NAME

Config::Model::Approx - Approx configuration file editor

=head1 SYNOPSIS

 use Config::Model ;
 my $model = Config::Model -> new ( ) ;

 my $inst = $model->instance (root_class_name   => 'Approx');
 my $root = $inst -> config_root ;

 $root->load("distribution:multimedia=http://www.debian-multimedia.org") ;

 $inst->write_back() ;

=head1 DESCRIPTION

This module provides a configuration model for Approx. Then
Config::Model provides a graphical editor program for
F</etc/approx/approx.conf>. See L<config-edit-approx> more help.

This module and Config::Model can also be used from Perl programs to
modify safely the content of F</etc/approx/approx.conf>.

Once this module is installed, you can run:

 # config-edit-approx

The Perl API is documented in L<Config::Model> and mostly in
L<Config::Model::Node>.

=head1 Functions

These functions are declared in Approx configuration models and are
called back.

=head2 read (object => approx_root>, io_handle => ...)

Read F<approx.conf> and load the data in the C<approx_root>
configuration tree.

=head2 write (object => approx_root>, io_handle => ...)

Write data from the C<approx_root> configuration tree into
F<approx.conf>.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 LICENSE

   Copyright (c) 2009 Dominique Dumont.

   This file is part of Config-Model-Approx.

   Config-Model-Approx is free software; you can redistribute it and/or
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

L<config-edit-approx>, L<Config::Model>,
