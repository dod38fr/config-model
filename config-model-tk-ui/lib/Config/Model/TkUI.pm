# $Author$
# $Date$
# $Revision$

package Config::Model::TkUI ;

use strict;
use warnings ;
use Carp ;

use base qw/Tk::Toplevel/;
use vars qw/$VERSION $icon_path $warn_img/ ;
use subs qw/menu_struct/ ;
use Scalar::Util qw/weaken/;
use Log::Log4perl;

use Tk::Photo ;
use Tk::PNG ; # required for Tk::Photo to be able to load pngs
use Tk::DialogBox ;

require Tk::ErrorDialog;

use Config::Model::Tk::LeafEditor ;
use Config::Model::Tk::CheckListEditor ;

use Config::Model::Tk::LeafViewer ;
use Config::Model::Tk::CheckListViewer ;

use Config::Model::Tk::ListViewer ;
use Config::Model::Tk::ListEditor ;

use Config::Model::Tk::HashViewer ;
use Config::Model::Tk::HashEditor ;

use Config::Model::Tk::NodeViewer ;
use Config::Model::Tk::NodeEditor ;

use Config::Model::Tk::Wizard ;


$VERSION = '1.301' ;

Construct Tk::Widget 'ConfigModelUI';

my $cust_img ;
my $tool_img ;

my $mod_file = 'Config/Model/TkUI.pm' ;
$icon_path = $INC{$mod_file} ;
$icon_path =~ s/TkUI.pm//;
$icon_path .= 'Tk/icons/' ;

my $logger = Log::Log4perl::get_logger(__PACKAGE__);

sub ClassInit {
    my ($class, $mw) = @_;
    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.


    # cw->Advertise(name=>$widget);
}

