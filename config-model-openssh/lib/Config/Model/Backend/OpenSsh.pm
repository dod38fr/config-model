package Config::Model::Backend::OpenSsh ;

use Moose ;
extends "Config::Model::Backend::Any" ;

has 'current_node'  => ( 
    is => 'rw', 
    isa => 'Config::Model::Node',
    weak_ref => 1 
) ;


use Carp ;
use IO::File ;
use Log::Log4perl;
use File::Copy ;
use File::Path ;

my $logger = Log::Log4perl::get_logger("Backend::OpenSsh");

my @dispatch = (
    qr/match/i                 => 'match',
    qr/host\b/i                => 'host',
    qr/(local|remote)forward/i => 'forward',
    qr/localcommand/i          => 'assign',
    qr/\w/                     => 'assign',
);

sub read_ssh_file {
    my $self = shift ;
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

    my $fh = new IO::File $file, "r"  
        || die __PACKAGE__," read_ssh_file: can't open $file:$!";

    my @lines = $fh->getlines ;
    # try to get global comments (comments before a blank line)
    $self->read_global_comments(\@lines,'#') ;

    my @assoc = $self->associates_comments_with_data( \@lines, '#' ) ;
    foreach my $item (@assoc) {
        my ( $vdata, $comment ) = @$item;

        my ( $k, @v ) = split /\s+/, $vdata;

        my $i = 0;
        while ( $i < @dispatch ) {
            my ( $regexp, $sub ) = @dispatch[ $i++, $i++ ];
            if ( $k =~ $regexp ) {
                $logger->trace("read_ssh_file: dispatch calls $sub");
                $self->$sub( $config_root, $k, \@v, $comment );
                last;
            }

            warn __PACKAGE__, " unknown keyword: $k" if $i >= @dispatch;
        }
    }
    $fh->close;
    return 1;
}

sub assign {
    my ($self,$root, $key,$arg,$comment) = @_ ;
    $logger->debug("assign: $key @$arg # $comment");
    $self->current_node($root) unless defined $self->current_node ;

    # keys are case insensitive, try to find a match
    if ( not $self->current_node->element_exists( $key ) ) {
	foreach my $elt ($self->current_node->get_element_name(for => 'master') ) {
	    $key = $elt if lc($key) eq lc($elt) ;
	}
    }

    my $elt = $self->current_node->fetch_element($key) ;
    my $type = $elt->get_type;
    #print "got $key type $type and ",join('+',@$arg),"\n";
    if    ($type eq 'leaf') { 
	$elt->store( join(' ',@$arg) ) ;
    }
    elsif ($type eq 'list') { 
	$elt->push ( @$arg ) ;
    }
    elsif ($type eq 'hash') {
        $elt->fetch_with_id($arg->[0])->store( $arg->[1] );
    }
    elsif ($type eq 'check_list') {
	my @check = split /,/,$arg->[0] ;
        $elt->set_checked_list (@check) ;
    }
    else {
       die "OpenSsh::assign did not expect $type for $key\n";
    }
  }


sub write_line {
    my $self= shift ;
    return sprintf("%-20s %s\n",@_) ;
}

sub write_node_content {
    my $self= shift ;
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
	    $match .= $self->write_all_match_block($elt,$mode) ;
	}
	elsif    ($name eq 'Host') { 
	    $match .= $self->write_all_host_block($elt,$mode) ;
	}
	elsif    ($name =~ /^(Local|Remote)Forward$/) { 
	    map { $result .= $self->write_forward($_,$mode) ;} $elt->fetch_all() ;
	}
#	elsif    ($name eq 'ClientAliveCheck') { 
#	    # special case that must be skipped
#	}
	elsif    ($type eq 'leaf') { 
	    my $v = $elt->fetch($mode) ;
	    if (defined $v and $elt->value_type eq 'boolean') {
		$v = $v == 1 ? 'yes':'no' ;
	    }
	    $result .= $self->write_line($name,$v) if defined $v;
	}
	elsif    ($type eq 'check_list') { 
	    my $v = $elt->fetch($mode) ;
	    $result .= $self->write_line($name,$v) if defined $v and $v;
	}
	elsif ($type eq 'list') { 
	    map { $result .= $self->write_line($name,$_) ;} $elt->fetch_all_values($mode) ;
	}
	elsif ($type eq 'hash') {
	    foreach my $k ( $elt->get_all_indexes ) {
		my $v = $elt->fetch_with_id($k)->fetch($mode) ;
		$result .=  $self->write_line($name,"$k $v") ;
	    }
	}
	else {
	    die "OpenSsh::write did not expect $type for $name\n";
	}
    }

    return $result.$match ;
}

1;

=head1 NAME

Config::Model::Backend::OpenSsh - Common backend methods for Ssh and Sshd backends

=head1 SYNOPSIS


=head1 DESCRIPTION

This module provides a configuration editors (and models) for the 
configuration files of OpenSsh. (C</etc/ssh/sshd_config>, F</etc/ssh/ssh_config>
and C<~/.ssh/config>).

This module can also be used to modify safely the
content of these configuration files from a Perl programs.

Once this module is installed, you can edit C</etc/ssh/sshd_config> 
with run (as root) :

 # config-edit -application sshd 

To edit F</etc/ssh/ssh_config>, run (as root):

 # config-edit -application ssh

To edit F<~/.ssh/config>, run as a normal user:

 # config-edit -application ssh

=head1 user interfaces

As mentioned in L<config-edit>, several user interfaces are available:

=over

=item *

A graphical interface is proposed by default if L<Config::Model::TkUI> is installed.

=item *

A Curses interface with option C<-ui curses> if L<Config::Model::CursesUI> is installed.

=item *

A Shell like interface with option C<-ui term>.

=item *

A L<Fuse> virtual file system with option C<< -ui fuse -fuse_dir <mountpoint> >> 
if L<Fuse> is installed (Linux only)

=back

=head1 STOP

The documentation provides on the reader and writer of OpenSsh configuration files.
These details are not needed for the basic usages explained above.

=head1 Functions

These read/write functions are part of OpenSsh read/write backend. They are 
declared in OpenSsh configuration models and are called back when needed to read the 
configuration file and write it back.

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
