package Config::Model::Tk::LeafViewer ;

use strict;
use warnings ;
use Carp ;
use Log::Log4perl ;

use base qw/Tk::Frame Config::Model::Tk::AnyViewer/;

Construct Tk::Widget 'ConfigModelLeafViewer';

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill x    -expand 1/ ;
my @fx   = qw/-fill x  / ;

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
      || die "LeafViewer: no -item, got ",keys %$args;
    my $path = delete $args->{-path} 
      || die "LeafViewer: no -path, got ",keys %$args;

    my $inst = $leaf->instance ;
    $inst->push_no_value_check('fetch') ;

    my $vt = $leaf -> value_type ;
    $logger->info("Creating leaf viewer for value_type $vt");
    my $v = $leaf->fetch ;

    $inst->pop_no_value_check ;

    $cw->add_header(View => $leaf)->pack(@fx) ;

    my @pack_args = @fx ;
    @pack_args = @fbe1 if $vt eq 'string' ;
    my $lv_frame = $cw->Frame(qw/-relief raised -borderwidth 2/)
      ->pack(@pack_args) ;
    $lv_frame -> Label(-text => 'Value') -> pack() ;

    if ($vt eq 'string') {
	require Tk::ROText ;
	$cw->{e_widget} = $lv_frame->Scrolled ('ROText',
					       -height => 5,
					       -scrollbars => 'ow',
					      )
	  ->pack(@fbe1);
	$cw->{e_widget}->insert('end',$v,'value') ;
	$cw->{e_widget}
	  ->tagConfigure(qw/value -lmargin1 2 -lmargin2 2 -rmargin 2/);
    }
    else {
	my $v_frame = $lv_frame->Frame(qw/-relief sunken -borderwidth 1/)
	  ->pack(@fxe1) ;
	$v_frame -> Label(-text => $v, -anchor => 'w')
	    -> pack(@fxe1, -side => 'left');
    }

    $cw->add_annotation($leaf)->pack(@fx);
    $cw->add_summary($leaf)->pack(@fx) ;
    $cw->add_description($leaf)->pack(@fx) ;
    $cw->add_help('value help'   => $leaf->get_help($cw->{value}))->pack(@fx) ;
    $cw->add_info_button()       -> pack(@fxe1, -side => 'left' , -anchor => 'n') ;
    $cw->add_editor_button($path)-> pack(@fxe1, -side => 'right', -anchor => 'n') ;

    $cw->ConfigSpecs(
		     #-fill   => [ qw/SELF fill Fill both/],
		     #-expand => [ qw/SELF expand Expand 1/],
		     -relief => [qw/SELF relief Relief groove/ ],
		     -borderwidth => [qw/SELF borderwidth Borderwidth 2/] ,
		     DEFAULT => [ qw/SELF/ ],
           );

    $cw->SUPER::Populate($args) ;
}

sub get_info {
    my $cw = shift ;

    my $leaf = $cw->{leaf} ;

    my $type = $leaf->value_type ;
    my @choice = $type eq 'enum' ? $leaf->get_choice : () ;
    my $choice_str = @choice ? ' ('.join(',',@choice).')' : '' ;

    my @items = (
		 'type : '.$leaf->value_type.$choice_str,
		);

    if (defined $leaf->upstream_default) {
	push @items, "upstream_default value: " . $leaf->upstream_default ;
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

    foreach my $what (qw/min max/) {
	my $v = $leaf->$what() ;
	push @items, "$what value: $v" if defined $v;
    }

    return $leaf->element_name, @items;
}



1;
