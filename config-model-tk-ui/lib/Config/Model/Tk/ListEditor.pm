package Config::Model::Tk::ListEditor ;

use strict;
use warnings ;
use Carp ;
use Log::Log4perl ;

use base qw/Config::Model::Tk::ListViewer/;
use subs qw/menu_struct/ ;
use vars qw/$icon_path/ ;
use Tk::Dialog ;
use Config::Model::Tk::NoteEditor ;


Construct Tk::Widget 'ConfigModelListEditor';

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill x    -expand 1/ ;
my @fx   = qw/-fill    x / ;
my $logger = Log::Log4perl::get_logger("Tk::ListEditor");

my ($up_img,$down_img, $rm_img, $eraser_img, $remove_img );
*icon_path = *Config::Model::TkUI::icon_path;

my $entry_width = 20 ;

sub ClassInit {
    my ($cw, $args) = @_;
    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.
    # cw->Advertise(name=>$widget);
}

sub Populate {
    my ( $cw, $args ) = @_;

    my $list = $cw->{list} = delete $args->{-item}
      || die "ListEditor: no -item, got ", keys %$args;

    delete $args->{-path};

    $cw->{store_cb} = delete $args->{-store_cb}
      or die __PACKAGE__, "no -store_cb";

    unless ( defined $up_img ) {
        $up_img     = $cw->Photo( -file => $icon_path . 'up.png' );
        $down_img   = $cw->Photo( -file => $icon_path . 'down.png' );
        $eraser_img  = $cw->Photo( -file => $icon_path . 'eraser.png' );
        $remove_img = $cw->Photo( -file => $icon_path . 'remove.png' );
    }

    $cw->add_header( Edit => $list )->pack(@fx);

    my $balloon = $cw->Balloon( -state => 'balloon' );

    my $inst = $list->instance;

    my $value_type = $list->get_cargo_info('value_type');    # may be undef

    my $elt_button_frame =
      $cw->Frame(qw/-relief raised -borderwidth 2/)->pack(@fbe1);
    my $frame_title = $list->element_name;
    $frame_title .=
      ( defined $value_type and $value_type =~ /node/ ) ? 'elements' : 'values';
    $elt_button_frame->Label( -text => $frame_title )->pack();

    my $tklist = $elt_button_frame->Scrolled(
        'Listbox',
        -selectmode => 'single',
        -scrollbars => 'oe',
        -height     => 8,
    )->pack(@fbe1);

    $balloon->attach( $tklist,
        -msg => 'select an element and perform ' . 'an action on the right' );

    my $cargo_type = $list->cargo_type;
    my @insert =
        $cargo_type eq 'leaf'
      ? $list->fetch_all_values( check => 'no' )
      : $list->get_all_indexes;
    map { $_ = '<undef>' unless defined $_ } @insert;
    $tklist->insert( end => @insert );

    my $right_frame =
      $elt_button_frame->Frame->pack( @fxe1, qw/-side right -anchor n/ );

    $cw->ConfigModelNoteEditor( -object => $list )->pack;
    $cw->add_summary($list)->pack(@fx);
    $cw->add_description($list)->pack(@fx);
    $cw->add_info_button($cw)->pack(@fx);

    my $mv_rm_frame = $right_frame->Frame->pack(@fx);

    $mv_rm_frame->Button(
        -image   => $up_img,
        -command => sub { $cw->move_up; },
    )->pack( -side => 'left', @fxe1 );

    $mv_rm_frame->Button(
        -image   => $down_img,
        -command => sub { $cw->move_down; },
    )->pack( -side => 'left', @fxe1 );

    my $eraser_b = $mv_rm_frame->Button(
        -image   => $eraser_img,
        -command => sub { $cw->remove_selection; },
    )->pack( -side => 'left', @fxe1 );
    $balloon->attach( $eraser_b, -msg => 'Remove selected element from the list' );

    my $rm_all_b = $mv_rm_frame->Button(
        -image   => $remove_img,
        -command => sub {
            $list->clear;
            $tklist->delete( 0, 'end' );
            $cw->reload_tree;
        },
    )->pack( -side => 'left', @fxe1 );
    $balloon->attach( $rm_all_b, -msg => 'Remove all elements from the list' );

    if (    $cargo_type eq 'leaf'
        and $value_type ne 'enum'
        and $value_type ne 'reference' )
    {
        my $set_push_b_entry_frame = $right_frame->Frame( -borderwidth => 2, -relief => 'groove' )
            ->pack(@fxe1) ;
        my $user_value ;
        my $value_entry  = $set_push_b_entry_frame -> Entry (
            -textvariable => \$user_value, 
            -width => $entry_width
        ) ;

        my $set_push_b_frame = $set_push_b_entry_frame->Frame ->pack(@fxe1) ;

        $cw->add_set_entry ( $set_push_b_frame, $balloon, $tklist,\$user_value )->pack(@fxe1);
        $cw->add_push_entry( $set_push_b_frame, $balloon ,\$user_value)->pack(@fxe1);
        $cw->add_set_all_b ( $set_push_b_entry_frame, $set_push_b_frame, $balloon ,\$user_value)
            ->pack(@fxe1);

	$value_entry -> pack  (@fxe1) ;
    }
    else {
        my $elt_name = $list->element_name;
        my $disp     = "$elt_name ( $cargo_type ";
        $disp .= $list->config_class_name . ' )' if $cargo_type eq 'node';
        $disp .= " $value_type )" if defined $value_type;
        my $b = $right_frame->Button(
            -text    => "Push new $disp",
            -command => sub { $cw->push_entry(''); },
        )->pack(@fxe1);
        $balloon->attach( $b,
            -msg => "add a new $elt_name at the end of the list" );
    }


    $cw->{tklist} = $tklist;

    $cw->Tk::Frame::Populate($args);
}

