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

sub push_list {
    my $line = shift;
    my $obj = shift ;
    my ($elt, $arg) = ($line =~ /(\w+)\s+"([\w\/\-:]+)"/ ); #";

    $obj->fetch_element($1)->push($2) ;
}

my %parse_line 
  = (
     'FontPath' => \&push_list,
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

	return if /^\s*EndSection/ ;

	if (/^\s*(\w+)/) {
	    if ($has_id and /^\s*Identifier\s+"([\w\- ])"/i ) {
		$obj->move('__tmp',$1) ;
		$tmp_obj = $obj->fetch_with_id($1) ;
	    }
	    elsif (defined $parse_line{$1}) {
		$parse_line{$1} -> ($_, $obj) ;
	    }
	    else {
		my ($elt, $arg) = ( /(\w+)\s+"([\w\/\-:])"/ ); #";
		if ($tmp_obj->has_element($1)) {
		    $tmp_obj->fetch_element($1)->store($2)
		}
		else {
		    print "parse_section: unexpected '$1' element for ",
		      $tmp_obj->name, "\n" ;
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
