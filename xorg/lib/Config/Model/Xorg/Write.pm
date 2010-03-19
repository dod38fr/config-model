
#    Copyright (c) 2005-2009 Dominique Dumont.
#
#    This file is part of Config-Xorg.
#
#    Config-Xorg is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Xorg is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

package Config::Model::Xorg::Write ;

use strict;
use warnings ;
use Carp ;
use IO::File ;
use Config::Model::ObjTreeScanner ;
use Log::Log4perl ;
use File::Path ;

# use vars qw($VERSION) ;


my $logger = Log::Log4perl::get_logger(__PACKAGE__);

sub write {
    my %args = @_ ;
    my $config_root = $args{object}
      || croak __PACKAGE__," write: undefined config root object";
    my $conf_dir = $args{config_dir} 
      || croak __PACKAGE__," write: undefined config_dir";
    my $root = $args{root} || '';

    my $dir = join('/',$root,$conf_dir) ;

    unless (-d $dir ) {
	mkpath($dir,{mode => 0755 }) || 
	  die __PACKAGE__," write: can't create dir $dir:$!";
    }

    my $file = "$dir/xorg.conf" ;

    $logger->info( __PACKAGE__." write: writing config file $file\n");

    open (CONF,"> $file ") || die __PACKAGE__," write: can't open $file:$!";

    print CONF join("\n", write_all($config_root)) ;
    close CONF;
}

sub wr_std_leaf {
    my ($scanner, $data_r, $node,$element_name,$index, $leaf_object,$v) = @_ ;
    push @$data_r , qq(\t$element_name\t"$v") if defined $v;
} ;

sub wr_module {
    my ($scanner, $data_r , $node,$element_name,$index, $leaf_object,$v) = @_ ;
    push @$data_r, qq(\tLoad "$element_name") if $v ;
} ;

sub wr_std_options {
    my ($scanner, $data_r ,$node,$element_name,$index, $leaf_object,$v) = @_ ;
    my $b_in = $leaf_object->upstream_default ;
    if ( defined $v && (   (not defined $b_in) 
			|| (defined $b_in && $v && $v ne $b_in) )
       ) {
	my $str =  qq(\tOption\t"$element_name");
	$str .= qq(\t"$v") if defined $v && $v ;
	push @$data_r, $str ;
    }
} ;

sub wr_kbd_model_options {
    my ($scanner, $data_r ,$node,$element_name,$index, $leaf_object,$v) = @_ ;
    if ( defined $v && $v ) {
	push @$data_r, qq(\tOption\t"XkbOptions"\t"$element_name:$v");
    }
} ;

sub push_value {
    my ($scanner, $data_r ,$node,$element_name,$index, $leaf_object,$v) = @_ ;
    push @$data_r, $v if defined $v;
} ;


sub push_flag_value {
    my ($scanner, $data_r ,$node,$element_name,$index, $leaf_object,$v) = @_ ;
    if (defined $v && $element_name =~ s/Polarity// ) {
	$v = ($v eq 'positive' ? '+' : '-' ) . $element_name ;
	push @$data_r, $v ;
    }
    else {
	push @$data_r, $element_name if defined $v && $v ;
    }
} ;

my %dispatch_leaf 
  = (
     'Xorg' => 1,
     'Xorg::Module' => \&wr_module,
     'Xorg::Files'  => \&wr_std_leaf ,
     'Xorg::InputDevice' => \&wr_std_leaf ,
     'Xorg::InputDevice::MouseOpt' => \&wr_std_options ,
     'Xorg::InputDevice::KeyboardOpt' => \&wr_std_options ,
     'Xorg::Device' => \&wr_std_leaf ,
     'Xorg::Device::Ati' => \&wr_std_options ,
     'Xorg::Device::Radeon' => \&wr_std_options ,
     'Xorg::Device::Nvidia' => \&wr_std_options ,
     'Xorg::Device::Fglrx' => \&wr_std_options ,
     'Xorg::Device::Vesa' => \&wr_std_options ,
     'Xorg::Extensions' => \&wr_std_options ,
     'Xorg::Extensions::Option' => \&wr_std_options ,
     'Xorg::Monitor' => \&wr_std_leaf ,
     'Xorg::Monitor::Option' => \&wr_std_options ,
     'Xorg::Monitor::Mode' => \&push_value ,
     'Xorg::Monitor::Mode::Timing' => \&push_value ,
     'Xorg::Monitor::Mode::Flags' => \&push_flag_value ,
     'Xorg::Screen' => \&wr_std_leaf ,
     'Xorg::Screen::Option' => \&wr_std_options ,
     'Xorg::Screen::Display' => \&wr_std_leaf ,
     'Xorg::ServerLayout' => \&wr_std_leaf ,
     'Xorg::ServerFlags' => \&wr_std_options ,
     'Xorg::DRI' => \&wr_std_leaf
    ) ;

