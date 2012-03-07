package Config::Model::Tk::LeafEditor ;

use strict;
use warnings ;
use Carp ;
use Log::Log4perl;
use Config::Model::Tk::NoteEditor ;
use File::Temp ;
use File::Slurp ;
use Tk::Balloon ;

use base qw/Config::Model::Tk::LeafViewer/;


Construct Tk::Widget 'ConfigModelLeafEditor';

my @fbe1 = qw/-fill both -expand 1/ ;
my @fxe1 = qw/-fill x    -expand 1/ ;
my @fx   = qw/-fill x  / ;

my $logger = Log::Log4perl::get_logger("Tk::LeafEditor");

sub ClassInit {
    my ($cw, $args) = @_;
    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.

    # cw->Advertise(name=>$widget);
}

sub Populate { 
    my ($cw, $args) = @_;
    my $leaf = $cw->{leaf} = delete $args->{-item} 
      || die "LeafEditor: no -item, got ",keys %$args;
    delete $args->{-path} ;
    $cw->{store_cb} = delete $args->{-store_cb} || die __PACKAGE__,"no -store_cb" ;

    my $inst = $leaf->instance ;
    my $vt = $leaf -> value_type ;
    $logger->info("Creating leaf editor for value_type $vt");
    $cw->{value} = $leaf->fetch ( check => 'no');
    $logger->info("Creating leaf editor with error ".$leaf->error_msg);

    $cw->add_header(Edit => $leaf)->pack(@fx) ;

    my $vref = \$cw->{value};

    my @pack_args = @fx ;
    @pack_args = @fbe1 if $vt eq 'string' or $vt eq 'enum' 
                       or $vt eq 'reference' ;

    my $ed_frame =  $cw->Frame(qw/-relief raised -borderwidth 2/)
      ->pack(@pack_args) ;
    $ed_frame  -> Label(-text => 'Value') -> pack() ;

    my $balloon = $cw->Balloon(-state => 'balloon') ;

    if ($vt eq 'string') {
        $cw->{e_widget} = $ed_frame->Scrolled ( 'Text',
                                                -height => 5 ,
                                                -scrollbars => 'ow',
                                              )
                             ->pack(@fbe1);
        $cw->{e_widget}
          ->tagConfigure(qw/value -lmargin1 2 -lmargin2 2 -rmargin 2/);
        $cw->reset_value ;
        my $bframe = $cw->add_buttons($ed_frame) ;
        $bframe -> Button ( -text => 'Cleanup',
                            -command => sub { $cw->cleanup},
                          ) -> pack(-side => 'left') ;
        my $ext_ed_b = $bframe -> Button ( 
            -text => 'Ext editor',
            -command => sub { $cw->exec_external_editor},
            -state => defined $ENV{EDITOR} ? 'normal' : 'disabled' ,
        ) -> pack( -side => 'left') ;
        $balloon->attach(
            $ext_ed_b,
            -msg => "Run external editor (if EDITOR environment variable is set"
        );
    }
    elsif ($vt eq 'boolean') {
        $ed_frame->Checkbutton(-text => $leaf->element_name,
                         -variable => $vref,
                         -command => sub { $cw->try},
                        )
          ->pack();
        $cw->add_buttons($ed_frame) ;
    }
    elsif ($vt eq 'uniline' or $vt eq 'integer') {
        $ed_frame -> Entry(-textvariable => $vref)
            -> pack(@fx);
        $cw->add_buttons($ed_frame) ;
    }
    elsif ($vt eq 'enum' or $vt eq 'reference') {
        my $lb = $ed_frame->Scrolled ( 'Listbox',
                                       -height => 5,
                                       -scrollbars => 'osow',
                                       #-listvariable => $vref,
                                       #-selectmode => 'single',
                                     ) ->pack(@fbe1) ;
        my @choice = $leaf->get_choice ;
        $lb->insert('end',$leaf->get_choice) ;
        my $idx = 0;
        if (defined $$vref) {
          map { $lb->selectionSet($idx) if $_ eq $$vref; $idx ++}  @choice;
        }
        $lb->bind('<Button-1>',sub {$cw->try($lb->get($lb->curselection()))});
        $cw->add_buttons($ed_frame) ;

    }

    $cw->ConfigModelNoteEditor( -object => $leaf )->pack;
    $cw->add_warning($leaf, 'edit')->pack(@fx) ;
    $cw->add_info_button()->pack( @fx,qw/-anchor n/) ;
    $cw->add_summary($leaf)->pack(@fx) ;
    $cw->add_description($leaf)->pack(@fx) ;
    my ($help_frame, $help_widget) = $cw->add_help('help on value' => '',1);

    $cw->Advertise( value_help_widget  => $help_widget );
    $cw->Advertise( value_help_frame   => $help_frame  );

    $cw->set_value_help ;

    $cw->ConfigSpecs(
                     #-fill   => [ qw/SELF fill Fill both/],
                     #-expand => [ qw/SELF expand Expand 1/],
                     -relief => [qw/SELF relief Relief groove/ ],
                     -borderwidth => [qw/SELF borderwidth Borderwidth 2/] ,
                     DEFAULT => [ qw/SELF/ ],
           );

    # don't call directly SUPER::Populate as it's LeafViewer's populate
    $cw->Tk::Frame::Populate($args) ;
}

sub cleanup {
    my ($cw) = @_ ;
    my $text_widget = $cw->{e_widget} || return ;
    my $selected = $text_widget -> getSelected ;
    my $text = $selected || $text_widget -> Contents ;
    $text =~ s/^\s+//gm;
    $text =~ s/\s+$//gm;
    $text =~ s/\s+/ /g;

    if ($selected) {
        $text_widget -> Insert ($text) ;
    } else {
        $text_widget -> Contents($text) ;
    }
}

