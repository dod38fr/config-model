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

package Config::Model::Tk::HashEditor ;

use strict;
use warnings ;
use Carp ;
use Log::Log4perl ;

use base qw/Config::Model::Tk::HashViewer/;
use vars qw/$VERSION $icon_path/ ;
use subs qw/menu_struct/ ;
use Tk::Dialog ;
use Tk::Photo ;

$VERSION = sprintf "1.%04d", q$Revision$ =~ /(\d+)/;

Construct Tk::Widget 'ConfigModelHashEditor';

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill x    -expand 1/ ;
my @fx   = qw/-fill x    / ;
my $logger = Log::Log4perl::get_logger(__PACKAGE__);

my $entry_width = 20 ;

my $up_img;
my $down_img;

*icon_path = *Config::Model::TkUI::icon_path;

sub ClassInit {
    my ($cw, $args) = @_;
    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.

    # cw->Advertise(name=>$widget);
}

sub Populate { 
    my ($cw, $args) = @_;
    my $hash = $cw->{hash} = delete $args->{-item} 
      || die "HashEditor: no -item, got ",keys %$args;
    delete $args->{-path} ;

    unless (defined $up_img) {
	$up_img   = $cw->Photo(-file => $icon_path.'up.png');
	$down_img = $cw->Photo(-file => $icon_path.'down.png');
    }

    $cw->add_header(Edit => $hash) ;

    my $inst = $hash->instance ;

    my $elt_button_frame = $cw->Frame->pack(@fbe1) ;

    my $elt_frame = $elt_button_frame->Frame(qw/-relief raised -borderwidth 2/)
                                     ->pack(@fbe1,-side => 'left') ;
    $elt_frame -> Label(-text => $hash->element_name.' elements') -> pack() ;

    my $tklist = $elt_frame ->Scrolled ( 'Listbox',
					 -selectmode => 'single',
					 -scrollbars => 'oe',
					 -height => 6,
				       )
                            -> pack(@fbe1, -side => 'left') ;

    $tklist->insert( end => $hash->get_all_indexes) ;

    my $right_frame = $elt_button_frame->Frame->pack(@fxe1, -side => 'left');

    $cw->add_info($cw) ;
    $cw->add_summary_and_description($hash) ;

    my $add_item = '';
    my $add_frame = $right_frame->Frame->pack( @fxe1);

    my $add_str = $hash->ordered ? "after selection " : '' ;
    $add_frame -> Button(-text => "Add item $add_str:",
			 -command => sub {$cw->add_entry($add_item);},
			 -anchor => 'e',
			)->pack(-side => 'left', @fx);
    $add_frame -> Entry (-textvariable => \$add_item, -width => $entry_width)
               -> pack  (-side => 'left') ;

    my $cp_frame = $right_frame->Frame->pack( @fxe1);
    my $cp_item = '';
    $cp_frame -> Button(-text => 'Copy selected item into:',
			-command => sub {$cw->copy_selected_in($cp_item);},
			-anchor => 'e',
		       )
              -> pack(-side => 'left', @fx);
    $cp_frame -> Entry (-textvariable => \$cp_item, -width => $entry_width)
              -> pack  (-side => 'left') ;


    my $mv_frame = $right_frame->Frame->pack( @fxe1);
    my $mv_item = '';
    $mv_frame -> Button(-text => 'Move selected item into:',
			-command => sub {$cw->move_selected_to($mv_item);},
		      	-anchor => 'e',
		       )
              -> pack(-side => 'left', @fxe1);
    $mv_frame -> Entry (-textvariable => \$mv_item, -width => $entry_width)
              -> pack  (-side => 'left') ;

    if ($hash->ordered) {
	my $mv_up_down_frame = $right_frame->Frame->pack( @fxe1);
	$mv_up_down_frame->Button(-image => $up_img,
				  -command => sub { $cw->move_selected_up ;} ,
				 )-> pack( -side =>'left' , @fxe1);

	$mv_up_down_frame->Button(-image => $down_img,
				  -command => sub { $cw->move_selected_down ;} ,
				 )-> pack( -side =>'left' , @fxe1);
    }

    my $del_rm_frame =  $right_frame->Frame->pack( @fxe1);

    $del_rm_frame->Button(-text => 'Delete selected',
			  -command => sub { $cw->delete_selection ;} ,
			 )-> pack( -side =>'left' , @fxe1);

    $del_rm_frame -> Button ( -text => 'Remove all elements',
			      -command => sub { $hash->clear ; 
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
    my $hash = $cw->{hash};

    $logger->debug("add_entry: $add");

    if ($hash->exists($add)) {
	$cw->Dialog(-title => "Add item error",
		    -text  => "Entry $add already exists",
		   )
           ->Show() ;
	return 0;
    }

    # add entry in hash
    eval {$hash->fetch_with_id($add)} ;

    if ($@) {
	$cw -> Dialog ( -title => 'Hash index error',
			-text  => $@,
		      )
	  -> Show ;
	return 0 ;
    }

    $logger->debug( "new hash idx: ". join(',',$hash->get_all_indexes));


    # ensure correct order for ordered hash
    my @selected = $tklist->curselection() ;

    $tklist -> selectionClear(0,'end') ;

    if (@selected and $hash->ordered) {
	my $idx = $tklist->get($selected[0]);
	$logger->debug("add_entry on ordered hash: swap $idx and $add");
	$hash->move_after($add, $idx) ;
	$logger->debug( "new hash idx: ". join(',',$hash->get_all_indexes));
	my $new_idx = $selected[0] + 1 ;
	$tklist -> insert($new_idx,$add) ;
	$tklist -> selectionSet($new_idx) ;
	$tklist -> see($new_idx) ;
    }
    elsif ($hash->ordered) {
	# without selection on ordered hash, items are simply pushed
	$tklist -> insert('end',$add) ;
	$tklist -> selectionSet('end') ;
	$tklist -> see('end') ;
    }
    else {
	$cw->add_and_sort_item($add) ;
    }

    # trigger redraw of Tk Tree
    $cw->reload_tree;
    return 1 ;
}

sub add_and_sort_item {
    my $cw  = shift;
    my $add = shift ;

    my $tklist = $cw->{tklist} ;
    my $idx = 0;
    my $added = 0 ;

    $tklist -> selectionClear(0,'end') ;
    foreach ($tklist->get(0,'end')) {
	if ($add lt $_) {
	    $tklist -> insert($idx,$add);
	    $tklist -> selectionSet($idx) ;
	    $tklist -> see($idx) ;
	    $added = 1 ;
	    last;
	}
	$idx ++ ;
    }

    if (not $added) {
	$tklist -> insert('end',$add); # last entry
	$tklist -> selectionSet('end') ;
	$tklist -> see('end') ;
    }
}

sub add_item {
    my $cw  = shift;
    my $add = shift ;

    my $hash = $cw->{hash};
    my $tklist = $cw->{tklist} ;

    # add entry in tklist
    if ($hash->ordered) {
	$tklist -> selectionClear(0,'end') ;
	$tklist -> insert('end',$add) ;
	$tklist -> selectionSet('end') ;
	$tklist -> see('end') ;    }
    else {
	# add the item so that items are ordered alphabetically
	$cw->add_and_sort_item($add) ;
    }
}

sub get_selection {
    my $cw =shift;
    my $what = shift ;
    my $tklist = $cw->{tklist} ;
    my @from_idx = $tklist->curselection() ;
    if (not @from_idx) {
	$cw->Dialog(-title => "$what selection error",
		    -text  => " Please select an item to $what",
		   )
           ->Show() ;
    }
    return @from_idx ;
}

sub copy_selected_in {
    my $cw =shift;
    my $to_name = shift ;
    my $tklist = $cw->{tklist} ;
    my @from_idx = $cw->get_selection('copy') or return 0 ;
    my $from_name = $tklist->get(@from_idx);

    if ($from_name eq $to_name) {
	$cw->Dialog(-title => "copy item error",
		    -text  => "Cannot copy in the same item ($to_name)",
		   )
           ->Show() ;
	return 0;
    }

    my $hash = $cw->{hash};
    $logger->debug( "copy_selected_to: from $from_name to $to_name" );

    my $new_idx = $hash->exists($to_name) ? 0 : 1 ;
    $hash->copy($from_name,$to_name) ;

    if ($new_idx) {
	$cw->add_item($to_name) ;
    }

    $cw->reload_tree ;
}

sub move_selected_to {
    my $cw =shift;
    my $to_name = shift ;
    my $tklist = $cw->{tklist} ;
    my @from_idx = $cw->get_selection('move') or return 0 ;
    my $from_name = $tklist->get(@from_idx);

    if ($from_name eq $to_name) {
	$cw->Dialog(-title => "move item error",
		    -text  => "Cannot move in the same item ($to_name)",
		   )
           ->Show() ;
	return 0;
    }

    $logger->debug( "move_selected_to: from $from_name to $to_name" );
    my $hash = $cw->{hash};
    $tklist -> delete(@from_idx) ;

    my $new_idx = $hash->exists($to_name) ? 0 : 1 ;
    $hash->move($from_name,$to_name) ;

    if ($new_idx) {
	if ($hash->ordered) {
	    $tklist -> selectionClear(0,'end') ;
	    $tklist -> insert($from_idx[0],$to_name) ;
	    $tklist -> selectionSet($from_idx[0]) ;
	}
	else {
	    # add the item so that items are ordered alphabetically
	    $cw->add_and_sort_item($to_name) ;
	}
    }

    $cw->reload_tree ;
}

sub move_selected_up {
    my $cw =shift;
    my $tklist = $cw->{tklist} ;
    my @idx = $tklist->curselection() ;

    return unless @idx and $idx[0] > 0;

    my $name = $tklist->get(@idx);

    $logger->debug( "move_selected_up: $name (@idx)" );
    $tklist -> delete(@idx) ;
    my $new_idx = $idx[0] - 1 ;
    $tklist -> insert($new_idx, $name) ;
    $tklist -> selectionSet($new_idx) ;
    $tklist -> see($new_idx) ;

    my $hash = $cw->{hash};
    $hash->move_up($name) ;
    $logger->debug( "move_up new hash idx: ". join(',',$hash->get_all_indexes));

    $cw->reload_tree ;
}

sub move_selected_down {
    my $cw =shift;
    my $tklist = $cw->{tklist} ;
    my @idx = $tklist->curselection() ;
    my $hash = $cw->{hash};
    my @h_idx =  $hash->get_all_indexes ;

    return unless @idx and $idx[0] < $#h_idx;

    my $name = $tklist->get(@idx);

    $logger->debug( "move_selected_down: $name (@idx)" );
    $tklist -> delete(@idx) ;
    my $new_idx = $idx[0] + 1 ;
    $tklist -> insert($new_idx, $name) ;
    $tklist -> selectionSet($new_idx) ;
    $tklist -> see($new_idx) ;

    $hash->move_down($name) ;
    $logger->debug( "move_down new hash idx: ". join(',',$hash->get_all_indexes));

    $cw->reload_tree ;
}

sub delete_selection {
    my $cw = shift ;
    my $tklist = $cw->{tklist} ;
    my $hash = $cw->{hash};

    foreach ($tklist->curselection()) {
	my $idx = $tklist->get($_) ;
	$hash   -> delete($idx) ;
	$tklist -> delete($_) ;
	$cw->reload_tree ;
    }
}

sub store {
    my $cw = shift ;

    eval {$cw->{hash}->set_checked_list_as_list(%{$cw->{check_list}}); } ;

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
