# $Author$
# $Date$
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

package Config::Model::Tk::ListEditor ;

use strict;
use warnings ;
use Carp ;
use Log::Log4perl ;

use base qw/Config::Model::Tk::ListViewer/;
use vars qw/$VERSION/ ;
use subs qw/menu_struct/ ;
use Tk::Dialog ;

$VERSION = sprintf "1.%04d", q$Revision$ =~ /(\d+)/;

Construct Tk::Widget 'ConfigModelListEditor';

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill x    -expand 1/ ;
my $logger = Log::Log4perl::get_logger(__PACKAGE__);

sub ClassInit {
    my ($cw, $args) = @_;
    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.

    # cw->Advertise(name=>$widget);
}

sub Populate { 
    my ($cw, $args) = @_;
    my $list = $cw->{list} = delete $args->{-item} 
      || die "ListEditor: no -item, got ",keys %$args;
    delete $args->{-path} ;

    $cw->add_header(Edit => $list) ;

    my $inst = $list->instance ;
    $inst->push_no_value_check('fetch') ;

    my $elt_button_frame = $cw->Frame->pack(@fbe1) ;

    my $elt_frame = $elt_button_frame->Frame(qw/-relief raised -borderwidth 4/)
                                     ->pack(@fxe1,-side => 'left') ;
    $elt_frame -> Label(-text => $list->element_name.' elements') -> pack() ;

    my $tklist = $elt_frame ->Scrolled ( 'Listbox',
					 -selectmode => 'single',
					 -height => 8,
				       )
                            -> pack(@fbe1, -side => 'left') ;
    $tklist->insert( end => $list->get_all_indexes) ;

    my $right_frame = $elt_button_frame->Frame->pack(@fxe1, -side => 'left');

    $cw->add_info($cw) ;
    $cw->add_help_frame() ;
    $cw->add_help(class   => $list->parent->get_help) ;
    $cw->add_help(element => $list->parent->get_help($list->element_name)) ;

    my $add_item = '';
    my $add_frame = $right_frame->Frame->pack( @fxe1);

    my $add_str = $list->ordered ? "after selection " : '' ;
    $add_frame -> Button(-text => "Add item $add_str:",
			 -command => sub {$cw->add_entry($add_item);},
			 -anchor => 'e',
			)->pack(-side => 'left', @fxe1);
    $add_frame -> Entry (-textvariable => \$add_item, -width => 10)
               -> pack  (-side => 'left') ;

    my $cp_frame = $right_frame->Frame->pack( @fxe1);
    my $cp_item = '';
    $cp_frame -> Button(-text => 'Copy selected item into:',
			-command => sub {$cw->copy_selected_in($cp_item);},
			-anchor => 'e',
		       )
              -> pack(-side => 'left', @fxe1);
    $cp_frame -> Entry (-textvariable => \$cp_item, -width => 10)
              -> pack  (-side => 'left') ;


    my $mv_frame = $right_frame->Frame->pack( @fxe1);
    my $mv_item = '';
    $mv_frame -> Button(-text => 'Move selected item into:',
			-command => sub {$cw->move_selected_to($mv_item);},
		      	-anchor => 'e',
		       )
              -> pack(-side => 'left', @fxe1);
    $mv_frame -> Entry (-textvariable => \$mv_item, -width => 10)
              -> pack  (-side => 'left') ;

    $right_frame->Button(-text => 'Delete selected',
			 -command => sub { $cw->delete_selection ;} ,
			)-> pack( @fxe1);

    $right_frame -> Button ( -text => 'Remove all elements',
			     -command => sub { $list->clear ; 
					       $tklist->delete(0,'end');
					       $cw->reload_tree;
					   },
			   ) -> pack(-side => 'left', @fxe1) ;

    $cw->{tklist} = $tklist ;
    $cw->Tk::Frame::Populate($args) ;
}

sub add_entry {
    my $cw = shift;
    my $add = shift;
    my $tklist = $cw->{tklist} ;
    my $list = $cw->{list};

    $logger->debug("add_entry: $add");

    if ($list->exists($add)) {
	$cw->Dialog(-title => "Add item error",
		    -text  => "Entry $add already exists",
		   )
           ->Show() ;
	return 0;
    }

    # add entry in list
    eval {$list->fetch_with_id($add)} ;

    if ($@) {
	$cw -> Dialog ( -title => 'List index error',
			-text  => $@,
		      )
	  -> Show ;
    }
    else {
	# trigger redraw of Tk Tree
	$cw->reload_tree;
    }

    $logger->debug( "new list idx: ". join(',',$list->get_all_indexes));

    # ensure correct order for ordered hash
    my @selected = $tklist->curselection() ;
    if (@selected and $list->ordered) {
	my $idx = $tklist->get($selected[0]);
	$list->swap($idx, $add) ;
    }

    # add entry in tklist
    if ($list->ordered) {
	$tklist->insert($selected[0]+1 || 0,$add) ;
    }
    else {
	my $idx = 0;
	foreach ($tklist->get(0,'end')) {
	    if ($add lt $_) {
		$tklist->insert($idx,$add);
		last;
	    }
	    $idx ++ ;
	}
	$tklist->insert($idx,$add) if $idx == 0; # first entry
    }
    return 1 ;
}

sub copy_selected_in {
    my $cw =shift;
    my $to_name = shift ;
    my $tklist = $cw->{tklist} ;
    my $from_idx = $tklist->curselection() ;
    my $from_name = $tklist->get($from_idx);
    my $list = $cw->{list};
    $cw->add_entry($to_name) or return ;
    $list->copy($from_name,$to_name) ;
    $cw->reload_tree ;
}

sub move_selected_to {
    my $cw =shift;
    my $to_name = shift ;
    my $tklist = $cw->{tklist} ;
    my $from_idx = $tklist->curselection() ;
    my $from_name = $tklist->get($from_idx);
    $logger->debug( "move_selected_to: from $from_name to $to_name" );
    my $list = $cw->{list};
    $tklist -> delete($from_idx) ;
    $cw->add_entry($to_name) or return ;
    $list->move($from_name,$to_name) ;
    $cw->reload_tree ;
}

sub delete_selection {
    my $cw = shift ;
    my $tklist = $cw->{tklist} ;
    my $list = $cw->{list};

    foreach ($tklist->curselection()) {
	my $idx = $tklist->get($_) ;
	$list   -> delete($idx) ;
	$tklist -> delete($_) ;
	$cw->reload_tree ;
    }
}

sub store {
    my $cw = shift ;

    eval {$cw->{list}->set_checked_list_as_list(%{$cw->{check_list}}); } ;

    if ($@) {
	$cw -> Dialog ( -title => 'Value error',
			-text  => $@,
		      )
            -> Show ;
	$cw->reset_value ;
    }
    else {
	# trigger redraw of Tk Tree
	$cw->reload_tree ;
    }
}

sub reload_tree {
    my $cw = shift ;
    $cw->parent->parent->parent->parent->reload(1) ;
}


1;
