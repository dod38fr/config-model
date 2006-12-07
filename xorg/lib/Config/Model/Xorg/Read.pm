# $Author: ddumont $
# $Date: 2006-12-07 13:13:20 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

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

sub read {
    my %args = @_ ;
    my $config_root = $args{object}
      || croak __PACKAGE__," read: undefined config root object";
    my $dir = $args{conf_dir} 
      || croak __PACKAGE__," read: undefined config dir";

    unless (-d $dir ) {
	croak __PACKAGE__," read: unknown config dir $dir";
    }

    my $file = "$dir/xorg.conf" ;
    unless (-r "$file") {
	croak __PACKAGE__," read: unknown file $file";
    }

    my $i = $config_root->instance ;

    # As the data contained in a typical xorg.conf are presented in an
    # order that might upset the model, model check are disabled while
    # reading xorg.conf. The accuracy of data will be checked when
    # reading data from the configuration tree
    $i->push_no_value_check('fetch','store','type') ;

    print __PACKAGE__," read: loading config file $file\n";

    my $fh = new IO::File $file, "r" ;

    if (defined $fh) {
	my @file = $fh->getlines ;
	$fh->close;
	map { s/#.*$//; s/^\s*//; } @file ;
	my @xorg_conf = grep { not /^\s*$/ ;} @file;

	chomp @xorg_conf ;
	parse_all(\@xorg_conf, $config_root) ;
    }
    else {
	die __PACKAGE__," read: can't open $file:$!";
    }

    # restore check when storing data in the configuration tree
    $i->pop_no_value_check() ;
}

sub parse_all {
    my $xorg_conf = shift;
    my $root = shift ;

    print "parse_all called\n";
    while (@$xorg_conf) {
	my $line = shift @$xorg_conf ;
	print "parse_all: line '$line'\n";

	if ($line =~ /^\s*Section\s+"(\w+)"/) {
	    if ($root->has_element($1)) {
		parse_section($xorg_conf,$root->fetch_element($1)) ;
	    }
	    else {
		skip_section($xorg_conf) ;
	    }
	}
	else {
	    print "parse_all: unexpected line '$line'\n";
	}
    }
}

sub skip_section {
    my $xorg_conf = shift;
    
    while ( @$xorg_conf ) {
	my $line = shift @$xorg_conf ;
	return if $line =~ /^\s*EndSection/ ;
    }
    print "skip_section reached end of file\n";
}

sub parse_option {
    my ($obj, $trash, $trash2, $line) = @_ ;
    my ($opt) = ( $line =~ /Option\s*"(\w+)"/ ); #";
    my ($arg) = ( $line =~ /Option\s*"\w+"\s+"?([\w\/\-:\.\s]+)"?/ ); #";
    if ($opt =~ /Core(Keyboard|Pointer)/ ) {
	my $id = $obj -> index_value ;
	print "Load $opt to '$id'\n";
	$obj->load( qq(! $opt="$id") ) ;
    }
    else {
	print "obj ",$obj->name, " load option '$opt' \n";
	my $opt_obj = $obj->fetch_element("Option")->fetch_element($opt) ;
	$opt_obj->store ( defined $arg ? $arg : 1 ) ;
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
    my ($obj, $trash, $mode_name, $line) = @_ ;
    my ($mode) = ( $line =~ /ModeLine\s*"[\w\.\-]+"\s+(.*)/ ); #";
    print "Mode line: $mode_name -> $mode\n";
    my @m = split /\s+/, $mode ;
    my $load = "Mode:$mode_name DotClock=$m[0] ";
    $load .= "HTimings disp=$m[1] syncstart=$m[2] syncend=$m[3] total=$m[4] - ";
    $load .= "VTimings disp=$m[5] syncstart=$m[6] syncend=$m[7] total=$m[8] - ";
    splice @m,0,9 ;

    $load .= "Flags " . join (' ', map {$mode_flags{$_} || "$_=1" } @m ) . ' - ' 
      if @m ;

    print "load '$load'\n";
    $obj->load($load) ;
}

sub parse_modes_list {
    my ($obj, $trash, $trash2, $line) = @_ ;
    $line =~ s/^\s*Modes\s*//;
    $line =~ s/"//g;
    my @modes = split /\s+/,$line;
    my $load = "Modes=".join(',',@modes);

    print "load '$load'\n";
    $obj->load($load) ;
}

sub parse_layout_screen {
    my ($obj, $trash, $trash2, $line) = @_ ;

    my $load;
    my $saved_line = $line ;

    if ($obj->config_class_name eq 'Xorg::Device') {
	my ($num) 
	  = ($line =~ /Screen\s+(\d*)/) ;
	$load = "Screen=$num";
    }
    else {
	my $num = 0 ;

	$line =~ s/\s*Screen\s*//;

	if ($line =~ /^(\d+)/) {
	    $num = $1 ;
	    $line =~ s/\d+\s*// ;
	}

	$load = "Screen:$num ";

	if ($line =~ /^"([\w\.\-\s]+)"/) {
	    $load .= "screen_id=\"$1\" " ; # screen_id
	    $line =~ s/^"[\w\.\-\s]+"\s*//g;
	}
	print "load '$load' from line '$line'\n";

	if ($line =~ /^(\w+)/) {
	    my $end = $1 ;
	    my ($relative_spec, $pos );

	    if ($end =~ /^\d+$/ or $end eq 'Relative') {
		$pos = 'Absolute' if $end =~ /^\d+$/;
		# there's a coordinate
		my ($x,$y) = ($line =~ /(\d+)\s+ (\d+)\s*$/) ;
		$relative_spec = "x=$x y=$y" ;
	    }
	    else {
		$pos = $end ;
		$line =~ /"([\w\.\-\s]+)"\s*$/ ;
		$relative_spec = "screen_id=\"$1\"" ;
	    }
	    $load .= "position relative_screen_location=$pos $relative_spec ";
	}
	print "load '$load' from line '$line'\n";
    }

    print $obj->config_class_name," load '$load' from line '$saved_line'\n";
    $obj->load($load) ;
}

sub parse_input_device {
    my ($obj, $trash, $id, $line) = @_ ;
    print "trash $trash id $id line '$line'\n";
    my ($last) = ($line =~ /"([^"]+)"\s*$/) ;
    my $dev = $obj->fetch_element('InputDevice')
      -> fetch_with_id($id) ;

    if ($last ne $id) {
	print "Load '! $last=\"$id\"'\n";
	$obj->load("! $last=\"$id\"") ;
    }
}

my %parse_line 
  = (
     'FontPath' => sub { $_[0]->fetch_element($_[1])->push($_[2]) ;} ,
     'Load'     => sub { $_[0]->fetch_element($_[2])->store(1)    ;} ,
     'ModeLine' => \&parse_mode_line,
     'Option'   => \&parse_option ,
     'Modes'    => \&parse_modes_list,
     'Screen'   => \&parse_layout_screen,
     'InputDevice' => \&parse_input_device,
    ) ;

sub parse_section {
    my $xorg_conf = shift;
    my $obj = shift ;

    # section like InputDevice must be parsed in 2 times
    my $obj_type = $obj->get_type ;
    my $has_id = $obj_type =~ /list|hash/ ? 1 : 0 ;
    my $tmp_obj = $obj ;

    print "parse_section called on ",$obj->name," (has_id: $has_id)\n";

    # first get the identifier and create the object. 
    my $idx = 0;
    while ($has_id and @$xorg_conf) {
	my $line = $xorg_conf->[$idx] ; # do not remove yet

	if (   $line =~ /^Identifier\s+"([\w\-\s]+)"/i
	    or $line =~ /^Depth\s+([\w]+)/i
	   ) {
	    my $id = $1 ;
	    print "parse_section: found id '$id' for '",$obj->name,"'\n";
	    $tmp_obj = $obj->fetch_with_id($id) ;
	    splice @$xorg_conf, $idx,1; # remove the line containing the id 
	    last ;
	}
	$idx ++ ;
	die "parse_section: can't find id " if $idx > 1000;
    }

    # then fill the data;
    while (@$xorg_conf) {
	my $line = shift @$xorg_conf ; # now we remove the line

	# should always work because array was cleaned up;
	my ($key) = ( $line =~ /^(\w+)/ ) ;

	die "parse_section: undefined key for line '$line'\n"
	  unless defined $key ;

	if ($line =~ /^End(Sub)?Section/) {
	    print "Found $line for ",$obj->name,"\n";
	    last ;
	}
	elsif ($line =~ /^\s*SubSection\s+"(\w+)"/) {
	    my $elt = $1 ;
	    parse_section($xorg_conf,$tmp_obj->fetch_element($elt)) ;
	}
	elsif (defined $parse_line{$key}) {
	    my ($elt, $arg) = ( $line =~ /(\w+)\s+"([^"]+)"/ ); #";
	    $parse_line{$key} -> ($tmp_obj, $elt, $arg, $line) ;
	}
	else {
	    my ($elt, $arg) = ( $line =~ /(\w+)\s+"?([^"]+)"?/ ); #";
	    if ($tmp_obj->has_element($elt)) {
		print $obj->name, " store $elt = '$arg' (from '$line')\n";
		$tmp_obj->fetch_element($elt)->store($arg)
	    }
	    else {
		print "parse_section: unexpected '$elt' element for ",
		  $tmp_obj->name, "($line)\n" ;
	    }
	}

    }
}
1;
