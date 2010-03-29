
#    Copyright (c) 2006-2008 Dominique Dumont.
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
our $VERSION="1.201";
use warnings ;

use Term::ReadLine;

# use vars qw($VERSION);
use base qw/Config::Model::SimpleUI/ ;


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
on top of L<Term::ReadLine>. To get better interaction you must
install either L<Term::ReadLine::Gnu> or L<Term::ReadLine::Perl>.

Depending on your installation, either L<Term::ReadLine::Gnu> or
L<Term::ReadLine::Perl>. See L<Term::ReadLine> to override default
choice.

=head1 USER COMMAND SYNTAX

See L<Config::Model::SimpleUI/"USER COMMAND SYNTAX">.

=cut

my $completion_sub = sub { 
    my ($self,$text,$line,$start) = @_ ;

    my @choice = $self->{current_node} -> get_element_name ;

    return () if scalar grep {$text eq $_ } @choice ;

    return @choice ;
} ;

my $leaf_completion_sub = sub { 
    my ($self,$text,$line,$start) = @_ ;

    my @choice = $self->{current_node} 
      -> get_element_name (cargo_type => 'leaf');

    return () if scalar grep {$text eq $_ } @choice ;

    return @choice ;
} ;

# BUG: When doing autocompletion on a hash element with an index
# containing white space (i.e. something like std_id:"abc def",
# readline's completion insists on adding a white space after :
# i.e. the run command tries 'std_id: "abd def"' . This fails.  The
# problem probably revolves around setting a readline variable like
# rl_completer_word_break_characters, but I do not know which one.

my $cd_completion_sub = sub { 
    my ($self,$text,$line,$start) = @_ ;

    #print "text '$text' line '$line' start $start\n";
    #print "  cd comp param is ",join('+',@_),"\n";

    # convert usual cd_ism ( '..' '/foo') to grab syntax ( '-' '! foo')
    #$text =~ s(^/)  (! ); 
    #$text =~ s(\.\.)(-)g;
    #$text =~ s(/)   ( )g;

    # we know that text begins with 'cd '
    my $cmd = $line;
    $cmd =~ s/cd\s+//;

    my $new_item;
    while (not defined $new_item) {
	# grab in tolerant mode
	#print "Grabbing $cmd\n";
	eval {$new_item = $self->{current_node} 
		-> grab(step => $cmd, strict => 1, autoadd => 0); };
	chop $cmd ;
    }

    #print "Grab got ",$new_item->location,"\n";

    my @choice = length($line) > 3 ? () : ('!','-');
    my $new_type = $new_item->get_type ;

    if ($new_type eq 'node') {
	my @cargo = $new_item -> get_element_name(cargo_type => 'node') ;
	foreach my $elt_name (@cargo) {
	    if ($new_item->element_type($elt_name) =~ /hash|list/ ) {
		push @choice, "$elt_name:" ;
	    }
	    else {
		push @choice, "$elt_name " ;
	    }
	}
    }
    elsif ($new_type eq 'hash' or $new_type eq 'list') {
	my @idx = $new_item -> get_all_indexes ;
	if (@idx) {
	    my $quote = $line =~ /"$/ ? '' : '"';
	    my @tmp = map { /\s/ ? qq($quote$_" ) : qq($_ ); } @idx ;
	    #print "tmp @tmp\n";
	    push @choice, @tmp ;
	}
	# skip leaf items
    }

    # filter possible choices according to input
    my @ret = grep(/^$text/, @choice) ;
    #print "->choice +",join('+',@ret),"+ text:'$text'<-\n";

    # my $name = $new_node -> element_name || '';
    #print "DEBUG:  cd cmd: new_node is ",$new_node->location,", name $name, ",
    #  "choice @choice\n" ;#if $::debug;

    return @ret ;
} ;


my %completion_dispatch = 
  (
   cd => $cd_completion_sub,
   desc => $completion_sub,
   ll   => $completion_sub,
   set => $leaf_completion_sub,
  );

sub completion {
    my ($self,$text,$line,$start) = @_ ;

    #print " comp param is +$text+$line+$start+\n";
    my $space_idx = index $line,' ' ;
    my ($main, $cmd) = split m/\s+/, $line, 2; # /;
    #warn " comp main cmd is '$main' (space_idx $space_idx)\n";

    if ( $space_idx > 0 and defined $completion_dispatch{$main}) {
	my $i = $self->{current_node}->instance;
	$i->push_no_value_check('fetch') ;
	return $completion_dispatch{$main}->($self,$text,$line,$start) ;
	$i->pop_no_value_check;
    }
    elsif (not $cmd) {
	return $self->simple_ui_commands() ;
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

    my $self = {} ;

    foreach my $p (qw/root title prompt/) {
	$self->{$p} = delete $args{$p} or
	  croak "WizardHelper->new: Missing $p parameter" ;
    }

    $self->{current_node} = $self->{root} ;

    my $term = new Term::ReadLine $self->{title};

    my $sub_ref = sub { $self->completion(@_) ;} ;

    my $word_break_string = "\\\t\n' `\@\$><;|&{(" ;

    if ($term->ReadLine eq "Term::ReadLine::Gnu") {
	# See Term::ReadLine::Gnu / Custom Completion
	my $attribs = $term->Attribs ;
	$attribs->{completion_function} = $sub_ref ;
	$attribs->{completer_word_break_characters} 
	  = $word_break_string;
    }
    elsif ($term->ReadLine eq "Term::ReadLine::Perl") {
	no warnings "once" ;
	$readline::rl_completion_function = $sub_ref ;
	&readline::rl_set(rl_completer_word_break_characters => $word_break_string) ;
	# &readline::rl_set('TcshCompleteMode', 'On');
    }

    $self->{term} = $term ;

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
	#print $OUT "cmd: $user_cmd\n";
	my $res = $self->run($user_cmd);
	print $OUT $res, "\n" if defined $res and $res;
	## $term->addhistory($_) if defined $_ && /\S/;
    }
    print "\n";
}

1;

=head1 BUGS

=over

=item *

Auto-completion is not complete.

=item *

Auto-completion provides wrong choice when you try to C<cd> in a hash
where the index contains a white space. I.e. the correct command is
C<cd foo:"a b"> instead of C<cd foo: "a b"> as proposed by auto
completion.

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
