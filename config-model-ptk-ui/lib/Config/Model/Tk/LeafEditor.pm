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

package Config::Model::Tk::LeafEditor ;

use strict;
use warnings ;
use Carp ;

use base qw/ Tk::Frame /;
use vars qw/$VERSION/ ;
use subs qw/menu_struct/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

Construct Tk::Widget 'ConfigModelLeafEditor';

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
      || die "LeafEditor: no leaf, got ",keys %$args;

    my $inst = $leaf->instance ;
    $inst->push_no_value_check('fetch') ;

    my $vt = $leaf -> value_type ;
    print "leaf editor for value_type $vt\n";
    $cw->{value} = $leaf->fetch || '';
    my $vref = \$cw->{value};

    my $ed_frame = $cw->Frame->pack(@fbe1);

    if ($vt eq 'string') {
	$cw->{e_widget} = $ed_frame->Text(-height => 10 )
                             ->pack(@fbe1);
	$cw->reset_value ;
    }
    elsif ($vt eq 'boolean') {
	$ed_frame->Checkbutton(-text => $leaf->element_name,
			 -variable => $vref,
			 -command => sub { $cw->try},
			)
	  ->pack();
    }
    elsif ($vt eq 'uniline' or $vt eq 'integer') {
	$ed_frame -> Entry(-textvariable => $vref)
	    -> pack(@fbe1);
    }
    elsif ($vt eq 'enum' or $vt eq 'reference') {
	foreach my $c ($leaf->get_choice) {
	    $ed_frame->Radiobutton ( -text => $c,
				     -value => $c,
				     -variable => $vref,
				     -command => sub {$cw->try} ,
				   )
                    ->pack(-side => 'left') ;
	}
    }
    $cw->add_info() ;
    $cw->add_value_help() ;
    $cw->set_value_help ;

    my $bframe = $cw->Frame->pack;
    $bframe -> Button ( -text => 'Reset',
			-command => sub { $cw->reset_value ; },
		      ) -> pack(-side => 'left') ;
    $bframe -> Button ( -text => 'Try ??',
			-command => sub { $cw->try},
		      ) -> pack(-side => 'left') ;
    $bframe -> Button ( -text => 'Store',
			-command => sub { $cw->store},
		      ) -> pack(-side => 'left') ;

    $cw->SUPER::Populate($args) ;
}

sub add_info {
    my $cw = shift ;

    my $info_frame = $cw->Frame(-relief => 'groove',
				-borderwidth => 2,
			       )->pack;
    my $leaf = $cw->{leaf} ;

    my @items = ('current value :'.$cw->{value},
		 'type :'.$leaf->value_type,
		);

    if (defined $leaf->built_in) {
	push @items, "built_in value: " . $leaf->built_in ;
    }
    elsif (defined $leaf->fetch('standard')) {
	push @items, "default value: " . $leaf->fetch('standard') ;
    }
    elsif (defined $leaf->refer_to) {
	push @items, "reference to: " . $leaf->refer_to ;
    }
    elsif (defined $leaf->computed_refer_to) {
	push @items, "computed reference to: " . $leaf->computed_refer_to ;
    }


    my $m = $leaf->mandatory ;
    push @items, "is mandatory: ".($m ? 'yes':'no') if defined $m;

    my @minmax ;
    foreach my $what (qw/min max/) {
	my $v = $leaf->$what() ;
	push @minmax, "$what: $v" if defined $v;
    }

    push @items, join(', ',@minmax) if @minmax ;

    map { $info_frame -> Label(-text => $_ )->pack } @items;
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

sub try {
    my $cw = shift ;

    require Tk::Dialog ;

    my $e_w = $cw->{e_widget} ;
    my $v = defined  $e_w ? $e_w->get('1.0','end')
          :                 $cw->{value} ;

    my @errors = $cw->{leaf}->check($cw->{value},1) ;

    if (@errors ) {
	$cw -> Dialog ( -title => 'Value error',
			-text  => join("\n",@errors),
		      )
            -> Show ;
	$cw->reset_value ;
	return undef ;
    }
    else {
	$cw->set_value_help ;
	return $v ;
    }
}

sub store {
    my $cw = shift ;
    my $v = $cw->try ;
    return unless defined $v;

    eval {$cw->{leaf}->store($v); } ;

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
    my $v = $cw->{value} ;
    $cw->{help}=$cw->{leaf}->get_help($v) if defined $v ;
}

sub reset_value {
    my $cw = shift ;
    $cw->{value} = $cw->{leaf}->fetch ;
    if (defined $cw->{e_widget}) {
	$cw->{e_widget}->delete('1.0','end') ;
	$cw->{e_widget}->insert('end',$cw->{value}) ;
    }
    $cw->set_value_help ;
}

1;