my %dispatch_leaf_re 
 = (
    'Xorg::InputDevice::KeyboardOptModel::.*' => \&wr_kbd_model_options ,
   ) ;

sub wr_leaf {
    my ($scanner, $data_r, $node,$element_name,$index, $leaf_object) = @_ ;
    my $v = $leaf_object->fetch ;
    my $class_name = $node ->config_class_name() ;
    my $cb = $dispatch_leaf{$class_name} ;

    if (not defined $cb) {
	foreach my $k (keys %dispatch_leaf_re) {
	    next unless $class_name =~ /$k/ ;
	    $cb = $dispatch_leaf_re{$k};
	    #warn "using regexp dispath $k for $class_name\n";
	    last;
	}
    }

    if (defined $cb && ref $cb) {
	$cb->(@_ ,$v ) ;
    }
    elsif (not defined $cb) {
	# can't fallback to wr_std_leaf as some elements from model
	# are not meant to be written back in xorg.conf
	warn "wr_leaf: no call-back defined for ",$node ->config_class_name() ;
    }
} 

sub wr_section {
    my ($scanner, $data_r, $node,$element_name,$key,$next_node) = @_;
    #print "wr_section called on ",$node->name," $element_name,$key\n";

    my @section_lines ;
    push @section_lines, qq(\tIdentifier\t"$key") if defined $key ;

    if ($element_name eq 'InputDevice') {
	map {
	    my $core_v = $node->grab_value("! $_") ;
	    push @section_lines, qq(\tOption\t"$_")
	      if (defined $core_v and $key eq $core_v) ;
	} qw/CoreKeyboard CorePointer/ ;
    }

    $scanner->scan_node(\@section_lines,$next_node) ;

    if (@section_lines) {
	push @$data_r, qq(Section "$element_name"), @section_lines,
	  "EndSection" , '' ;
    }
}

sub wr_mode_line {
    my ($scanner, $data_r, $node,$element_name,$key,$next_node) = @_;

    my @mode_values ;
    $scanner->scan_node(\@mode_values,$next_node) ;
    my @numbers = splice (@mode_values, 0, 9) ;

    my $flags = join(' ',@mode_values) || '' ;
    push @$data_r,
      sprintf(
	      qq(\tModeLine %-20s %8.3f %4u %4u %4u %4u %4u %4u %4u %4u %s),
	      qq("$key"), @numbers, $flags);
} ;

sub wr_sub_section {
    my ($scanner, $data_r, $node,$element_name,$key,$next_node) = @_;
    { 
	no warnings "uninitialized" ;
	$logger->debug( "wr_sub_section called on ",$node->name," $element_name,$key");
    }

    push @$data_r, qq(\tSubSection "$element_name") ,
                   qq(\t\tDepth\t$key) ;

    $scanner->scan_node($data_r,$next_node) ;
    push @$data_r, "\tEndSubSection" , '' ;
} ;

sub wr_serverlayout_screen {
    my ($scanner, $data_r, $node,$element_name,$key,$next_node) = @_;
    my $id = $next_node->fetch_element_value('screen_id') ;
    my $rel_loc = $next_node->grab_value("position relative_screen_location") ;

    my $str = qq(\tScreen $key "$id") ;

    if (defined $rel_loc) {
	$str .= qq( $rel_loc ) ;
	my $pos_obj = $next_node->fetch_element('position') ;
	if ($pos_obj-> is_element_available('screen_id')) {
	    $str .= '"'. $pos_obj->fetch_element_value("screen_id").'" ' ;
	}
	if ($pos_obj-> is_element_available('x')) {
	    map {
		$str .= $pos_obj->fetch_element_value($_).' ' ;
		} qw/x y/ ;
	}

    }
    push @$data_r, $str ;
}