sub Populate { 
    my ($cw, $args) = @_;

    unless (defined $warn_img) {
	$warn_img = $cw->Photo(-file => $icon_path.'stop.png');
	$cust_img = $cw->Photo(-file => $icon_path.'next.png');
	# snatched from openclipart-png
	$tool_img = $cw->Photo(-file => $icon_path.'tools_nicu_buculei_01.png');
    }

    foreach my $parm (qw/-root/) {
	my $attr = $parm ;
	$attr =~ s/^-//;
	$cw->{$attr} = delete $args->{$parm} 
	  or croak "Missing $parm arg\n";
    }

    foreach my $parm (qw/-store_sub -quit/) {
	my $attr = $parm ;
	$attr =~ s/^-//;
	$cw->{$attr} = delete $args->{$parm} ;
    }

    $cw->{experience} = delete $args->{'-experience'} || 'beginner' ;
    my $extra_menu = delete $args->{'-extra-menu'} || [] ;

    my $title = delete $args->{'-title'} 
              || "config-edit ".$cw->{root}->config_class_name ;

    # check unknown parameters
    croak "Unknown parameter ",join(' ',keys %$args) if %$args;

    # initialize internal attributes
    $cw->{location} = '';
    $cw->{modified_data} = 0;

    $cw->setup_scanner() ;

    # create top menu
    require Tk::Menubutton ;
    my $menubar = $cw->Menu ;
    $cw->configure(-menu => $menubar ) ;
    $cw->{my_menu} = $menubar ;

    my $file_items = [[ qw/command wizard -command/, sub{ $cw->wizard }],
		      [ qw/command reload -command/, sub{ $cw->reload }],
		      [ qw/command check  -command/, sub{ $cw->check(1)}],
		      [ qw/command save   -command/, sub{ $cw->save }],
		      [ command => 'save in dir ...',
                        -command => sub{ $cw->save_in_dir ;} ],
		      @$extra_menu ,
		      [ command => 'debug ...',
                        -command => sub{ require Tk::ObjScanner; 
					 Tk::ObjScanner::scan_object($cw->{root});}],
		      [ qw/command quit   -command/, sub{ $cw->quit }],
		     ] ;
    $menubar->cascade( -label => 'File', -menuitems => $file_items ) ; 

    $cw->add_help_menu($menubar) ;

    my $edit_items = [
		      # [ qw/command cut   -command/, sub{ $cw->edit_cut }],
		      [ qw/command copy  -command/, sub{ $cw->edit_copy }],
		      [ qw/command paste -command/, sub{ $cw->edit_paste }],
		     ];
    $menubar->cascade( -label => 'Edit', -menuitems => $edit_items ) ; 

    my $exp_ref = $cw->{scanner}->get_experience_ref ;
    $cw->{exp_ref} = $exp_ref ;
    $$exp_ref = $cw->{experience} ;

    my $exp_items = [
		      map {['radiobutton',$_,'-variable', $exp_ref,
			    -command => sub{$cw->reload ;} 
			   ] }
		          qw/master advanced beginner/
		     ] ;
    my $opt_items = [[qw/cascade experience -menuitems/, $exp_items ]] ;
    $menubar->cascade( -label => 'Options', -menuitems => $opt_items ) ; 


    # create frame for location entry 
    my $loc_frame = $cw -> Frame (-relief => 'sunken', -borderwidth => 1)
                        -> pack  (-pady => 0,  -fill => 'x' ) ;
    $loc_frame->Label(-text => 'location :') -> pack ( -side => 'left');
    $loc_frame->Label(-textvariable => \$cw->{location}) -> pack ( -side => 'left');

    # add bottom frame 
    my $bottom_frame = $cw->Frame 
      ->pack  (qw/-pady 0 -fill both -expand 1/ ) ;

    # create the widget for tree navigation 
    require Tk::Tree;
    my $tree = $bottom_frame 
      -> Scrolled ( qw/Tree/,
		    -columns => 4,
		    -header  => 1,
		    -browsecmd => sub{$cw->on_browse(@_) ;},
		    -command   => sub{$cw->on_select(@_) ;},
		    -opencmd   => sub{$cw->open_item(@_) ;},
		  )
      -> pack ( qw/-fill both -expand 1 -side left/) ;
    $cw->{tktree} = $tree ;

    # add adjuster
    require Tk::Adjuster;
    $bottom_frame -> Adjuster()->packAfter($tree, -side => 'left') ;

    # add headers
    $tree -> headerCreate(0, -text => "element" ) ;
    $tree -> headerCreate(1, -text => "status" ) ;
    $tree -> headerCreate(2, -text => "value" ) ;
    $tree -> headerCreate(3, -text => "standard value" ) ;

    $cw->reload ;

    # add frame on the right for entry and help
    my $eh_frame = $bottom_frame -> Frame -> pack (qw/-fill both -expand 1 -side left/) ;
    $cw->{eh_frame} = $eh_frame ;

    # add entry frame, filled by call-back
    # should be a composite widget
    $cw->{e_frame} = $eh_frame -> Frame 
      -> pack (qw/-side top -fill both -expand 1/) ;
    $cw->{e_frame} ->Label(#-text => "placeholder",
			   -image => $tool_img,
			   -width => 400, # width in pixel for image
			  ) -> pack(-side => 'top') ;
    $cw->{e_frame} ->Button(-text => "Run Wizard !",
			    -command => sub { $cw->wizard}
			  ) -> pack(-side => 'bottom') ;

    # bind button3 as double-button-1 does not work
    my $b3_sub = sub{my $item = $tree->nearest($tree->pointery - $tree->rooty) ;
		     $cw->on_select($item)} ;
    $tree->bind('<Button-3>', $b3_sub) ;

    $args->{-title} = $title;
    $cw->SUPER::Populate($args) ;

    $cw->ConfigSpecs
      (
       #-background => ['DESCENDANTS', 'background', 'Background', $background],
       #-selectbackground => [$hlist, 'selectBackground', 'SelectBackground', 
       #                      $selectbackground],
       -width  => [$tree, undef, undef, 60],
       -height => [$tree, undef, undef, 20],
       -selectmode => [ $tree, 'selectMode' ,'SelectMode', 'single' ], #single',
       #-oldcursor => [$hlist, undef, undef, undef],
       DEFAULT => [$tree]
      ) ;

    $cw->Advertise(tree => $tree,
		   menubar => $menubar,
		   ed_frame => $cw->{e_frame} ,
		  );

}

my $help_text = << 'EOF' ;

Tree usage (left hand side of widget)

* Click on '+' and '-' boxes to open or close content
* Left-click on item to open a viewer widget.
* Right-click on any item to open an editor widget

Editor widget usage

When clicking on store, the new data is stored in the tree represented
on the left side of TkUI. The new data will be stored in the
configuration file only when "File->save" menu is invoked.

Copy'n'paste

You copy and paste content from one part of the tree to
another. Beware, there's no "undo" operation.

