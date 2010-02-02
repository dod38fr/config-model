# $Author: ddumont $
# $Date: 2008-05-24 17:04:16 +0200 (sam, 24 mai 2008) $
# $Revision: 836 $

# See license at bottom of pod

package Config::Model::OpenSsh ;

use strict ; 
use warnings ;

use Carp ;
use IO::File ;
use Log::Log4perl;
use File::Copy ;
use File::Path ;

use Parse::RecDescent ;
use vars qw($VERSION $grammar $parser)  ;

$VERSION = '1.210' ;


my $logger = Log::Log4perl::get_logger(__PACKAGE__);

my $__test_ssh_root_file = 0;
sub _set_test_ssh_root_file { $__test_ssh_root_file = shift ;} 
my $__test_ssh_home = '';
sub _set_test_ssh_home { $__test_ssh_home = shift ;}

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
    read_ssh_file( @_,  file => 'sshd_config',) ;
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

    my $is_user = 1 ;

    # $__test_root_file is a special global variable used only for tests
    $is_user = 0 if ($> == 0 or $__test_ssh_root_file ); 

    my $home_dir = $__test_ssh_home || $ENV{HOME} ;

    $logger->info("ssh_read: reading ".($is_user ? 'user' :'root').
		 " ssh config in ". ($is_user ? $home_dir : $args{config_dir}));

    $instance -> preset_start if $is_user ; # regular user

    my $ret = read_ssh_file( @_, file => 'ssh_config' ) ;

    $instance -> preset_stop if $is_user ;

    if ( $is_user) {
	# don't croak if user config file is missing
	 read_ssh_file( @_ , file => 'config',
		       config_dir => $home_dir.'/.ssh') ;
    }

    return $ret ;
}

