
#    Copyright (c) 2009 Dominique Dumont.
#
#    This file is part of Config-Model-DebconfUI.
#
#    Config-Model is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Model is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

package Config::Model::Debconf::Wizard;

use strict;
use warnings ;
use Carp ;

# use vars qw/$VERSION/ ;

use Log::Log4perl;

my $logger = Log::Log4perl::get_logger('Tk::Wizard');

use Debconf::Client::ConfModule ':all';

sub new {
    my $class = shift ;

    my $self = {} ;

    foreach my $parm (qw/-root/) {
	my $attr = $parm ;
	$attr =~ s/^-//;
	$self->{$attr} = delete $args->{$parm} 
	  or croak "Missing $parm arg\n";
    }

    foreach my $parm (qw/-from_widget -stop_on_important -store_cb/) {
	my $attr = $parm ;
	$attr =~ s/^-//;
	$self->{$attr} = delete $args->{$parm} ;
    }

    $logger->info("Creating wizard widget");

    bless $self,$type ;
}

# FIXME: should debconf template be generated from a model ?
# then stored in /var/lib/config-model 
# debconf namespace ??
# then used with X_LOADTEMPLATEFILE
# when should this file be generated ? run time bcoz run in pre-install script

sub start_wizard {
    my ($self,$exp) = @_ ;

    my $text = 'The wizard will scan all configuration items and stop on "important" items or on error (like missing mandatory values). If no "important" item and no error are found, the wizard will exit immediately' ;

    my $edf = $self->{ed_frame} ;

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
		 -command => sub {$self->_start_wizard($exp)}
		) -> pack (-side => 'right') ;
    $edf->Button(-text => 'cancel',
		 -command => sub {$self->destroy()}
		) -> pack (-side => 'left') ;
}

sub _start_wizard {
    my ($self,$exp) = @_ ;

    my $button_f  = $self->Frame 
      ->pack  (qw/-pady 0 -fill x -expand 1/ ) ;

    my $back = $button_f -> Button(-text => 'Back', 
				   -command => sub {
				       $self->{keep_wiz} = 0 ;
				       $self->{wizard}->go_backward;
				   } 
				  );
    $back -> pack(qw/-side left -fill x -expand 1/) ;

    my $stop = $button_f -> Button(-text => 'Stop', 
				   -command => sub {$self->destroy;} 
				  );
    $stop -> pack(qw/-side left -fill x -expand 1/) ;

    my $forw = $button_f -> Button(-text => 'Next', 
				   -command => sub {
				       $self->{keep_wiz} = 0 ;
				       $self->{wizard}->go_forward;
				   } 
				  );
    $forw-> pack(qw/-side right -fill x -expand 1/) ;

    my ($sort_element, $sort_idx) ;
    $self->{keep_wiz} = 1 ;

    my %cb_table ;
    # a local event loop is run within the call-back
    foreach my $cb_key (qw/leaf_cb check_list_element_cb 
			   list_element_cb hash_element_cb/) {
	$cb_table{$cb_key} = sub 
	  {
	      my ($scanner, $data_ref,$node,$element_name) = @_ ;
	      $logger->info("$cb_key (element $element_name) called on '", 
			    $node->name,"'->'$element_name'");
	      map { $_ ->destroy if Tk::Exists($_) } $self->{ed_frame}->children ;
	      $self->{keep_wiz} = 1 ;
	      $self->$cb_key(@_) ;
	      my $loop_c = 0;
	      $logger->debug("$cb_key wizard entered local loop ",++$loop_c);
	      $self->DoOneEvent() while $self->{keep_wiz};
	      $logger->debug("$cb_key wizard exited local loop ",$loop_c);
	  } ;
    }


    my @wiz_args = (experience        => $exp,
		    %cb_table 
		   );


    #Tk::ObjScanner::scan_object(\@wiz_args) ;
    $self->{wizard} = $self->{root}->instance->wizard_helper (@wiz_args);

    # exits when wizard is done
    $self->{wizard}->start ;

    $self->destroy ;
  }

1;

