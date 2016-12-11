package Config::Model::TermUI;

use Carp;
use utf8;      # so literals and identifiers can be in UTF-8
use v5.12;     # or later to get "unicode_strings" feature
use strict;
use warnings;
use open      qw(:std :utf8);    # undeclared streams in UTF-8
use Encode qw(decode_utf8);

use Term::ReadLine;

use base qw/Config::Model::SimpleUI/;

my $completion_sub = sub {
    my ( $self, $text, $line, $start ) = @_;

    my @choice = $self->{current_node}->get_element_name;
    my @ret = grep( /^$text/, @choice );
    return @ret;
};

my $leaf_completion_sub = sub {
    my ( $self, $text, $line, $start ) = @_;

    my @choice = $self->{current_node}->get_element_name( cargo_type => 'leaf' );
    my @ret = grep( /^$text/, @choice );
    return @ret;
};

my $fix_completion_sub = sub {
    my ( $self, $text, $line, $start ) = @_;

    my @choice = $self->{current_node}->get_element_name;
    push @choice, '!';
    my @ret = grep( /^$text/, @choice );
    return @ret;
};

my $ll_completion_sub = sub {
    my ( $self, $text, $line, $start ) = @_;

    my @choice = $self->{current_node}->get_element_name;
    push @choice, '-nz';
    my @ret = grep( /^$text/, @choice );
    return @ret;
};

# BUG: autocompletion does not really on a hash element with an index
# containing white space (i.e. something like std_id:"abc def",

my $cd_completion_sub = sub {
    my ( $self, $text, $line, $start ) = @_;

    #print "text '$text' line '$line' start $start\n";
    #print "  cd comp param is ",join('+',@_),"\n";

    # we know that text begins with 'cd '
    my $cmd = $line;
    $cmd =~ s/cd\s+//;

    # convert usual cd_ism ( '..' '/foo') to grab syntax ( '-' '! foo')
    #$text =~ s(^/)  (! );
    $cmd =~ s(^\.\.$)(-)g;
    #$text =~ s(/)   ( )g;

    my $new_item;
    while ( not defined $new_item ) {

        # grab in tolerant mode
        #print "Grabbing $cmd\n";
        eval {
            $new_item = $self->{current_node}->grab( step => $cmd, type => 'node', mode => 'strict', autoadd => 0 );
        };
        chop $cmd;
    }

    #print "Grab got ",$new_item->location,"\n";

    my @choice = length($line) > 3 ? () : ( '!', '-' );
    my $new_type = $new_item->get_type;

    my @cargo = $new_item->get_element_name( cargo_type => 'node' );
    foreach my $elt_name (@cargo) {
        if ( $new_item->element_type($elt_name) =~ /hash|list/ ) {
            push @choice, "$elt_name:";
            foreach my $idx ( $new_item->fetch_element($elt_name)->fetch_all_indexes ) {
                # my ($idx) = ($raw_idx =~ /([^\n]{1,40})/ );
                # $idx .= '...' unless $raw_idx eq $idx ;
                push @choice, "$elt_name:" . ($idx =~ /[^\w._-]/ ? qq("$idx") : $idx );
            }
        }
        else {
            push @choice, $elt_name;
        }
    }

    # filter possible choices according to input
    my @ret = grep( /^$text/, @choice );

    #print "->choice +",join('+',@ret),"+ text:'$text'<-\n";

    return @ret;
};

my %completion_dispatch = (
    cd     => $cd_completion_sub,
    desc   => $completion_sub,
    ll     => $ll_completion_sub,
    ls     => $completion_sub,
    check  => $completion_sub,
    fix    => $fix_completion_sub,
    clear  => $completion_sub,
    set    => $leaf_completion_sub,
    delete => $leaf_completion_sub,
    reset  => $completion_sub,
);

sub completion {
    my ( $self, $text, $line, $start ) = @_;

    #print " comp param is +$text+$line+$start+\n";
    my $space_idx = index $line, ' ';
    my ( $main, $cmd ) = split m/\s+/, $line, 2;    # /;
            #warn " comp main cmd is '$main' (space_idx $space_idx)\n";

    if ( $space_idx > 0 and defined $completion_dispatch{$main} ) {
        my $i = $self->{current_node}->instance;
        return $completion_dispatch{$main}->( $self, $text, $line, $start );
    }
    elsif ( not $cmd ) {
        return grep ( /^$text/, $self->simple_ui_commands() );
    }

    return ();
}

sub new {
    my $type = shift;
    my %args = @_;

    my $self = {};

    foreach my $p (qw/root title prompt/) {
        $self->{$p} = delete $args{$p}
            or croak "TermUI->new: Missing $p parameter";
    }

    $self->{current_node} = $self->{root};

    my $term = new Term::ReadLine $self->{title};

    my $sub_ref = sub { $self->completion(@_); };

    my $word_break_string = "\\\t\n' `\@\$><;|&{(";

    if ( $term->ReadLine eq "Term::ReadLine::Gnu" ) {

        # See Term::ReadLine::Gnu / Custom Completion
        my $attribs = $term->Attribs;
        $attribs->{completion_function}             = $sub_ref;
        $attribs->{completer_word_break_characters} = $word_break_string;
        # this method is available only on Term::ReadLine::Gnu > 1.32
        $term->enableUTF8 if $term->can('enableUTF8');
    }
    elsif ( $term->ReadLine eq "Term::ReadLine::Perl" ) {
        no warnings "once";
        $readline::rl_completion_function = $sub_ref;
        &readline::rl_set( rl_completer_word_break_characters => $word_break_string );

        # &readline::rl_set('TcshCompleteMode', 'On');
    }

    $self->{term} = $term;

    foreach my $p (qw//) {
        $self->{$p} = delete $args{$p} if defined $args{$p};
    }

    bless $self, $type;
}