EOF

my $todo_text = << 'EOF' ;
- add better navigation
- add tabular view ?
- improve look and feel
- add search element or search value
- expand the whole tree at once
- add plug-in mechanism so that dedicated widget
  can be used for some config Class (Could be handy for 
  Xorg::ServerLayout)
EOF

sub add_help_menu {
    my ($cw,$menubar) = @_ ;

    my $about_sub = sub {
	$cw->Dialog(-title => 'About',
		    -text => "Config::Model::TkUI \n"
		    ."(c) 2008-2009 Dominique Dumont \n"
		    ."Licensed under LGPLv2\n"
		   ) -> Show ;
    };

    my $todo_sub = sub {
	my $db = $cw->DialogBox( -title => 'TODO');
	my $text = $db -> add('ROText')->pack ;
	$text ->insert('end',$todo_text) ;
	$db-> Show ;
    };

    my $help_sub = sub{
	my $db = $cw->DialogBox( -title => 'help');
	my $text = $db -> add('ROText')->pack ;
	$text ->insert('end',$help_text) ;
	$db-> Show ;
    };

    my $help_items = [[ qw/command About -command/, $about_sub ],
		      [ qw/command Todo  -command/, $todo_sub  ],
		      [ qw/command Usage -command/, $help_sub  ],
		     ] ;
    $menubar->cascade( -label => 'Help', -menuitems => $help_items ) ; 
}

# Note: this callback is called by Tk::Tree *before* changing the
# indicator. And the indicator is used by Tk::Tree to store the
# open/close/none mode. So we can't rely on getmode for path that are
# opening. HEnce the parameter passed to the sub stored with each
# Tk::Tree item
sub open_item {
    my ($cw,$path) = @_ ;
    my $tktree = $cw->{tktree} ;
    $logger->trace( "open_item on $path" );
    my $data = $tktree -> infoData($path);

    # invoke the scanner part (to create children)
    # the parameter indicates that we are opening this path
    $data->[0]->(1) ;

    my @children = $tktree->infoChildren($path) ;
    $logger->trace( "open_item show @children" );
    map { $tktree->show (-entry => $_); } @children ;
}

sub save_in_dir {
    my $cw = shift ;
    require Tk::DirSelect ; 
    $cw->{save_dir} = $cw->DirSelect()->Show ;
    # chooseDirectory does not work correctly.
    #$cw->{save_dir} = $cw->chooseDirectory(-mustexist => 'no') ;
    $cw->save() ;
}

sub check {
    my $cw = shift ;
    my $show = shift || 0 ;

    # first check for errors, will die on errors
    eval { $cw->{root}->dump_tree(auto_vivify => 1, full_dump => 1) } ;

    if ($@) {
	$cw->handle_error($@) ;
    } 
    elsif ($show) {
	$cw->Dialog(-title => 'Check',
		    -text => "No errors found"
		   ) -> Show ;
    }
}

sub handle_error {
    my $cw = shift;
    my $e_obj = shift ;
    my $mode = shift || '' ;

    my @buttons = qw/ok/ ;

    my $conf_obj = $e_obj->object ;
    push @buttons, 'edit' if defined $conf_obj ;

    push @buttons, 'trace' unless $mode eq 'trace' ;

    my $d = $cw->DialogBox(-title => 'Error',
			   -buttons => \@buttons,
			  ) ;

    if ($mode eq 'trace') {
	my $t = $d->add('ROText') -> pack;
	$t->insert(end => $e_obj->trace->as_string);
    }
    else {
	$d->add('Label',
		-text => $e_obj-> as_string ) -> pack ;
    }

    my $answer = $d -> Show ;

    if ($answer eq 'trace') {
	$cw->handle_error($e_obj,$answer) ;
    }
    elsif ($answer eq 'edit') {
	$cw->force_element_display($conf_obj) ;
    }
}

sub save {
    my $cw = shift ;

    my $dir = $cw->{save_dir} ;
    my $trace_dir = defined $dir ? $dir : 'default' ;
    my @wb_args =  defined $dir ? (config_dir => $dir) : () ;

    $cw->check() ;

    if (defined $cw->{store_sub}) {
	$logger->info( "Saving data in $trace_dir directory with store call-back" );
	$cw->{store_sub}->($dir) ;
    }
    else {
	$logger->info( "Saving data in $trace_dir directory with instance write_back" );
	$cw->{root}->instance->write_back(@wb_args);
    }
    $cw->{modified_data} = 0 ;
}

