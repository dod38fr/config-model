package Config::Model::Tk::HashEditor;

use strict;
use warnings;
use Carp;
use Log::Log4perl;

use base qw/Config::Model::Tk::HashViewer/;
use vars qw/$icon_path/;
use subs qw/menu_struct/;
use Tk::Dialog;
use Tk::Photo;
use Tk::Balloon;
use Config::Model::Tk::NoteEditor;

Construct Tk::Widget 'ConfigModelHashEditor';

my @fbe1   = qw/-fill both -expand 1/;
my @fxe1   = qw/-fill x    -expand 1/;
my @fx     = qw/-fill x    /;
my $logger = Log::Log4perl::get_logger("Tk::HashEditor");

my $entry_width = 15;

my (
    $up_img,     $down_img,   $add_img, $rm_img,
    $eraser_img, $remove_img, $rename_img, $copy_img
);
*icon_path = *Config::Model::TkUI::icon_path;

sub ClassInit {
    my ( $cw, $args ) = @_;

    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.

    # cw->Advertise(name=>$widget);
}

# list of widget that must be activated (0 in this table) when
# item is selected in listbox or entry is not empty

my %widget_activation_table = (
    add  => { tklist => 1, entry => 0 },
    mv   => { tklist => 0, entry => 0 },
    cp   => { tklist => 0, entry => 0 },
    up   => { tklist => 0, entry => 1 },
    down => { tklist => 0, entry => 1 },
    del  => { tklist => 0, entry => 1 },
);

