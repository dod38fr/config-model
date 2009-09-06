# $Author$
# $Date$
# $Revision$

#    Copyright (c) 2008-2009 Dominique Dumont.
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
    my $path = delete $args->{-path} ;

    $cw->add_header(View => $node) ;

    my $inst = $node->instance ;

    my $elt_frame = $cw->Frame(qw/-relief flat/)->pack(@fbe1) ;

    $elt_frame -> Label(-text => $node->composite_name.' node elements') -> pack() ;

    my $hl = $elt_frame ->Scrolled ( 'HList',
				     -scrollbars => 'osow',
				     -columns => 3, 
				     -header => 1,
				     -height => 8,
				   ) -> pack(@fbe1) ;
    $hl->headerCreate(0, -text => 'name') ;
    $hl->headerCreate(1, -text => 'type') ;
    $hl->headerCreate(2, -text => 'value') ;
    $cw->{hlist}=$hl ;
    $cw->reload ;

    # add adjuster. Buggy behavior on destroy...
    #require Tk::Adjuster;
    #$cw->{adjust} = $cw -> Adjuster();
    #$cw->{adjust}->packAfter($hl, -side => 'top') ;

    $cw->add_info($cw) ;

    if ($node->parent) {
	$cw->add_summary_and_description($node) ;
    }
    else {
	$cw->add_help(class   => $node->get_help) ;
    }

    $cw->add_editor_button($path) ;

    $cw->SUPER::Populate($args) ;
}

#sub DESTROY {
#    my $cw = shift ;
#    $cw->{adjust}->packForget(1);
#}

sub reload {
    my $cw = shift ;

    my $exp = $cw->parent->parent->parent->parent->get_experience ;
    my $node = $cw->{node};
    my $hl=$cw->{hlist} ;

    my %old_elt = %{$cw->{elt_path}|| {} } ;

    foreach my $c ($node->get_element_name(for => $exp)) {
	next if delete $old_elt{$c} ;

	$hl->add($c) ;
	$cw->{elt_path}{$c} = 1 ;

	$hl->itemCreate($c,0, -text => $c) ;
	my $type = $node->element_type($c) ;
	$hl->itemCreate($c,1, -text => $type) ;

	if ($type eq 'leaf') {
	    my $v = eval {$node->fetch_element_value($c)} ;
	    if ($@) {
		$hl->itemCreate($c,2, 
				-itemtype => 'image' , 
				-image => $Config::Model::TkUI::warn_img) ;
	    }
	    elsif (defined $v) {
		substr ($v,15) = '...' if length($v) > 15;
		$hl->itemCreate($c,2, -text => $v) ;
	    }
	}
    }

    # destroy leftover widgets (may occur with warp mechanism)
    map {$hl->delete(entry => $_); } keys %old_elt ;
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
