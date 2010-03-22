
package Config::Model::Tk::Wizard ;

use strict;
use warnings ;
use Carp ;

use base qw/Tk::Toplevel/;
use vars qw/$icon_path/ ;
use Log::Log4perl;

use Config::Model::Tk::LeafEditor ;
use Config::Model::Tk::CheckListEditor ;
use Config::Model::Tk::ListEditor ;
use Config::Model::Tk::HashEditor ;

Construct Tk::Widget 'ConfigModelWizard';

my $logger = Log::Log4perl::get_logger('Tk::Wizard');

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill x    -expand 1/ ;
my @fx   = qw/-fill x    / ;

sub ClassInit {
    my ($class, $mw) = @_;
    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.


    # cw->Advertise(name=>$widget);
}

sub Populate { 
    my ($cw, $args) = @_;

    foreach my $parm (qw/-root/) {
	my $attr = $parm ;
	$attr =~ s/^-//;
	$cw->{$attr} = delete $args->{$parm} 
	  or croak "Missing $parm arg\n";
    }

    foreach my $parm (qw/-from_widget -stop_on_important -store_cb -show_cb/) {
	my $attr = $parm ;
	$attr =~ s/^-//;
	$cw->{$attr} = delete $args->{$parm} ;
    }

    $logger->info("Creating wizard widget");
    $cw->{show_cb} ||= sub {} ;

    my $title = delete $args->{'-title'} 
              || "config wizard ".$cw->{root}->config_class_name ;

    $cw->Label( -text => "Configuration of ".$cw->{root}->config_class_name,
		-font => [ -size => 20 ],
	      )
      -> pack ;

    my $ed = $cw->{ed_frame} = $cw->Frame 
      ->pack  (qw/-pady 0 -fill both -expand 1/ ) ;
    $cw->{ed_frame}->packPropagate(0) ;

    $args->{-title} = $title;
    $cw->SUPER::Populate($args) ;

    $cw->Advertise(ed_frame   => $ed ,
		  );

    $cw->ConfigSpecs
      (
       #-background => ['DESCENDANTS', 'background', 'Background', $background],
       #-selectbackground => [$hlist, 'selectBackground', 'SelectBackground', 
       #                      $selectbackground],
       -width  => [$ed, undef, undef, 600 ],
       -height => [$ed, undef, undef, 400 ],
       DEFAULT => [ $ed ]
      ) ;

}

sub save {
    my $cw = shift ;

    $cw->check() ;

    $logger->info("Saving data in default directory with instance write_back" );
    $cw->{root}->instance->write_back();
}

sub leaf_cb {
    my ($cw,$scanner, $data_ref,$node,$element_name,$index, $leaf_object) = @_ ;
    # cleanup existing widget contained in this frame
    $cw->{show_cb}->($leaf_object) ;
    $cw->{ed_frame}->ConfigModelLeafEditor(-item => $leaf_object, 
					   -store_cb => $cw->{store_cb},
					  )->pack(@fbe1) ;
}

sub list_element_cb {
    my ($cw,$scanner, $data_ref,$node,$element_name,@indexes) = @_ ;
    # cleanup existing widget contained in this frame
    my $obj = $node->fetch_element($element_name) ;
    $cw->{show_cb}->($obj) ;
    $cw->{ed_frame}->ConfigModelListEditor(-item => $obj, 
					   -store_cb => $cw->{store_cb},
					  )->pack(@fbe1) ;
}

sub hash_element_cb {
    my ($cw,$scanner, $data_ref,$node,$element_name,@keys) = @_ ;
    # cleanup existing widget contained in this frame
    my $obj = $node->fetch_element($element_name) ;
    $cw->{show_cb}->($obj) ;
    $cw->{ed_frame}->ConfigModelHashEditor(-item => $obj, 
					   -store_cb => $cw->{store_cb},
					  )->pack(@fbe1) ;
}
sub check_list_element_cb {
    my ($cw,$scanner, $data_ref,$node,$element_name,@items) = @_ ;
    # cleanup existing widget contained in this frame
    my $obj = $node->fetch_element($element_name) ;
    $cw->{show_cb}->($obj) ;
    $cw->{ed_frame}->ConfigModelCheckListEditor(-item => $obj, 
						-store_cb => $cw->{store_cb},
					       )->pack(@fbe1) ;
}

