
my $verb_wiz = 1 ;

package Config::Model::CursesUI ;
require Exporter;
use strict ;
use Config::Model::Exception ;
use Carp;
use warnings FATAL => "all";

use Config::Model::ObjTreeScanner ;
use Curses::UI ;

use Config::Model::Exception ;
use Exception::Class 
  (
   'Config::Model::CursesUI::AbortWizard'
   => {
       isa => 'Config::Model::Exception::Any',
       description => 'wizard found a highlighted item' ,
       fields =>  [qw/object slot index info/]
      },
  ) ;

our $VERSION = '1.103';

my @help_settings = qw/-bg green -fg black -border 1 
                       -titlereverse 0
                       -padbottom 1 -wrapping 1/ ;

sub new {
    my $class = shift ;
    my %args = @_ ;
    my $self = { init_done => 0 , stack => [], debug => 0 } ;

    $self->{debug} = $args{debug} if defined $args{debug} ;
    foreach my $param (qw/store load/) {
	$self->{tree}{$param} = $args{$param} if defined $args{$param} ;
    }

    $self->{cui} =  new Curses::UI (
				    -color_support => 1,
				    #-default_colors=> 0,
				    #-clear_on_exit => 1, 
				    #-compat => 1,
				    #-debug => 1
				   );

    $self->{experience} = $args{experience} || 'beginner' ;

    my %cb_set 
      = (
	 #                             scanner self 
	 list_element_cb       => sub {shift; shift->display_hash_element      (@_); },
	 check_list_element_cb => sub {shift; shift->display_check_list_element(@_); },
	 hash_element_cb       => sub {shift; shift->display_hash_element      (@_); },
	 node_element_cb       => sub {shift; shift->display_node_element      (@_); },

	 node_content_cb       => sub {shift; shift->display_node_content      (@_); },

	 leaf_cb               => sub {shift; shift->display_leaf              (@_); },
	 string_value_cb       => sub {shift; shift->display_string            (@_); },
	 reference_value_cb    => sub {shift; shift->display_enum              (@_); },
	 enum_value_cb         => sub {shift; shift->display_enum              (@_); },
	 integer_value_cb      => sub {shift; shift->display_string            (@_); },
	 number_value_cb       => sub {shift; shift->display_string            (@_); },
	 boolean_value_cb      => sub {shift; shift->display_boolean           (@_); },
	) ;

    eval {
      $self->{scan} = Config::Model::ObjTreeScanner
	-> new (
		fallback   => 'all',
		experience => $self->{experience},
		%cb_set ,
	       ) ;
  };

    $self->{cui}->fatalerror("Could not create ObjTreeScanner:\n$@")
      if $@ ;

    bless $self,$class ;
}

# create dialog windows 
sub init {
    my $self = shift ;
    my $cui = $self->{cui};

    $self->create_explanation ;

    # Bind <CTRL+Q> to quit.
    my $quit_sub = sub { 
			 $self->store_config ;
			 exit;
		     } ;
    $cui->set_binding( $quit_sub, "\cQ" );

    # Bind <CTRL+C> to quit.
    $cui->set_binding( sub {exit;}, "\cC" );

    # Bind <CTRL+R> to reset.
    $cui->set_binding( sub {$self->reset_screen} , "\cR" );

    # Bind <CTRL+B> to back.
    $cui->set_binding( sub {$self->back}, "\cB" );

    # Bind <CTRL+X> to menubar.
    $cui->set_binding( sub{ $self->{cui}->root->focus('menu') }, "\cX" );

    $self->{init_done} = 1;
}

sub back {
    my $self=shift ;
    return unless @{$self->{stack}} > 1;
    pop  @{$self->{stack}};
    $self->reset_screen ;
}

sub reset_screen {
    my $self=shift ;
    return unless @{$self->{stack}};
    &{ pop  @{$self->{stack}} };
}

sub create_explanation {
    my $self = shift ;
    my $cui = $self->{cui} ;

    my $w_bottom = $cui->add( 'bottom', 'Window', 
			      -border        => 1, 
			      '-y'           => -1, 
			      -height        => 3
			    );

    $w_bottom->add( 'explain', 'Label', 
		    -text => "CTRL-Q: save & quit CTRL+C: exit CTRL+X: menu CTRL+B: "
                           . "back CTRL-R: reset screen"
                  );

    my $w_url = $cui->add( 'undef', 'Window', 
			   -border        => 1, 
			   '-y'           => 1,
			   -height        => 3
                         );

    $self->{conf_label} = $w_url->add ('conf_label', 
				       'Label', -x => 1,
				       -text => "", 
				       -width => 15
				      );

    $self->{loc_label} = $w_url->add ( 'location', 'Label',
				       -bg => 'blue', 
				       -fg => 'white',
				       -bold => 1,
				       '-padleft' => 16,
				       -text => "." x 60
				     );
}

sub set_center_window {
    $_[0]->{cui}->delete('center') ;
    $_[0]->{cui}->add ( 'center', 'Window',
			-border       => 1,
			-titlereverse => 0,
			-padtop       => 4, 
			-padbottom    => 3, 
			-ipad         => 1,
			-title        => $_[1]
		      ) ;
}

sub add_debug_label {
    my ($self,$win) = @_ ;

    my @a = caller (1) ;
    my $f = $a[3] ;
    $f =~ s/.*::// ;
    $win->add(undef, 'Label', -x => 40,
	      -text => "debug: '$f()',l $a[2]") if $self->{debug} ;
}

sub start {
    my $self      = shift ;
    my $model_obj = shift ;

    $self->{model_obj} = $model_obj ;

    $self->init unless $self->{init_done} ;

    $self->create_menu ;
    $self->{conf_label} -> text('') ;

    my $start = sub {$self->start($model_obj)} ;
    push @{$self->{stack}} , $start ;
    $self->{start_all} = $start ;
    $self->{loc_label}->text('') ;

    my @inst_names = $model_obj -> instance_names ;
    warn "found @inst_names\n";

    my $win = $self->set_center_window("XXX configuration");

    # create an instance screen if more than one instance was passed
    if (@inst_names > 1) {
	# TBD scan the tree to get a name

	$self->add_debug_label($win) ;

	$win->add(undef, 'Label', 
		  -text => "Choose your configuration instance");

	my $y = 2 ;
	foreach my $i_name (@inst_names) {
	    $win->add ( undef, 'Buttonbox', 
			'-x' => 2, 
			'-y'=> $y , 
			-width => 15,
			'-buttons' 
			=> [
			    {
			     -label => "< $i_name >",
			     -onpress => sub {$self->start_config($i_name) ;}, 
			    },
			   ]
		      ) ;

	    $y++ ;
	}

	$win->focus ;
    }
    else {
	$self->start_config(@inst_names) ;
    }

    $self->{cui}->mainloop;
}

sub reset_config {
    my ($self,$inst_name) = @_ ;
    $self->{cui}->status("Reseting $inst_name ...") ;
    $self->{tree}{root} 
      = $self->{model_obj}->instance(name => $inst_name)
	-> reset_config ;

    $self->{tree}{load}->() if defined  $self->{tree}{load} ;

    $self->{cui}->nostatus ;
    return $self->{tree}{root}  ;
}