sub add_buttons {
    my ($cw,$frame) = @_ ;
    my $bframe = $frame->Frame->pack() ;
    $bframe -> Button ( -text => 'Reset',
                        -command => sub { $cw->reset_value ; },
                      ) -> pack(-side => 'left') ;
    $bframe -> Button ( -text => 'Delete',
                        -command => sub { $cw->delete},
                      ) -> pack(-side => 'left') ;
    $bframe -> Button ( -text => 'Store',
                        -command => sub { $cw->store},
                      ) -> pack(-side => 'right') ;
    return $bframe ;
}


sub try {
    my $cw = shift ;
    my $v = shift ;

    if (defined $v) {
        $cw->{value} = $v ;
    }
    else {
        my $e_w = $cw->{e_widget} ;
        # tk widget use a reference
        $v = defined  $e_w ? $e_w->get('1.0','end')
           :                 $cw->{value} ;
    }

    $v = '' unless defined $v ;
    chomp $v ;

    $logger->debug( "try: value $v") ;
    require Tk::Dialog ;

    my @errors = $cw->{leaf}->check(value => $v,quiet => 1) ;

    if (@errors ) {
        $cw -> Dialog ( -title => 'Value error',
                        -text  => join("\n",@errors),
                      )
            -> Show ;
        $cw->reset_value ;
        return ;
    }
    else {
        $cw->set_value_help($v) ;
        return $v ;
    }
}

sub delete {
    my $cw = shift ;

    eval {$cw->{leaf}->store(undef); } ;

    if ($@) {
        $cw -> Dialog ( -title => 'Delete error',
                        -text  => $@->as_string,
                      )
            -> Show ;
    }
    else {
        # trigger redraw of Tk Tree
        $cw->reset_value ;
        $cw->update_warning($cw->{leaf}) ;
        $cw->parent->parent->parent->parent->reload(1) ;
    }
}

# can be used without parameters to store value from widget into config tree
sub store {
    my $cw = shift ;
    my $v = $cw->try(@_) ;
    return unless defined $v;

    print "Storing '$v'\n";

    eval {$cw->{leaf}->store($v); } ;

    if ($@) {
        $cw -> Dialog ( -title => 'Value error',
                        -text  => $@->as_string,
                      )
            -> Show ;
    }
    else {
        # trigger redraw of Tk Tree
        $cw->{store_cb}->($cw->{leaf}) ;
        $cw->update_warning($cw->{leaf}) ;
    }
}

sub set_value_help {
    my $cw = shift;
    my $v  = $cw->{value};
    my $value_help = defined $v ? $cw->{leaf}->get_help($v) : '' ;

    my $w = $cw->Subwidget('value_help_widget');
    my $f = $cw->Subwidget('value_help_frame');
 
    if ( $value_help ) {
        #$w->delete( '0.0', 'end' );
        #$w->insert( 'end', $value_help ) ;
        $cw->update_help($w,$value_help);
        $f->pack(@fbe1) ;
    }
    else {
        $f->packForget ;
    }
}

sub reset_value {
    my $cw = shift ;
    $cw->{value} = $cw->{leaf}->fetch (check => 'no') ;
    if (defined $cw->{e_widget}) {
        $cw->{e_widget}->delete('1.0','end') ;
        $cw->{e_widget}->insert('end',$cw->{value},'value') ;
    }
    $cw->set_value_help if defined $cw->{value_help_widget};
}

sub exec_external_editor {
    my $cw = shift ;

    my $fh = File::Temp->new ; ;
    die "Can't open temp file:$!" unless defined $fh ;
    binmode($fh,":utf8");
    $fh->print($cw->{value});
    $fh->close ;

    # See mastering Perl/Tk p382
    my $h = $cw->{ed_handle} = IO::Handle->new;
    die "IO::Handle->new failed." unless defined $h;

    my $ed = $ENV{EDITOR}.' '.$fh->filename ;
    $cw->{ed_pid} = open $h, $ed . ' 2>&1 |';

    if (not defined $cw->{ed_pid}) {
	$cw -> Dialog ( -title => 'External editor error',
                        -text  => "'$ed' : $!",
                      )
            -> Show ;
 	return;
    }
    $h->autoflush(1);
    $cw->fileevent($h, 'readable' => [\&_read_stdout, $cw]);
    
    # prevent navigation in the tree (and destruction of this widget
    # while the external editor is active). See mastering Perl/Tk p302
    $cw->grab ;

    $cw->waitVariable(\$cw->{ed_done});
    
    $cw->grabRelease; 
    
    my $new_v = read_file($fh->filename) ;
    print "exec_external_editor done with '$new_v'\n";
    $cw->store($new_v);
    $cw->reset_value ;
}

# also from Mastering Perl/Tk
sub _read_stdout {

    # Called when input is available for the output window.  Also checks
    # to see if the user has clicked Cancel.
    print "_read_stdout called\n";
    my ($cw) = @_;

    my $h = $cw->{ed_handle};
    die "External editor handle is udefined!\n" unless defined $h;
    my $stat;
    
    if ( $stat = sysread $h, $_, 4096 ) {
	print ;
    } elsif ( $stat == 0 ) {
        print "edition done\n";
        $h->close ;
	$cw->{ed_done} = 1;
    } else {
        die "External editor sysread error: $!";
    }
} # end _read_stdout

sub reload {
    my $cw = shift;
    $cw -> reset_value ;
    $cw->update_warning ($cw->{leaf});
}
1;