sub start_wizard {
    my ($cw,$exp) = @_ ;

    my $text = 'The wizard will scan all configuration items and stop on "important" items or on error (like missing mandatory values). If no "important" item and no error are found, the wizard will exit immediately' ;

    my $edf = $cw->{ed_frame} ;

    my $textw = $edf
      -> ROText(qw/-relief flat -wrap word -height 12/,
		-font => [ -family => 'Arial' ]
	       );
    $textw -> insert(end => $text) ;
    $textw -> pack(-side => 'top', @fbe1) ;


    $edf->Label(-text => 'Choose experience for the wizard :'.$exp)
      ->pack(qw/-side top -anchor w/);

    map { $edf->Radiobutton(-text => $_ ,
			    -variable => \$exp,
			    -value => $_
			   )->pack(qw/-side top -anchor w/);
      } qw/master advanced beginner/ ;

    $edf->Button(-text => 'OK',
		 -command => sub {$cw->_start_wizard($exp)}
		) -> pack (-side => 'right') ;
    $edf->Button(-text => 'cancel',
		 -command => sub {$cw->destroy()}
		) -> pack (-side => 'left') ;
}

sub _start_wizard {
    my ($cw,$exp) = @_ ;

    my $button_f  = $cw->Frame 
      ->pack  (qw/-pady 0 -fill x -expand 1/ ) ;

    my $back = $button_f -> Button(-text => 'Back', 
				   -command => sub {
				       $cw->{keep_wiz} = 0 ;
				       $cw->{wizard}->go_backward;
				   } 
				  );
    $back -> pack(qw/-side left -fill x -expand 1/) ;

    my $stop = $button_f -> Button(-text => 'Stop', 
				   -command => sub {$cw->destroy;} 
				  );
    $stop -> pack(qw/-side left -fill x -expand 1/) ;

    my $forw = $button_f -> Button(-text => 'Next', 
				   -command => sub {
				       $cw->{keep_wiz} = 0 ;
				       $cw->{wizard}->go_forward;
				   } 
				  );
    $forw-> pack(qw/-side right -fill x -expand 1/) ;

    my ($sort_element, $sort_idx) ;
    $cw->{keep_wiz} = 1 ;

    my %cb_table ;
    # a local event loop is run within the call-back
    foreach my $cb_key (qw/leaf_cb check_list_element_cb 
			   list_element_cb hash_element_cb/) {
	$cb_table{$cb_key} = sub 
	  {
	      my ($scanner, $data_ref,$node,$element_name) = @_ ;
	      $logger->info("$cb_key (element $element_name) called on '", 
			    $node->name,"'->'$element_name'");
	      map { $_ ->destroy if Tk::Exists($_) } $cw->{ed_frame}->children ;
	      $cw->{keep_wiz} = 1 ;
	      $cw->$cb_key(@_) ;
	      my $loop_c = 0;
	      $logger->debug("$cb_key wizard entered local loop ",++$loop_c);
	      $cw->DoOneEvent() while $cw->{keep_wiz};
	      $logger->debug("$cb_key wizard exited local loop ",$loop_c);
	  } ;
    }


    my @wiz_args = (experience        => $exp,
		    %cb_table 
		   );


    #Tk::ObjScanner::scan_object(\@wiz_args) ;
    $cw->{wizard} = $cw->{root}->instance->wizard_helper (@wiz_args);

    # exits when wizard is done
    $cw->{wizard}->start ;

    $cw->destroy ;
  }

1;