sub run_loop {
    my $self = shift;

    my $term = $self->{term};

    my $OUT = $term->OUT || \*STDOUT;
    my $user_cmd;
    while ( defined( $user_cmd = $term->readline( $self->prompt ) ) ) {
        last if $user_cmd eq 'exit' or $user_cmd eq 'quit';
        $user_cmd = decode_utf8($user_cmd,1);
        #print $OUT "cmd: $user_cmd\n";
        my $res = $self->run($user_cmd);
        print $OUT $res, "\n" if defined $res and $res;
        ## $term->addhistory($_) if defined $_ && /\S/;
    }
    print "\n";

    my $instance = $self->{root}->instance;
    if ( $instance->c_count ) {
        my @changes = $instance->say_changes;
        if (@changes) {
            $user_cmd = $term->readline("write back data before exit ? (Y/n)");
            $instance->write_back unless $user_cmd =~ /n/i;
            print "\n";
        }
    }
}

1;

# ABSTRACT: Interactive command line interface for cme

__END__

=head1 SYNOPSIS

 use Config::Model;
 use Config::Model::TermUI ;

 # define configuration tree object
 my $model = Config::Model->new;
  $model->create_config_class(
    name    => "Foo",
    element => [
        [qw/foo bar/] => {
            type       => 'leaf',
            value_type => 'string'
        },
    ]
 );
 $model ->create_config_class (
    name => "MyClass",

    element => [

        [qw/foo bar/] => {
            type       => 'leaf',
            value_type => 'string'
        },
        hash_of_nodes => {
            type       => 'hash',     # hash id
            index_type => 'string',
            cargo      => {
                type              => 'node',
                config_class_name => 'Foo'
            },
        },
    ],
 ) ;

 my $inst = $model->instance(root_class_name => 'MyClass' );

 my $root = $inst->config_root ;

 # put data
 my $steps = 'foo=FOO hash_of_nodes:fr foo=bonjour -
   hash_of_nodes:en foo=hello ';
 $root->load( steps => $steps );

 my $ui = Config::Model::TermUI->new(
     root => $root ,
     title => 'My class ui',
     prompt => 'class ui',
 );

 # engage in user interaction
 $ui -> run_loop ;

 print $root->dump_tree ;

Once the synopsis above has been saved in C<my_test.pl>, you can achieve the
same interactions as with C<Config::Model::SimpleUI>. Except that you can use
TAB completion:

 class ui:$ ls
 foo  bar  hash_of_nodes
 class ui:$ ll hash_of_nodes
 name         value        type         comment
 hash_of_nodes <Foo>        node hash    keys: "en" "fr"

 class ui:$ cd hash_of_nodes:en
 class ui: hash_of_nodes:en $ ll
 name         value        type         comment
 foo          hello        string
 bar          [undef]      string

 class ui: hash_of_nodes:en $ set bar=bonjour
 class ui: hash_of_nodes:en $ ll
 name         value        type         comment
 foo          hello        string
 bar          bonjour      string

 class ui: hash_of_nodes:en $ ^D

At the end, the test script dumps the configuration tree. The modified
C<bar> value can be found in there:

 foo=FOO
 hash_of_nodes:en
   foo=hello
   bar=bonjour -
 hash_of_nodes:fr
   foo=bonjour - -

=head1 DESCRIPTION

This module provides a helper to construct pure ASCII user interface
on top of L<Term::ReadLine>. To get better interaction you must
install either L<Term::ReadLine::Gnu> or L<Term::ReadLine::Perl>.

Depending on your installation, either L<Term::ReadLine::Gnu> or
L<Term::ReadLine::Perl> is used. See L<Term::ReadLine> to
override default choice.

=head1 Dependencies

This module is optional and depends on L<Term::ReadLine> to work. To
reduce the dependency list of L<Config::Model>, C<Term::ReadLine> is
only recommended. L<cme> gracefully degrades to
L<Config::Model::SimpleUI> when necessary.

=head1 USER COMMAND SYNTAX

See L<Config::Model::SimpleUI/"USER COMMAND SYNTAX">.

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

=head1 Methods

=head2 run_loop()

Engage in user interaction until user enters '^D' (CTRL-D).

=head1 BUGS

=over

=item *

Auto-completion is not complete.

=item *

Auto-completion provides wrong choice when you try to C<cd> in a hash
where the index contains a white space. I.e. the correct command is
C<cd foo:"a b"> instead of C<cd foo: "a b"> as proposed by auto
completion.

=back

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,
L<Config::Model::Instance>,
L<Config::Model::Node>,

=cut
