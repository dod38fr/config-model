# $Author: ddumont $
# $Date: 2008-02-08 17:19:45 $
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

package Config::Model::Tk::AnyViewer ;

use strict;
use warnings ;
use Carp ;

use vars qw/$VERSION/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill x    -expand 1/ ;

sub add_header {
    my ($cw,$type) = @_ ;

    my $leaf = $cw->{leaf} ;
    my $idx = $leaf->index_value ;
    my $elt_name = $leaf->element_name ;
    $elt_name .= ':' . $idx if defined $idx ;
    my $class = $leaf->parent->config_class_name ;
    $cw -> Label ( -text => "$type: Class $class Element $elt_name",
			    -anchor => 'w' )
              -> pack (@fxe1);
}

sub add_info_frame {
    my $cw = shift;
    my @items = @_;

    my $frame = $cw->Frame(qw/-relief raised -borderwidth 4/)->pack(@fxe1) ;
    $frame -> Label(-text => 'Info', -anchor => 'w' ) ->pack() ;

    my $i_frame = $frame->Frame(qw/-relief sunken -borderwidth 1/)->pack(@fxe1) ;
    map { $i_frame -> Label(-text => $_, -anchor => 'w' ) ->pack(@fxe1) } @items;
}


sub add_help_frame {
    my $cw = shift ;
    my $leaf = $cw->{leaf} ;

    my $htop_frame = $cw->Frame(qw/-relief raised -borderwidth 4/)->pack(@fxe1) ;
    $htop_frame -> Label(-text => 'Help', -anchor => 'w' ) ->pack() ;

    $cw->{help_f} = $htop_frame->Frame(qw/-relief sunken -borderwidth 1/)->pack(@fxe1) ;
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