sub load_config {
    my ($self,$inst_name) = @_ ;

    $self->{cui}->status("Loading $inst_name ...") ;
    warn "Loading config $inst_name ...\n" ;

    my $root = $self->{tree}{root} = 
      $self->{model_obj}->instance(name => $inst_name)->config_root ;

    $self->{tree}{load}->() if defined  $self->{tree}{load} ;

    $self->{cui}->nostatus ;
    return $root;
}

sub store_config {
    my ($self) = @_ ;

    my $label = $self->{tree}{root}->instance->name ;

    if (defined $self->{tree}{store}) {
	warn "Storing config $label with provided store call-back...\n" ;
	$self->{tree}{store}->() ;
    }
    else {
	warn "Storing config $label with model call-back...\n" ;
	$self->{tree}{root}->instance->write_back; 
    }

    $self->{cui}->nostatus ;
}

sub start_config {
    my $self      = shift ;
    my $inst_name = shift ;

    $self->{start_config} = sub {$self->start_config($inst_name) } ;

    my $inst = $self->{model_obj}->instance(name => $inst_name) ;

    $self->{conf_label} -> text($inst_name.':') ;
    $self->create_config_menu($inst_name) ;

    # reset location label
    $self->{loc_label}->text('') ;

    $self->{tree}{root} ||= $self->load_config($inst_name);
    my $root = $self->{tree}{root} ;

    $self->init unless $self->{init_done} ;

    my $win = $self->set_center_window($inst->name." configuration");

    $self->add_debug_label($win) ;

    $win->add(undef, 'Label', 
              -text => $root->name." configuration");

    $win
      ->add ( undef, 'Buttonbox', '-y' => 2, -vertical => 1,
	      '-buttons' 
	      => [ { -label => "< config wizard >",
		     -onpress => sub{$self->wizard($root,1) ;}, 
		   },
		   {
		    -label => "< open >",
		    -onpress => sub{$self->scan('node',$root) ;}, 
		   },
		   {
		    -label => "< search >",
		    -onpress => sub{$self->display_all_elements($root) ;}, 
		   },
		   {
		    -label => "< overall tabular view >",
		    '-onpress'
                     => sub{$self->display_view_list($root,
						     'std',
						     'tabular') ;}, 
		   },
		   {
		    -label => "< overall tabular audit >",
		    -onpress => sub{$self->display_view_list($root,
							     'audit',
							     'tabular') ;}, 
		   },
		   {
		    -label => "< overall view >",
		    -onpress => sub{$self->display_view_list($root,
							     'std',
							     'tree') ;}, 
		   },
		   {
		    -label => "< overall audit >",
		    -onpress => sub{$self->display_view_list($root,
							     'audit',
							     'tree') ;}, 
		   },
		   {
		    -label => "< look for errors >",
		    -onpress => sub{$self->wizard($root,0) ;}, 
		   },
		 ]
	    );

    $self->{displayed_object} = $_[0] ;

    push @{$self->{stack}} , $self->{start_config};

    $self->{cui}->getobj('center')->focus ;

    # must add:
    # button to access a view style list
}

# update the location label with config element path
# add the current screen on user's call stack
sub wrap_screen {
    my ($self,$node,$element,$idx) = @_ ;

    $self->{displayed_object} = $node ;

    $self->update_location($node,$element,$idx) ;

    my $scan_type = defined $idx     ? 'hash'
                  : defined $element ? 'element' 
                  :                    'node' ;

    push @{$self->{stack}} , sub{$self->scan($scan_type,$node,$element,$idx)};

    $self->{cui}->getobj('center')->focus ;
}

sub update_location {
    my ($self,$node,$element,$idx) = @_ ;

    my $loc = $node->location ;
    $loc   .= ' '        if $loc ;
    $loc   .= $element   if defined $element ;
    $loc   .= ":$idx"    if defined $idx ;

    $self->{loc_label}->text($loc) ;
}

sub scan {
    my ($self,$what,@args) = @_ ;

    my $meth = 'scan_'.$what ;

    eval {$self->{scan}->$meth($self,@args) ; };

    # we may want to handle differently the exception
    $self->{cui}->fatalerror("Error in $meth:\n$@")
      if $@ ;
}

sub display_node_content {
    my ($self,$node,@element) = @_ ;

    my $win = $self->set_center_window("Node ".$node->name) ;

    $self->add_debug_label($win) ;

    $win->add(undef, 'Label', '-y' => 0,
	      -text => "Choose one of the elements:");

    my $valuew = $win->add(undef, 'Label', -bg => 'yellow',
			   '-y' => 2, '-x' => 40, -width => 38 );
    my $permw  = $win->add(undef, 'Label', 
			   '-y' => 3, '-x' => 40, -width => 38 );
    my $selw   = $win->add(undef, 'Label', 
			   '-y' => 4, '-x' => 40, -width => 38 );
    my $helpw  = $win->add(undef, 'TextViewer', 
			   '-y' => 5, '-x' => 40, -width => 38,
			   '-title' => 'Help on element',
			   @help_settings);

    my $listbox ;
    my $buttons ;
    my $lb_change = sub {
        my $sel = ($listbox->get)[0];
        $selw->text("selected $sel ");
        $buttons -> focus ;
    } ;

    my $lb_sel_change = sub {
        my $sel = ($listbox->get_active_value)[0];
	return unless defined $sel ; # may happen with empty node
        my $help = $node->get_help($sel) ;
        $help = "no help for $sel" unless $help ;
        $helpw->text($help)  ;
	if ($self->{experience} ne 'beginner') {
	    my $p = $node
	      -> get_element_property(property => 'experience',
				      element  => $sel) ;
	    $permw->text("experience: $p");
	}
	my $type = $node->element_type($sel) ;
	my $elt = $node->fetch_element($sel) ;
	my $v_str = '' ;
	if ($type eq 'leaf') {
	    my $v = $elt->fetch_no_check ;
	    $v_str = 'value: ';
	    $v_str .= defined $v ? "'$v'" : '<undef>';
	}
	elsif ($type =~ 'node') {
	    $v_str = 'node: '.$elt->config_class_name ;
	}
	else {
	    $v_str = 'type: '.$type ;
	}
	$valuew -> text ( $v_str ) ;
    };

    $listbox 
      = $win->add (
		   'mylistbox',
		   'Listbox',
		   -border      => 1,
		   '-y'         => 2,
		   -width       => 38 ,
		   -padbottom   => 1,
		   -title       => 'element',
		   -vscrollbar  => 1,
		   -onchange    => $lb_change ,
		   -onselchange => $lb_sel_change ,
		   -values      => \@element,
		   -selected    => 0, # automatically select first item
		  );

    $listbox->focus ;

    my $go = {
              -label => '< GO >',
              -onpress => sub {
		  my @sel = $listbox->get;
		  if (@sel) {
		      $self->scan('element',$node,$sel[0]);
		  }
		  else {
		      $self->{cui}->dialog(-message => 
					   "Please select an element");
		  }
              }
             } ;

    my $help = {
		-label => '< Help on node >',
		-onpress => sub {
		    my $help= $node->get_help ;
		    $help = "Sorry, no help available" 
		      unless defined $help;
		    $self->{cui}->dialog($help) ;
		}
	       } ;

    my $parent = $node->parent ;

    # closure: don't remove the $buttons assignment
    $buttons = $self->add_std_button($win,$parent,undef,$help,$go) ;

    $self->wrap_screen($node) ;

    # display value and help of selected element (i.e. -selected 0)
    my $sel = ($listbox->get)[0];
    $selw->text("selected $sel ");
    &$lb_sel_change() ;
}