sub add_set_entry {
    my ( $cw, $frame, $balloon, $tklist, $user_value_r ) = @_;

    my $set_item = '';
    my $set_sub = sub { $cw->set_entry($set_item); $set_item = ''; };

    my $set_b = $frame->Button(
        -text    => "set selected item",
        -command => $set_sub,
    )->pack( -side => 'left', @fxe1 );

    $balloon->attach( $set_b,
            -msg => 'enter a value, select an element on the left '
          . 'and click the button to replace the selected '
          . 'element with this value.' );

    my $b_sub = sub {
        my $idx = $tklist->curselection;
        $set_item = $tklist->get($idx) if $idx;
    };

    $tklist->bind( '<<ListboxSelect>>', $b_sub );

    return $set_b;
}

sub add_push_entry {
    my ( $cw, $frame, $balloon, $user_value_r ) = @_;

    my $push_item = '';
    my $push_sub  = sub { $cw->push_entry($push_item); $push_item = ''; };
    my $push_b    = $frame->Button(
        -text    => "push item",
        -command => $push_sub,
    )->pack( -side => 'left', @fxe1 );

    $balloon->attach( $push_b,
        -msg => 'enter a value, and click the push button to add '
          . 'this value at the end of the list' );
    return $push_b;
}

sub push_entry {
    my $cw = shift;
    my $add = shift;
    my $tklist = $cw->{tklist} ;
    my $list = $cw->{list};

    $logger->debug("push_entry: $add");

    my $cargo_type = $list->cargo_type ;
    my $value_type = $list->get_cargo_info('value_type') ; # may be undef
    if ($cargo_type eq 'leaf' and $value_type ne 'enum' and $value_type ne 'reference') {
	return unless $add;
	eval {$list->push($add) ;};
    }
    else {
	# create new item in list (may auto create node object)
	my @idx = $list -> get_all_indexes ;
	eval {$list->fetch_with_id(scalar @idx)} ;
    }

    if ($@) {
	$cw -> Dialog ( -title => "List index error with type $cargo_type",
			-text  => $@->as_string,
		      )
	  -> Show ;
    }
    else {
	# trigger redraw of Tk Tree
	$cw->reload_tree;
    }

    my @new_idx = $list->get_all_indexes ;
    $logger->debug("new list idx: ". join(',',@new_idx));

    my $insert = $add || $#new_idx ;
    $tklist->insert('end',$insert);

    return 1 ;
}

