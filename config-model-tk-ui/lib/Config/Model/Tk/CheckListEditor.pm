
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
our $VERSION="1.305";
use warnings ;
use Carp ;

use base qw/ Tk::Frame Config::Model::Tk::CheckListViewer/;
use vars qw/$icon_path/ ;
use subs qw/menu_struct/ ;

use Tk::NoteBook;


Construct Tk::Widget 'ConfigModelCheckListEditor';

my $up_img;
my $down_img;

*icon_path = *Config::Model::TkUI::icon_path;

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill    x -expand 1/ ;

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
    $cw->{store_cb} = delete $args->{-store_cb} || die __PACKAGE__,"no -store_cb" ;

    my $inst = $leaf->instance ;

    $cw->add_header(Edit => $leaf) ;

    my $nb = $cw->Component('NoteBook','notebook')->pack(@fbe1);

    my $lb ;
    my @choice = $leaf->get_choice ;
    my $raise_cmd = sub{ 
	$lb->selectionClear(0,'end') ;
	my %h = $leaf->get_checked_list_as_hash ;
	for (my $i=0; $i<@choice; $i++) {
	    $lb->selectionSet($i,$i) if $h{$choice[$i]} ;
	}
    } ;

    my $ed_frame = $nb->add('content', -label => 'Change content',
			    -raisecmd => $raise_cmd ,
			   );

    $lb = $ed_frame->Scrolled ( qw/Listbox -selectmode multiple/,
				   -scrollbars => 'osoe',
				   -height => 10,
				 ) ->pack(@fbe1) ;
    $lb->insert('end',@choice) ;


    my $get_selected = sub { return map { $choice[$_]} $lb->curselection ;};

    # mastering perl/Tk page 160
    my $b_sub = sub { $cw->set_value_help(&$get_selected);} ;
    $lb->bind('<<ListboxSelect>>',$b_sub);

    my $bframe = $ed_frame->Frame->pack;
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
			-command => sub { $cw->store ( &$get_selected )},
		      ) -> pack(-side => 'left') ;

    $cw->add_summary_and_description($leaf) ;
    $cw->{value_help_widget} = $cw->add_help(value => '',1);
    $b_sub->() ;

    # Add a second page to edit the list order for ordered check list
    if ($leaf->ordered) {
	$cw->add_change_order_page($nb,$leaf) ;
    }

    # don't call directly SUPER::Populate as it's CheckListViewer's populate
    $cw->Tk::Frame::Populate($args) ;
}

sub add_change_order_page {
    my ($cw,$nb,$leaf) = @_ ;

    my $order_list ;
    my $raise_cmd = sub{ 
	$order_list->delete(0,'end');
	$order_list->insert( end => $leaf->get_checked_list) ;
    } ;

    my $order_frame = $nb->add('order', -label => 'Change order',
			       -raisecmd => $raise_cmd ,
			      );

    $order_list = $order_frame ->Scrolled ( 'Listbox',
					       -selectmode => 'single',
					       -scrollbars => 'oe',
					       -height => 6,
					     )
      -> pack(@fbe1) ;

    $cw->{order_list} = $order_list ;

    unless (defined $up_img) {
	$up_img   = $cw->Photo(-file => $icon_path.'up.png');
	$down_img = $cw->Photo(-file => $icon_path.'down.png');
    }

    my $mv_up_down_frame = $order_frame->Frame->pack( -fill => 'x');
    $mv_up_down_frame->Button(-image => $up_img,
			      -command => sub { $cw->move_selected_up ;} ,
			     )-> pack( -side => 'left', @fxe1);

    $mv_up_down_frame->Button(-image => $down_img,
			      -command => sub { $cw->move_selected_down ;} ,
			     )-> pack( -side => 'left',  @fxe1);
}

sub move_selected_up {
    my $cw =shift;
    my $order_list = $cw->{order_list} ;
    my @idx = $order_list->curselection() ;

    return unless @idx and $idx[0] > 0;

    my $name = $order_list->get(@idx);

    $order_list -> delete(@idx) ;
    my $new_idx = $idx[0] - 1 ;
    $order_list -> insert($new_idx, $name) ;
    $order_list -> selectionSet($new_idx) ;
    $order_list -> see($new_idx) ;

    $cw->{leaf}->move_up($name) ;

    $cw->reload_tree ;
}

sub move_selected_down {
    my $cw =shift;
    my $order_list = $cw->{order_list} ;
    my @idx = $order_list->curselection() ;
    my $leaf = $cw->{leaf};
    my @h_idx =  $leaf->get_checked_list ;

    return unless @idx and $idx[0] < $#h_idx;

    my $name = $order_list->get(@idx);

    $order_list -> delete(@idx) ;
    my $new_idx = $idx[0] + 1 ;
    $order_list -> insert($new_idx, $name) ;
    $order_list -> selectionSet($new_idx) ;
    $order_list -> see($new_idx) ;

    $cw->{leaf}->move_down($name) ;

    $cw->reload_tree ;
}


sub store {
    my $cw = shift ;

    my %set = map { $_ => 1 ; } @_ ;
    my $cl = $cw->{leaf};

    map {
	if ($set{$_} and not $cl->is_checked($_) ) {
	    $cl->check($_) ;
	} 
	elsif (not $set{$_} and $cl->is_checked($_) ) {
	    $cl->uncheck($_) ;
	}
    } $cw->{leaf}->get_choice;

    $cw->{store_cb}->() ;
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


sub reload_tree {
    my $cw = shift ;
    $cw->parent->parent->parent->parent->reload(1) ;
}

1;
