
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
use subs qw/menu_struct/ ;
use Tk::Dialog ;


Construct Tk::Widget 'ConfigModelListEditor';

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill x    -expand 1/ ;
my $logger = Log::Log4perl::get_logger(__PACKAGE__);

my $entry_width = 20 ;

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
    $cw->{store_cb} = delete $args->{-store_cb} || die __PACKAGE__,"no -store_cb" ;

    $cw->add_header(Edit => $list) ;

    my $inst = $list->instance ;

    my $elt_button_frame = $cw->Frame->pack(@fbe1) ;

    my $elt_frame = $elt_button_frame->Frame(qw/-relief raised -borderwidth 2/)
                                     ->pack(@fxe1,-side => 'left') ;
    $elt_frame -> Label(-text => $list->element_name.' elements') -> pack() ;

    my $tklist = $elt_frame ->Scrolled ( 'Listbox',
					 -selectmode => 'single',
					 -scrollbars => 'oe',
					 -height => 8,
				       )
                            -> pack(@fbe1, -side => 'left') ;

    my $cargo_type = $list->cargo_type ;
    my @insert = $cargo_type eq 'leaf' ? $list->fetch_all_values 
               :                         $list->get_all_indexes ;
    map { $_ = '<undef>' unless defined $_ } @insert ;
    $tklist->insert( end => @insert ) ;

    my $right_frame = $elt_button_frame->Frame->pack(@fxe1, -side => 'left');

    $cw->add_info($cw) ;
    $cw->add_summary_and_description($list) ;

    my $value_type = $list->get_cargo_info('value_type') ; # may be undef
    if ($cargo_type eq 'leaf' and $value_type ne 'enum' and $value_type ne 'reference') {
	my $set_item = '';
	my $set_sub = sub {$cw->set_entry($set_item); $set_item = '';} ;
	my $set_frame = $right_frame->Frame->pack( @fxe1);

	$set_frame -> Button(-text => "set selected item:",
			     -command => $set_sub ,
			     -anchor => 'e',
			    )->pack(-side => 'left', @fxe1);
	$set_frame -> Entry (-textvariable => \$set_item, 
			     -width => $entry_width)
	  -> pack  (-side => 'left') ;

	my $push_item = '' ;
	my $push_sub = sub {$cw->push_entry($push_item); $push_item = '';} ;
	my $push_frame = $right_frame->Frame->pack( @fxe1);
	$push_frame -> Button(-text => "push item:",
			      -command => $push_sub ,
			      -anchor => 'e',
			     )->pack(-side => 'left', @fxe1);
	$push_frame -> Entry (-textvariable => \$push_item, 
			      -width => $entry_width)
	    -> pack  (-side => 'left') ;

	my $set_all_items = '' ;
	my $set_all_sub = sub {$cw->set_all_items($set_all_items);} ;
	my $set_all_frame = $right_frame->Frame->pack( @fxe1);
	$set_all_frame -> Button(-text => "set all:",
				 -command => $set_all_sub ,
				 -anchor => 'e',
				)->pack(-side => 'left', @fxe1);
	$set_all_frame -> Entry (-textvariable => \$set_all_items, 
				 -width => $entry_width)
	    -> pack  (-side => 'left') ;

    }
    else {
	my $disp = $cargo_type ;
	$disp .= ' ('.$list->config_class_name.')' if $cargo_type eq 'node' ;
	$disp .= " ($value_type)" if defined $value_type ;
	$right_frame->Button(-text => "Push new $disp",
			     -command => sub { $cw->push_entry('') ;} ,
			    )-> pack( @fxe1);
    }


    $right_frame->Button(-text => 'Move selected up',
			 -command => sub { $cw->move_up ;} ,
			)-> pack( @fxe1);
    $right_frame->Button(-text => 'Move selected down',
			 -command => sub { $cw->move_down ;} ,
			)-> pack( @fxe1);

    $right_frame->Button(-text => 'Remove selected',
			 -command => sub { $cw->remove_selection ;} ,
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

sub push_entry {
    my $cw = shift;
    my $add = shift;
    my $tklist = $cw->{tklist} ;
    my $list = $cw->{list};

    $logger->debug("push_entry: $add");

    my $cargo_type = $list->cargo_type ;
    my $value_type = $list->get_cargo_info('value_type') ; # may be undef
    if ($cargo_type eq 'leaf' and $value_type ne 'enum' and $value_type ne 'reference') {
	return unless $add;
	eval {$list->push($add) ;};
    }
    else {
	# create new item in list (may auto create node object)
	my @idx = $list -> get_all_indexes ;
	eval {$list->fetch_with_id(scalar @idx)} ;
    }

    if ($@) {
	$cw -> Dialog ( -title => 'List index error with type $cargo_type',
			-text  => $@,
		      )
	  -> Show ;
    }
    else {
	# trigger redraw of Tk Tree
	$cw->reload_tree;
    }

    my @new_idx = $list->get_all_indexes ;
    $logger->debug("new list idx: ". join(',',@new_idx));

    my $insert = $add || $#new_idx ;
    $tklist->insert('end',$insert);

    return 1 ;
}

sub set_entry {
    my $cw =shift;
    my $data = shift ;

    my $tklist = $cw->{tklist} ;
    my $idx_ref = $tklist->curselection() ;
    return unless defined $idx_ref;
    return unless @$idx_ref ;

    my $idx = $idx_ref->[0] ;
    return unless $idx ;
    $tklist->delete($idx) ;
    $tklist->insert($idx, $data) ;
    $tklist->selectionSet($idx ) ;
    $cw->{list}->fetch_with_id($idx)->store($data) ;
    $cw->reload_tree ;
}

sub set_all_items {
    my $cw =shift;
    my $data = shift ;

    return unless $data ;
    my $tklist = $cw->{tklist} ;

    my @list = split /[^\w\-]+/,$data ;

    $tklist->delete(0,'end') ;
    $tklist->insert(0, @list) ;
    $cw->{list}->load_data(\@list) ;
    $cw->reload_tree ;
}


sub move_up {
    my $cw =shift;

    my $tklist = $cw->{tklist} ;
    my $from_idx_ref = $tklist->curselection() ;

    return unless defined $from_idx_ref;
    return unless @$from_idx_ref ;

    my $from_idx = $from_idx_ref->[0] ;
    return unless $from_idx ;
    return unless $from_idx > 0 ;

    $cw->swap($from_idx , $from_idx - 1) ;
}

sub move_down {
    my $cw =shift;

    my $tklist = $cw->{tklist} ;
    my $from_idx_ref = $tklist->curselection() ;

    return unless defined $from_idx_ref;
    return unless @$from_idx_ref ;

    my $from_idx = $from_idx_ref->[0] ;
    return unless $from_idx < @$from_idx_ref ;

    $cw->swap($from_idx , $from_idx + 1) ;
}

sub swap {
    my ($cw, $ida, $idb ) = @_ ;

    my $tklist = $cw->{tklist} ;

    my $list = $cw->{list};
    $list->swap($ida , $idb) ;

    my $cargo_type = $list->cargo_type ;

    $tklist->selectionClear($ida ) ;

    if ($cargo_type ne 'node') {
	my $old = $tklist->get($ida) ;
	$tklist->delete($ida) ;

	while ($idb > $tklist->size) {
	    $tklist->insert('end','<undef>') ;
	}
	$tklist->insert($idb, $old) ;
    }

    $tklist->selectionSet($idb ) ;
    $cw->reload_tree ;
}

sub remove_selection {
    my $cw = shift ;
    my $tklist = $cw->{tklist} ;
    my $list = $cw->{list};

    foreach ($tklist->curselection()) {
	$logger->debug( "remove_selection: removing index $_" );
	$list   -> remove($_) ;
	$cw->reload_tree ;
    }

    # redraw the list content
    $tklist -> delete(0,'end') ;
    my $cargo_type = $list->cargo_type ;
    my @insert = $cargo_type eq 'leaf' ? $list->fetch_all_values 
               :                         $list->get_all_indexes ;
    map { $_ = '<undef>' unless defined $_ } @insert ;
    $tklist->insert( end => @insert ) ;
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
    $cw->{store_cb}->() ;
}


1;