sub read_ssh_file {
    my %args = @_ ;
    my $config_root = $args{object}
      || croak __PACKAGE__," read_ssh_file: undefined config root object";
    my $dir = $args{root}.$args{config_dir} ;

    unless (-d $dir ) {
	$logger->info("read_ssh_file: unknown config dir $dir");
	return 0;
    }

    my $file = $dir.'/'.$args{file} ;
    unless (-r "$file") {
	$logger->info("read_ssh_file: unknown file $file");
	return 0;
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
    return 1;
}


$grammar = << 'EOG' ;
# See Parse::RecDescent faq about newlines
sshd_parse: <skip: qr/[^\S\n]*/> line[@arg](s) 

#line: match_line | client_alive_line | host_line | any_line
line: match_line | host_line | forward_line | single_arg_line | any_line

match_line: /match/i arg(s) "\n"
{
   Config::Model::OpenSsh::match($arg[0],@{$item[2]}) ;
}

#client_alive_line: /clientalive\w+/i arg(s) "\n"
#{
#   Config::Model::OpenSsh::clientalive($arg[0],$item[1],@{$item[2]}) ;
#}

host_line: /host\b/i arg(s) "\n"
{
   Config::Model::OpenSsh::host($arg[0],@{$item[2]}) ;
}

forward_line: /(local|remote)forward/i arg(s) "\n"
{
   Config::Model::OpenSsh::forward($arg[0],$item[1],@{$item[2]}) ;
}

single_arg_line: /localcommand/i /[^\n]+/ "\n"
{
   Config::Model::OpenSsh::assign($arg[0],$item[1],$item[2]) ;
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
    #print "got $key type $type and ",join('+',@arg),"\n";
    if    ($type eq 'leaf') { 
	$elt->store( join(' ',@arg) ) ;
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

#  sub clientalive {
#    my ($root, $key, $arg) = @_ ;
#
#    # first set warp master parameter
#    $root->load("ClientAliveCheck=1") ;
#
#    # then we can load the parameter as usual
#    assign($root,$key,$arg) ;
#  }

  sub match {
    my ($root, @pairs) = @_ ;

    my $list_obj = $root->fetch_element('Match');

    # create new match block
    my $nb_of_elt = $list_obj->fetch_size;
    my $block_obj = $list_obj->fetch_with_id($nb_of_elt) ;

    while (@pairs) {
	my $criteria = shift @pairs;
	my $pattern  = shift @pairs;
	$block_obj->load(qq!Condition $criteria="$pattern"!);
    }

    $current_node = $block_obj->fetch_element('Settings');
  }

  sub host {
    my ($root,@patterns)  = @_;

    my $hash_obj = $root->fetch_element('Host');

    $logger->info("ssh: load host patterns '".join("','", @patterns)."'");

    $current_node = $hash_obj->fetch_with_id("@patterns");
  }

  sub forward {
    my ($root,$key,@args)  = @_;
    $current_node = $root unless defined $current_node ;

    my $elt_name = $key =~ /local/i ? 'Localforward' : 'RemoteForward' ;
    my $size = $current_node->fetch_element($key)->fetch_size;

    $logger->info("ssh: load $key '".join("','", @args)."'");

    my $v6 = ($args[1] =~ m![/\[\]]!) ? 1 : 0;

    # cleanup possible square brackets used for IPv6
    foreach (@args) {s/[\[\]]+//g;}

    # reverse enable to assign string to port even if no bind_adress
    # is specified
    my $re = $v6 ? qr!/! : qr!:! ; 
    my ($port,$bind_adr ) = reverse split $re,$args[0] ;
    my ($host,$host_port) = split $re,$args[1] ;

    my $load_str = '';
    $load_str .= "GatewayPorts=1 " if $bind_adr ;

    $load_str .= "$key:$size ";

    $load_str .= 'ipv6=1 ' if $v6 ;

    $load_str .= "bind_address=$bind_adr " if defined $bind_adr ;
    $load_str .= "port=$port host=$host hostport=$host_port";

    $current_node -> load($load_str) ;
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
	my $backup = "$file.".time.".bak" ;
	$logger->info("Backing up file $file in $backup");
	copy($file,$backup);
    }

    $logger->info("writing config file $file");

    my $result = write_node_content($config_root);

    #print $result ;
    open(OUT,"> $file") || die "cannot open $file:$!";
    print OUT $result;
    close OUT;

    return 1;
}

# for ssh_write:
# if root: use /etc/ssh/ssh_config as usual
# if normal user: load root file in "preset mode" 
#                 load ~/.ssh/config in normal mode
#                 write back to ~/.ssh/config
#                 Ssh model can only specify root config_dir

sub ssh_write {
    my %args = @_ ;
    my $config_root = $args{object}
      || croak __PACKAGE__," ssh_write: undefined config root object";

    my $is_user = 1 ;
    # $__test_root_file is a special global variable used only for tests
    $is_user = 0 if ($> == 0 or $__test_ssh_root_file ); 
    my $home_dir = $__test_ssh_home || $ENV{HOME} ;

    my $config_dir = $is_user ? $home_dir.'/.ssh' : $args{config_dir} ;
    my $dir = $args{root}.$config_dir ;

    mkpath($dir, {mode => 0755} )  unless -d $dir ;

    my $file = $is_user ? "$dir/config" : "$dir/ssh_config" ;

    if (-r "$file") {
	my $backup = "$file.".time ;
	$logger->info("Backing up file $file in $backup");
	copy($file,$backup);
    }

    $logger->info("writing config file $file");

    my $result = write_node_content($config_root,'custom');

    #print $result ;
    open(OUT,"> $file") || die "cannot open $file:$!";
    print OUT $result;
    close OUT;

    return 1;
}

sub write_line {
    return sprintf("%-20s %s\n",@_) ;
}

sub write_node_content {
    my $node = shift ;
    my $mode = shift || '';

    my $result = '' ;
    my $match  = '' ;

    foreach my $name ($node->get_element_name(for => 'master') ) {
	next unless $node->is_element_defined($name) ;
	my $elt = $node->fetch_element($name) ;
	my $type = $elt->get_type;

	#print "got $key type $type and ",join('+',@arg),"\n";
	if    ($name eq 'Match') { 
	    $match .= write_all_match_block($elt,$mode) ;
	}
	elsif    ($name eq 'Host') { 
	    $match .= write_all_host_block($elt,$mode) ;
	}
	elsif    ($name =~ /^(Local|Remote)Forward$/) { 
	    map { $result .= write_forward($_,$mode) ;} $elt->fetch_all() ;
	}
#	elsif    ($name eq 'ClientAliveCheck') { 
#	    # special case that must be skipped
#	}
	elsif    ($type eq 'leaf') { 
	    my $v = $elt->fetch($mode) ;
	    if (defined $v and $elt->value_type eq 'boolean') {
		$v = $v == 1 ? 'yes':'no' ;
	    }
	    $result .= write_line($name,$v) if defined $v;
	}
	elsif    ($type eq 'check_list') { 
	    my $v = $elt->fetch($mode) ;
	    $result .= write_line($name,$v) if defined $v and $v;
	}
	elsif ($type eq 'list') { 
	    map { $result .= write_line($name,$_) ;} $elt->fetch_all_values($mode) ;
	}
	elsif ($type eq 'hash') {
	    foreach my $k ( $elt->get_all_indexes ) {
		my $v = $elt->fetch_with_id($k)->fetch($mode) ;
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
    my $mode = shift || '';

    my $result = '' ;
    foreach my $elt ($match_elt->fetch_all($mode) ) {
	$result .= write_match_block($elt,$mode) ;
    }

    return $result ;
}

sub write_match_block {
    my $match_elt = shift ;
    my $mode = shift || '';

    my $result = "\nMatch " ;

    foreach my $name ($match_elt->get_element_name(for => 'master') ) {
	my $elt = $match_elt->fetch_element($name) ;

	if ($name eq 'Settings') {
	    $result .= "\n".write_node_content($elt,$mode)."\n" ;
	}
	elsif ($name eq 'Condition') {
	    $result .= write_match_condition($elt,$mode) ."\n" ;
	}
	else {
	    die "write_match_block: unexpected element: $name";
	}
    }

    return $result ;
}

sub write_match_condition {
    my $cond_elt = shift ;
    my $mode = shift || '';

    my $result = '' ;

    foreach my $name ($cond_elt->get_element_name(for => 'master') ) {
	my $elt = $cond_elt->fetch_element($name) ;
	my $v = $elt->fetch($mode) ;
	$result .= " $name $v" if defined $v;
    }

    return $result ;
}

sub write_all_host_block {
    my $host_elt = shift ;
    my $mode = shift || '';

    my $result = '' ;

    foreach my $pattern ( $host_elt->get_all_indexes) {
	my $block_elt = $host_elt->fetch_with_id($pattern) ;
	my $block_data = write_node_content($block_elt,'custom') ;

	# write data only if custom pattern or custom data is found this
	# is necessary to avoid writing data from /etc/ssh/ssh_config that
	# were entered as 'preset' data
	if ($block_data) {
	    $result .= "Host $pattern\n$block_data\n" ;
	}
    }
    return $result ;
}

sub write_forward {
    my $forward_elt = shift ;
    my $mode = shift || '';

    my $result = '' ;

    my $v6 = $forward_elt->grab_value('ipv6') ;
    my $sep = $v6 ? '/' : ':';

    my $line = '';
    foreach my $name ($forward_elt->get_element_name(for => 'master') ) {
	next if $name eq 'ipv6' ;
	my $elt = $forward_elt->fetch_element($name) ;
	my $v = $elt->fetch($mode) ;
	next unless defined $v;
	$line .=  $name =~ /bind|host$/ ? "$v$sep"
	       :  $name eq 'port'       ? "$v "
	       :                           $v ;
    }

    return write_line($forward_elt->element_name,$line) ;
}
1;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 LICENSE

   Copyright (c) 2008-2010 Dominique Dumont.

   This file is part of Config-Model-OpenSsh.

   Config-Model-OpenSsh is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser Public License as
   published by the Free Software Foundation; either version 2.1 of
   the License, or (at your option) any later version.

   Config-Xorg is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser Public License for more details.

   You should have received a copy of the GNU Lesser Public License
   along with Config-Model; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

=head1 SEE ALSO

L<config-edit-sshd>, L<config-edit-ssh>, L<Config::Model>,