sub save_if_yes {
    my $cw =shift ;
    my $text = shift || "Save data ?" ;

    if ($cw->{modified_data}) {
	my $answer = $cw->Dialog(-title => "quit",
				 -text  => $text,
				 -buttons => [ qw/yes no/],
				 -default_button => 'yes',
				)->Show ;
	$cw->save if $answer eq 'yes';
    }
}

sub quit {
    my $cw = shift ;

    $cw->save_if_yes ;

    if (defined $cw->{quit} and $cw->{quit} eq 'soft') {
	$cw->destroy ;
    }
    else {
	# destroy main window to exit Tk Mainloop;
	$cw->parent->destroy ;
    }
}

sub reload {
    my $cw =shift ;
    my $is_modif          = shift || 0; # whether values where modified
    my $force_display_obj = shift ;     # force open editor
    my $path              = shift ;     # force tree to show this path

    $logger->trace("reloading tk tree".
		   (defined $force_display_obj ? " (forcedisplay)" : '' )
		  ) ;

    my $tree = $cw->{tktree} ;
    $cw->{modified_data} = 1 if $is_modif ;

    my $instance_name = $cw->{root}->instance->name ;

    my $new_drawing = not $tree->infoExists($instance_name) ;

    my $sub 
      = sub {$cw->{scanner}->scan_node([$instance_name,$cw,@_],$cw->{root}) ;};

    if ($new_drawing) {
	$tree->add($instance_name, -data => [ $sub,  $cw->{root} ]);
	$tree->itemCreate( $instance_name, 0,
			   -text => $instance_name , 
			 ); 
	$tree->setmode($instance_name,'close') ;
	$tree->open($instance_name) ;
    }

    # the first parameter indicates that we are opening the root
    $sub->(1,$force_display_obj) ; 
    $tree->see($path) if $path and $tree->info(exists => $path);
    $cw->{editor}->reload if defined $cw->{editor};
}

# call-back when Tree element is selected
sub on_browse {
    my ($cw,$path) = @_ ;
    $cw->update_loc_bar($path) ;
    $cw->create_element_widget('view') ;
}

sub update_loc_bar {
    my ($cw,$path) = @_ ;
    #$cw->{path}=$path ;
    my $datar = $cw->{tktree}->infoData($path) ;
    my $obj = $datar->[1] ;
    $cw->{location} = $obj->location;
}

sub on_select {
    my ($cw,$path) = @_ ;
    $cw->update_loc_bar($path) ;
    $cw->create_element_widget('edit') ;
}


# replace dot in str by _|_
sub to_path   { my $str  = shift ; $str  =~ s/\./_|_/g; return $str ;}
sub from_path { my $path = shift ; $path =~ s/_|_/./g ; return $path; }

sub force_element_display {
    my $cw   = shift ;
    my $elt_obj = shift ;

    $logger->trace( "force display of ".$elt_obj->location );
    $cw->reload(0, $elt_obj) ;
}

sub prune {
    my $cw = shift ;
    my $path = shift ;
    $logger->trace( "prune $path" );
    my %list = map { "$path." . to_path($_) => 1 } @_ ;
    # remove entries that are not part of the list
    my $tkt = $cw->{tktree} ;

    map { 
	$tkt->deleteEntry($_) if $_ and not defined $list{$_} ;
    }  $tkt -> infoChildren($path) ;
    $logger->trace( "prune $path done" );
}

# Beware: TkTree items store tree object and not tree cds path. These
# object might become irrelevant when warp master values are
# modified. So the whole Tk Tree layout must be redone very time a
# config value is modified. This is a bit heavy, but a smarter
# alternative would need hooks in the configuration tree to
# synchronise the Tk Tree with the configuration tree :-p

my %elt_mode = ( leaf => 'none',
		 hash => 'open',
		 list => 'open',
		 node => 'open',
		 check_list => 'none',
		 warped_node => 'open',
	       );

