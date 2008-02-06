# $Author: ddumont $
# $Date: 2008-02-06 13:00:43 $
# $Name: not supported by cvs2svn $
# $Revision: 1.4 $

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

use base qw/Config::Model::Tk::LeafViewer/;
use vars qw/$VERSION/ ;
use subs qw/menu_struct/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;

Construct Tk::Widget 'ConfigModelLeafEditor';

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
    my $leaf = $cw->{leaf} = delete $args->{-item} 
      || die "LeafEditor: no -item, got ",keys %$args;

    my $inst = $leaf->instance ;
    $inst->push_no_value_check('fetch') ;

    my $vt = $leaf -> value_type ;
    print "leaf editor for value_type $vt\n";

    $cw->add_header('Edit') ;

    $cw->{value} = $leaf->fetch || '';
    my $vref = \$cw->{value};

    my $v_frame =  $cw->Frame(qw/-relief raised -borderwidth 4/)->pack(@fxe1) ;
    $v_frame  -> Label(-text => 'Value') -> pack() ;
    my $ed_frame = $v_frame->Frame(qw/-relief sunken -borderwidth 1/)
      ->pack(@fxe1) ;

    if ($vt eq 'string') {
	$cw->{e_widget} = $v_frame->Text(-height => 10 )
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
    $cw->add_help_frame() ;
    $cw->add_help(class   => $leaf->parent->get_help) ;
    $cw->add_help(element => $leaf->parent->get_help($leaf->element_name)) ;
    $cw->{value_help} = '';
    $cw->add_help(value => \$cw->{value_help});
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

    $cw->ConfigSpecs(
		     #-fill   => [ qw/SELF fill Fill both/],
		     #-expand => [ qw/SELF expand Expand 1/],
		     -relief => [qw/SELF relief Relief groove/ ],
		     -borderwidth => [qw/SELF borderwidth Borderwidth 2/] ,
		     DEFAULT => [ qw/SELF/ ],
           );

    # don't call directly SUPER::Populate as it's LeafViewer's populate
    $cw->Tk::Frame::Populate($args) ;
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
	$cw->parent->parent->parent->parent->reload
    }
}

sub set_value_help {
     my $cw = shift ;
     my $v = $cw->{value} ;
     $cw->{value_help} = $cw->{leaf}->get_help($v) if defined $v ;
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