sub wr_serverlayout_inputdevice {
    my ($scanner, $data_r, $node,$element_name,$key,$next_node) = @_;

    my $str = qq(\tInputDevice "$key") ;
    my $sce = $next_node->fetch_element_value("SendCoreEvents");
    if (defined $sce && $sce) {
	$str .= ' "SendCoreEvents" ' ;
    }
    push @$data_r, $str ;
}

sub wr_monitor_display_size {
    my ($scanner, $data_r, $node,$element_name,$key,$next_node) = @_;

    my $w = $next_node->fetch_element_value("width") ;
    my $h = $next_node->fetch_element_value("height") ;

    push @$data_r, "\tDisplaySize\t$w $h" if defined $w && defined $h; 
}

sub wr_monitor_gamma {
    my ($scanner, $data_r, $node,$element_name,$key,$next_node) = @_;

    if ($next_node->fetch_element_value("use_global_gamma")) {
	my $g = $next_node->fetch_element_value("gamma") ;
	push @$data_r, "\tGamma\t$g" if defined $g ;
    }
    else {
	my @v = map { $next_node->fetch_element_value($_."_gamma") }
	  qw/red green blue/ ;
	push @$data_r, "\tGamma\t@v" ;
    }

}

sub wr_screen_display_virtual {
    my ($scanner, $data_r, $node,$element_name,$key,$next_node) = @_;

    my $x = $next_node->fetch_element_value("xdim") ;
    my $y = $next_node->fetch_element_value("ydim") ;

    push @$data_r, "\t\tVirtual\t$x $y" if defined $x && defined $y; 
}

sub wr_screen_display_viewport {
    my ($scanner, $data_r, $node,$element_name,$key,$next_node) = @_;

    my $x = $next_node->fetch_element_value("x0") ;
    my $y = $next_node->fetch_element_value("y0") ;

    push @$data_r, "\t\tViewPort\t$x $y" if defined $x && defined $y; 
}

sub wr_device_kbd_autorepeat {
    my ($scanner, $data_r, $node,$element_name,$key,$next_node) = @_;

    my $d = $next_node->fetch_element_value("delay") ;
    my $r = $next_node->fetch_element_value("rate") ;

    push @$data_r, qq(\tOption\t"AutoRepeat" "$d $r")
      if defined $d && defined $r; 
}

my %dispatch_node 
  = ( 
     'Xorg' => 1 ,
     'Xorg::Extensions' => \&wr_section,
     'Xorg::Files' => \&wr_section,
     'Xorg::Module' => \&wr_section,
     'Xorg::InputDevice' => \&wr_section,
     'Xorg::InputDevice::KeyboardOpt::AutoRepeat' => \&wr_device_kbd_autorepeat,
     'Xorg::Device' => \&wr_section,
     'Xorg::DRI' => \&wr_section,
     'Xorg::Monitor' => \&wr_section,
     'Xorg::Monitor::Mode' => \&wr_mode_line ,
     'Xorg::Monitor::DisplaySize' => \&wr_monitor_display_size ,
     'Xorg::Monitor::Gamma' => \&wr_monitor_gamma ,
     'Xorg::Screen' => \&wr_section,
     'Xorg::Screen::Display' => \&wr_sub_section,
     "Xorg::Screen::Display::Virtual" => \&wr_screen_display_virtual,
     "Xorg::Screen::Display::ViewPort" => \&wr_screen_display_viewport,
     'Xorg::ServerLayout' => \&wr_section,
     'Xorg::ServerFlags' => \&wr_section,
     'Xorg::ServerLayout::Screen' => \&wr_serverlayout_screen,
     'Xorg::ServerLayout::InputDevice' => \&wr_serverlayout_inputdevice,
    ) ;