sub disp_obj_elt {
    my ($scanner, $data_ref,$node,@element_list) = @_ ;
    my ($path,$cw,$opening,$fdp_obj) = @$data_ref ;
    my $tkt = $cw->{tktree} ;
    my $mode = $tkt -> getmode($path) ;
    $logger->trace("disp_obj_elt path $path mode $mode opening $opening "
		   ."(@element_list)" );

    $cw->prune($path,@element_list) ;

    my $node_loc = $node->location ;

    my $prevpath = '' ;
    foreach my $elt (@element_list) { 
	my $newpath = "$path." . to_path($elt) ;
	my $scan_sub = sub { 
	    $scanner->scan_element([$newpath,$cw,@_], $node,$elt) ;
	} ;
	my @data = ( $scan_sub, $node -> fetch_element($elt) );

	# It's necessary to store a weakened reference of a tree
	# object as these ones tend to disappear when warped out. In
	# this case, the object must be destroyed. This does not
	# happen if a non-weakened reference is kept in Tk Tree.
	weaken( $data[1] );

	my $elt_type = $node->element_type($elt) ;
	my $eltmode = $elt_mode{$elt_type};
	if ($tkt->infoExists($newpath)) {
	    $eltmode = $tkt->getmode($newpath); # will reuse mode below
	}
	else {
	    my @opt = $prevpath ? (-after => $prevpath) : (-at => 0 ) ;
	    $logger->trace( "disp_obj_elt add $newpath mode $eltmode type $elt_type" );
	    $tkt -> add($newpath, -data => \@data, @opt) ;
	    $tkt -> itemCreate($newpath,0, -text => $elt) ;
	    $tkt -> setmode($newpath => $eltmode) ;
	}

	my $elt_loc = $node_loc ? $node_loc.' '.$elt : $elt ;

	$cw->setmode('node',$newpath,$eltmode,$elt_loc,$fdp_obj,$opening,$scan_sub) ;

	$prevpath = $newpath ;
    } ;
}

sub disp_hash {
    my ($scanner, $data_ref,$node,$element_name,@idx) = @_ ;
    my ($path,$cw,$opening,$fdp_obj) = @$data_ref ;
    my $tkt = $cw->{tktree} ;
    my $mode = $tkt -> getmode($path) ;
    $logger->trace( "disp_hash    path is $path  mode $mode (@idx)" );

    $cw->prune($path,@idx) ;

    my $elt = $node -> fetch_element($element_name) ;
    my $elt_type = $elt->get_cargo_type();

    my $node_loc = $node->location ;

    my $prevpath = '' ;
    my $idx_nb = 0 ; # used to keep track of tktree item order
    foreach my $idx (@idx) {
	my $newpath = $path.'.'. to_path($idx) ;
	my $scan_sub = sub {
	    $scanner->scan_hash([$newpath,$cw,@_],$node, $element_name,$idx);
	};

	my $eltmode = $elt_mode{$elt_type};

	if ($tkt->infoExists($newpath) ) {
	    my $previous_data = $tkt->info(data => $newpath);
	    my $previous_idx_nb = $previous_data->[2] ;
	    $eltmode = $tkt->getmode($newpath); # will reuse mode below
	    if ($idx_nb != $previous_idx_nb) {
		$logger->trace( "disp_hash delete $newpath mode $eltmode (got "
				.$previous_idx_nb
				." expected $idx_nb)" );
		# wrong order, delete the entry
		$tkt->delete(entry => $newpath) ;
	    }
	}

	if (not $tkt->infoExists($newpath)) {
	    my @opt = $prevpath ? (-after => $prevpath) : (-at => 0 ) ;
	    $logger->trace( "disp_hash add $newpath mode $eltmode cargo_type $elt_type" );
	    my @data = ( $scan_sub, $elt->fetch_with_id($idx), $idx_nb );
	    weaken($data[1]) ;
	    $tkt->add($newpath, -data => \@data, @opt) ;
	    $tkt->itemCreate($newpath,0, -text => $idx ) ;
	    $tkt -> setmode($newpath => $eltmode) ;
	}

	my $elt_loc = $node_loc ;
	$elt_loc .=' ' if $elt_loc;
	$elt_loc .= $element_name.':'.($idx =~ / / ? '"'.$idx.'"' : $idx);

	# hide new entry if hash is not yet opened
	$cw->setmode('hash',$newpath,$eltmode,$elt_loc,$fdp_obj,$opening,$scan_sub) ;

	$prevpath = $newpath ;
	$idx_nb++ ;
    } ;
}

