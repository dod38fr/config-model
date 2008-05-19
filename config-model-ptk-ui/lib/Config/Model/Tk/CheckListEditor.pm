# $Author$
# $Date$
# $Name: not supported by cvs2svn $
# $Revision$

#    Copyright (c) 2008 Dominique Dumont.
#
#    This file is part of Config-Model-TkUI.
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

package Config::Model::Tk::CheckListEditor ;

use strict;
use warnings ;
use Carp ;

use base qw/ Tk::Frame Config::Model::Tk::CheckListViewer/;
use vars qw/$VERSION/ ;
use subs qw/menu_struct/ ;

$VERSION = sprintf "1.%04d", q$Revision$ =~ /(\d+)/;

Construct Tk::Widget 'ConfigModelCheckListEditor';

my @fbe1 = qw/-fill both -expand 1/ ;

sub ClassInit {
    my ($cw, $args) = @_;
    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.

    # cw->Advertise(name=>$widget);
}

sub Populate { 
    my ($cw, $args) = @_;
    my $leaf = $cw->{leaf} = delete $args->{-item} 
      || die "CheckListEditor: no -item, got ",keys %$args;
    delete $args->{-path} ;

    my $inst = $leaf->instance ;

    $cw->add_header(Edit => $leaf) ;

    my $ed_frame = $cw->Frame->pack(@fbe1);

    my %h = $leaf->get_checked_list_as_hash ;
    my $lb = $ed_frame->Scrolled ( qw/Listbox -selectmode multiple/,
				   -scrollbars => 'osoe',
				   -height => 10,
				 ) ->pack(@fbe1) ;
    my @choice = $leaf->get_choice ;
    $lb->insert('end',@choice) ;

    my $array_ref;
    # warning: array_ref is not a "mirror" if listbox content
    tie $array_ref, "Tk::Listbox", $lb ;
    # set all element in list box
    $array_ref = $leaf->get_checked_list ; 
    $cw->{tied} = \$array_ref ;

    # mastering perl/Tk page 160
    my $b_sub = sub { $cw->set_value_help(@$array_ref);} ;
    $lb->bind('<<ListboxSelect>>',$b_sub);

    my $bframe = $cw->Frame->pack;
    $bframe -> Button ( -text => 'Clear all',
			-command => sub { $lb->selectionClear(0,'end') ; },
		      ) -> pack(-side => 'left') ;
    $bframe -> Button ( -text => 'Set all',
			-command => sub { $lb->selectionSet(0,'end') ; },
		      ) -> pack(-side => 'left') ;
    $bframe -> Button ( -text => 'Reset',
			-command => sub { $cw->reset_value ; },
		      ) -> pack(-side => 'left') ;
    $bframe -> Button ( -text => 'Store',
			-command => sub { $cw->store ( @$array_ref )},
		      ) -> pack(-side => 'left') ;

    $cw->add_help_frame() ;
    $cw->add_help(class   => $leaf->parent->get_help) ;
    $cw->add_help(element => $leaf->parent->get_help($leaf->element_name)) ;
    $cw->{value_help_widget} = $cw->add_help(value => '',1);
    $b_sub->() ;

    # don't call directly SUPER::Populate as it's CheckListViewer's populate
    $cw->Tk::Frame::Populate($args) ;
}


sub store {
    my $cw = shift ;
    my @set = @_ ;

    eval {$cw->{leaf}->set_checked_list(@set); } ;

    if ($@) {
	$cw -> Dialog ( -title => 'Value error',
			-text  => $@,
		      )
            -> Show ;
	$cw->reset_value ;
    }
    else {
	# trigger redraw of Tk Tree
	$cw->parent->parent->parent->parent->reload(1) ;
    }
}

sub reset_value {
    my $cw = shift ;

    my $h_ref = $cw->{leaf}->get_checked_list_as_hash ;

    # reset also the content of the listbox
    # weird behavior of tied Listbox :-/
    ${$cw->{tied}} = $cw->{leaf}->get_checked_list ;

    # the CheckButtons have stored the reference of the hash *values*
    # so we must preserve them.
    map { $cw->{check_list}{$_} = $h_ref->{$_}} keys %$h_ref ;
    $cw->{help} = '' ;
}

1;
