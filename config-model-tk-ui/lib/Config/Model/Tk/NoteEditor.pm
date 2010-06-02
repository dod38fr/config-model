package Config::Model::Tk::NoteEditor ;

use strict;
use warnings ;
use Carp ;
use Log::Log4perl ;

use base qw/Tk::Frame/;
use vars qw/$icon_path/ ;
use subs qw/menu_struct/ ;
use Tk::Dialog ;
use Tk::Photo ;
use Tk::Balloon ;
use Tk; # Needed to import Ev function

Construct Tk::Widget 'ConfigModelNoteEditor';

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill x    -expand 1/ ;
my @fx   = qw/-fill x    / ;
my $logger = Log::Log4perl::get_logger(__PACKAGE__);

sub ClassInit {
    my ($cw, $args) = @_;
    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.

    # cw->Advertise(name=>$widget);
}

# This widget is to be integrated directly in a ConfigModel editor widget

sub Populate { 
    my ($cw, $args) = @_;
    my $obj = delete $args->{-object} 
      || croak "NoteEditor: no -object option, got ",
	join(',', keys %$args);

    my $label = 'Edit Note' ;
    my $status = $label;
    $cw->Label( -textvariable => \$status )->pack() ;
    my $note_w = $cw->Scrolled ( 'Text',
				 -height => 5 ,
				 -scrollbars => 'ow',
			       )
      ->pack(@fbe1);

    # read annotation and set up a callback to save user's entry at
    # every return
    $note_w ->  Contents($obj->annotation);
    $note_w -> bind('<Return>',
		       sub { $obj->annotation($note_w-> Contents ) ; $status = $label ;}
		      );
    $note_w -> bind ('<KeyPress>', 
		     sub { my $k = Ev('k') ; 
			   $status = $label.'(* hit enter to save)' if $k =~/\w/ ;},
		    );
    #$cw->Button(label=>'ok');
}
1;

