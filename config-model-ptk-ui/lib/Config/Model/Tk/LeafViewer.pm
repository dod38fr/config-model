# $Author: ddumont $
# $Date: 2008-02-06 09:20:42 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

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

package Config::Model::Tk::LeafViewer ;

use strict;
use warnings ;
use Carp ;

use base qw/ Tk::Frame /;
use vars qw/$VERSION/ ;
use subs qw/menu_struct/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

Construct Tk::Widget 'ConfigModelLeafViewer';

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
    my $leaf = $cw->{leaf} = delete $args->{-item} 
      || die "LeafViewer: no -item, got ",keys %$args;

    my $inst = $leaf->instance ;
    $inst->push_no_value_check('fetch') ;

    my $vt = $leaf -> value_type ;
    print "leaf viewer for value_type $vt\n";
    my $v = $leaf->fetch ;

    my $idx = $leaf->index_value ;
    my $elt_name = $leaf->element_name ;
    $elt_name .= ':' . $idx if defined $idx ;
    my $class = $leaf->parent->config_class_name ;
    $cw -> Label ( -text => "View: Class $class Element $elt_name",
			    -anchor => 'w' )
              -> pack (@fxe1);

    my $lv_frame = $cw->Frame(qw/-relief raised -borderwidth 4/)->pack(@fxe1) ;
    $lv_frame -> Label(-text => 'Value') -> pack() ;
    
    if ($vt eq 'string') {
	require Tk::ROText ;
	$cw->{e_widget} = $lv_frame->ROText(-height => 10 )
                                  ->pack(@fxe1);
	$cw->{e_widget}->insert('end',$v) ;
    }
    else {
	my $v_frame = $lv_frame->Frame(qw/-relief sunken -borderwidth 1/)
	  ->pack(@fxe1) ;
	$v_frame -> Label(-text => $v, -anchor => 'w')
	    -> pack(@fxe1, -side => 'left');
    }

    $cw->add_info() ;

    my $htop_frame = $cw->Frame(qw/-relief raised -borderwidth 4/)->pack(@fxe1) ;
    $htop_frame -> Label(-text => 'Help', -anchor => 'w' ) ->pack() ;

    $cw->{help_f} = $htop_frame->Frame(qw/-relief sunken -borderwidth 1/)->pack(@fxe1) ;


    $cw->add_help(class   => $leaf->parent->get_help) ;
    $cw->add_help(element => $leaf->parent->get_help($leaf->element_name)) ;
    $cw->add_help(value   => $leaf->get_help($cw->{value})) ;


    $cw->ConfigSpecs(
		     #-fill   => [ qw/SELF fill Fill both/],
		     #-expand => [ qw/SELF expand Expand 1/],
		     -relief => [qw/SELF relief Relief groove/ ],
		     -borderwidth => [qw/SELF borderwidth Borderwidth 2/] ,
		     DEFAULT => [ qw/SELF/ ],
           );

    $cw->SUPER::Populate($args) ;
}

sub add_info {
    my $cw = shift ;

    my $leaf = $cw->{leaf} ;

    my @items = (
		 'type : '.$leaf->value_type,
		);

    if (defined $leaf->built_in) {
	push @items, "built_in value: " . $leaf->built_in ;
    }
    elsif (defined $leaf->fetch('standard')) {
	push @items, "default value: " . $leaf->fetch('standard') ;
    }
    elsif (defined $leaf->refer_to) {
	push @items, "reference to: " . $leaf->refer_to ;
    }
    elsif (defined $leaf->computed_refer_to) {
	push @items, "computed reference to: " . $leaf->computed_refer_to ;
    }


    my $m = $leaf->mandatory ;
    push @items, "is mandatory: ".($m ? 'yes':'no') if defined $m;

    foreach my $what (qw/min max/) {
	my $v = $leaf->$what() ;
	push @items, "$what value: $v" if defined $v;
    }


    my $frame = $cw->Frame(qw/-relief raised -borderwidth 4/)->pack(@fxe1) ;
    $frame -> Label(-text => 'Info', -anchor => 'w' ) ->pack() ;

    my $i_frame = $frame->Frame(qw/-relief sunken -borderwidth 1/)->pack(@fxe1) ;
    map { $i_frame -> Label(-text => $_, -anchor => 'w' ) ->pack(@fxe1) } @items;
}

sub add_help {
    my $cw = shift ;
    my $type = shift ;
    my $help = shift ;

    my $help_frame = $cw->{help_f}->Frame()->pack(@fxe1);

    my $leaf = $cw->{leaf} ;
    $help_frame->Label(-text => "on $type: ")->pack(-side => 'left');
    my @text = ref $help ? ( -textvariable => $help)
             :             ( -text => $help ) ;
    $help_frame->Label( @text,
		       -justify => 'left',
		       -anchor => 'w')
      ->pack( -fill => 'x');
}


1;