# node_element_cb
sub display_node_element {
    my ($self,$node,$element,$key, $contained_node) = @_ ;

    # here, there's no need to define a screen, just fetch the
    # node and scan it
    if (not $node->is_accessible($element)) {
        my $str = "Node ".$node->name." element: $element";
        $str .= " key $key" if defined $key;
        my $win = $self->set_center_window($str);
        $win->add (
		   undef, 'Label', 
		   -text => "Node is currently unavailable.\n"
		          . "To make it available, change one "
		          . "of the following items"
		  );

        my $y = 3 ;
        foreach my $master ($contained_node->get_all_warper_object) {
            my $s = $master->element_name ;
            my $cb = sub {
                my $p = $master->parent ;
                $self->scan('element',$p,$s) ;
	    };

            $win->add (
               undef, 'Buttonbox',
               '-y' => $y++ ,
               -buttons => 
               [{
                 -label => "< ".$master->name." >",
                 -value => $master,
                 -width => 20,
                 -onpress => $cb
                }]
              );
            no warnings "uninitialized" ;
            $win->add
              (
               undef, 'Label', 
               '-y' => $y++ ,
               '-x' => 3 ,
               #-width => 20,
               -text => "* $s value '".$master->fetch."'"
              );
	}

        $self->wrap_screen($node,$element,$key) ;

    }
    else {
        $self->{scan}->scan_node($self,$contained_node);
    }
}

sub display_hash_element {
    my ($self,$node,$element,@keys) = @_ ;

    my $win = $self->set_center_window(ucfirst($node->element_type($element)));

    $self->add_debug_label($win) ;

    my $listbox = $self->layout_hash($win, $node,$element,@keys) ;

    my @but = 
      (
       { -label => '< GO >',
	 -onpress => sub
	 {
	   my @sel = $listbox->get;
	   return unless @sel;
	   $self->scan('hash',$node,$element,$sel[0]);
	 }
       }
      ) ;

    $self->add_std_button_with_help($win,$node,$element,@but) ;

    $self->wrap_screen($node,$element) ;
    return $win ;
}

sub layout_hash {
    my ($self,$win,$node,$element,@keys) = @_ ;

    $win->add(undef, 'Label', -text => "Select or add one element:");

    my $lb_sel_change ;

    my $listbox = $win->add (
			     'mylistbox', 'Listbox',
			     -border     => 1,
			     '-y' => 2,
			     -padbottom => 1,
			     -width => 40 ,
			     -title => $element.' elements',
			     -onselchange => $lb_sel_change ,
			     -vscrollbar => 1,
			     -values    => \@keys,
			     -selected    => 0, # automatically select first item
			    );

    my $hash_obj = $node->fetch_element($element) ;

    my $redraw 
      = sub {
	  my @rkeys = $self->{scan}->get_keys($node,$element) ;
	  warn "redraw: keys are @rkeys\n" ;
	  $listbox->values( \@rkeys ) ;
	  #$listbox->layout ;
	  $listbox->draw ; #intellidraw ;
	  #$win->intellidraw ;
      } ;

    $listbox->focus ;

    $win->add(undef, 'Label', 
	      '-x' => 41, '-y' => 2,
	      -text => "Id to add, rm, cp, mv:");

    my $editor = $win -> add ( undef, 'TextEntry',
			       -sbborder => 1,
			       '-x' => 41,
			       '-y' => 3,
			       -width => 15,
			       -text => ''
			     );

    # $node and $element are closure

    my $add_sub 
      = sub {
	  my $add = $editor->get;
	  if ($add) {
	      my $res = $self->try_it(sub {$hash_obj->fetch_with_id($add);}) ;
	      &$redraw;
	  }
	  else {
	      $self->{cui}->dialog(-message => 
				  "Please type in an id to add");
	  }
      };

    my $del_sub
      = sub {
	  my $del = $listbox->get;
	  if ($del) {
		$self->try_it(sub {$hash_obj->delete($del);}) 
		  or return ;
		&$redraw;
	    }
	  else {
	      $self->{cui}->error(-message => 
				  "Please type in an id to remove");
	  }
      };

    my $copy_sub
      = sub {
	  my @sel = $listbox->get;
	  my $to = $editor->get;

	  unless (@sel) {
	      $self->{cui}->error(-message => 
				  "Please select an id to copy from");
	      return ;
	  }
	  unless ($to) {
	      $self->{cui}->error(-message => 
				  "Please type in an id to copy to") ;
	      return ;
	  }

	  $self->try_it(sub { $hash_obj -> copy ($sel[0],$to) ;} ) ;
	  # redraw the screen
	  &$redraw;
      };

    my $move_sub 
      = sub {
	  my @sel = $listbox->get;
	  my $to = $editor->get;

	  unless (@sel) {
	      $self->{cui}->error(-message => 
				  "Please select an id to move from");
	      return ;
	  }
	  unless ($to) {
	      $self->{cui}->error(-message => 
				  "Please type in an id to move to");
	      return ;
	  }

	  $self->try_it(sub { $hash_obj -> move($sel[0], $to) ;} );
	  # redraw the screen
	  &$redraw;
      } ;

    $win->add(undef, 'Label', '-x' => 41, '-y' => 4, -text => "do: " );

    $win->add ( undef, 'Buttonbox', 
		'-y' => 4,
		'-x' => 45,
		#-buttonalignment => 'left', 
		-width => 20,
		-vertical => 0,
		-buttons   => 
		[ 
		 { -label => '<add>' , -onpress => $add_sub  },
		 { -label => '<rm>' ,  -onpress => $del_sub  },
		 { -label => '<cp>' ,  -onpress => $copy_sub },
		 { -label =>  '<mv>',  -onpress => $move_sub }
		]
	      );

    $win->add(undef, 'Label', 
	      '-x' => 41, '-y' => 5, -bg => 'yellow',
	      -text => "Cargo type: ".$hash_obj->cargo_type );

    my $value_w = $win-> add(undef, 'Label', 
			     '-x' => 41, '-y' => 6,-width => 38,
			     -bg => 'yellow',
			     -text => "content: " );

    $lb_sel_change = sub {
	my $sel = ($listbox->get_active_value)[0];
	return unless defined $sel ; # may happen with empty hash
	my $ct = $hash_obj -> cargo_type ;
	my $value = $ct eq 'leaf' ? $hash_obj->fetch_with_id($sel) -> fetch
 	          : $ct =~ /node/ ? "node " . $hash_obj->config_class_name 
 	          :                 "type $ct" ;

         $value_w->text("content: ".$value)  ;
    };

    &$lb_sel_change ; # to display selected value ;

    my $helpw  = $win->add(undef, 'TextViewer', 
			   '-y' => 7, '-x' => 41, -width => 38,
			   '-title' => 'Help on element',
			   @help_settings);
    my $help = $node->get_help($element) || "no help for $element" ;
    $helpw->text($help)  ;

    return $listbox ;
}


