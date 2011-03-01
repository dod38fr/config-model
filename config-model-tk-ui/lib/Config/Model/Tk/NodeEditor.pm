package Config::Model::Tk::NodeEditor ;

use strict;
use warnings ;
use Carp ;

use Tk::Pane ;
use Tk::Balloon;
use Text::Wrap;
use Config::Model::Tk::NoteEditor ;

use base qw/Tk::Frame Config::Model::Tk::AnyViewer/;
use subs qw/menu_struct/ ;


Construct Tk::Widget 'ConfigModelNodeEditor';

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill x    -expand 1/ ;
my @fx   = qw/-fill x    -expand 0/ ;

my $logger = Log::Log4perl::get_logger("Tk::NodeEditor");

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
    $cw->{path} = delete $args->{-path} ;
    $cw->{store_cb} = delete $args->{-store_cb} || die __PACKAGE__,"no -store_cb" ;

    $cw->add_header(Edit => $node)->pack(@fx) ;

    $cw -> Label(-text => $node->composite_name.' node elements') -> pack() ;

    $cw->{pane} = $cw->Scrolled(qw/Pane -scrollbars osow -sticky senw/);
    $cw->{pane}->pack(@fbe1) ;

    $cw->fill_pane ;

    # add adjuster
    #require Tk::Adjuster;
    #$cw -> Adjuster()->pack(-fill => 'x' , -side => 'top') ;

    $cw->ConfigModelNoteEditor( -object => $node )->pack;
    $cw->add_info_button()->pack(@fxe1, qw/-anchor n/) ;

    if ($node->parent) {
	$cw->add_summary($node)->pack(@fx) ;
	$cw->add_description($node)->pack(@fx) ;
    }
    else {
	$cw->add_help(class   => $node->get_help)->pack(@fx) ;
    }
    $cw->SUPER::Populate($args) ;
}

sub reload {
    goto &fill_pane ;
}

sub fill_pane {
    my $cw = shift ;

    my $node = $cw->{node} ;
    my $elt_pane = $cw->{pane} ;

    my $exp = $cw->parent->parent->parent->parent->get_experience ;

    my %old_elt = map { ($_ => 1) } keys %{$cw->{elt_widgets}|| {} } ;

    my %values;
    my %modified ;
    my $old_f ;

    foreach my $c ($node->get_element_name(for => $exp)) {
	next if delete $old_elt{$c} ;

	my $type = $node->element_type($c) ;
	my $elt_path = $cw->{path}.'.'.$c ;

	my @after = $old_f ? ( -after => $old_f ) : () ;
	my $f = $elt_pane->Frame(-relief=> 'groove', -borderwidth => 1)
	  ->pack(-side =>'top',@fx,@after) ;
	$old_f = $f ;

	$cw->{elt_widgets}{$c} = $f ;
	my $label = $f -> Label(-text => $c,-width=> 22, -anchor => 'w') ;
	$label->pack(qw/-side left -fill x -anchor w/);

	my $help = $node->get_help(summary => $c) || $node->get_help(description => $c);
 	$cw->Balloon(-state => 'balloon') ->attach($label, -msg => wrap('','',$help)) ;

	if ($type eq 'leaf') {
	    my $leaf = $node->fetch_element($c) ;
	    my $v = $node->fetch_element_value(name => $c, check  => 'no') ;
	    my $store_sub = sub {$leaf->store($v); 
				 $cw->{store_cb}->(1,undef,$elt_path);
				 $cw->fill_pane;
			     };
	    my $v_type = $leaf->value_type ;

	    if ($v_type =~ /integer|number|uniline/ ) {
		my $e = $f->Entry(-textvariable => \$v)
		  ->pack(qw/-side left -anchor w/,@fxe1) ;
		$e->bind("<Return>" => $store_sub) ;
		$e->bind("<FocusOut>" => $store_sub) ;
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
	my $obj = $node->fetch_element($c) ;
	my $edit_sub = sub {
	    $cw->parent->parent->parent->parent
	      ->create_element_widget('edit',$elt_path,$obj) ;
	};
	my $edb = $f->Button(-text => '...',-font =>[ -size => 6 ],
		    -command => $edit_sub) ;
	$edb -> pack(-anchor => 'w');

	my $content = $type eq 'leaf' ? $obj->fetch( check => 'no') || ''
	            : $type eq 'node' ? $node->config_class_name
	            :                   $type ;
 	$cw->Balloon(-state => 'balloon') 
	  ->attach($edb, -msg => wrap('','',$content)) ;
    }

    # destroy leftover widgets (may occur with warp mechanism)
    map {my $w = delete $cw->{elt_widgets}{$_};$w->destroy } keys %old_elt ;
}

sub get_info {
    my $cw = shift ;

    my $node = $cw->{node} ;

    my @items = ('type : '. $node->get_type ,
		 'class name : '.$node->config_class_name ,
		);

    return $node->element_name,@items ;
}


1;