sub setmode {
    my ($cw,$type,$newpath,$eltmode,$elt_loc,$fdp_obj,$opening,$scan_sub) = @_ ;
    my $tkt = $cw->{tktree} ;

    my $fdp = defined $fdp_obj ? $fdp_obj->location : '';

    my $force_open  = ($fdp and index($fdp,$elt_loc) == 0) ? 1 : 0 ; 
    my $force_match = ($fdp and $fdp eq $elt_loc )         ? 1 : 0;

    $logger->trace("$type: elt_loc '$elt_loc', opening $opening "
		   ."eltmode $eltmode force_open $force_open "
		   . ($fdp ? "on $fdp" : '' ) 
		  ) ;

    if ($eltmode ne 'open' or $force_open or $opening ) {
	$tkt->show( -entry => $newpath);
	# counter-intuitive: want to display [-] if force opening and not leaf item
	$tkt -> setmode($newpath => 'close') if($force_open and $eltmode ne 'none');
    }
    else {
	$tkt->close($newpath) ;
    }

    # counterintuitive but right: scan will be done when the entry
    # is opened. mode can be open, close, none
    $scan_sub->($force_open,$fdp_obj) if ( ($eltmode ne 'open') or $force_open) ; 

    if ($force_match) {
	$tkt->see($newpath);
	$tkt->selectionSet($newpath) ;
	$cw->update_loc_bar($newpath) ;
	$cw->create_element_widget('edit',$newpath) ;
    }
}

sub trim_value {
    my $cw = shift ;
    my $value = shift ;

    return undef unless defined $value ;

    $value =~ s/\n/ /g;
    $value = substr($value,0,15) . '...' if length($value) > 15;
    return $value;
}

sub disp_check_list {
    my ($scanner, $data_ref,$node,$element_name,$index, $leaf_object) =@_;
    my ($path,$cw,$opening,$fdp_obj) = @$data_ref ;
    $logger->trace( "disp_check_list    path is $path" );

    my $value = $leaf_object->fetch ;

    $cw->{tktree}->itemCreate($path,2,-text => $cw->trim_value($value)) ;

    my $std_v = $leaf_object->fetch('standard') ;
    $cw->{tktree}->itemCreate($path,3, -text => $cw->trim_value($std_v)) ;
}

sub disp_leaf {
    my ($scanner, $data_ref,$node,$element_name,$index, $leaf_object) =@_;
    my ($path,$cw,$opening,$fdp_obj) = @$data_ref ;
    $logger->trace( "disp_leaf    path is $path" );

    my $std_v = $leaf_object->fetch('standard') ;
    my $value = $leaf_object->fetch_no_check ;
    my $tkt = $cw->{tktree} ;

    my $img ;
    {
	no warnings qw/uninitialized/ ;
	$img = $cust_img if (defined $value and $std_v ne $value) ;
	$img = $warn_img unless $leaf_object->check($value) ;
    }

    if (defined $img) {
	$tkt->itemCreate($path,1,
			 -itemtype => 'image' , 
			 -image => $img
			) ;
    }
    else {
	# remove image when value is identical to standard value
	$tkt->itemDelete($path,1) if $tkt->itemExists($path,1) ;
    }

    $tkt->itemCreate($path,2, -text => $cw->trim_value($value)) ;

    $tkt->itemCreate($path,3, -text => $std_v) ;
}

sub disp_node {
    my ($scanner, $data_ref,$node,$element_name,$key, $contained_node) = @_;
    my ($path,$cw,$opening,$fdp_obj) = @$data_ref ;
    $logger->trace( "disp_node    path is $path" );
    my $curmode = $cw->{tktree}->getmode($path);
    $cw->{tktree}->setmode($path,'open') if $curmode eq 'none';

    # explore next node 
    $scanner->scan_node($data_ref,$contained_node);
}


sub setup_scanner {
    my ($cw) = @_ ;
    require Config::Model::ObjTreeScanner ;

    my $scanner = Config::Model::ObjTreeScanner->new 
      (

       fallback => 'node',
       experience => 'master', #'beginner', 

       # node callback
       node_content_cb       => \&disp_obj_elt ,

       # element callback
       list_element_cb       => \&disp_hash    ,
       check_list_element_cb => \&disp_check_list ,
       hash_element_cb       => \&disp_hash    ,
       node_element_cb       => \&disp_node     ,

       # leaf callback
       leaf_cb               => \&disp_leaf,
       enum_value_cb         => \&disp_leaf,
       integer_value_cb      => \&disp_leaf,
       number_value_cb       => \&disp_leaf,
       boolean_value_cb      => \&disp_leaf,
       string_value_cb       => \&disp_leaf,
       uniline_value_cb      => \&disp_leaf,
       reference_value_cb    => \&disp_leaf,

       # call-back when going up the tree
       up_cb                 => sub {} ,
      ) ;

    $cw->{scanner} = $scanner ;

}

