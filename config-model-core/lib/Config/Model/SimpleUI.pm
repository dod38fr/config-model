
#    Copyright (c) 2008 Dominique Dumont.
#
#    This file is part of Config-Model.
#
#    Config-Model is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Model is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
#    02110-1301 USA

package Config::Model::SimpleUI ;

use Carp;
use strict ;
use warnings ;


=head1 NAME

Config::Model::SimpleUI - Simple interface for Config::Model

=head1 SYNOPSIS

 my $model = Config::Model -> new ;
 my $inst = $model->instance (root_class_name => 'RootClass', 
                              instance_name => 'my_instance');
 my $root = $inst -> config_root ;

 my $ui = Config::Model::SimpleUI->new( root => $root ,
  	               		        title => 'My Title',
					prompt => 'My Prompt',
				      );

 # engage in user interaction
 $ui -> run_loop ;

=head1 DESCRIPTION

This module provides a pure ascii user interface using STDIN and
STDOUT.

=head1 USER COMMAND SYNTAX

=over

=item cd ...

Jump into node or value element. You can use C<< cd <element> >>,
C<< cd <elt:key> >> or C<cd -> to go up one node or C<cd !> 
to go to configuration root.

=item set elt=value 

Set a leaf value. 

=item set elt:key=value

Set a leaf value locate in a hash or list element.

=item display node_name elt:key

Display a value

=item ls

Show elements of current node

=item help

Show available commands.

=item desc[ription]

Show class description of current node.

=item desc(elt)

Show description of element from current node.

=item desc(value)

Show effect of value (for enum)

=back

=cut

my $syntax = '
cd <elt> cd <elt:key>, cd - , cd !
   -> jump into node
set elt=value, elt:key=value
   -> set a value
delete elt:key
   -> delete a value from a list or hash element
display elt elt:key
   -> display a value
ls -> show elements of current node
ll -> show elements of current node and their value 
help -> show available command
desc[ription] -> show class desc of current node
desc <element>   -> show desc of element from current node
desc <value> -> show effect of value (for enum)
exit -> exit shell
';

my $desc_sub = sub {
    my $self = shift ;
    my $obj = $self->{current_node} ;
    my $res = '';

    if (@_) {
	my $item ;
	while ($item = shift) {
	    print "DEBUG: desc on $item\n" if $::debug;
	    if ($obj->isa('Config::Model::Node')) {
		my $type = $obj->element_type($item) ;
		my $elt = $obj->fetch_element($item);
		$res .= "element $item (type $type): "
		  . $obj->get_help($item)."\n" ;
		if ($type eq 'leaf' and $elt->value_type eq 'enum') {
		    $res .= "  possible values: "
		      . join(', ',$elt->get_choice) . "\n" ;
		}
	    }
	}
    }
    else {
	$res = $obj->get_help() ;
    }
    return $res ;
} ;

my $ll_sub = sub {
    my $self = shift ;
    my $elt = shift ;

    my $obj = $self->{current_node} ;

    my $i = $self->{current_node}->instance;
    my $res = $obj->describe(element => $elt, check =>'no') ;
    return $res ; 
} ;

my $cd_sub = sub { 
    my $self = shift ;
    my @cmds = @_;
    # convert usual cd_ism ( .. /foo) to grab syntax ( - ! foo)
    #map { s(^/)  (! ); 
#	  s(\.\.)(-)g; 
#	  s(/)   ( )g;
#      } @cmds ;

    my $new_node = $self->{current_node}->grab("@cmds") ;
    my $type = $new_node -> get_type ;
    my $name = $new_node -> element_name ;

    if (defined $new_node && $type eq 'node') {
	$self->{current_node} = $new_node;
    }
    elsif (defined $new_node && $type eq 'list' ) {
	print "Can't cd in a $type, please add an index (e.g. $name:0)\n" ;
    }
    elsif (defined $new_node && $type eq 'hash' ) {
	print "Can't cd in a $type, please add an index (e.g. $name:foo)\n" ;
    }
    elsif (defined $new_node && $type eq 'leaf' ) {
	print "Can't cd in a $type\n" ;
    }
    else {
	print "Cannot find @_\n" ;
    }

    return "" ;
} ;