sub Populate {
    my ( $cw, $args ) = @_;
    my $hash = $cw->{hash} = delete $args->{-item}
      || die "HashEditor: no -item, got ", keys %$args;
    delete $args->{-path};
    $cw->{store_cb} = delete $args->{-store_cb} || die __PACKAGE__,
      "no -store_cb";

    unless ( defined $up_img ) {
        $add_img    = $cw->Photo( -file => $icon_path . 'add.png' );
        $up_img     = $cw->Photo( -file => $icon_path . 'up.png' );
        $down_img   = $cw->Photo( -file => $icon_path . 'down.png' );
        $eraser_img = $cw->Photo( -file => $icon_path . 'eraser.png' );
        $remove_img = $cw->Photo( -file => $icon_path . 'remove.png' );
        $rename_img = $cw->Photo( -file => $icon_path . 'rotate_cw.png' );
        $copy_img   = $cw->Photo( -file => $icon_path . 'fontsizeup.png' );
    }

    $cw->add_header( Edit => $hash )->pack( @fx, -anchor => 'n' );

    my $inst = $hash->instance;

    # frame for element list
    my $elt_frame = $cw->Frame(qw/-relief raised -borderwidth 2/) ->pack( @fbe1 );

    $elt_frame->Label( -text => $hash->element_name . ' elements' )->pack(@fx);

    # element list
    my $tklist = $elt_frame->Scrolled(
        'Listbox',
        -selectmode => 'single',
        -scrollbars => 'oe',
        -height     => 6,
    );
    $tklist->pack( @fbe1, -side => 'left' );
    $tklist->insert( end => $hash->get_all_indexes );
    $cw->Advertise( tklist => $tklist );

    my $item_frame =
      $cw->Frame(qw/-borderwidth 1 -relief groove/)
      ->pack( @fx, -anchor => 'n' );

    my $balloon = $cw->Balloon( -state => 'balloon' );

    my $label_keep_frame = $item_frame->Frame->pack(@fxe1);
    my $item             = '';
    my $keep             = 0;
    $label_keep_frame->Label( -text => 'Item:' )
      ->pack( -side => 'left', -anchor => 'w' );

    # copy selected entry text into item (textvariable) when $keep is set
    my $keep_cb = sub {
        my $sel = $tklist->curselection;
        $item = $keep && $sel ? $tklist->get($sel) : '';
    };

    my $keep_b = $label_keep_frame->Checkbutton(
        -variable => \$keep,
        -command  => $keep_cb,
        -text     => 'keep'
    )->pack(qw/-side right -anchor e/);
    $balloon->attach( $keep_b,
        -msg => 'keep entry in widget after add, move or copy' );

    # Entry
    my $entry = $item_frame->Entry( -textvariable => \$item );
    $entry->pack( @fxe1, qw/-side top -anchor n/ );
    $balloon->attach( $entry,
        -msg => 'enter item name to add, copy to, or move to' );
    $cw->Advertise( entry => $entry );

    # bind both entries to update correctly the state of all buttons
    my $bound_sub = sub {
        $cw->update_state(
            entry  => $item,
            tklist => $tklist->curselection || 0
        );
    };
    $entry->bind( '<KeyPress>', $bound_sub );
    $entry->bind( '<B2-ButtonRelease>', $bound_sub );
    $tklist->bind( '<<ListboxSelect>>', $bound_sub );

    # frame for all buttons
    my $button_frame = $item_frame->Frame->pack( @fxe1, qw/-anchor n/ );

    # add button
    my $addb = $button_frame->Button(
        -image   => $add_img,
        -command => sub {
            $cw->add_entry($item);
            $item = '' unless $keep;
            &$bound_sub;
        },
    );
    $addb->pack( @fxe1, qw/-side left/ );
    $cw->Advertise( add => $addb );
    my $add_str = $hash->ordered ? " after selection" : '';
    $balloon->attach( $addb,
        -msg => "fill field above and click to add new entry" . $add_str );

    # copy button
    my $cp_b = $button_frame->Button(
        -image   => $copy_img,
        -command => sub {
            $cw->copy_selected_in($item);
            $item = '' unless $keep;
            &$bound_sub;
        },
    );
    $cp_b->pack(@fxe1,qw/-side right/);
    $cw->Advertise( @fxe1, cp => $cp_b );
    $balloon->attach( $cp_b, -msg => "copy selected item in entry" );

    # rename button
    my $rename_b = $button_frame->Button(
        -image   => $rename_img,
        -command => sub {
            $cw->move_selected_to($item);
            $item = '' unless $keep;
            &$bound_sub,;
        },
    );
    $rename_b->pack( @fxe1, -side => 'left' );
    $cw->Advertise( mv => $rename_b );
    $balloon->attach( $rename_b, -msg => "rename selected key in entry" );

    if ( $hash->ordered ) {
         my $up_b = $button_frame->Button(
            -image   => $up_img,
            -command => sub { $cw->move_selected_up; },
        );

        my $down_b = $button_frame->Button(
            -image   => $down_img,
            -command => sub { $cw->move_selected_down; },
        );
        $up_b->pack( -side => 'left', @fxe1 );
        $down_b->pack( -side => 'left', @fxe1 );

        $cw->Advertise( up   => $up_b );
        $cw->Advertise( down => $down_b );
    }

    my $eraser_b = $button_frame->Button(
        -image   => $eraser_img,
        -command => sub {
            $cw->delete_selection;
            $item = '' unless $keep;
            &$bound_sub;
        },
    );
    $balloon->attach( $eraser_b, -msg => 'Remove selected key' );
    $eraser_b->pack( -side => 'left', @fxe1 );
    $cw->Advertise( del => $eraser_b );

    my $rm_all_b = $button_frame->Button(
        -image   => $remove_img,
        -command => sub { $cw->remove_all_elements; $item = ''; },
    )->pack( -side => 'left', @fxe1 );
    $balloon->attach( $rm_all_b, -msg => 'Remove all keys' );

    $cw->ConfigModelNoteEditor( -object => $hash )->pack(qw/-anchor n/);

    # set all buttons to their default state
    $cw->update_state( tklist => '', entry => '' );

    $cw->add_warning( $hash, 'edit' )->pack(@fx);
    $cw->add_info_button()->pack( @fx, qw/-anchor n/ );
    $cw->add_summary($hash)->pack(@fx);
    $cw->add_description($hash)->pack(@fx);

    $cw->Tk::Frame::Populate($args);
}

