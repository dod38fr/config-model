# $Author: ddumont $
# $Date: 2009-09-03 14:05:31 +0200 (Thu, 03 Sep 2009) $
# $Revision: 1013 $

#    Copyright (c) 2009 Dominique Dumont.
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

package Config::Model::Tk::NodeEditor ;

use strict;
use warnings ;
use Carp ;

use Tk::Pane ;
use Tk::Balloon;

use base qw/Tk::Frame Config::Model::Tk::AnyViewer/;
use vars qw/$VERSION/ ;
use subs qw/menu_struct/ ;

$VERSION = sprintf "1.%04d", q$Revision: 1013 $ =~ /(\d+)/;

Construct Tk::Widget 'ConfigModelNodeEditor';

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
    my $node = $cw->{node} = delete $args->{-item} 
      || die "NodeViewer: no -item, got ",keys %$args;
    my $path = delete $args->{-path} ;
    $cw->{store_cb} = delete $args->{-store_cb} || die __PACKAGE__,"no -store_cb" ;

    $cw->add_header(Edit => $node) ;

    my $inst = $node->instance ;

    $cw -> Label(-text => $node->composite_name.' node elements') -> pack() ;

    my $elt_pane = $cw->Scrolled(qw/Pane -scrollbars osow -sticky senw/)
      ->pack(@fbe1) ;

    my $exp = $cw->parent->parent->parent->parent->get_experience ;

    my %values;
    my %modified ;
    foreach my $c ($node->get_element_name(for => $exp)) {
	my $type = $node->element_type($c) ;
	my $f = $elt_pane->Frame(-relief=> 'groove', -borderwidth => 1)
	  ->pack(-side =>'top',@fxe1) ;
	my $label = $f -> Label(-text => $c,-width=> 22, -anchor => 'w') ;
	$label->pack(qw/-side left -fill x -anchor w/);

	my $help = $node->get_help(summary => $c) || $node->get_help(description => $c);
 	$cw->Balloon(-state => 'balloon') ->attach($label, -msg => $help) ;

	if ($type eq 'leaf') {
	    my $leaf = $node->fetch_element($c) ;
	    my $v = eval {$node->fetch_element_value($c)} ;
	    my $store_sub = sub {$leaf->store($v); $cw->{store_cb}->($leaf)};
	    my $v_type = $leaf->value_type ;

	    if ($v_type =~ /integer|number|uniline/ ) {
		my $e = $f->Entry(-textvariable => \$v)
		  ->pack(qw/-side left -anchor w/,@fxe1) ;
		$e->bind("<Return>" => $store_sub) ;
		next ;
	    }

	    if ($v_type =~ /boolean/ ) {
		my $e = $f->Checkbutton(-variable => \$v, -command => $store_sub)
		  ->pack(qw/-side left -anchor w/) ;
		next ;
	    }

	    if ($v_type =~ /enum|reference/) {
		my @choices = $leaf->get_choice ;
		require Tk::BrowseEntry;
		my $e = $f->BrowseEntry(-variable => \$v,
					-browsecmd => $store_sub,
					-choices => \@choices)
		  ->pack(qw/-side left -anchor w/,@fxe1) ;
		next ;
	    }
	}

	# add button to launch dedicated editor
	my $edit_sub = sub {
	    $cw->parent->parent->parent->parent
	      ->create_element_widget('edit',"$path.$c") ;
	};
	$f->Button(-text => '...',-font =>[ -size => 6 ],
		   -command => $edit_sub) 
	  -> pack(-anchor => 'w');
    }

    $cw->add_info($cw) ;

    if ($node->parent) {
	$cw->add_summary_and_description($node) ;
    }
    else {
	$cw->add_help(class   => $node->get_help) ;
    }
    $cw->SUPER::Populate($args) ;
}


sub add_info {
    my $cw = shift ;
    my $info_frame = shift ;

    my $node = $cw->{node} ;

    my @items = ('type : '. $node->get_type ,
		 'class name : '.$node->config_class_name ,
		);

    $cw->add_info_frame(@items) ;
}


1;
