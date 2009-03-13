# $Author: ddumont $
# $Date: 2008-01-23 11:12:16 $
# $Revision$

#    Copyright (c) 2005,2006 Dominique Dumont.
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

package Config::Model::Xorg::Read ;

use strict;
use warnings ;
use Carp ;
use IO::File ;
use Log::Log4perl;
use Data::Dumper ;

use vars qw($VERSION) ;

$VERSION = sprintf "1.%04d", q$Revision: 711 $ =~ /(\d+)/;

my $logger = Log::Log4perl::get_logger(__PACKAGE__);

sub read {
    my %args = @_ ;
    my $config_root = $args{object}
      || croak __PACKAGE__," read: undefined config root object";
    my $conf_dir = $args{config_dir} 
      || croak __PACKAGE__," read: undefined config_dir";
    my $root = $args{root} || '';
    my $test = $args{test} || 0;

    my $dir = join('/',$root,$conf_dir) ;

    unless (-d $dir ) {
	warn __PACKAGE__," read: unknown config dir $dir";
	return 0;
    }

    my $file = "$dir/xorg.conf" ;
    unless (-r "$file") {
	warn __PACKAGE__," read: unknown file $file";
	return 0;
    }

    my $i = $config_root->instance ;

    $logger->info("loading config file $file");

    my $fh = new IO::File $file, "r" ;

    if (defined $fh) {
	my @file = $fh->getlines ;
	$fh->close;
	my $idx = 0 ;
	# store also input line number
	map {s/#.*$//; s/^\s*//; s/\s+$//; $_ = [ "line ".$idx++ ,$_ ]} @file ;
	my @raw_xorg_conf = grep { $_->[1] !~ /^\s*$/ ;} @file;
	chomp @raw_xorg_conf ;

	#print Dumper(\@raw_xorg_conf); exit ;
	my $data = parse_raw_xorg(\@raw_xorg_conf) ;

	return $data if $test ;
	#print Dumper($data); exit ;

	parse_all($data, $config_root) ;
	return 1 ;
    }
    else {
	die __PACKAGE__," read: can't open $file:$!";
    }
}

# return a data structure in the form :
#   hash_ref->array_ref->hash_ref->array_ref
#
# { section_name => [ 
#                     # section_a
#                     { element_name => [ [ value_a ] , [ va, lue, _b ] },
#                     ...
#                     # section_b 
#                     ...
#                   ],
# },
# ...
sub parse_raw_xorg {
    my $xorg_lines = shift ;

    my %data ;

    while (@$xorg_lines) {
	my $line_data = shift @$xorg_lines ;
	my ($line_nb,$line) = @$line_data ;
	my ($key,$value) = split /\s+/,$line,2;
	if ($key =~ /\bsection\b/i) {
	    $value =~ s/"//g;
	    push @{$data{$value}}, 
	      [ $line_nb, parse_raw_section($xorg_lines) ] ;
	}
    }
    return \%data ;
}

sub parse_raw_section {
    my $xorg_lines = shift ;

    my %data ;
    $logger->debug( "parse_raw_section: called");

    while (@$xorg_lines) {
	my $line_data = shift @$xorg_lines ;
	my ($line_nb,$line) = @$line_data ;
	my ($key,$value) = split /\s+/,$line,2;
	if ($key =~ /EndSection/i or $key =~ /EndSubSection/i) {
	    return \%data ;
	}
	elsif ($key =~ /subsection/i) {
	    $value =~ s/"//g;
	    $logger->debug( "parse_raw_section: SubSection $value line $line_nb");
	    push @{$data{$value}}, [ $line_nb, parse_raw_section($xorg_lines) ];
	}
	else {
	    my @store = ( $line_nb ) ;
	    while (length($value)) {
		if ($value =~ /^"([^"]+)"/) {
		    push @store,$1 ;
		    $value =~ s/^"[^"]+"\s*//g;
		}
		elsif ($value =~ /^([^"\s]+)/) {
		    push @store,$1 ;
		    $value =~ s/^([^"\s]+)\s*//g;
		}
		else {
		    die "parse_raw_section: unexpected value $value";
		}

	    }
	    push @{$data{$key}}, \@store ;
	}
    }
}

# Need to update functions beloow
sub parse_all {
    my $xorg_conf = shift;
    my $root = shift ;

    # important sections must be parsed in a specific order
    my @sections = qw/InputDevice Monitor Device Screen ServerLayout
                      ServerFlags/ ;

    foreach my $section_name (@sections) {
	foreach	my $section_data (@{$xorg_conf->{$section_name}}) {
	    $logger->debug( "parse_all: important section '$section_name'");
	    parse_section($section_data,$root->fetch_element($section_name)) ;
	}
	delete $xorg_conf->{$section_name} ;
    }

    # try to parse remaining sections
    foreach my $section_name (keys %$xorg_conf) {
	next unless $root->has_element($section_name) ;

	foreach	my $section_data (@{$xorg_conf->{$section_name}}) {
	    $logger->debug( "parse_all: section '$section_name'");
	    parse_section($section_data,$root->fetch_element($section_name)) ;
	}
	delete $xorg_conf->{$section_name} ;
    }

    if (keys %$xorg_conf) {
	die "can't handle section ", join(' ',keys %$xorg_conf),
	  ": Error in input file or Xorg model is incomplete";
    }
}

sub parse_option {
    my ($obj, $trash, $line, @args) = @_ ;
    my $opt = shift @args;

    if ($obj->config_class_name eq 'Xorg::ServerFlags') {
	$logger->debug( "parse_option: obj ",$obj->name, " ($line) load option '$opt' ");
	my $opt_obj = $obj->fetch_element($opt) ;
	$opt_obj->store ( @args  ? $args[0] : 1 ) ;
    }
    elsif ($opt =~ /Core(Keyboard|Pointer)/ ) {
	my $id = $obj -> index_value ;
	$logger->debug( "parse_option: ($line) Load top level $opt to '$id'");
	$obj->load( qq(! $opt="$id") ) ;
    }
    elsif (    $obj->config_class_name eq 'Xorg::InputDevice' 
	   and $opt eq 'AutoRepeat') {
	$logger->debug( "parse_option: obj ",$obj->name, " ($line) load option '$opt' with '",
			join('+',@args),"' ");
	my @v = split / /,$args[0] ;
	my $load = sprintf ( "Option AutoRepeat delay=%s rate=%s", @v);
	$logger->debug( "parse_option: ",$obj->name," load '$load'");
	$obj->load($load) ;
    }
    elsif (     $obj->config_class_name eq 'Xorg::InputDevice'
	    and $opt eq 'XkbOptions' ) {
	$logger->debug( "parse_option: obj ",$obj->name, " ($line) load option '$opt' with '",
			join('+',@args),"' ");
	my @v = split /:/,$args[0] ;
	my $load = sprintf ( "Option XkbOptions %s=%s", @v);
	$logger->debug( "parse_option: ",$obj->name," load '$load'");
	$obj->load($load) ;
    }
    else {
	# dont' work for ServerFlags
	my $opt_p_obj = $obj->fetch_element("Option") ;
	my $opt_obj;
	if ($opt_p_obj->has_element($opt)) {
	    $logger->debug( "parse_option: obj ",$obj->name, " ($line) load option '$opt' ");
	    $opt_obj= $opt_p_obj->fetch_element($opt) ;
	    $opt_obj->store ( @args  ? $args[0] : 1 ) if defined $opt_obj ;
	}
	elsif ($opt_p_obj->instance->get_value_check('fetch_or_store')) {
	    Config::Model::Exception::UnknownElement
		-> throw(
			 object   => $opt_p_obj,
			 where    => $opt_p_obj->location ,
			 element  => $opt,
			);
	}
	else {
	    $logger->warn( "parse_option: obj ",$obj->name, " ($line) option '$opt' is unknown");
	}
    }
}

my %mode_flags = (
	     '+HSync' => "HSyncPolarity=positive",
	     '-HSync' => "HSyncPolarity=negative",
	     '+VSync' => "VSyncPolarity=positive",
	     '-VSync' => "VSyncPolarity=negative",
	     '+CSync' => "CSyncPolarity=positive",
	     '-CSync' => "CSyncPolarity=negative",
	    );

sub parse_mode_line {
    my ($obj, $trash, $line, $mode, @m) = @_ ;

    # force @v content to be numerical instead of strings
    my @v = map { 0 + $_ } splice @m,0,9 ;

    my $load = "Mode:$mode DotClock=$v[0] ";
    $load .= "HTimings disp=$v[1] syncstart=$v[2] syncend=$v[3] total=$v[4] - ";
    $load .= "VTimings disp=$v[5] syncstart=$v[6] syncend=$v[7] total=$v[8] - ";

    $load .= "Flags " . join (' ', map {$mode_flags{$_} || "$_=1" } @m ) . ' - ' 
      if @m ;

    $logger->debug( "parse_mode_line: ($line) load '$load'");
    $obj->load($load) ;
}

sub parse_modes_list {
    my ($obj, $trash, $line_nb, @modes) = @_ ;

    my $load = "Modes=".join(',',@modes);
    $logger->debug( "parse_modes_list: ($line_nb))load '$load'");
    $obj->load($load) ;
}

# called while parsing ServerLayout or Device
# key is always 'Screen'
sub parse_layout_screen {
    my ($obj, $key, $line, $value, @args) = @_ ;

    my $load;

    if ($obj->config_class_name eq 'Xorg::Device') {
	$load = "Screen=$value";
    }
    else {
	my ($num, $screen_id);
	if ($value =~ /^(\d+)$/) {
	    $num = $value ;
	    $screen_id = shift @args ;
	} 
	else {
	    $num = 0;
	    $screen_id = $value ;
	}

	$load = "Screen:$num screen_id=\"$screen_id\" ";

	$logger->debug( "parse_layout_screen: screen load '$load'");

	if (@args) {
	    # there's a position information
	    my ($relative_spec, $pos );

	    if ( $args[0] =~ /^\d+$/ ) {
		$pos = 'Absolute' ;
		$relative_spec = sprintf("x=%s y=%s",@args) ;
	    }
	    elsif ($args[0] eq 'Absolute') {
		$pos = shift @args ;
		$relative_spec = sprintf("x=%s y=%s",@args) ;
	    }
	    elsif ($args[0] eq 'Relative') {
		$pos = shift @args ;
		$relative_spec = sprintf("screen_id=\"%s\" x=%s y=%s",@args) ;
	    }
	    else {
		$pos = shift @args;
		$relative_spec = sprintf("screen_id=\"%s\"",@args) ;
	    }
	    $load .= "position relative_screen_location=$pos $relative_spec ";
	}
	$logger->debug( "parse_layout_screen: Screen ($line) load '$load' ");
    }

    $logger->debug( "parse_layout_screen:", $obj->config_class_name," load '$load'");
    $obj->load($load) ;
}

# called when parsing section ServerLayout
sub parse_input_device {
    my ($obj, $trash, $line ,$id, @opt) = @_ ;

    $logger->debug( "$trash id:'$id' option '".join("' '",@opt)."'");

    my $dev = $obj->fetch_element('InputDevice') -> fetch_with_id($id) ;

    foreach my $opt (@opt) {
	if ($opt eq 'SendCoreEvents') {
	    $dev->fetch_element($opt)->store(1) ;
	}
	elsif ($opt =~ /Core(Keyboard|Pointer)/) {
	    $logger->debug( "parse_input_device: Load '! $opt=\"$id\"'");
	    $obj->load("! $opt=\"$id\"") ;
	}
	else {
	    die "parse_input_device ($line): Unexpected ServerLayout->InputDevice ",
	      "option: $opt. Error in input file or Xorg model is incomplete";
	}
    }
}

sub parse_display_size {
    my ($obj, $tag_name, $line ,$w, $h) = @_ ;
    $logger->debug( "$tag_name width:'$w' height:$h");
    my $load = "DisplaySize width=$w height=$h";
    $logger->debug( $obj->config_class_name," load '$load'");
    $obj->load($load) ;
}

sub parse_view_port {
    my ($obj, $tag_name, $line ,$x0, $y0) = @_ ;
    $logger->debug( "$tag_name x0:'$x0' y0:$y0");
    my $load = "ViewPort x0=$x0 y0=$y0";
    $logger->debug( $obj->config_class_name," load '$load'");
    $obj->load($load) ;
}

sub parse_virtual {
    my ($obj, $tag_name, $line ,$xdim, $ydim) = @_ ;
    $logger->debug( "$tag_name xdim:'$xdim' ydim:$ydim");
    my $load = "Virtual xdim=$xdim ydim=$ydim";
    $logger->debug( $obj->config_class_name," load '$load'");
    $obj->load($load) ;
}

sub parse_gamma {
    my ($obj, $tag_name, $line ,@g) = @_ ;
    $logger->debug( "$tag_name @g");
    my $global = @g == 1 ? 1 : 0 ;
    my $load = "Gamma use_global_gamma=$global ";
    $load .= $global ? "gamma=$g[0]" 
                     : sprintf("red_gamma=%s green_gamma=%s blue_gamma=%s",@g) ;
    $logger->debug( $obj->config_class_name," load '$load'");
    $obj->load($load) ;
}

my %parse_line 
  = (
     'FontPath' => sub { $_[0]->fetch_element($_[1])->push($_[3]) ;} ,
     'Load'     => sub { $_[0]->fetch_element($_[3])->store(1)    ;} ,
     'ModeLine' => \&parse_mode_line,
     'Option'   => \&parse_option ,
     'Modes'    => \&parse_modes_list,
     'Screen'   => \&parse_layout_screen,
     'InputDevice' => \&parse_input_device,
     'DisplaySize' => \&parse_display_size ,
     'ViewPort' => \&parse_view_port ,
     'Virtual'  => \&parse_virtual ,
     'Gamma'    => \&parse_gamma ,
    ) ;

sub parse_section {
    my $section_line_data = shift ; # [ line_nb, hash ref ]
    my $obj = shift ;

    my ($sect_line_nb, $section_data) = @$section_line_data ;

    # section like InputDevice have an identifier which must be extracted first
    my $obj_type = $obj->get_type ;
    my $has_id = $obj_type =~ /list|hash/ ? 1 : 0 ;
    my $tmp_obj = $obj ;

    $logger->debug( "parse_section ($sect_line_nb) called on ",
		    $obj->name," (has_id: $has_id)");

    # first get the identifier and create the object. 
    if ($has_id) {
	my $id_rr =  delete $section_data->{Identifier}
	          || delete $section_data->{Depth} ;
	if (not defined $id_rr) {
	    $logger->debug( "parse_section can't find identifier for ",$obj->name );
	    return ;
	}


	my ($line,$id) = @{$id_rr->[0]}  ;
	$logger->debug( "parse_section $line: found id '$id' for '",
			$obj->name,"'");
	$tmp_obj = $obj->fetch_with_id($id) ;
    }

    # get driver or other important (warp master) element
    foreach my $important (qw/Driver Monitor/) {
	if ($tmp_obj->has_element($important)) {
	    my $item = delete $section_data->{$important};
	    $logger->debug( $tmp_obj->name," loads $important with ",$item->[0][1]);
	    $tmp_obj->fetch_element($important)->store($item->[0][1]) ;
	}
    }

    # then fill remaining data;
    foreach my $key (keys %$section_data) {
	my $a2_r = $section_data->{$key}; # array of array ref ;

	foreach my $arg (@$a2_r) {
	    if (defined $parse_line{$key}) {
		$parse_line{$key} -> ($tmp_obj, $key, @$arg) ;
	    }
	    else {
		if (ref $arg->[1] eq 'HASH') {
		    # we have a subsection
		    $logger->debug( $tmp_obj->name, " subsection $key ");
		    parse_section($arg,$tmp_obj->fetch_element($key)) ;
		}
		elsif ($tmp_obj->has_element($key) ) {
		    my $line = shift @$arg ;
		    my $val = "@$arg" ; 
		    $logger->debug( $tmp_obj->name, 
				    " ($line) store $key = '$val'");
		    $tmp_obj->fetch_element($key)->store($val)
		}
		else {
		    my $line = shift @$arg ;
		    $logger->warn( "parse_section $line: unexpected '$key' "
				   ."element for ",
				   $tmp_obj->name, " (@$arg)") ;
		}
	    }
	}

    }
}
1;
