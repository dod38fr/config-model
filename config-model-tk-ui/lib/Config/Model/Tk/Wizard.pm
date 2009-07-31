# $Author: ddumont $
# $Date: 2009-06-24 12:48:54 +0200 (Wed, 24 Jun 2009) $
# $Revision: 987 $

package Config::Model::Tk::Wizard ;

use strict;
use warnings ;
use Carp ;

use base qw/Tk::Toplevel/;
use vars qw/$VERSION $icon_path/ ;
use Log::Log4perl;

use Config::Model::Tk::LeafEditor ;
use Config::Model::Tk::CheckListEditor ;
use Config::Model::Tk::ListEditor ;
use Config::Model::Tk::HashEditor ;

Construct Tk::Widget 'ConfigModelWizard';

my $logger = Log::Log4perl::get_logger('Tk::Wizard');

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

    foreach my $parm (qw/-from_widget -stop_on_important -store_cb/) {
	my $attr = $parm ;
	$attr =~ s/^-//;
	$cw->{$attr} = delete $args->{$parm} ;
    }

    $logger->info("Creating wizard widget");

    my $title = delete $args->{'-title'} 
              || "config wizard ".$cw->{root}->config_class_name ;

    $cw->Label( -text => "Configuration of ".$cw->{root}->config_class_name,
		-font => [ -size => 20 ],
	      )
      -> pack ;

    my $ed = $cw->{ed_frame} = $cw->Frame 
      ->pack  (qw/-pady 0 -fill both -expand 1/ ) ;
    $cw->{ed_frame}->packPropagate(0) ;

    my $button_f  = $cw->Frame 
      ->pack  (qw/-pady 0 -fill x -expand 1/ ) ;

    my $back = $button_f -> Button(-text => 'Back', 
				   -command => sub {
				       $cw->{keep_wiz} = 0 ;
				       $cw->{wizard}->go_backward;
				   } 
				  );
    $back -> pack(-side => 'left') ;
    my $forw = $button_f -> Button(-text => 'Next', 
				   -command => sub {
				       $cw->{keep_wiz} = 0 ;
				       $cw->{wizard}->go_forward;;
				   } 
				  );
    $forw-> pack(-side => 'right') ;

    $args->{-title} = $title;
    $cw->SUPER::Populate($args) ;

    $cw->Advertise(ed_frame => $ed ,
		   go_back => $back,
		   go_forward => $forw,
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
    $cw->{ed_frame}->ConfigModelLeafEditor(-item => $leaf_object, 
					   -store_cb => $cw->{store_cb},
					  )->pack ;
}

sub list_element_cb {
    my ($cw,$scanner, $data_ref,$node,$element_name,@indexes) = @_ ;
    # cleanup existing widget contained in this frame
    my $obj = $node->fetch_element($element_name) ;
    $cw->{ed_frame}->ConfigModelListEditor(-item => $obj, 
					   -store_cb => $cw->{store_cb},
					  )->pack ;
}

sub hash_element_cb {
    my ($cw,$scanner, $data_ref,$node,$element_name,@keys) = @_ ;
    # cleanup existing widget contained in this frame
    my $obj = $node->fetch_element($element_name) ;
    $cw->{ed_frame}->ConfigModelHashEditor(-item => $obj, 
					   -store_cb => $cw->{store_cb},
					  )->pack ;
}
sub check_list_element_cb {
    my ($cw,$scanner, $data_ref,$node,$element_name,@items) = @_ ;
    # cleanup existing widget contained in this frame
    my $obj = $node->fetch_element($element_name) ;
    $cw->{ed_frame}->ConfigModelCheckListEditor(-item => $obj, 
						-store_cb => $cw->{store_cb},
					       )->pack ;
}

sub start_wizard {
    my ($cw) = @_ ;

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


    my @wiz_args = (experience        => $cw->{experience},
		    %cb_table 
		   );


    #Tk::ObjScanner::scan_object(\@wiz_args) ;
    $cw->{wizard} = $cw->{root}->instance->wizard_helper (@wiz_args);

    # exits when wizard is done
    $cw->{wizard}->start ;

    $cw->destroy ;
  }

1;
__END__

