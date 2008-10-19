# $Author: ddumont $
# $Date: 2008-05-24 17:04:16 +0200 (sam, 24 mai 2008) $
# $Revision$

#    Copyright (c) 2008 Dominique Dumont.
#
#    This file is part of Config-Model-OpenSsh.
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

package Config::Model::OpenSsh ;

use strict ; 
use warnings ;

use Carp ;
use IO::File ;
use Log::Log4perl;
use File::Copy ;
use File::Path ;

use Parse::RecDescent ;
use vars qw($VERSION $grammar $parser) ;

$VERSION = sprintf "1.%04d", q$Revision$ =~ /(\d+)/;

my $logger = Log::Log4perl::get_logger(__PACKAGE__);

=head1 NAME

Config::Model::OpenSsh - OpenSsh configuration files editor

=head1 SYNOPSIS

 # Config::Model::OpenSsh is a plugin for Config::Model. You can use
 # Config::Model API to modify its content

 use Config::Model ;
 my $model = Config::Model -> new ( ) ;

 my $inst = $model->instance (root_class_name   => 'Sshd',
                              instance_name     => 'my_instance',
                             );
 my $root = $inst -> config_root ;

 $root->load("AllowUsers=foo,bar") ;

 $inst->write_back() ;

=head1 DESCRIPTION

This module provides a configuration model for OpenSsh. Then
Config::Model provides a graphical editor program for
F</etc/ssh/sshd_config> and F</etc/ssh/ssh_config>. See
L<config-edit-sshd> and L<config-edit-ssh> for more help.

This module and Config::Model can also be used to modify safely the
content for F</etc/ssh/sshd_config>, F</etc/ssh/ssh_config> or
F<~/.ssh/config> from Perl programs.

Once this module is installed, you can run (as root, but please backup
/etc/X11/xorg.conf before):

 # config-edit-sshd 

Or to edit F</etc/ssh/ssh_config> configuration files:

 # config-edit-ssh

To edit F<~/.ssh/config>, run as a normal user:

 # config-edit-ssh

The Perl API is documented in L<Config::Model> and mostly in
L<Config::Model::Node>.

=head1 Functions

These functions are declared in OpenSsh configuration models and are
called back.

=head2 sshd_read (object => <sshd_root>, conf_dir => ...)

Read F<sshd_config> in C<conf_dir> and load the data in the 
C<sshd_root> configuration tree.

=cut 

sub sshd_read {
    read_ssh_file( file => 'sshd_config', @_ ) ;
}

sub read_ssh_file {
    my %args = @_ ;
    my $config_root = $args{object}
      || croak __PACKAGE__," read_ssh_file: undefined config root object";
    my $dir = $args{root}.$args{config_dir} ;

    unless (-d $dir ) {
	croak __PACKAGE__," read_ssh_file: unknown config dir $dir";
    }

    my $file = $dir.'/'.$args{file} ;
    unless (-r "$file") {
	croak __PACKAGE__," read_ssh_file: unknown file $file";
    }

    $logger->info("loading config file $file");

    my $fh = new IO::File $file, "r" ;

    &clear ; # reset Match closure

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
	die __PACKAGE__," read_ssh_file: can't open $file:$!";
    }
}

# for ssh_read:
# if root: use /etc/ssh/ssh_config as usual
# if normal user: load root file in "preset mode" 
#                 load ~/.ssh/config in normal mode
#                 write back to ~/.ssh/config
#                 Ssh model can only specify root config_dir

sub ssh_read {
    my %args = @_ ;
    my $config_root = $args{object}
      || croak __PACKAGE__," ssh_read: undefined config root object";
    my $instance = $config_root -> instance ;

    $instance -> preset_start if $> ; # regular user

    read_ssh_file(file => 'ssh_config', @_) ;

    if ( $> ) {
      $instance -> preset_stop ;
      read_ssh_file(file => 'config', @_, 
		    config_dir => $ENV{HOME}.'/.ssh') ;
    }
}


$grammar = << 'EOG' ;
# See Parse::RecDescent faq about newlines
sshd_parse: <skip: qr/[^\S\n]*/> line[@arg](s) 

line: match_line | client_alive_line | host_line | any_line

match_line: /match/i arg(s) "\n"
{
   Config::Model::OpenSsh::match($arg[0],@{$item[2]}) ;
}

client_alive_line: /clientalive\w+/i arg(s) "\n"
{
   Config::Model::OpenSsh::clientalive($arg[0],$item[1],@{$item[2]}) ;
}

