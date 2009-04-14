# $Author$
# $Date$
# $Revision$

#    Copyright (c) 2009 Dominique Dumont.
#
#    This file is part of Config-Model-Approx.
#
#    Config-Approx is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Approx is distributed in the hope that it will be useful,
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

use vars qw($VERSION)  ;

$VERSION = '1.001' ;

my $logger = Log::Log4perl::get_logger(__PACKAGE__);

sub read {
    # keys are object , root,  config_dir, io_handle, file
    my %args = @_ ;

    $logger->info("loading config file $args{file}");

    foreach ($args{io_handle}->getlines) {
	chomp;
	s/#.*//;
	s/\s+/=/; # translate file in string loadable by C::M::Loader
	next unless $_;
	my $load = s/^\$// ? $_ : "distributions:".$_;
	$args{object}->load($load) ;
    }

    return 1;
}

sub write {
    my %args = @_ ;

    $logger->info("writing config file $args{file}");
    my $node = $args{object} ;
    my $ioh  = $args{io_handle} ;

    # Using Config::Model::ObjTreeScanner would be overkill
    foreach my $elt ($node->get_element_name) {
	next if $elt eq 'distributions';
	my $v = $node->grab_value($elt) ;
	$ioh->printf("\$%-10s %s\n",$elt,$v) if defined $v ;
    }

    my $h = $node->fetch_element('distributions') ;
    foreach my $dname ($h->get_all_indexes) {
	$ioh->printf("%-10s %s\n",$dname,
		     $node->grab_value("distributions:$dname")
		    ) ;
    }
    return 1;

}
