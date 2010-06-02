package Config::Model::Tk::CheckListViewer ;

use strict;
use warnings ;
use Carp ;

use base qw/Tk::Frame Config::Model::Tk::AnyViewer/;
use subs qw/menu_struct/ ;
use Tk::ROText ;


Construct Tk::Widget 'ConfigModelCheckListViewer';

my @fbe1 = qw/-fill both -expand 1/ ;

sub ClassInit {
    my ($cw, $args) = @_;
    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.

    # cw->Advertise(name=>$widget);
}

sub Populate { 
    my ($cw, $args) = @_;
    my $leaf = $cw->{leaf} = delete $args->{-item} 
      || die "CheckListViewer: no -item, got ",keys %$args;
    my $path = delete $args->{-path} 
      || die "CheckListViewer: no -path, got ",keys %$args;

    my $inst = $leaf->instance ;

    $cw->add_header(View => $leaf) ;

    my $rt = $cw->Scrolled ( 'ROText',
			     -scrollbars => 'osoe',
			     -height => 6,
			   ) ->pack(@fbe1) ;
    $rt->tagConfigure('in',-background => 'black', -foreground => 'white') ;

    $cw->add_annotation($leaf) ;
    $cw->add_info() ;
    $cw->add_summary_and_description($leaf) ;
    $cw->{value_help_widget} = $cw->add_help(value => '',1);

    my %h = $leaf->get_checked_list_as_hash ;
    foreach my $c ($leaf->get_choice) {
	my $tag = $h{$c} ? 'in' : 'out' ;
	$rt->insert('end', $c."\n" , $tag) ;
    }

    $cw->set_value_help($leaf->get_checked_list);

    $cw->add_editor_button($path) ;

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

sub set_value_help {
     my $cw = shift ;
     my @set = @_ ;

     my $w = $cw->{value_help_widget};
     $w->delete('0.0','end');

     foreach my $v (@set) {
	 my $value_help = $cw->{leaf}->get_help($v);
	 $w->insert('end',"$v: ".$value_help."\n") if defined $value_help ;
     }
 }

sub add_info {
    my $cw = shift ;

    my @items = () ;
    my $leaf = $cw->{leaf} ;
    if (defined $leaf->refer_to) {
	push @items, "refer_to: ".$leaf->refer_to ;
    }
    $cw->add_info_frame(@items) if @items ;
}

1;