my %widget_table = (
		    edit => {
			     leaf       => 'ConfigModelLeafEditor',
			     check_list => 'ConfigModelCheckListEditor',
			     list       => 'ConfigModelListEditor',
			     hash       => 'ConfigModelHashEditor',
			     node       => 'ConfigModelNodeEditor',
			    },
		    view => {
			     leaf       => 'ConfigModelLeafViewer',
			     check_list => 'ConfigModelCheckListViewer',
			     list       => 'ConfigModelListViewer',
			     hash       => 'ConfigModelHashViewer',
			     node       => 'ConfigModelNodeViewer',
			    },
		   ) ;

sub create_element_widget {
    my $cw = shift ;
    my $mode = shift ;
    my $tree_path = shift ; # reserved for tests

    my $tree = $cw->{tktree};

    unless (defined $tree_path)
      {
        # pointery and rooty are common widget method and must called on
        # the right widget to give accurate results
        $tree_path = $tree->nearest($tree->pointery - $tree->rooty) ;
      }

    $tree->selectionClear() ; # clear all
    $tree->selectionSet($tree_path) ;
    my $data_ref = $tree->infoData($tree_path);
    unless (defined $data_ref->[1]) {
	$cw->reload;
	return;
    }
    my $loc = $data_ref->[1]->location;

    my $obj = $cw->{root}->grab($loc);
    my $type = $obj -> get_type ;
    $logger->trace( "item $loc to $mode (type $type)" );

    # cleanup existing widget contained in this frame
    delete $cw->{editor} ;
    map { $_ ->destroy if Tk::Exists($_) } $cw->{e_frame}->children ;

    my $frame = $cw->{e_frame} ;

    my $widget = $widget_table{$mode}{$type} 
      || die "Cannot find $mode widget for type $type";
    my @store = $mode eq 'edit' ? (-store_cb => sub {$cw->reload(@_)} ) : () ;
    $cw->{editor} = $frame -> $widget(-item => $obj, -path => $tree_path,
				      @store ) ;
    $cw->{editor}-> pack(-expand => 1, -fill => 'both') ;
    return $cw->{editor} ;
}

sub get_perm {
    carp "get_perm is deprecated";
    goto &get_experience ;
}

sub get_experience {
    my $cw = shift ;
    return $ {$cw->{exp_ref}} ;
}

sub edit_copy {
    my $cw = shift ;
    my $tkt = $cw->{tktree} ;

    my @selected = @_ ? @_ : $tkt -> info('selection');

    #print "edit_copy @selected\n";
    my @res ;

    foreach my $selection (@selected) {
	my $data_ref = $tkt->infoData($selection);

	my $cfg_elt = $data_ref->[1] ;
	my $type = $cfg_elt->get_type ;
	my $cfg_class = $type eq 'node' ? $cfg_elt->config_class_name : '';
	#print "edit_copy '",$cfg_elt->location, "' type '$type' class '$cfg_class'\n";

	push  @res, [ $cfg_elt->element_name,
		      $cfg_elt->index_value ,
		      $cfg_elt->composite_name,
		      $type,
		      $cfg_class ,
		      $cfg_elt->dump_as_data()] ;
    }

    $cw->{cut_buffer} = \@res ;

    #use Data::Dumper; print "cut_buffer: ", Dumper( \@res ) ,"\n";

    return \@res ; # for tests
}

