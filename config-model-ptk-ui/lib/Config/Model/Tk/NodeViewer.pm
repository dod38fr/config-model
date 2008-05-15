# $Author$
# $Date$
# $Revision$

#    Copyright (c) 2008 Dominique Dumont.
#
#    This file is part of Config-Model-TkUi.
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

package Config::Model::Tk::NodeViewer ;

use strict;
use warnings ;
use Carp ;

use base qw/Tk::Frame Config::Model::Tk::AnyViewer/;
use vars qw/$VERSION/ ;
use subs qw/menu_struct/ ;

$VERSION = sprintf "1.%04d", q$Revision$ =~ /(\d+)/;

Construct Tk::Widget 'ConfigModelNodeViewer';

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill x    -expand 1/ ;

sub ClassInit {
    my ($cw, $args) = @_;
    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.

    # cw->Advertise(name=>$widget);
}

sub Populate { 
    my ($cw, $args) = @_;
    my $node = $cw->{node} = delete $args->{-item} 
      || die "NodeViewer: no -item, got ",keys %$args;
    delete $args->{-path} ;

    $cw->add_header(View => $node) ;

    my $inst = $node->instance ;

    my $elt_frame = $cw->Frame(qw/-relief raised -borderwidth 4/)->pack(@fxe1) ;

    $elt_frame -> Label(-text => $node->composite_name.' node elements') -> pack() ;

    my $rt = $elt_frame ->Scrolled ( 'ROText',
				     -height => 10,
				   ) ->pack(@fbe1) ;

    my $exp = $cw->parent->parent->parent->parent->get_experience ;

    foreach my $c ($node->get_element_name(for => $exp)) {
	$rt->insert('end', $c."\n" ) ;
    }

    $cw->add_info($cw) ;
    my $parent = $node->parent ;

    $cw->add_help_frame() ;
    if (defined $parent) {
	$cw->add_help(class   => $parent->get_help) ;
	$cw->add_help(element => $parent->get_help($node->element_name)) ;
    }
    else {
	$cw->add_help(class   => $node->get_help) ;
    }
    $cw->SUPER::Populate($args) ;
}


sub add_info {
    my $cw = shift ;
    my $info_frame = shift ;

    my $node = $cw->{node} ;

    my @items = ('type : '. $node->get_type ,
		 'class name : '.$node->config_class_name ,
		);

    $cw->add_info_frame(@items) ;
}


1;