my %run_dispatch =
  (
   help => sub{ return $syntax; } ,
   set  => sub { 
       my $self = shift ;
       $self->{current_node}->load(@_) ;
       return "" ;
   },
   display => sub { 
       my $self = shift ;
       print "Nothing to display" unless @_ ;
       return $self->{current_node}->grab_value(@_) ;
   },
   ls => sub { 
       my $self = shift ;
       my $i = $self->{current_node}->instance;
       my @res = $self->{current_node}->get_element_name ;
       return join('  ',@res) ;
   },
   dump => sub { 
       my $self = shift ;
       my $i = $self->{current_node}->instance;
       my @res = $self->{current_node}-> dump_tree(full_dump => 1);
       return join('  ',@res) ;
   },
   delete => sub {
       my $self = shift ;
       my ($elt,$key) = split /:/,$_[0] ;
       $self->{current_node}->fetch_element($elt)->delete($key);
       return '' ;
   },
   save => sub { 
       my ($self,$dir) = @_ ;
       $self->{root}->instance->write_back($dir);
       return "done";
   },
   ll => $ll_sub,
   cd => $cd_sub,
   description => $desc_sub,
   desc => $desc_sub ,
  ) ;

sub simple_ui_commands {
    sort keys %run_dispatch ;
}

=head1 CONSTRUCTOR

=head2 parameters

=over

=item root

Root node of the configuration tree

=item title

UI title

=item prompt

UI prompt. The prompt will be completed with the location of the
current node.

=back

=cut

sub new {
    my $type = shift; 
    my %args = @_ ;

    my $self = {} ;

    foreach my $p (qw/root title prompt/) {
	$self->{$p} = delete $args{$p} or
	  croak "SimpleUI->new: Missing $p parameter" ;
    }

    $self->{current_node} = $self->{root} ;

    bless $self, $type ;
}

=head1 Methods

=head2 run_loop()

Engage in user interaction until user enters '^D' (CTRL-D).

=cut

sub run_loop {
    my $self = shift ;

    my $user_cmd ;
    print $self->prompt ;
    while ( defined ($user_cmd = <STDIN>) ) {
	chomp $user_cmd ;
	last if $user_cmd eq 'exit' or $user_cmd eq 'quit' ;
	my $res = $self->run($user_cmd);
	print $res, "\n" if defined $res;
	print $self->prompt ;
    }
    print "\n";
}

sub prompt {
     my $self = shift ;
     my $ret = $self->{prompt}.':' ;
     my $loc = $self->{current_node}->location ;
     $ret .= " $loc " if $loc;
     return $ret . '$ '  ;
}


sub run {
    my ($self, $user_cmd ) = @_ ;

    return '' unless $user_cmd =~ /\w/ ;

    $user_cmd =~ s/^\s+// ;

    my ($action,$args) = split (m/\s+/,$user_cmd, 2)  ;
    $args =~ s/\s+$//g if defined $args ; #cleanup

    print "DEBUG: run '$action' with '$args'\n" if $::debug;

    if (defined $run_dispatch{$action}) {
	my $res = eval { $run_dispatch{$action}->($self,$args) ; } ;
	print $@ if $@ ;
	return $res ;
    }
    else {
	return "Unexpected command '$action'";
    }
}

sub list_cd_path {
    my $self = shift ;
    my $c_node = $self->{current_node} ;

    my @result ;
    foreach my $elt_name ($c_node->get_element_name) {
	my $t = $c_node->element_type($elt_name) ;

	if ($t eq 'list' or $t eq 'hash') {
	    push @result, 
	      map { "$elt_name:$_" }
		$c_node->fetch_element($elt_name)->get_all_indexes ;
	}
	else {
	    push @result, $elt_name ;
	}
    }

    return \@result ;
}
1;

=head1 BUGS

=over

=item *

UI should take into account experience.

=back

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,
L<Config::Model::Instance>,
L<Config::Model::Node>,

=cut
