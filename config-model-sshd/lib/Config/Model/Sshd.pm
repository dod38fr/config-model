# $Author: ddumont $
# $Date$
# $Revision: 1.5 $

#    Copyright (c) 2008 Dominique Dumont.
#
#    This file is part of Config-Model-Sshd.
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

package Config::Model::Sshd ;

use strict ; 
use warnings ;

use Carp ;
use IO::File ;
use Log::Log4perl;

use Parse::RecDescent ;
use vars qw($VERSION $grammar $parser) ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/;

my $logger = Log::Log4perl::get_logger(__PACKAGE__);

sub read {
    my %args = @_ ;
    my $config_root = $args{object}
      || croak __PACKAGE__," read: undefined config root object";
    my $dir = $args{conf_dir} 
      || croak __PACKAGE__," read: undefined config dir";

    unless (-d $dir ) {
	croak __PACKAGE__," read: unknown config dir $dir";
    }

    my $file = "$dir/sshd_config" ;
    unless (-r "$file") {
	croak __PACKAGE__," read: unknown file $file";
    }

    $logger->info("loading config file $file");

    my $fh = new IO::File $file, "r" ;

    if (defined $fh) {
	my @file = $fh->getlines ;
	$fh->close;
	# remove comments and cleanup beginning of line
	map  { s/#.*//; s/^\s+//; } @file ;

	$parser->sshd_parse(join('',@file), # text to be parsed
			    1,              # start line
			    $config_root    # arguments
			   ) ;
    }
    else {
	die __PACKAGE__," read: can't open $file:$!";
    }
}

$grammar = << 'EOG' ;
# See Parse::RecDescent faq about newlines
sshd_parse: <skip: qr/[^\S\n]*/> line[@arg](s) 

line: match_line  | any_line

match_line: /match/i arg(s) "\n"
{
   Config::Model::Sshd::match($arg[0],@{$item[2]}) ;
}

any_line: key arg(s) "\n"  
{
   Config::Model::Sshd::assign($arg[0],$item[1],@{$item[2]}) ;
}

key: /\w+/

arg: string | /\S+/

string: '"' /[^"]+/ '"' 

EOG

$parser = Parse::RecDescent->new($grammar) ;

{
  my $current_node ;

  sub assign {
    my ($root, $key,@arg) = @_ ;
    $current_node = $root unless defined $current_node ;

    # keys are case insensitive, try to find a match
    if ( not $current_node->element_exists( $key ) ) {
	foreach my $elt ($current_node->get_element_name(for => 'master') ) {
	    $key = $elt if lc($key) eq lc($elt) ;
	}
    }

    my $elt = $current_node->fetch_element($key) ;
    my $type = $elt->get_type;
    print "got $key type $type and ",join('+',@arg),"\n";
    if    ($type eq 'leaf') { 
	$elt->store( $arg[0] ) ;
    }
    elsif ($type eq 'list') { 
	$elt->push ( @arg ) ;
    }
    elsif ($type eq 'hash') {
        $elt->fetch_with_id($arg[0])->store( $arg[1] );
    }
    elsif ($type eq 'check_list') {
	my @check = split /,/,$arg[1] ;
        $elt->set_checked_list (@check) ;
    }
    else {
       die "Sshd::assign did not expect $type for $key\n";
    }
  }

  sub match {
    my ($root, @pairs) = @_ ;

    my $list_obj = $root->fetch_element('Match');

    # create new match block
    my $nb_of_elt = $list_obj->fetch_size;
    my $block_obj = $list_obj->fetch_with_id($nb_of_elt) ;

    while (@pairs) {
	my $criteria = shift @pairs;
	my $pattern  = shift @pairs;
	$block_obj->load(qq!$criteria="$pattern"!);
    }

    $current_node = $block_obj->fetch_element('Elements');
  }

  sub clear {
    $current_node = undef ;
  }
}
1;