sub wr_node {
    my ($scanner, $data_r, $node,$element_name,$key, $next_node) = @_;
    my $dispatcher_data = $next_node->config_class_name ;
    my $cb = $dispatch_node{$dispatcher_data} ;
    if (defined $cb && ref $cb) { $cb->(@_) ; }
    elsif (defined $cb && $cb) {
	$scanner->scan_node($data_r,$next_node) ;
    }
    else {
	no warnings "uninitialized" ;
	$logger->debug( "wr_node called on $dispatcher_data $element_name,$key");
	$scanner->scan_node($data_r,$next_node) ;
    }
} ;

sub wr_mode_list {
    my ($scanner, $data_ref,$node,$element_name,@indexes) = @_ ;
    my @list = $node->fetch_element($element_name)->fetch_all_values ;
    push @$data_ref, qq(\t\tModes\t").join('" "',@list).'"' if @list;
}

my %dispatch_list = ( 'Xorg::Screen::Display' => \&wr_mode_list );

sub wr_list {
    my ($scanner, $data_ref,$node,$element_name,@indexes) = @_ ;
    my $dispatcher_data = $node->config_class_name ;
    my $cb = $dispatch_list{$dispatcher_data} ;
    if (defined $cb ) { $cb->(@_) ; }
    else {
	# resume exploration
	map {$scanner->scan_list($data_ref,$node,$element_name,$_)} @indexes ;
    }
}

sub wr_check_list {
    my ($scanner, $data_ref,$node,$element_name,@indexes) = @_ ;
    #warn "wr_check_list called on node ".$node->name." element $element_name\n";
    my @list = $node->fetch_element($element_name)->get_checked_list ;
    push @$data_ref, qq(\t\t$element_name\t").join('" "',@list).'"' if @list;
}

sub write_all {
    my $root = shift ;

    $logger->debug( "write_all called");

    my @result = ("# Xorg.conf written by Xorg Config::Model",
		  "# do not edit", '' ) ;

    my $scan = Config::Model::ObjTreeScanner-> new
      (
       leaf_cb => \&wr_leaf ,
       node_element_cb => \&wr_node ,
       check_list_element_cb => \&wr_check_list ,
       experience => 'master' ,
       fallback => 'all',
      ) ;

    $scan->scan_node (\@result, $root) ;

    return @result ;
#     foreach my $sect_obj (@_) {
# 	my $section_name = $sect_obj->element_name ;
# 	$$ref .= qq(Section "$section_name"\n) ;
# 	$scan->scan_node($sect_obj) ;
# 	$$ref .= "EndSection\n\n" ;
#     }

}

1;
__END__

sub wr_leaf2 {
    my ($node,$element_name,$index, $leaf_object) = @_ ;
    #$logger->debug( "Node $node $index  $element_name\n";
    my $v = $leaf_object->fetch ;
    my $loc = $node->location ;

    if ($loc eq 'Module') {
	$result .= qq(\tLoad "$element_name"\n) if $v ;
    }
    elsif ($loc =~ /Option\s*$/) {
	$result .= qq(\tOption "$element_name");
	$result .= qq(\t"$v") if defined $v && $v ;
	$result .= "\n";
    }
    else {
    }
}

sub wr_section {
    my ($node, $element_name, $key) = @_ ;
    # avoid auto-vivification
    return unless $node->is_element_defined($element_name) ;

    my $next = $node -> fetch_element($element_name) ;

    $next = $next->fetch_with_id($key) if defined $key ;

    if ($element_name eq 'Option') {
	$result .= "\t# node ".$node->name." option section\n";
    }
    else {
	$result .= "# node ".$node->name." "
                .  ( $element_name || "[no elt name]" )
                . " "
	        .  ( $key || '[no key]' ) . "\n";
	$result .= qq(Section "$element_name"\n) ;
	$result .= qq(\tIdentifier "$key"\n) if defined $key ;
    }

    # explore node 

    if ($element_name eq 'Option') {
	$result .= "\t# end node ".$node->name." option section\n";
    }
    else {
	$result .= "EndSection\n" . "# end node\n\n";
    }

}


1;