sub edit_paste {
    my $cw = shift ;
    my $tkt = $cw->{tktree} ;

    my @selected = @_ ? @_ : $tkt -> info('selection');

    #print "edit_paste in @selected\n";
    my @res ;

    my $selection = $selected[0];

    my $data_ref = $tkt->infoData($selection);

    my $cfg_elt = $data_ref->[1] ;
    #print "edit_paste '",$cfg_elt->location, "' type '", $cfg_elt->get_type,"'\n";
    my $t_type  = $cfg_elt->get_type ;
    my $t_class = $t_type eq 'node' ? $cfg_elt->config_class_name : '';
    my $t_name  = $cfg_elt->element_name ;
    my $cut_buf = $cw->{cut_buffer} || [] ;

    foreach my $data (@$cut_buf) {
	my ($name,$index,$composite,$type, $cfg_class, $dump) = @$data;
	#print "from composite name '$composite' type $type\n";
	#print "t_name '$t_name' t_type '$t_type'  class '$t_class'\n";
	if (   ($name eq $t_name and $type eq $t_type )
	    or $t_class eq $cfg_class
	   ) {
	   $cfg_elt->load_data($dump) ;
	}
	elsif (($t_type eq 'hash' or $t_type eq 'list') and defined $index) {
	    $cfg_elt->fetch_with_id($index)->load_data($dump) ;
	}
	elsif ($t_type eq 'hash' or $t_type eq 'list' or $t_type eq 'leaf') {
	    $cfg_elt->load_data($dump) ;
	}
	else {
	    $cfg_elt->grab($composite)->load_data($dump) ;
	}
    }

    $cw->reload(1) if @$cut_buf;
}

sub wizard {
    my $cw = shift ;
    my $tree = $cw->{tktree} ;

    my $wiz = $cw->ConfigModelWizard (
				      -root => $cw->{root}, 
				      -store_cb => sub{ $cw->force_element_display(@_)},
				     ) ;
    $wiz->start_wizard($cw->{experience}) ;
}

1;

__END__

=head1 NAME

Config::Model::TkUI - Tk GUI to edit config data through Config::Model

=head1 SYNOPSIS

 use Config::Model::TkUI;

 # init trace
 Log::Log4perl->easy_init($WARN);

 # create configuration instance
 my $model = Config::Model -> new ;
 my $inst = $model->instance (root_class_name => 'a_config_class',
                              instance_name   => 'test');
 my $root = $inst -> config_root ;

 # Tk part
 my $mw = MainWindow-> new ;
 $mw->withdraw ;
 $mw->ConfigModelUI (-root => $root) ;

 MainLoop ;

=head1 DESCRIPTION

This class provides a GUI for L<Config::Model>.

With this class, L<Config::Model> and an actual configuration
model (like L<Config::Model::Xorg>), you get a tool to 
edit configuration files (e.g. C</etc/X11/xorg.conf>).

Be default, only items with C<beginner> experience are shown. You can
change the C<experience> level in C<< Options -> experience >> menu.

=head1 USAGE

=head2 Left side tree

=over

=item *

Click on '+' and '-' boxes to open or close content

=item *

Left-click on item to open a viewer widget.

=item *

Right-click on any item to open an editor widget

=back

=head2 Editor widget

When clicking on store, the new data is stored in the tree represented
on the left side of TkUI. The new data will be stored in the
configuration file only when C<File->save> menu is invoked.

=head2 Wizard

A wizard can be launched either with C<< File -> Wizard >> menu entry
or with C<Run Wizard> button.

The wizard will scan the configuration tree and stop on all items
flagged as important in the model. It will also stop on all erroneous
items (mostly missing mandatory values).

=head2 TODO

Document widget options. (-root_model and -store_sub, -quit)

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 LICENSE

    Copyright (c) 2008-2009 Dominique Dumont.

    This file is part of Config-Model.

    Config-Model is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser Public License as
    published by the Free Software Foundation; either version 2.1 of
    the License, or (at your option) any later version.

    Config-Model is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser Public License for more details.

    You should have received a copy of the GNU Lesser Public License
    along with Config-Model; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
    02110-1301 USA

=head1 FEEDBACK and HELP wanted

This project needs feedback from its users. Please send your
feedbacks, comments and ideas to :

  config-mode-users at lists.sourceforge.net


This projects also needs help to improve its user interfaces:

=over

=item *

Look and feel of Perl/Tk interface can be improved

=item *

A nicer logo (maybe a penguin with a wrench...) would be welcomed

=item *

Config::Model could use a web interface

=item *

May be also an interface based on Gtk or Wx for better integration in
Desktop

=back

If you want to help, please send a mail to:

  config-mode-devel at lists.sourceforge.net

=head1 SEE ALSO

=over

=item *

L<Config::Model>

=item *

http://config-model.wiki.sourceforge.net/

=item *

Config::Model mailing lists on http://sourceforge.net/mail/?group_id=155650

=back



