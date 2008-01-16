# $Author: ddumont $
# $Date: 2008-01-16 12:10:57 $
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

package Config::Model::Tk::CheckListEditor ;

use strict;
use warnings ;
use Carp ;

use base qw/ Tk::Frame /;
use vars qw/$VERSION/ ;
use subs qw/menu_struct/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

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
    my $leaf = $cw->{leaf} = delete $args->{-leaf} 
      || die "CheckListEditor: no leaf, got ",keys %$args;

    my $inst = $leaf->instance ;
    $inst->push_no_value_check('fetch') ;

    my $ed_frame = $cw->Frame->pack(@fbe1);

    my %h = $leaf->get_checked_list_as_hash ;
    foreach my $c (keys %h) {
	$ed_frame->Checkbutton ( -text => $c,
				 -variable => \$h{$c},
				 -command => sub {$cw->set_value_help($c);} ,
			       )
	  ->pack(-side => 'left') ;
    }
    $cw->{check_list} = \%h;

    $cw->add_value_help() ;
    $cw->set_value_help ;

    my $bframe = $cw->Frame->pack;
    $bframe -> Button ( -text => 'Reset',
			-command => sub { $cw->reset_value ; },
		      ) -> pack(-side => 'left') ;
    $bframe -> Button ( -text => 'Store',
			-command => sub { $cw->store},
		      ) -> pack(-side => 'left') ;

    $cw->SUPER::Populate($args) ;
}

sub add_value_help {
    my $cw = shift ;

    my $help_frame = $cw->Frame(-relief => 'groove',
				-borderwidth => 2,
			       )->pack(@fbe1);
    my $leaf = $cw->{leaf} ;
    $help_frame->Label(-text => 'value help: ')->pack(-side => 'left');
    $help_frame->Label(-textvariable => \$cw->{help})
      ->pack(-side => 'left', -fill => 'x', -expand => 1);
}

sub store {
    my $cw = shift ;

    eval {$cw->{leaf}->set_checked_list_as_hash(%{$cw->{check_list}}); } ;

    if ($@) {
	$cw -> Dialog ( -title => 'Value error',
			-text  => $@,
		      )
            -> Show ;
	$cw->reset_value ;
    }
    else {
	# trigger redraw of Tk Tree
	$cw->parent->parent->parent->parent->parent->reload
    }
}

sub set_value_help {
    my $cw = shift ;
    my $v = shift ;
    $cw->{help} = $cw->{leaf}->get_help($v) if defined $v ;
}

sub reset_value {
    my $cw = shift ;

    my $h_ref = $cw->{leaf}->get_checked_list_as_hash ;

    # the CheckButtons have stored the reference of the hash *values*
    # so we must preserve them.
    map { $cw->{check_list}{$_} = $h_ref->{$_}} keys %$h_ref ;
    $cw->{help} = '' ;
}

1;