sub remove_all_elements {
    my $cw     = shift;
    my $dialog = $cw->Dialog(
        -title          => "Delete ?",
        -text           => "Are you sure you want to delete all elements ?",
        -buttons        => [qw/Yes No/],
        -default_button => 'Yes',
    );
    my $answer = $dialog->Show;
    return unless $answer eq 'Yes';
    $cw->{hash}->clear;
    $cw->Subwidget('tklist')->delete( 0, 'end' );
    $cw->reload_tree();
}

# update buttons state according to entry and list widget
# this method is called whenever one of them changes its content
sub update_state {
    my ( $cw, %content ) = @_;

    my $wat = \%widget_activation_table;

    foreach my $button ( keys %$wat ) {
        my $new = 1;
        foreach my $c ( keys %content ) {
            $new &&= $wat->{$button}{$c} || $content{$c};
        }
        my $subwidget = $cw->Subwidget($button) || next;
        $subwidget->configure( -state => $new ? 'normal' : 'disabled' );
    }
}

sub add_entry {
    my $cw     = shift;
    my $add    = shift;
    my $tklist = $cw->Subwidget('tklist');
    my $hash   = $cw->{hash};

    $logger->debug("add_entry: $add");

    if ( $hash->exists($add) ) {
        $cw->Dialog(
            -title => "Add item error",
            -text  => "Entry $add already exists",
        )->Show();
        return 0;
    }

    # add entry in hash
    eval { $hash->fetch_with_id($add) };

    if ($@) {
        $cw->Dialog(
            -title => 'Hash index error',
            -text  => $@->as_string,
        )->Show;
        return 0;
    }

    $logger->debug( "new hash idx: " . join( ',', $hash->get_all_indexes ) );

    # ensure correct order for ordered hash
    my @selected = $tklist->curselection();

    $tklist->selectionClear( 0, 'end' );

    if ( @selected and $hash->ordered ) {
        my $idx = $tklist->get( $selected[0] );
        $logger->debug("add_entry on ordered hash: swap $idx and $add");
        $hash->move_after( $add, $idx );
        $logger->debug(
            "new hash idx: " . join( ',', $hash->get_all_indexes ) );
        my $new_idx = $selected[0] + 1;
        $tklist->insert( $new_idx, $add );
        $tklist->selectionSet($new_idx);
        $tklist->see($new_idx);
    }
    elsif ( $hash->ordered ) {

        # without selection on ordered hash, items are simply pushed
        $tklist->insert( 'end', $add );
        $tklist->selectionSet('end');
        $tklist->see('end');
    }
    else {
        $cw->add_and_sort_item($add);
    }

    # trigger redraw of Tk Tree
    $cw->reload_tree;
    return 1;
}

sub add_and_sort_item {
    my $cw  = shift;
    my $add = shift;

    my $tklist = $cw->Subwidget('tklist');
    my $idx    = 0;
    my $added  = 0;

    $tklist->selectionClear( 0, 'end' );
    foreach ( $tklist->get( 0, 'end' ) ) {
        if ( $add lt $_ ) {
            $tklist->insert( $idx, $add );
            $tklist->selectionSet($idx);
            $tklist->see($idx);
            $added = 1;
            last;
        }
        $idx++;
    }

    if ( not $added ) {
        $tklist->insert( 'end', $add );    # last entry
        $tklist->selectionSet('end');
        $tklist->see('end');
    }
}

sub add_item {
    my $cw  = shift;
    my $add = shift;

    my $hash   = $cw->{hash};
    my $tklist = $cw->Subwidget('tklist');

    # add entry in tklist
    if ( $hash->ordered ) {
        $logger->debug("add_item: adding $add in ordered hash");
        $tklist->selectionClear( 0, 'end' );
        $tklist->insert( 'end', $add );
        $tklist->selectionSet('end');
        $tklist->see('end');
    }
    else {

        # add the item so that items are ordered alphabetically
        $logger->debug("add_item: adding $add in plain hash");
        $cw->add_and_sort_item($add);
    }
}

sub get_selection {
    my $cw       = shift;
    my $what     = shift;
    my $tklist   = $cw->Subwidget('tklist');
    my @from_idx = $tklist->curselection();
    if ( not @from_idx ) {
        $cw->Dialog(
            -title => "$what selection error",
            -text  => " Please select an item to $what",
        )->Show();
    }
    return @from_idx;
}