host_line: /host\b/i arg(s) "\n"
{
   Config::Model::OpenSsh::host($arg[0],$item[1],@{$item[2]}) ;
}

any_line: key arg(s) "\n"  
{
   Config::Model::OpenSsh::assign($arg[0],$item[1],@{$item[2]}) ;
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
    # print "got $key type $type and ",join('+',@arg),"\n";
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
	my @check = split /,/,$arg[0] ;
        $elt->set_checked_list (@check) ;
    }
    else {
       die "OpenSsh::assign did not expect $type for $key\n";
    }
  }

  sub clientalive {
    my ($root, $key, $arg) = @_ ;

    # first set warp master parameter
    $root->load("ClientAliveCheck=1") ;

    # then we can load the parameter as usual
    assign($root,$key,$arg) ;
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

  sub host {
    my ($root, @patterns) = @_ ;

    my $list_obj = $root->fetch_element('Host');

    # create new host block
    my $nb_of_elt = $list_obj->fetch_size;
    my $block_obj = $list_obj->fetch_with_id($nb_of_elt) ;
    my $pattern_obj = $block_obj->fetch_element('patterns') ;

    map { $pattern_obj->push($_) ; } @patterns;

    $current_node = $block_obj->fetch_element('block');
  }

  sub clear {
    $current_node = undef ;
  }
}

=head2 sshd_write (object => <sshd_root>, conf_dir => ...)

Write F<sshd_config> in C<conf_dir> from the data stored the
C<sshd_root> configuration tree.

=cut 

# now the write part

sub sshd_write {
    my %args = @_ ;
    my $config_root = $args{object}
      || croak __PACKAGE__," sshd_write: undefined config root object";
    my $dir = $args{root}.$args{config_dir} ;

    mkpath($dir, {mode => 0755} )  unless -d $dir ;

    my $file = "$dir/sshd_config" ;
    if (-r "$file") {
	my $backup = "$file.".time ;
	$logger->info("Backing up file $file in $backup");
	copy($file,$backup);
    }

    $logger->info("writing config file $file");

    my $result = write_node_content($config_root);

    #print $result ;
    open(OUT,"> $file") || die "cannot open $file:$!";
    print OUT $result;
    close OUT;
}

sub write_line {
    return sprintf("%-20s %s\n",@_) ;
}

sub write_node_content {
    my $node = shift ;

    my $result = '' ;
    my $match  = '' ;

    foreach my $name ($node->get_element_name(for => 'master') ) {
	next unless $node->is_element_defined($name) ;
	my $elt = $node->fetch_element($name) ;
	my $type = $elt->get_type;

	#print "got $key type $type and ",join('+',@arg),"\n";
	if    ($name eq 'Match') { 
	    $match .= write_all_match_block($elt) ;
	}
	elsif    ($name eq 'ClientAliveCheck') { 
	    # special case that must be skipped
	}
	elsif    ($type eq 'leaf') { 
	    my $v = $elt->fetch ;
	    if (defined $v and $elt->value_type eq 'boolean') {
		$v = $v == 1 ? 'yes':'no' ;
	    }
	    $result .= write_line($name,$v) if defined $v;
	}
	elsif    ($type eq 'check_list') { 
	    my $v = $elt->fetch ;
	    $result .= write_line($name,$v) if defined $v and $v;
	}
	elsif ($type eq 'list') { 
	    map { $result .= write_line($name,$_) ;} $elt->fetch_all_values ;
	}
	elsif ($type eq 'hash') {
	    foreach my $k ( $elt->get_all_indexes ) {
		my $v = $elt->fetch_with_id($k)->fetch ;
		$result .=  write_line($name,"$k $v") ;
	    }
	}
	else {
	    die "OpenSsh::write did not expect $type for $name\n";
	}
    }

    return $result.$match ;
}

sub write_all_match_block {
    my $match_elt = shift ;

    my $result = '' ;
    foreach my $elt ($match_elt->fetch_all() ) {
	$result .= write_match_block($elt) ;
    }

    return $result ;
}

sub write_match_block {
    my $match_elt = shift ;
    my $result = "\nMatch " ;

    foreach my $name ($match_elt->get_element_name(for => 'master') ) {
	my $elt = $match_elt->fetch_element($name) ;

	if ($name eq 'Elements') {
	    $result .= "\n".write_node_content($elt)."\n" ;
	}
	else {
	    my $v = $elt->fetch($name) ;
	    $result .= " $name $v" if defined $v;
	}
    }

    return $result ;
}

1;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<config-edit-sshd>, L<Config::Model>,