sub display_check_list_element {
    my ($self,$node,$element,@check_items) = @_ ;

    my $win = $self->set_center_window("Check list");

    $self->layout_checklist($win, $node,$element) ;

    $self->wrap_screen($node,$element) ;
    return $win ;
}

sub layout_checklist {
    my ($self,$win,$node,$element) = @_ ;

    my $check_list_obj = $node->fetch_element($element) ;

    my $notebook = $win->add(undef, 'Notebook', -intellidraw => 1);

    my $content_page = $notebook->add_page('edit content');
    $self->layout_checklist_editor($content_page,$node,$element) ;

    if ($check_list_obj -> ordered ) {
	my $lb ;
	my $c_sub = sub {
	    my @values = $check_list_obj->get_checked_list ;
	    $lb->values(\@values) ;
	};
	my $order_page = $notebook->add_page('change order', 
					     -on_activate => $c_sub ) ;
	$lb = $self->layout_checklist_order($order_page,$node,$element) ;
    }

}

sub layout_checklist_info {
    my ($self,$win,$node,$element, $yr,$text) = @_ ;
    my $check_list_obj = $node->fetch_element($element) ;

    $win->add(undef, 'Label', '-y' => $$yr   , -text => "Current value :");

    my $cur_val_w
      = $win->add(undef, 'Label', '-y' => $$yr++ , '-x' => 16 );

    $win->add(undef, 'Label', '-y' => $$yr++ , -text => $text);

    my @values = $check_list_obj->get_choice ;

    my $help_w = $win -> add ( undef, 'TextViewer',
			     '-x' => 42 ,
			     '-y' => $$yr ,
			     -width => 35,
			     -text => $node->get_help($element) ,
			     '-title' => 'Help on value',
			     @help_settings ) ;

    my $help_update = sub {
	my $widget = shift ;
	my $choice = $values[$widget->get_active_id] ;
	$help_w->text($check_list_obj->get_help($choice)) ;
    } ;

    return ($cur_val_w,$help_update) ;
}

sub layout_checklist_editor {
    my ($self,$win,$node,$element) = @_ ;

    my $y = 1 ;
    my ($cur_val_w,$help_update)
      = $self->layout_checklist_info($win,$node,$element,\$y,
				     "Check one or more:" ) ;

    my $check_list_obj = $node->fetch_element($element) ;
    my @values = $check_list_obj->get_choice ;
    my $listbox = $win->add (
			     'mylistbox', 'Listbox',
			     -border     => 1,
			     '-y'        => $y,
			     -multi      => 1 ,
			     -padbottom  => 1,
			     -width      => 40 ,
			     -title      => $element.' elements',
			     -vscrollbar => 1,
			     -onselchange   => $help_update ,
			     -selected => { 0 => 1, 1 => 1 } ,
			     -values     => \@values ,
			    );

    my $update_value = sub {
	$cur_val_w->text(join(",",$check_list_obj->get_checked_list)) ;
	my %new_hash = $check_list_obj->get_checked_list_as_hash ;
	my $idx = 0;
	$listbox->clear_selection ;
	foreach my $v (sort keys %new_hash) {
	    warn "set $v ($idx) to $new_hash{$v} for @{$listbox->{-values}}\n";
	    $listbox->set_selection($idx) if $new_hash{$v} ;
	    $idx ++ ;
	}
	# Tk::ObjScanner::scan_object($listbox) ;
	$listbox->draw ;
    } ;

    $update_value->() ;

    my $ok_sub = sub {
	my (@set) = $listbox->get ;
	$check_list_obj->set_checked_list(@set) ;
	$update_value->() ;
    } ;

    my @buttons = (
		   { -label => '< Store >', -onpress => $ok_sub } 
		  ) ;

    $self->add_std_button_with_help($win,$node,$element, @buttons ) ;

    $listbox->focus ;

    return $listbox ;
}

sub layout_checklist_order {
    my ($self,$win,$node,$element) = @_ ;

    my $y = 1;
    my ($cur_val_w,$help_update)
      = $self->layout_checklist_info($win,$node,$element,\$y,
				     "Current value :");

    my $check_list_obj = $node->fetch_element($element) ;
    my @values = $check_list_obj->get_checked_list ;
    my $listbox = $win->add (
			     'mylistbox', 'Listbox',
			     -border     => 1,
			     '-y'        => $y,
			     -padbottom  => 1,
			     -width      => 40 ,
			     -title      => $element.' elements',
			     -vscrollbar => 1,
			     -onselchange   => $help_update ,
			     -values     => \@values ,
			    );

    my $update_value = sub {
	my $set  = shift ;
	my @new_list = $check_list_obj->get_checked_list ;
	$cur_val_w->text(join(",",$check_list_obj->get_checked_list)) ;
	$listbox->values(\@new_list) ;
	# Tk::ObjScanner::scan_object($listbox) ;
	$listbox->set_selection($set) if defined $set ;
	$listbox->draw ;
    } ;

    $win->onFocus(sub {$update_value->()} ) ; ;

    my $up_sub = sub {
	my ($item) = $listbox->get || return ; # no selection
	my ($idx)  = $listbox->id  || return ; # first item selected
	$check_list_obj->move_up($item) ;
	$update_value->($idx - 1) ;
    } ;

    my $down_sub = sub {
	my ($item) = $listbox->get || return ;
	my ($idx)  = $listbox->id ;
	my @new_list = $check_list_obj->get_checked_list ;
	return if $idx >= $#new_list ; # last item selected
	$check_list_obj->move_down($item) ;
	$update_value->($idx + 1) ;
    } ;

    my @buttons = (
		   { -label => '< up >', -onpress => $up_sub } ,
		   { -label => '< down >', -onpress => $down_sub } ,
		  ) ;

    $self->add_std_button_with_help($win,$node,$element, @buttons ) ;

    $listbox->focus ;

    return $listbox ;
}
## end check_list

sub display_leaf {
    my ($self,$node,$element,$index,$leaf) = @_ ;

    my $win = $self->set_center_window($element);

    my $editor = $self->layout_leaf_value($win,$node,$element,$index,$leaf ) ;

    $editor -> focus;
    $self->add_std_button_with_help($win,$node,$element) ;
    $self->wrap_screen($node,$element,$index);
}

sub layout_leaf_value
  {
      goto &layout_string_value ;
  }

sub set_leaf_value {
    my ($self,$leaf,$new) = @_ ;

    my $sub = sub { 
	no warnings "uninitialized" ;
	warn "set_leaf_value: ", $leaf->name,"-> store( $new )\n";
	my $v = $leaf->store($new);
    } ;

    $self->try_it($sub) ;
}

