package Config::Model::Tk::NodeViewer ;

use strict;
use warnings ;
use Carp ;

use base qw/Tk::Frame Config::Model::Tk::AnyViewer/;
use subs qw/menu_struct/ ;


Construct Tk::Widget 'ConfigModelNodeViewer';

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill x    -expand 1/ ;
my @fx   = qw/-fill    x / ;

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

    $cw->add_header(View => $node)->pack(@fx) ;

    my $inst = $node->instance ;

    my $elt_frame = $cw->Frame(qw/-relief flat/)->pack(@fbe1) ;

    $elt_frame -> Label(-text => $node->composite_name.' node elements') -> pack() ;

    my $hl = $elt_frame ->Scrolled ( 'HList',
				     -scrollbars => 'osow',
				     -columns => 3, 
				     -header => 1,
				     -height => 8,
				   ) -> pack(@fbe1) ;
    $hl->headerCreate(0, -text => 'name') ;
    $hl->headerCreate(1, -text => 'type') ;
    $hl->headerCreate(2, -text => 'value') ;
    $cw->{hlist}=$hl ;
    $cw->reload ;

    # add adjuster. Buggy behavior on destroy...
    #require Tk::Adjuster;
    #$cw->{adjust} = $cw -> Adjuster();
    #$cw->{adjust}->packAfter($hl, -side => 'top') ;

    $cw->add_annotation($node)->pack(@fx);

    if ($node->parent) {
	$cw->add_summary($node)->pack(@fx) ;
	$cw->add_description($node)->pack(@fx) ;
    }
    else {
	$cw->add_help(class   => $node->get_help)->pack(@fx) ;
    }

    $cw->add_info_button()->pack(@fxe1, -side => 'left') ;
    $cw->add_editor_button($path)-> pack (@fxe1, -side => 'right');

    $cw->SUPER::Populate($args) ;
}

#sub DESTROY {
#    my $cw = shift ;
#    $cw->{adjust}->packForget(1);
#}

sub reload {
    my $cw = shift ;

    my $exp = $cw->parent->parent->parent->parent->get_experience ;
    my $node = $cw->{node};
    my $hl=$cw->{hlist} ;

    my %old_elt = %{$cw->{elt_path}|| {} } ;

    foreach my $c ($node->get_element_name(for => $exp)) {
	my $type = $node->element_type($c) ;

	unless (delete $old_elt{$c}) {
	    # create item
	    $hl->add($c) ;
	    $cw->{elt_path}{$c} = 1 ;

	    $hl->itemCreate($c,0, -text => $c) ;
	    $hl->itemCreate($c,1, -text => $type) ;
	    $hl->itemCreate($c,2, 
			    -itemtype => 'imagetext' ,
			    -text => '', 
			    -showimage => 0,
			    -image => $Config::Model::TkUI::warn_img) ;
	}

	if ($type eq 'leaf') {
	    # update displayed value
	    my $v = eval {$node->fetch_element_value($c)} ;
	    if ($@) {
		$hl->itemConfigure($c,2, 
				   -showtext => 0 ,
				   -showimage => 1,
				   ) ;
	    }
	    elsif (defined $v) {
		substr ($v,15) = '...' if length($v) > 15;
		$hl->itemConfigure($c,2,  
				   -showtext => 1 ,
				   -showimage => 0,
				   -text => $v) ;
	    }
	}
    }

    # destroy leftover widgets (may occur with warp mechanism)
    map {$hl->delete(entry => $_); } keys %old_elt ;
}

sub get_info {
    my $cw = shift ;

    my $node = $cw->{node} ;

    my @items = ('type : '. $node->get_type ,
		 'class name : '.$node->config_class_name ,
		);

    my @rexp = $node->accept_regexp ;
    if (@rexp) {
	push @items, 'accept : /^'.join('$/, /^',@rexp).'$/';
    }

    return $node->element_name,@items ;
}


1;
