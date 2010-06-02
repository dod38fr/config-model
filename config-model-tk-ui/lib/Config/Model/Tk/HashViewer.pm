package Config::Model::Tk::HashViewer ;

use strict;
use warnings ;
use Carp ;

use base qw/Tk::Frame Config::Model::Tk::AnyViewer/;
use subs qw/menu_struct/ ;

Construct Tk::Widget 'ConfigModelHashViewer';

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
    my $hash = $cw->{hash} = delete $args->{-item} 
      || die "HashViewer: no -item, got ",keys %$args;
    my $path = delete $args->{-path} 
      || die "HashViewer: no -path, got ",keys %$args;

    $cw->add_header(View => $hash) ;

    my $inst = $hash->instance ;

    my $elt_frame = $cw->Frame(qw/-relief raised -borderwidth 2/)->pack(@fxe1) ;
    my $str =  $hash->element_name.' '.$hash->get_type .' elements' ;
    $elt_frame -> Label(-text => $str) -> pack() ;

    my $rt = $elt_frame ->Scrolled ( 'ROText',
				     -scrollbars => 'oe',
				     -height => 10,
				   ) ->pack(@fbe1) ;

    foreach my $c ($hash->get_all_indexes) {
	$rt->insert('end', $c."\n" ) ;
    }

    $cw->add_annotation($hash);
    $cw->add_info($cw) ;
    $cw->add_summary_and_description($hash) ;
    $cw->add_editor_button($path) ;

    $cw->SUPER::Populate($args) ;
}


sub add_info {
    my $cw = shift ;
    my $info_frame = shift ;

    my $hash = $cw->{hash} ;

    my @items = ('type : '. $hash->get_type 
                          . ( $hash->ordered ? '(ordered)' : ''),
		 'index : '.$hash->index_type ,
		 'cargo : '.$hash->cargo_type ,
		);

    if ($hash->cargo_type eq 'node') {
	push @items, "cargo class: " . $hash->config_class_name ;
    }

    foreach my $what (qw/min_index max_index max_nb/) {
	my $v = $hash->$what() ;
	my $str = $what ;
	$str =~ s/_/ /g;
	push @items, "$str: $v" if defined $v;
    }

    $cw->add_info_frame(@items) ;
}


1;
