
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

package Config::Model::Tk::ListViewer ;

use strict;
our $VERSION="1.305";
use warnings ;
use Carp ;

use base qw/Tk::Frame Config::Model::Tk::AnyViewer/;
use subs qw/menu_struct/ ;


Construct Tk::Widget 'ConfigModelListViewer';

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
    my $list = $cw->{list} = delete $args->{-item} 
      || die "ListViewer: no -item, got ",keys %$args;
    my $path = delete $args->{-path} 
      || die "ListViewer: no -path, got ",keys %$args;

    $cw->add_header(View => $list) ;

    my $inst = $list->instance ;

    my $elt_frame = $cw->Frame(qw/-relief raised -borderwidth 2/)->pack(@fxe1) ;
    my $str =  $list->element_name.' '.$list->get_type .' elements' ;
    $elt_frame -> Label(-text => $str) -> pack() ;

    my $rt = $elt_frame ->Scrolled ( 'ROText',
				     -height => 10,
				   ) ->pack(@fbe1) ;

    my @insert = $list->cargo_type eq 'leaf' ? $list->fetch_all_values 
               :                         $list->get_all_indexes ;
    foreach my $c (@insert) {
	my $line = defined $c ? $c : '<undef>' ;
	$rt->insert('end', $line."\n" ) ;
    }

    $cw->add_info($cw) ;
    $cw->add_summary_and_description($list) ;
    $cw->add_editor_button($path) ;

    $cw->SUPER::Populate($args) ;
}


sub add_info {
    my $cw = shift ;
    my $info_frame = shift ;

    my $list = $cw->{list} ;

    my @items = ('type : '. $list->get_type ,
		 'index : '.$list->index_type ,
		 'cargo : '.$list->cargo_type ,
		);

    if ($list->cargo_type eq 'node') {
	push @items, "cargo class: " . $list->config_class_name ;
    }

    if ($list->cargo_type eq 'leaf') {
	push @items, "leaf value type: " . ($list->get_cargo_info('value_type') || '') ;
    }

    foreach my $what (qw/min_index max_index/) {
	my $v = $list->$what() ;
	my $str = $what ;
	$str =~ s/_/ /g;
	push @items, "$str: $v" if defined $v;
    }

    $cw->add_info_frame(@items) ;
}


1;
