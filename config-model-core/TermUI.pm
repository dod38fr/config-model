# $Author: ddumont $
# $Date: 2007-01-11 12:33:34 $
# $Revision: 1.8 $

#    Copyright (c) 2006-2007 Dominique Dumont.
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
$VERSION = sprintf "1.%04d", q$Revision: 1.8 $ =~ /(\d+)/;

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
   -> jump into node
set elt=value, elt:key=value
   -> set a value
delete elt:key
   -> delete a value from a list or hash element
display elt elt:key
   -> display a value
ls   -> show elements of current node
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
    my $obj = $self->{current_node} ;

    my $i = $self->{current_node}->instance;
    $i->push_no_value_check('fetch') ;
    my $res = $obj->describe ;
    $i->pop_no_value_check;
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
       $i->push_no_value_check('fetch') ;
       my @res = $self->{current_node}->get_element_name ;
       $i->pop_no_value_check;
       return join('  ',@res) ;
   },
   dump => sub { 
       my $self = shift ;
       my $i = $self->{current_node}->instance;
       $i->push_no_value_check('fetch') ;
       my @res = $self->{current_node}-> dump_tree(full_dump => 1);
       $i->pop_no_value_check;
       return join('  ',@res) ;
   },
   delete => sub {
       my $self = shift ;
       my ($elt,$key) = split /:/,$_[0] ;
       $self->{current_node}->fetch_element($elt)->delete($key);
       return '' ;
   },
   ll => $ll_sub,
   cd => $cd_sub,
   description => $desc_sub,
   desc => $desc_sub ,
  ) ;

my $completion_sub = sub { 
    my ($self,$text,$start) = @_ ;

    my @choice = $self->{current_node} -> get_element_name ;

    return () if scalar grep {$text eq $_ } @choice ;

    return @choice ;
} ;

my $leaf_completion_sub = sub { 
    my ($self,$text,$start) = @_ ;

    my @choice = $self->{current_node} 
      -> get_element_name (cargo_type => 'leaf');

    return () if scalar grep {$text eq $_ } @choice ;

    return @choice ;
} ;

my $cd_completion_sub = sub { 
    my ($self,$text,$start) = @_ ;

    #print "  cd comp param is ",join('+',@_),"\n";
    # convert usual cd_ism ( '..' '/foo') to grab syntax ( '-' '! foo')
    #$text =~ s(^/)  (! ); 
    #$text =~ s(\.\.)(-)g;
    #$text =~ s(/)   ( )g;
    my @cmds = split m(\s+),$text ;

    my $last = $cmds[-1] || '';
    #print "  cd cmd is ",join('+',@cmds),", last is $last\n";

    # grab in tolerant mode
    my $new_node = $self->{current_node} 
      -> grab(step => "@cmds", strict => 0, type => 'node', autoadd => 0);

    my $name = $new_node -> element_name || '';

    my @choice ;

    my @cargo = $new_node -> get_element_name(cargo_type => 'node') ;
    foreach my $elt_name (@cargo) {
	if ($new_node->element_type($elt_name) =~ /hash|list/ ) {
	    my @idx = $new_node -> fetch_element($elt_name)
	      -> get_all_indexes ;
	    #print "$elt_name @idx\n";
	    if (@idx) {
		my @tmp = map { qq($elt_name:$_); } @idx ;
		#print "tmp @tmp\n";
		push @choice, @tmp ;
	    } 
	    else {
		push @choice, "$elt_name:" ;
	    }
	}
	else {
	    push @choice, "$elt_name" ;
	}
    }

    my $found = scalar grep {$_ eq $last} @choice ;

    print "DEBUG:  cd cmd: new_node is ",$new_node->location,", name $name, ",
      "choice @choice, found $found\n" if $::debug;
    return () if $found ;

    return @choice ;
} ;


my %completion_dispatch = 
  (
   cd => $cd_completion_sub,
   desc => $completion_sub,
   set => $leaf_completion_sub,
  );

sub completion {
    my ($self,$text,$line,$start) = @_ ;

    #print " comp param is ",join('+',@_),"\n";
    my $space_idx = index $line,' ' ;
    my ($main, @cmds) = split m/\s+/, $line; # /;
    #print " comp main cmd is '$main' (space_idx $space_idx)\n";

    if ( $space_idx > 0 and defined $completion_dispatch{$main}) {
	my $i = $self->{current_node}->instance;
	$i->push_no_value_check('fetch') ;
	return $completion_dispatch{$main}->($self,"@cmds",$start) ;
	$i->pop_no_value_check;
    }
    elsif (scalar @cmds <= 1) {
	return keys %run_dispatch ;
    }

    return () ;
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

    # See Term::ReadLine::Gnu / Custom Completion
    my $attribs = $self->{term}->Attribs ;
    $attribs->{completion_function} = sub { $self->completion(@_) ;} ;

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
	last if $user_cmd eq 'exit' or $user_cmd eq 'quit' ;
	my $res = $self->run($user_cmd);
	print $OUT $res, "\n" if defined $res;
	# $term->addhistory($_) if defined $_ && /\S/;
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

Auto-completion is not complete.

=item *

Auto-completion provides wrong choice when you try to C<cd> in a hash
where the index contains a white space. I.e. the correct command is
C<cd foo:"a b"> instead of C<cd foo:a b> as proposed by auto
completion.

=item *

UI should take into account permission.

=back

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,
L<Config::Model::Instance>,
L<Config::Model::Node>,

=cut