sub try_it {
    my ($self,$sub) = @_ ;

    eval {
        &$sub ;
	warn "try_it: call to sub succeeded\n" if $verb_wiz ;
    } ;

    my $e ;
    if ($e = Config::Model::Exception::User->caught()) {
	my $oops = $e->error ;
	$oops =~ s/\t//g;
	chomp($oops) ;
	$self->{cui}->error(-message => $oops ) ;
        return undef;
    }
    elsif ($@) {
	warn $@ ;
        $self->{cui}->fatalerror("try_it: $@") ;
        # does not return ...
    } ;
}

sub display_enum {
    my ($self,$node,$element,$index, $leaf) = @_ ;

    my $win = $self->set_center_window("display_enum $element");

    my $lb = $self->layout_enum_value($win,$node,$element,$index, $leaf) ;

    my $but = { -label => '< OK >',
                -onpress => sub {$self->back} } ;

    $lb->focus ;
    $self->add_std_button_with_help($win,$node,$element,$but) ;
    $self->wrap_screen($node,$element,$index);
}

sub layout_enum_value {
    my ($self,$win,$node,$element,$index, $leaf) = @_ ;

    $self->add_debug_label($win) ;

    my ($orig_value,$current_value_widget,$help) = 
      $self->value_info($win,$leaf, 40, 1) ;

    $help -> text ($leaf->get_help($orig_value) ) ;

    my $y = 0;

    if ($leaf->value_type eq 'reference') {
	$win -> add ( undef, 'Label',
		      '-y' => $y++,
		      -text => "Enum values are taken from:"
		    ) ;

	foreach my $c_obj ($leaf->reference_object->compute_obj) {
	    my $button ;
	    my $path = $c_obj -> user_formula ;
	    if (defined $path) {
		my $target = $leaf->grab($path) ;
		my $p_target = $target->parent ;
		my $n_target = $target->element_name ;
		my $go = sub { $self->scan('element',$p_target, $n_target) ;  } ;
		$button = {  -label => "< go to '$path' >", -onpress => $go  } ;
	    }
	    else {
		my $go = sub {$self->{cui}->fatalerror( $c_obj->compute_info )} ;
		$button = {  -label => "< info on undef '$path' >", 
			     -onpress => $go  } ;
	    }
	    $win -> add ( undef, 'Buttonbox',
			  '-y' => $y++,
			  '-x' => 0 ,
			  -buttons   => [ $button ] ,
			) ;
	}
	$y ++ ;
    }

    $win -> add ( undef, 'Label',
                  '-y' => $y,
                  -text => "Select new value.\nPress </> for a"
                  . "'less'-like\nsearch through the choice list."
		) ;
    $y += 3 ;

    my $listbox ;
    my $value = $orig_value ;

    my $lb_change = sub {
	my ($new) = $listbox->get;
	if (not defined $orig_value or $new ne $value) {
	    $self->set_leaf_value($leaf,$new);
	    $value = $new ;
	    $current_value_widget->text($new) ;
	}
    } ;

    my $lb_sel_change = sub {
	my ($new) = $listbox->get_active_value;
	$help ->text($leaf->get_help($new)) ;
    } ;

    $listbox = $win -> add ( undef, 'Listbox',
			     '-y'         => $y ,
			     -padbottom   => 1,
			     -values      => $leaf->choice,
			     -width       => 35,
			     -border      => 1,
			     -title       => 'Enum choice',
			     -vscrollbar  => 1,
			     -onchange    => $lb_change ,
			     -onselchange => $lb_sel_change ,
			   ) ;

    return $listbox ;
}


sub display_boolean {
    my ($self,$node,$element,$index, $leaf) = @_ ;

    my $win = $self->set_center_window("display_boolean $element");

    my $listbox = $self->layout_boolean_value($win,$node,$element,$index, $leaf) ;
    $listbox->focus;

    my $but = { -label => '< OK >',
                -onpress => sub {$self->back} } ;

    $self->add_std_button_with_help($win,$node,$element,$but) ;
    $self->wrap_screen($node,$element,$index);
}

sub layout_boolean_value {
    my ($self,$win,$node,$element,$index, $leaf) = @_ ;

    my ($orig_value,$current_value_widget, $help) 
      = $self->value_info($win,$leaf, 0, 4, 75) ;

    $orig_value ||= 0 ; # avoid undef boolean values
    my $value = $orig_value ;
    my $check_box ;

    my $set = sub {
	my ($new) = $check_box->get;
	if (not defined $orig_value or $new ne $value) {
	    $self->set_leaf_value($leaf , 0+$new ) ;
	    $value = $new ;
	    $current_value_widget->text( 0+$new ) ;
	    $help ->text($leaf->get_help($new ? '1' : '0')) ;
	}
    } ;

    $check_box = $win -> add ( undef, 'Checkbox',
			       -label => "Toggle checkbox for new value",
			       '-y'        => 1,
			       -checked => $orig_value ,
			       -onchange => $set
			     ) ;

    my $reset = sub {
	my $meth = $orig_value == 1 ? 'check' : 'uncheck' ;
	$check_box->$meth() ;
	$check_box ->draw ;
	$set->() ;
    } ;

    $win->add(undef,
	      'Buttonbox',
	      '-y' => 2 ,
	      '-x' => 0 ,
	      '-width' => 40 ,
	      -buttons   => 
	      [ { -label => '< Reset value >', -onpress => $reset} ]
	     ) ;

    return $check_box ;
}

sub display_string {
    my ($self,$node,$element,$index, $leaf) = @_ ;

    my $win = $self->set_center_window("display_string_v $element");

    my $editor = $self->layout_string_value($win,$node,$element,$index, $leaf ) ;
    $editor -> focus;

    my $but = { -label => '< OK >',
                -onpress => sub {$self->back} } ;
    $self->add_std_button_with_help($win,$node,$element, $but) ;
    $self->wrap_screen($node,$element,$index);
}

sub layout_string_value {
    my ($self,$win,$node,$element,$index, $leaf) = @_ ;

    $self->add_debug_label($win) ;
    my $v_type = $leaf->value_type;
    my $height = $v_type eq 'uniline' ? 1 : 4 ;

    my ($orig_value,$current_value_widget, $help) 
      = $self->value_info($win,$leaf, 0, $height + 2 , 75) ;

    $win -> add ( undef, 'Label', '-y' => 0, -bold => 1,
                  -text => "Enter new value:") ;

    my $editor = $win -> add ( undef,  
			       $v_type eq 'string' ? 'TextEditor' : 'TextEntry',
			       -sbborder => 1,
			       '-y' => 1,
			       '-height' => $height,
			       -width => 70,
			       -wrapping => 1,
			       -showhardreturns => 1,
			       -text => $orig_value
			     );


    my $value = $orig_value ;
    my $store = sub {
	my ($new) = $editor->get;
	if (not defined $orig_value or $new ne $value) {
	    $self->set_leaf_value($leaf,$new) ;
	    $value = $new ;
	    $current_value_widget->text($new) ;
	}
	else {
	    $editor -> focus;
	} 
    } ;

    my $reset = sub {
	my $reset_value = defined $orig_value ? $orig_value : '<undef>';
	$self->set_leaf_value($leaf , $orig_value );
	$editor->text($orig_value || '') ;
	$current_value_widget->text($reset_value) ;
    } ;

    $win->add(undef,
	      'Buttonbox',
	      '-y' => $height + 1 ,
	      '-x' => 0 ,
	      '-width' => 40 ,
	      -buttons   => 
	      [ { -label => '< Reset value >', -onpress => $reset},
		{ -label => '< store >',   -onpress => $store } 
	      ]
	     ) ;

    return $editor ;
}

