# $Author: ddumont $
# $Date: 2008-02-05 17:25:07 $
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

package Config::Model::Tk::ListEditor ;

use strict;
use warnings ;
use Carp ;

use base qw/ Tk::Frame /;
use vars qw/$VERSION/ ;
use subs qw/menu_struct/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;

Construct Tk::Widget 'ConfigModelListEditor';

my @fbe1 = qw/-fill both -expand 1/ ;

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

    my $inst = $list->instance ;
    $inst->push_no_value_check('fetch') ;

    my $tklist = $cw -> Listbox(-selectmode => 'single')
                     -> pack(@fbe1, -side => 'left') ;
    $tklist->insert( end => $list->get_all_indexes) ;

    my $right_frame = $cw->Frame->pack(@fbe1, -side => 'left');

    $cw->add_info($right_frame) ;

    my $add_item = '';
    my $add_frame = $right_frame->Frame->pack;
    my $add_str = $list->ordered ? "after selection " : '' ;
    $add_frame -> Button(-text => "Add item $add_str:",
			 -command => sub {$cw->add_entry($add_item);},
			)->pack(-side => 'left');
    $add_frame -> Entry (-textvariable => \$add_item, -width => 10)
               -> pack  (-side => 'left') ;

    my $cp_frame = $right_frame->Frame->pack;
    my $cp_item = '';
    $cp_frame -> Button(-text => 'Copy selected item into:',
			-command => sub {$cw->copy_selected_in($cp_item);},
		       )
              -> pack(-side => 'left');
    $cp_frame -> Entry (-textvariable => \$cp_item, -width => 10)
              -> pack  (-side => 'left') ;


    my $mv_frame = $right_frame->Frame->pack;
    my $mv_item = '';
    $mv_frame -> Button(-text => 'Move selected item into:',
			-command => sub {$cw->move_selected_to($mv_item);},
		       )
              -> pack(-side => 'left');
    $mv_frame -> Entry (-textvariable => \$mv_item, -width => 10)
              -> pack  (-side => 'left') ;

    $right_frame->Button(-text => 'Delete selected',
			 -command => sub { $cw->delete_selection ;} ,
			)-> pack;

    $right_frame -> Button ( -text => 'Clear',
			     -command => sub { $list->clear ; 
					       $tklist->delete(0,'end');
					       $cw->reload_tree;
					   },
			   ) -> pack(-side => 'left') ;

    $cw->{tklist} = $tklist ;
    $cw->SUPER::Populate($args) ;
}

sub add_entry {
    my $cw = shift;
    my $add = shift;
    my $tklist = $cw->{tklist} ;
    my $list = $cw->{list};

    print "add_entry: $add\n";

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

    print "new list idx: ", join(',',$list->get_all_indexes),"\n";

    # ensure correct order for ordered hash
    my @selected = $tklist->curselection() ;
    print "add_entry for ",scalar @selected, " items\n";
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
}

sub copy_selected_in {
    my $cw =shift;
    my $to_name = shift ;
    my $tklist = $cw->{tklist} ;
    my $from_idx = $tklist->curselection() ;
    my $from_name = $tklist->get($from_idx);
    my $list = $cw->{list};
    $cw->add_entry($to_name) ;
    $list->copy($from_name,$to_name) ;
    $cw->reload_tree ;
}

sub move_selected_to {
    my $cw =shift;
    my $to_name = shift ;
    my $tklist = $cw->{tklist} ;
    my $from_idx = $tklist->curselection() ;
    my $from_name = $tklist->get($from_idx);
    print "move_selected_to: from $from_name to $to_name\n";
    my $list = $cw->{list};
    $tklist -> delete($from_idx) ;
    $cw->add_entry($to_name) ;
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
    $cw->parent->parent->parent->parent->reload ;
}

sub add_info {
    my $cw = shift ;
    my $info_frame = shift ;

    my $list = $cw->{list} ;

    my @items = ('type : '. $list->get_type 
                          . ( $list->ordered ? '(ordered)' : ''),
		 'index : '.$list->index_type ,
		 'cargo : '.$list->cargo_type ,
		);

    if ($list->cargo_type eq 'node') {
	push @items, "cargo class: " . $list->config_class_name ;
    }

    foreach my $what (qw/min max max_nb/) {
	my $v = $list->$what() ;
	my $str = $what ;
	$str =~ s/_/ /g;
	push @items, "$str: $v" if defined $v;
    }

    map { $info_frame -> Label(-text => $_ )->pack(-fill => 'x') } @items;
}


1;