sub set_entry {
    my $cw =shift;
    my $data = shift ;

    my $tklist = $cw->{tklist} ;
    my $idx_ref = $tklist->curselection() ;
    return unless defined $idx_ref;
    return unless @$idx_ref ;

    my $idx = $idx_ref->[0] ;
    return unless $idx ;
    $tklist->delete($idx) ;
    $tklist->insert($idx, $data) ;
    $tklist->selectionSet($idx ) ;
    $cw->{list}->fetch_with_id($idx)->store($data) ;
    $cw->reload_tree ;
}

sub add_set_all_b {
    my ( $cw, $frame, $b_frame, $balloon, $user_value_r ) = @_;

    my $set_all_items = '';
    my $regexp        = '\s*,\s*';
    my $set_all_sub   = sub { $cw->set_all_items( $set_all_items, $regexp ); };

    #my $set_all_frame = $frame->Frame;
    #my $set_top       = $set_all_frame->Frame->pack(@fxe1);
    my $set_bottom    = $frame->Frame->pack(@fxe1, -side => 'bottom');

    my $set_b = $b_frame->Button(
        -text    => "set all",
        -command => $set_all_sub,
    )->pack( -side => 'left', @fx );

    $balloon->attach( $set_b,
        -msg => 'set all elements with a single string that '
          . 'will be split by the regexp displayed below' );

    my $split_lb = $set_bottom->Label( -text => 'split regexp' )
      ->pack( -side => 'left', @fxe1 );
    $set_bottom->Entry( -textvariable => \$regexp )
      ->pack( -side => 'left', @fxe1 );

    $balloon->attach( $split_lb,
        -msg => 'regexp used to split the entry above when "set all" button is pressed' 
        );

    return $set_bottom;
}

sub set_all_items {
    my $cw =shift;
    my $data = shift ;
    my $regexp = shift ;

    return unless $data ;
    my $tklist = $cw->{tklist} ;

    my @list = split /$regexp/,$data ;

    $tklist->delete(0,'end') ;
    $tklist->insert(0, @list) ;
    $cw->{list}->load_data(\@list) ;
    $cw->reload_tree ;
}


sub move_up {
    my $cw =shift;

    my $tklist = $cw->{tklist} ;
    my $from_idx_ref = $tklist->curselection() ;

    return unless defined $from_idx_ref;
    return unless @$from_idx_ref ;

    my $from_idx = $from_idx_ref->[0] ;
    return unless $from_idx ;
    return unless $from_idx > 0 ;

    $cw->swap($from_idx , $from_idx - 1) ;
}

sub move_down {
    my $cw =shift;

    my $tklist = $cw->{tklist} ;
    my $from_idx_ref = $tklist->curselection() ;

    return unless defined $from_idx_ref;
    return unless @$from_idx_ref ;

    my $from_idx = $from_idx_ref->[0] ;
    my $max_idx = $cw->{list}->fetch_size - 1;
    return unless $from_idx < $max_idx ;

    $cw->swap($from_idx , $from_idx + 1) ;
}

sub swap {
    my ($cw, $ida, $idb ) = @_ ;

    my $tklist = $cw->{tklist} ;

    my $list = $cw->{list};
    $list->swap($ida , $idb) ;

    my $cargo_type = $list->cargo_type ;

    $tklist->selectionClear($ida ) ;

    if ($cargo_type ne 'node') {
	my $old = $tklist->get($ida) ;
	$tklist->delete($ida) ;

	while ($idb > $tklist->size) {
	    $tklist->insert('end','<undef>') ;
	}
	$tklist->insert($idb, $old) ;
    }

    $tklist->selectionSet($idb ) ;
    $cw->reload_tree ;
}

sub remove_selection {
    my $cw = shift ;
    my $tklist = $cw->{tklist} ;
    my $list = $cw->{list};

    foreach ($tklist->curselection()) {
	$logger->debug( "remove_selection: removing index $_" );
	$list   -> remove($_) ;
	$cw->reload_tree ;
    }

    # redraw the list content
    $tklist -> delete(0,'end') ;
    my $cargo_type = $list->cargo_type ;
    my @insert = $cargo_type eq 'leaf' ? $list->fetch_all_values (check => 'no')
               :                         $list->get_all_indexes ;
    map { $_ = '<undef>' unless defined $_ } @insert ;
    $tklist->insert( end => @insert ) ;
}

sub reload_tree {
    my $cw = shift ;
    $cw->{store_cb}->() ;
}


1;