sub copy_selected_in {
    my $cw        = shift;
    my $to_name   = shift;
    my $tklist    = $cw->Subwidget('tklist');
    my @from_idx  = $cw->get_selection('copy') or return 0;
    my $from_name = $tklist->get(@from_idx);

    if ( $from_name eq $to_name ) {
        $cw->Dialog(
            -title => "copy item error",
            -text  => "Cannot copy in the same item ($to_name)",
        )->Show();
        return 0;
    }

    my $hash = $cw->{hash};

    my $new_idx = $hash->exists($to_name) ? 0 : 1;
    $logger->debug(
        "copy_selected_to: from $from_name to $to_name (is new index: $new_idx)"
    );
    $hash->copy( $from_name, $to_name );

    if ($new_idx) {
        $logger->debug("copy_selected_to: add_item $to_name");
        $cw->add_item($to_name);
    }

    $cw->reload_tree;
}

sub move_selected_to {
    my $cw        = shift;
    my $to_name   = shift;
    my $tklist    = $cw->Subwidget('tklist');
    my @from_idx  = $cw->get_selection('move') or return 0;
    my $from_name = $tklist->get(@from_idx);

    if ( $from_name eq $to_name ) {
        $cw->Dialog(
            -title => "move item error",
            -text  => "Cannot move in the same item ($to_name)",
        )->Show();
        return 0;
    }

    $logger->debug("move_selected_to: from $from_name to $to_name");
    my $hash = $cw->{hash};
    $tklist->delete(@from_idx);

    my $new_idx = $hash->exists($to_name) ? 0 : 1;
    $hash->move( $from_name, $to_name );

    if ($new_idx) {
        if ( $hash->ordered ) {
            $tklist->selectionClear( 0, 'end' );
            $tklist->insert( $from_idx[0], $to_name );
            $tklist->selectionSet( $from_idx[0] );
        }
        else {

            # add the item so that items are ordered alphabetically
            $cw->add_and_sort_item($to_name);
        }
    }

    $cw->reload_tree;
}

sub move_selected_up {
    my $cw     = shift;
    my $tklist = $cw->Subwidget('tklist');
    my @idx    = $tklist->curselection();

    return unless @idx and $idx[0] > 0;

    my $name = $tklist->get(@idx);

    $logger->debug("move_selected_up: $name (@idx)");
    $tklist->delete(@idx);
    my $new_idx = $idx[0] - 1;
    $tklist->insert( $new_idx, $name );
    $tklist->selectionSet($new_idx);
    $tklist->see($new_idx);

    my $hash = $cw->{hash};
    $hash->move_up($name);
    $logger->debug(
        "move_up new hash idx: " . join( ',', $hash->get_all_indexes ) );

    $cw->reload_tree;
}

sub move_selected_down {
    my $cw     = shift;
    my $tklist = $cw->Subwidget('tklist');
    my @idx    = $tklist->curselection();
    my $hash   = $cw->{hash};
    my @h_idx  = $hash->get_all_indexes;

    return unless @idx and $idx[0] < $#h_idx;

    my $name = $tklist->get(@idx);

    $logger->debug("move_selected_down: $name (@idx)");
    $tklist->delete(@idx);
    my $new_idx = $idx[0] + 1;
    $tklist->insert( $new_idx, $name );
    $tklist->selectionSet($new_idx);
    $tklist->see($new_idx);

    $hash->move_down($name);
    $logger->debug(
        "move_down new hash idx: " . join( ',', $hash->get_all_indexes ) );

    $cw->reload_tree;
}

sub delete_selection {
    my $cw     = shift;
    my $tklist = $cw->Subwidget('tklist');
    my $hash   = $cw->{hash};

    foreach ( $tklist->curselection() ) {
        my $idx = $tklist->get($_);
        $hash->delete($idx);
        $tklist->delete($_);
        $cw->reload_tree;
    }
}

sub reload_tree {
    my $cw = shift;
    $cw->update_warning( $cw->{hash} );
    $cw->{store_cb}->();
}

1;
