# $Author: ddumont $
# $Date: 2006-06-20 12:00:46 $
# $Name: not supported by cvs2svn $
# $Revision: 1.2 $

#    Copyright (c) 2005 Dominique Dumont.
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

package Config::Model::TermUI ;

use Carp;
use strict ;
use warnings ;

use Term::ReadLine;

use vars qw($VERSION);
$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

=head1 NAME

  Config::Model::TermUI - Provides Config::Model UI à la Term::ReadLine

=head1 SYNOPSIS

 my $model = Config::Model -> new ;
 my $inst = $model->instance (root_class_name => 'RootClass', 
                                 instance_name => 'my_instance');
 my $root = $inst -> config_root ;

 my $term_ui = Config::Model::TermUI->new( root => $root ,
					   title => 'My Title',
					   prompt => 'My Prompt',
					 );

 # engage in user interaction
 $term_ui -> run_loop ;

=head1 DESCRIPTION

This module provides a helper to construct pure ascii user interface
on top of L<Term::ReadLine>.

=head1 CONSTRUCTOR

=head2 parameters

=over

=item root

Root node of the configuration tree

=item title

UI title

=item prompt

UI prompt. The prompt will be completed with the location of the current node

=back

=cut

sub new {
    my $type = shift; 
    my %args = @_ ;

    my $self = {
		call_back_on_important => 1 ,
		forward                => 1 ,
		current_node           => undef ,
	       } ;

    foreach my $p (qw/root title prompt/) {
	$self->{$p} = delete $args{$p} or
	  croak "WizardHelper->new: Missing $p parameter" ;
    }

    $self->{current_node} = $self->{root} ;

    $self->{term} = new Term::ReadLine $self->{title};

    foreach my $p (qw//) {
	$self->{$p} = delete $args{$p} if defined $args{$p} ;
    }

    bless $self, $type ;
}

=head1 Methods

=head2 run_loop()

Engage in user interaction until user enters '^D' (CTRL-D).

=cut

sub run_loop {
    my $self = shift ;

    my $term = $self->{term} ;
    my $OUT = $term->OUT || \*STDOUT;
    my $user_cmd ;
    while ( defined ($user_cmd = $term->readline($self->prompt)) ) {
	my $res = $self->run($user_cmd);
	print $OUT $res, "\n" ;
	$term->addhistory($_) if /\S/;
    }
}

sub prompt {
     my $self = shift ;
     my $ret = $self->{prompt}.':' ;
     my $loc = $self->{current_node}->location ;
     $ret .= " $loc " if $loc;
     return $ret . '$'  ;
}

=head1 USER COMMAND SYNTAX

=over

=item cd ...

Jump into node or value element. You can use C<< cd <element> >>,
C<< cd <elt:key> >> or C<cd -> to go up one node or C<cd !> 
to go to configuration root.

=item set elt=value, elt:key=value

Set a value.

=item display elt elt:key

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
   -> jump into node or value element
set elt=value, elt:key=value
   -> set a value
display elt elt:key
   -> display a value
ls   -> show elements of current node
help -> show available command
desc[ription] -> show class desc of current node
desc(elt)   -> show desc of element from current node
desc(value) -> show effect of value (for enum)
';

my $desc_sub = sub {
    my $self = shift ;
    $self->{current_node}->get_help(@_) ;
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
       return $self->{current_node}->grab_value(@_) ;
   },
   ls => sub { 
       my $self = shift ;
       return $self->{current_node}->get_element_name ;
   },
   cd => sub { 
       my $self = shift ;
       $self->{current_node} = $self->{current_node}->grab(@_) ;
       return "" ;
   },
   description => $desc_sub,
   desc => $desc_sub ,
  ) ;

sub run {
    my ($self, $user_cmd ) = @_ ;

    my ($action,@args) = split /\s+/,$user_cmd ;

    print "run '$action' with '",join("','",@args),"'\n";

    if (defined $run_dispatch{$action}) {
	return $run_dispatch{$action}->($self,@args) ;
    }
    else {
	return "Unexpected command '$action'";
    }
}

1;

=head1 AUTHOR

Dominique Dumont, domi@komarr.grenoble.hp.com

=head1 SEE ALSO

L<Config::Model>,
L<Config::Model::Instance>,
L<Config::Model::Node>,

=cut
