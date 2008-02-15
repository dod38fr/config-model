# $Author: ddumont $
# $Date: 2008-02-15 12:19:49 $
# $Name: not supported by cvs2svn $
# $Revision: 1.8 $

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
use Log::Log4perl;

use base qw/Config::Model::Tk::LeafViewer/;
use vars qw/$VERSION/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/;

Construct Tk::Widget 'ConfigModelLeafEditor';

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
    my $leaf = $cw->{leaf} = delete $args->{-item} 
      || die "LeafEditor: no -item, got ",keys %$args;

    my $inst = $leaf->instance ;
    $inst->push_no_value_check('fetch') ;

    my $vt = $leaf -> value_type ;
    $logger->info("Creating leaf editor for value_type $vt");

    $cw->add_header(Edit => $leaf) ;

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
	$cw->add_buttons($v_frame) ;
    }
    elsif ($vt eq 'boolean') {
	$ed_frame->Checkbutton(-text => $leaf->element_name,
			 -variable => $vref,
			 -command => sub { $cw->try},
			)
	  ->pack();
	$cw->add_buttons($ed_frame) ;
    }
    elsif ($vt eq 'uniline' or $vt eq 'integer') {
	$ed_frame -> Entry(-textvariable => $vref)
	    -> pack(@fbe1);
	$cw->add_buttons($ed_frame) ;
    }
    elsif ($vt eq 'enum' or $vt eq 'reference') {
	my $lb = $ed_frame->Scrolled ( 'Listbox',
				       -height => 5,
				       #-listvariable => $vref,
				       #-selectmode => 'single',
				     ) ->pack(@fxe1) ;
	my @choice = $leaf->get_choice ;
	$lb->insert('end',$leaf->get_choice) ;
	my $idx = 0;
	map { $lb->selectionSet($idx) if $_ eq $$vref; $idx ++}  @choice;
	$lb->bind('<Button-1>',sub {$cw->try($lb->get($lb->curselection()))});
	$cw->add_buttons($ed_frame) ;
    }

    $cw->add_info() ;
    $cw->add_help_frame() ;
    $cw->add_help(class   => $leaf->parent->get_help) ;
    $cw->add_help(element => $leaf->parent->get_help($leaf->element_name)) ;
    $cw->{value_help} = '';
    $cw->add_help(value => \$cw->{value_help});
    $cw->set_value_help ;

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

sub add_buttons {
    my ($cw,$frame) = @_ ;
    my $bframe = $frame->Frame->pack() ;
    $bframe -> Button ( -text => 'Reset',
			-command => sub { $cw->reset_value ; },
		      ) -> pack(-side => 'left') ;
    $bframe -> Button ( -text => 'Try ??',
			-command => sub { $cw->try},
		      ) -> pack(-side => 'left') ;
    $bframe -> Button ( -text => 'Store',
			-command => sub { $cw->store},
		      ) -> pack(-side => 'left') ;
}


sub try {
    my $cw = shift ;
    my $v = shift ;
    if (defined $v) {
	$cw->{value} = $v ;
    }
    else {
	my $e_w = $cw->{e_widget} ;
	# tk widget use a reference
	$v = defined  $e_w ? $e_w->get('1.0','end')
           :                 $cw->{value} ;
    }
    $logger->debug( "try: value $v") ;
    require Tk::Dialog ;

    my @errors = $cw->{leaf}->check($v,1) ;

    if (@errors ) {
	$cw -> Dialog ( -title => 'Value error',
			-text  => join("\n",@errors),
		      )
            -> Show ;
	$cw->reset_value ;
	return undef ;
    }
    else {
	$cw->set_value_help($v) ;
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
	$cw->parent->parent->parent->parent->reload(1) ;
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
