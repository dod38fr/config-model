package Config::Xorg::Read ;

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

    print __PACKAGE__," read: loading config file $file\n";

    my $fh = new IO::File $file, "r" ;

    if (defined $fh) {
	parse_all($fh, $config_root) ;
    }
    else {
	die __PACKAGE__," read: can't open $file:$!";
    }
}

sub parse_all {
    my $fh = shift;
    my $root = shift ;

    print "parse_all called\n";
    while (<$fh>) {
	chomp ;
	s/#.*$//;

	next if /^\s*$/;
	print "parse_all: line '$_'\n";

	if (/^\s*Section\s+"(\w+)"/) {
	    if ($root->has_element($1)) {
		parse_section($fh,$root->fetch_element($1)) ;
	    }
	    else {
		skip_section($fh) ;
	    }
	}
	else {
	    print "parse_all: unexpected line '$_'\n";
	}
    }
}

sub skip_section {
    my $fh = shift;
    
    while ( <$fh> ) {
	return if /^\s*EndSection/ ;
    }
    print "skip_section reached end of file\n";

}

sub parse_option {
    my ($obj, $trash, $trash2, $line) = @_ ;
    my ($opt) = ( $line =~ /Option\s*"(\w+)"/ ); #";
    my ($arg) = ( $line =~ /Option\s*"\w+"\s+"?([\w\/\-:\.]+)"?/ ); #";
    print "obj ",$obj->name, " load option '$_' \n";
    my $opt_obj = $obj->fetch_element("Option")->fetch_element($opt) ;
    $opt_obj->store ( defined $arg ? $arg : 1 ) ;
}

my %flags = {
	     '+HSync' => "HSyncPolarity=positive",
	     '-HSync' => "HSyncPolarity=negative",
	     '+VSync' => "VSyncPolarity=positive",
	     '-VSync' => "VSyncPolarity=negative",
	     '+CSync' => "CSyncPolarity=positive",
	     '-CSync' => "CSyncPolarity=negative",
	    };

sub parse_mode_line {
    my ($obj, $trash, $mode_name, $line) = @_ ;
    my ($mode) = ( $line =~ /ModeLine\s*"[\w\.\-]+"\s+(.*)/ ); #";
    print "obj ",$obj->name, " load option '$_' \n";
    print "$mode_name -> $mode\n";
    my @m = split /\s+/, $mode ;
    my $load = "Mode:$mode_name DotClock=$m[0] ";
    $load .= "HTimings disp=$m[1] syncstart=$m[2] syncend=$m[3] total=$m[4] - ";
    $load .= "VTimings disp=$m[5] syncstart=$m[6] syncend=$m[7] total=$m[8] - ";
    splice @m,0,9 ;

    $load .= "Flags " . join (' ', map { $flags{$_} || "$_=1" } @m ) . ' - ' 
      if @m ;

    print "load '$load'\n";
    $obj->load($load) ;
}

sub parse_modes_list {
    my ($obj, $trash, $trash2, $line) = @_ ;
    my @modes = ( $line =~ /Modes(?:\s*"([\w\.\-]+)")+/ ); #";
    my $load = "Modes=".join(',',@modes);

    print "load '$load'\n";
    $obj->load($load) ;
}

my %parse_line 
  = (
     'FontPath' => sub { $_[0]->fetch_element($_[1])->push($_[2]) ;} ,
     'Load'     => sub { $_[0]->fetch_element($_[2])->store(1)    ;} ,
     'ModeLine' => \&parse_mode_line,
     'Option'   => \&parse_option ,
     'Modes'    => \&parse_modes_list,
    ) ;

sub parse_section {
    my $fh = shift;
    my $obj = shift ;

    # section like InputDevice must be parsed in 2 times
    # create a tmp index, fill it, and perform a hash->move
    # when Identifier is found.

    my $obj_type = $obj->get_type ;
    my $has_id = $obj_type =~ /list|hash/ ? 1 : 0 ;

    print "parse_section called on ",$obj->name," (has_id: $has_id)\n";

    my $tmp_obj = $has_id ? $obj->fetch_with_id('__tmp') : $obj ;

    while (<$fh>) {
	chomp ;
	s/#.*$//;

	next if /^\s*$/;

	return if /^\s*End(Sub)?Section/ ;

	if (/^\s*(\w+)/) {
	    my $key = $1 ;
	    if ($has_id and /^\s*Identifier\s+"([\w\-\s]+)"/i ) {
		my $elt = $1 ;
		print $obj->name, " moved to '$elt'  (from '$_')\n";
		$obj->move('__tmp',$elt) ;
		$tmp_obj = $obj->fetch_with_id($elt) ;
	    }
	    elsif (/^\s*SubSection\s+"(\w+)"/) {
		my $elt = $1 ;
		parse_section($fh,$tmp_obj->fetch_element($elt)) ;
	    }
	    elsif (defined $parse_line{$key}) {
		my ($elt, $arg) = ( /(\w+)\s+"([\w\/\-:\.]+)"/ ); #";
		$parse_line{$key} -> ($tmp_obj, $elt, $arg, $_) ;
	    }
	    else {
		my ($elt, $arg) = ( /(\w+)\s+"?([^"]+)"?/ ); #";
		if ($tmp_obj->has_element($elt)) {
		    print $obj->name, " store $elt = '$arg' (from '$_')\n";
		    $tmp_obj->fetch_element($elt)->store($arg)
		}
		else {
		    print "parse_section: unexpected '$elt' element for ",
		      $tmp_obj->name, "($_)\n" ;
		}
	    }
	}
	else {
	    print "parse_section: unexpected line '$_'\n";
	}

    }
    print "parse_section reached end of file\n";

}
1;