sub value_info {
    my ($self,$win,$leaf, $x,$y, $width) = @_ ;
    my $inst = $leaf->instance ;

    $inst->push_no_value_check('fetch') ;

    no warnings "uninitialized";
    my $value = $leaf->fetch ;
    $win -> add ( undef, 'Label', -text => "current value: ",
		  '-x' => $x, '-y' => $y ) ;
    my $display_value = defined $value ? $value : '<undef>' ;
    my $cur_win = 
      $win -> add ( undef, 'Label', -text => $display_value , 
		    -bg => 'yellow',
		    -width => $width || 35 ,
		    '-x' => $x + 15, '-y' => $y++ ) ;

    my @items = ();
    if (defined $leaf->upstream_default) {
	push @items, "upstream_default value: " . $leaf->upstream_default ;
    }
    elsif (defined $leaf->fetch_standard) {
	push @items, "default value: " . $leaf->fetch_standard ;
    }

    $inst->pop_no_value_check ;

    my $m = $leaf->mandatory ;
    push @items, "is mandatory: ".($m ? 'yes':'no') if defined $m;

    my @minmax ;
    foreach my $what (qw/min max/) {
        my $v = $leaf->$what() ;
        push @minmax, "$what: $v" if defined $v;
    }

    push @items, join(', ',@minmax) if @minmax ;

    $win -> add ( undef, 'Label', 
		  '-x' => $x, '-y' => $y,
		  '-text' => join("\n",@items),
		  ) ;
    my $help =
      $win -> add ( undef, 'TextViewer',
		    '-x' => $x ,
		    '-y' => $y + scalar @items ,
		    -width => $width || 35,
		    '-title' => 'Help on value',
		    @help_settings ) ;

    return ($value, $cur_win, $help) ;
}

sub create_menu {
    my $self = shift ;

    $self->{cui}->delete('menu') ;

    my $file_menu = [
		     { -label => 'Quit',  
		       -value => sub { exit(0) ;} 
		     },
		    ];

    my $menu = [ { -label => 'File', -submenu => $file_menu }, ];

    $self->{cui}->add('menu', 'Menubar', -menu => $menu);
}

sub create_config_menu {
    my ($self,$label) = @_ ;

    $self->{cui}->delete('menu') ;

    my $file_menu 
      = [
	 { -label => 'Commit config' , 
	   -value => sub {$self->store_config($label)} },
	 { -label => 'Go back to config root', 
	   -value => $self->{start_config}},
	 { -label => 'Reset config' , 
	   -value => sub {$self->reset_config($label)} },
	 { -label => 'Abort config', -value => $self->{start_all}  },
	];

    my @menu_data = ( ['View',               'std','  tree'   ],
		      ['View Audit',         'audit','tree'   ],
		      ['Tabular View',       'std',  'tabular'],
		      ['Tabular View Audit', 'audit','tabular'],
		    ) ;

    my @nav_menu ;
    foreach my $i  (@menu_data) {
	my $sub = sub {
	    $self->display_view_list( 
				     $self->{displayed_object} || $self->{root},
				     $i->[1],$i->[2]
				    ) ;
	};
	push @nav_menu , {-label => $i->[0],  -value => $sub } ;
    }

    my $menu = [
		{ -label => 'File',     -submenu => $file_menu },
		{ -label => 'Navigate', -submenu => \@nav_menu }
	       ];

    $self->{cui}->add('menu', 'Menubar', -menu => $menu);
}

sub add_std_button_with_help {
    my ($self,$win,$node,$element,@buttons) = @_ ;

    my $help = $self->show_node_element_help($node,$element) ;

    unshift @buttons, { -label => '< More help >', 
			-onpress => sub{$self->{cui}->dialog($help);}
		      }
      if $help ;

    $self->add_std_button($win,$node,$element,@buttons) ;
}

sub add_std_button {
    my ($self,$win,$node,$element,@buttons) = @_ ;

    my $up = defined $node ? sub {$self->scan('node',$node);} 
           :                 $self->{start_config} ;

    unshift @buttons,
        { -label => '< Back >',
          -onpress => sub {$self->back}
        },
        {
         -label => '< Up >',
         -onpress => $up
        },
        {
         -label => '< Reset >',
         -onpress => sub {$self->reset_screen ;}
        },
        {
         -label => '< Top >',
         -onpress => $self->{start_config} 
        }  ;

    $win->add (undef, 'Buttonbox', 
	       '-y' => $win->canvasheight-1  ,
	       -buttonalignment => 'middle',
	       -buttons   => \@buttons,
	       -selected  => $#buttons, # select last button
	      ) ;
}


##### explore with Searcher

sub display_all_elements {
    my ($self,$root) = @_;

    unless (defined $self->{searcher}) {
	$self->{searcher} = $root->searcher ;
    }

    my $searcher = $self->{searcher} ;

    my $win = $self->set_center_window("Search for an element");

    $win -> add ( undef, 'Label',
                  -text => "Select the element you're looking for. \n"
                         . "Press </> for a"
                         . "'less'-like search through the list."
		) ;

    my @searchable_elements = $self->{searcher}->get_searchable_elements ;


    # The searcher must be set in manual mode

    my $listbox ;
    my $sub = sub {
	my ($searched) = $listbox->get;
	$searcher->prepare(element => $searched) ;
	my $choices = $searcher->next_choice ;
	if (@$choices ) {
	    $self->display_possible_element ($root,@$choices) ;
	}
	else {
	    # go fetch the searched object
	    my $target = $searcher->current_object ;
	    warn "Search found ",$target->name,"\n";
	}
    } ;

    $listbox = $win -> add ( 
			    undef, 'Listbox',
			    '-y'        => 3,
			    -values     => \@searchable_elements,
			    -width      => 30,
			    -border     => 1,
			    -title      => 'Search element',
			    -vscrollbar => 1,
			    -onchange   => $sub ,
			   ) ;

    $listbox->focus ;

    #$self->add_std_button($win,$node,$but) ;
    push @{$self->{stack}} , sub{$self->display_all_elements($root)};
  }

sub search_dispatch {
    my ($self, $object) = @_ ;
    my $obj_type = $object->get_type ;
    my $elt_name = $object->element_name ;
    my $idx_value = $object->index_value ;

    my $scan_type = $obj_type eq 'leaf' ? 'element' 
                  :                       $obj_type ;
    my $scan_object = $obj_type eq 'leaf' ? $object->parent : $object ;

    $self->scan($scan_type, $scan_object, $elt_name, $idx_value ) ;
}

