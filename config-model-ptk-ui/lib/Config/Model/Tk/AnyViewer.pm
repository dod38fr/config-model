# $Author: ddumont $
# $Date: 2008-02-12 17:23:35 $
# $Name: not supported by cvs2svn $
# $Revision: 1.3 $

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

use Tk::Photo ;

use vars qw/$VERSION/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill x    -expand 1/ ;

my %img ;

sub add_header {
    my ($cw,$type,$item) = @_ ;

    unless (%img) {
	$img{edit} = $cw->Photo(-file => 'edit-find-replace.gif');
	$img{view} = $cw->Photo(-file => 'system-search.gif');
    }

    my $idx ;
    $idx = $item->index_value if $item->can('index_value' ) ;
    my $elt_name = $item->composite_name ;
    my $class = $item->parent->config_class_name ;
    my $f = $cw -> Frame -> pack (@fxe1);
    $f -> Label ( -text => "$type: Class $class - Element $elt_name",
			    -anchor => 'w' )
              -> pack (-side => 'left', @fxe1);

    $f -> Label (-image => $img{lc($type)} , -anchor => 'e') 
      -> pack (-side => 'left');
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

    my $htop_frame = $cw->Frame(qw/-relief raised -borderwidth 4/)->pack(@fxe1) ;
    $htop_frame -> Label(-text => 'Help', -anchor => 'w' ) ->pack() ;

    $cw->{help_f} = $htop_frame->Frame(qw/-relief sunken -borderwidth 1/)->pack(@fxe1) ;
}

sub add_help {
    my $cw = shift ;
    my $type = shift ;
    my $help = shift ;

    my $help_frame = $cw->{help_f}->Frame()->pack(@fxe1);

    $help_frame->Label(-text => "on $type: ")->pack(-side => 'left');
    my @text = ref $help ? ( -textvariable => $help)
             :             ( -text => $help ) ;
    $help_frame->Label( @text,
		       -justify => 'left',
		       -anchor => 'w')
      ->pack( -fill => 'x');
}


1;
