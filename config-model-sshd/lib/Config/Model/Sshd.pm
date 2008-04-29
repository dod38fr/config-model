# $Author: ddumont $
# $Date: 2008-01-23 11:12:16 $
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
use Data::Dumper ;

use vars qw($VERSION) ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/;

my $logger = Log::Log4perl::get_logger(__PACKAGE__);

sub read {
    my %args = @_ ;
    my $config_root = $args{object}
      || croak __PACKAGE__," read: undefined config root object";
    my $dir = $args{conf_dir} 
      || croak __PACKAGE__," read: undefined config dir";
    my $test = $args{test} || 0;

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
	my $idx = 0 ;
	parse(\@file, $config_root) ;
    }
    else {
	die __PACKAGE__," read: can't open $file:$!";
    }
}

my %dispatch 
  = (
     PermitOpen => \&load_list ,
     AcceptEnv  => \&load_list ,
     AllowGroups => \&load_list ,
     AllowUsers => \&load_list ,
    );

sub load_list { 
    my ($obj,$arg) = @_;
    map {$obj->push($_) } split /\s+/,$arg ;
}

sub parse {
    my ($file,$config_root) = @_ ;

    my $node = $config_root ;
    my $instance = $config_root->instance ;
    foreach (@$file) {
	s/#.*//; # remove comments
	next if /^\s*$/; # skip blank lines
	s/^\s+//; # cleanup beginning of line

	my ($keyword, $arg) = split /\s+/,$_,2 ;
	my $elt_obj = $node -> fetch_element($keyword)
	  or next ; # return undef in tolerant mode if keyword is inknown

	if (defined $dispatch{$keyword}) {
	    $dispatch{$keyword}->($elt_obj,$arg) ;
	} 
    }
}



1;