sub add_id_elt_in_search {
    my ($self,$node,$element,@keys) = @_ ;

    my $win = $self->set_center_window(ucfirst($node->element_type($element)));

    my $listbox = $self->layout_hash($win, $node,$element,@keys) ;

    my @but = 
      (
       { -label => '< Done >',
	 -onpress => sub
	 {
	   my @sel = $listbox->get;
	   if (scalar @sel) {
	       $self->search_choose_jump($sel[0]) ;
	   }
	   else {
	       $self->{cui}->error(-message => "Please select an id");
	   }
	 }
       }
      ) ;

    $self->add_std_button_with_help($win,$node,$element,@but) ;

    $self->wrap_screen($node,$element) ;
    return $win ;

}

sub search_choose_jump {
    my $self = shift ;
    my $id = shift ;
    $self->{searcher}->choose($id) ;
    warn "choose $id\n";
    my $next_choices = $self->{searcher}->next_choice ;
    my $next_object  = $self->{searcher}->current_object ;
    warn "jump: to ",$next_object->name," with @$next_choices\n";

    if ($next_object->get_type =~ /list|hash/ or scalar @$next_choices ) {
	$self->display_possible_element ($next_object,@$next_choices) ;
    }
    else {
	# go fetch the searched object
	warn "Search found ",$next_object->name,"\n";
	$self->search_dispatch($next_object) ;
    }
} 

sub display_possible_element
  {
    my ($self,$object, @choices) = @_;

    $self->update_location($object) ;

    my $obj_type  = $object->get_type ;
    my $elt_name  = $object->element_name ;
    my $idx_value = $object->index_value ;

    my $searched = $self->{searcher}->searched ;

    my $win = $self->set_center_window("Select a path for $searched");

    $win -> add ( undef, 'Label',
                  -text => "'$searched' can be found in all these\n"
		         . "configuration elements. Please select one.");

    $self->add_debug_label($win) ;

    if ($obj_type eq 'list' or $obj_type eq 'hash') {
	$win->add  (undef, 'Buttonbox', 
		    '-y'=> 3 ,
		    -buttons => 
		    [
		     {
		      -label => "< jump to '$elt_name' to add an id >",
		      -onpress => sub{$self->add_id_elt_in_search($object->parent,$elt_name,@choices) ;}, 
		     },
		    ]
		   ) ;
    }

    my $jump = sub {
        my $id = shift->get;
	$self -> search_choose_jump($id) ;
      } ;

    my $listbox = $win -> add 
      ( undef, 'Listbox',
        '-y'        => 5,
        -values     => \@choices,
        -width      => 30,
        -border     => 1,
        -title      => 'Select path',
        -vscrollbar => 1,
        -onchange   => $jump ,
      ) ;

    $listbox->focus ;

    #$self->add_std_button($win,$node,$but) ;
    push @{$self->{stack}} , 
      sub{$self->display_possible_element($object,@choices)};

  }

##### explore through view like list

sub display_view_list {
    my ($self,$root,$select,$view_type,$pre_select) = @_;

    # reset location label
    $self->{loc_label}->text('') ;

    my $audit_cb = sub {
	my ($scanner, $data_ref,$node,$element_name,$index, $leaf_object) = @_ ;
	my $custom = $leaf_object->fetch_custom;
	push @$data_ref, [ $node,$element_name,$index , $custom ] if defined $custom;
    } ;

    my $std_cb = sub {
	my ($scanner, $data_ref,$node,$element_name,$index, $leaf_object) = @_ ;
	my $value = $leaf_object->fetch ;
	my $value_str = defined $value          ? $value 
                      : $leaf_object->mandatory ? '*MISSING*' 
		      :                            undef ;
	$value_str = '"'.$value_str.'"' if defined $value_str && $value_str =~ /\s/ ;
	push @$data_ref, [ $node, $element_name, $index , $value_str ] ;
    } ;

    my $hash_cb = sub {
	my ($scanner, $data_ref,$node,$element_name,@keys) = @_ ;

	foreach my $k (@keys) {
	    push @$data_ref, [ $node, $element_name, undef, $k ] ;
	    $scanner->scan_hash($data_ref,$node,$element_name,$k) ;
	}
    } ;

    my $node_cb = sub {
        my ($scanner, $data_ref,$node,$element_name,$key, $contained_node) = @_ ;
        push @$data_ref, [ $node, $element_name, $key ] ;
        $scanner->scan_node($data_ref,$contained_node);
    } ;

    my $leaf_cb = ($select eq 'audit') ? $audit_cb : $std_cb ;

    my @scan_args = ( experience       => $self->{experience},
                      fallback         => 'all',
 		      hash_element_cb  => $hash_cb ,
		      leaf_cb          => $leaf_cb ,
		      node_element_cb  => $node_cb ,
		    );

    my $view_scanner = Config::Model::ObjTreeScanner->new (@scan_args);

    my @leaves ;
    eval {
	# perform the scan that fills @leaves
        $root->instance->push_no_value_check('fetch','store','type') ;
        $view_scanner-> scan_node(\@leaves, $root) ;
        $root->instance->pop_no_value_check ;
    } ;

    if ($@) {
	warn "$@" ;
        $self->{cui}->fatalerror("display_view_list: $@") ;
    };

    my $idx = 0;
    my @good_leaves = $view_type eq 'tree' ? @leaves : grep { @$_ == 4 } @leaves ;

    my %labels = map { 
        my ($node,$element,$index,$value) = @$_ ;
        my $name  = defined $index ? "$element:$index" : $element ;
        my $loc = $node->location ;
        no warnings "uninitialized" ;
        my $str ;
        if ($view_type eq 'tabular') {
            $str =sprintf("%-28s | %-10s | %-30s", $name,$value,$node->name) ;
	}
        else {
            my @level = split / +/,$loc ;
            $str = ('. ' x scalar @level) . $name ;
            $str .= " = '$value'" if @$_ == 4;
	}
        ($idx++,$str) ;
    } @good_leaves ;

    my $win = $self->set_center_window("View ".$root->name);

    $win -> add ( undef, 'Label',
                  -text => "Select the item you're looking for. \n"
		         . "Press </> for a "
                         . "'less'-like search through the list."
		) ;

    my $listbox ;
    my $sub = sub {
	my ($searched) = $listbox->get;
	my ($node,$element,$index,$value) = @{$good_leaves[$searched]} ;

	# replace call with a call with a selected value
	pop @{$self->{stack}} ; 
	push @{$self->{stack}} , 
	  sub{$self->display_view_list($root,$select,$view_type,$searched)};

	if (defined $index) {
	    $self->scan('hash',$node,$element,$index) ;
	} 
	else {
	    $self->scan('element',$node,$element) ;
	}
    } ;

    $listbox = $win -> add ( undef, 'Listbox',
			     '-y'        => 3,
			     -values     => [0 .. $#good_leaves],
			     -labels     => \%labels ,
			     -border     => 1,
			     -title      => 'Search element',
			     -vscrollbar => 1,
			     -onchange   => $sub ,
			     -selected   => $pre_select 
			   ) ;

    $listbox->focus ;

    #$self->add_std_button($win,$node,$but) ;
    push @{$self->{stack}} , 
      sub{$self->display_view_list($root,$select,$view_type,$pre_select)};

}


##### wizard: explore depth first and stop on "important" or undefined
##### mandatory elements (or on erroneous elements ?)
sub wizard {
    my ($self,$root, $stop_on_important) = @_;

    # reset location label
    $self->{loc_label}->text('') ;

    eval {
	$self->wiz_walk( $stop_on_important , $root) ;
    } ;

    if (Config::Model::CursesUI::AbortWizard->caught()) {
	# ignored
    }
    elsif ($@) {
	warn "$@" ;
	$self->{cui}->fatalerror("search: $@") ;
    } ;

    $self->{start_config}->() ;
}

# do not delete
sub display_hash_wizard {
    my ($self, $node, $element) = @_ ;
    my $win = $self->set_center_window('wizard') ;

    $self->layout_hash($win,$node,$element)->focus ;
    $self->update_location($node, $element) ;
    $self->wrap_wizard($win, $node, $element) ;
  }

sub show_node_element_help {
    my ($self,$node, $element) = @_ ;
    my $text = '' ;

    return $text unless defined $node ;
    my $node_help = $node->get_help();

    my $element_name = $node->element_name() ; # may be undef for root class
    if ($node_help) {
	$text .= "$element_name:\n  " if defined $element_name;
	$text .= "$node_help\n" ;
    }

    if (defined $element) {
	my $element_help = $node->get_help($element);
	$text .= "$element:\n  $element_help\n" if $element_help ;
    }

    return $text ;
}

my $loop_c = 0 ;

sub wrap_wizard {
    my ($self,$win, $node, $element) = @_ ;

    my $keep_wiz = 1 ;
    my $abort_wiz = 0 ;

    my @buttons 
      = (
	 {
	  -label => '< Exit wizard >',
	  -onpress => sub {$keep_wiz=0 ; $abort_wiz = 1 ;}
	 } 
	);

    my $help = $self->show_node_element_help($node, $element) ;

    push @buttons, {
		    -label => '< More help >',
		    -onpress => sub {    $self->{cui}->dialog($help) ;}
		   } if $help ;

    push @buttons, { 
		    -label => '< Back >',
		    -onpress => sub {$self->{wizard}->go_backward ; $keep_wiz = 0 ;}
		   },
		   {
		    -label => "< Next >",
		    -onpress => sub {$self->{wizard}->go_forward ; $keep_wiz = 0 ;}
		   } ;

    my $buttons = $win->add ( undef, 'Buttonbox', 
			      '-y' => $win->canvasheight-1  ,
			      -buttonalignment => 'middle',
			      -selected => $#buttons , # select < Next > at startup
			      -buttons   => \@buttons
			    ) ;

    $buttons -> focus ;

    $self->{cui}->draw ;

    warn "entered local loop ",++$loop_c,"\n";
    while ($keep_wiz) {
	$self->{cui}->do_one_event ;
    }
    warn "exited local loop ",$loop_c,"\n";

    $self->{cui}->delete('wizard');

    if ($abort_wiz) {
	Config::Model::CursesUI::AbortWizard->throw ;
    }
}

# callback is used for tests only
sub wiz_walk {
    my ($self, $stop_on_important , $root) = @_ ;

    # mode can be wizard or error check
    warn "wiz_walk called on '", $root->name, "'\n" 
      if $verb_wiz;

    my ($sort_element, $sort_idx) ;

    my $hash_element_cb = sub 
      {
	my ($scanner, $data_ref,$node,$element_name,@keys) = @_ ;

	warn "wiz_walk, hash_cb (element $element_name) called on '", $node->name,
	  "' keys: '@keys' \n" if $verb_wiz;
	$self->display_hash_wizard($node, $element_name) ;
      } ;

    my %cb_hash ;
    my %override_meth = ( integer_value => 'layout_string_value',
			  number_value  => 'layout_string_value',
			  leaf          => 'layout_leaf_value',
                          check_list_element => 'layout_checklist' ,
			) ;

    foreach my $leaf_item (qw/leaf enum_value enum_integer_value
                              integer_value number_value 
                              boolean_value string_value/) {
	my $layout_meth = $override_meth{$leaf_item} || 'layout_'.$leaf_item ;
	$cb_hash{$leaf_item.'_cb'} = sub {
	    my @cb_args = @_ ;
	    splice @cb_args,0,2; # remove scanner and data_ref from cb args
	    warn "called $layout_meth for $leaf_item";
	    my $win = $self->set_center_window('wizard') ;
	    $self->$layout_meth($win,@cb_args) ;
	    $self->update_location(@cb_args) ;
	    $self->wrap_wizard($win,@cb_args) ;
	} ;
    }

    my @wiz_args = (experience        => $self->{experience},
		    hash_element_cb   => $hash_element_cb ,
		    %cb_hash 
		   );

    #Tk::ObjScanner::scan_object(\@wiz_args) ;
    $self->{wizard} = $root->instance->wizard_helper (@wiz_args);

    my $result;
    eval {$self->{wizard}->start ;} ;

    if (my $e = Config::Model::CursesUI::AbortWizard->caught()) {
	$e -> throw ; # propagate up
    }
    elsif ($@) {
	# really die
	warn "$@" ;
	$self->{cui}->fatalerror("display_view_list: $@") ;
    }

    return $result ;
  }

1;
__END__

=head1 NAME

Config::Model::CursesUI - Curses interface to edit config data

=head1 SYNOPSIS

 use Config::Model ;
 use Config::Model::CursesUI ;

 my $model = Config::Model -> new ;

 my $inst = $model->instance (root_class_name => 'XXX',
                              instance_name   => 'yyy');

 # create dialog
 my $dialog = Config::Model::CursesUI-> new
  (
   experience => 'beginner', # or 'advanced'
  ) ;

 # start never returns
 $dialog->start($model) ;

=head1 DESCRIPTION

This class provides a L<Curses::UI> interface to configuration data
managed by L<Config::Model>.

IMPORTANT: Once the CursesUI object is created, STDOUT and STDERR
are managed by the Curses interface, so all print and warn will not
work as expected.

=head1 CONSTRUCTOR

The constructor accepts the following parameters:

=over

=item experience

Specifies the experience level of the user (default:
C<beginner>). The experience can be C<master advanced
beginner>.

=item load

Subroutine ref containing the code to load the configuration data from
the configuration files. This may overrides loading mechanism
specified in the model with L<Config::Model::AutoRead>. This sub is
called without any arguments.

=item store

Subroutine ref containing the code to store the configuration data in
the configuration files.  This may overrides writing mechanism
specified in the model with L<Config::Model::AutoRead>. This sub is
called without any arguments.

=back

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 LICENSE

    Copyright (c) 2007-2009 Dominique Dumont.

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

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::ObjTreeScanner>, 
L<Curses::UI>,
L<Curses>

=cut

