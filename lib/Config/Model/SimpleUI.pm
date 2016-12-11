package Config::Model::SimpleUI;

use Carp;
use 5.010;
use strict;
use warnings;
use open      qw(:std :utf8);    # undeclared streams in UTF-8
use Encode qw(decode_utf8);
use Regexp::Common qw/delimited/;

my $syntax = '
cd <elt> cd <elt:key>, cd - , cd !
   -> jump into node
set elt=value, elt:key=value
   -> set a value
clear elt
   -> clear value or list or hash
delete elt:key
   -> delete a value from a list or hash element
delete elt
   -> like reset, delete a value (set to undef)
display elt elt:key
   -> display a value
ls -> show elements of current node (args: filter pattern)
ll [-nz] [-v] [ element | pattern ]
   -> show elements of current node and their value
     (options: -nz → hides empty value, -v → verbose)
     (args: element name or filter pattern)
tree -> show configuration tree from current node
help -> show available command
desc[ription] -> show class desc of current node
desc <element>   -> show desc of element from current node
desc <value> -> show effect of value (for enum)
changes -> list unsaved changes
check [elt] -> run check current on current node or elt
fix [ ! | elt ]
  -> fix warnings in current node or of specified element or on all tree (with ! arg)
save -> save current changes
exit -> exit shell
';

my $desc_sub = sub {
    my $self = shift;
    my $obj  = $self->{current_node};
    my $res  = '';

    if (@_) {
        my $item;
        while ( $item = shift ) {
            if ( $obj->get_type() eq 'node' ) {
                my $type = $obj->element_type($item);
                my $elt  = $obj->fetch_element($item);
                my $help = $obj->get_help_as_text($item);
                $res .= "element $item (type $type)";
                $res .= ": " if $help;
                $res .= "\n" if $help =~ /\n/ or length($help) > 40 ;
                $res .= $help  . "\n" if $help;
                if ( $type eq 'leaf' and $elt->value_type eq 'enum' ) {
                    $res .= "  possible values: " . join( ', ', $elt->get_choice ) . "\n";
                }
            }
        }
    }
    else {
        $res = $obj->get_help_as_text();
    }
    return $res;
};

my $ll_sub = sub {
    my $self = shift;
    my @raw_args = @_;

    my @desc_opt = qw/check no/;

    my %opt = map { /^-(\w+)/; $1 => 1 } grep { /^-/ } @raw_args;
    push @desc_opt, hide_empty => 1 if $opt{nz} ;
    push @desc_opt, verbose    => 1 if $opt{v} ;

    my @args = grep {! /^-/ } @raw_args;
    push @args, '*' unless @args; # default action is to list all elements

    my $obj = $self->{current_node};
    map {s/\*/.*/g;} @args ;
    my $pattern = join ('|',@args);

    return $obj->describe( pattern => qr/^$pattern$/, @desc_opt );
};

my $cd_sub = sub {
    my $self = shift;
    my @cmds = @_;

    # convert usual cd_ism ( .. /foo) to grab syntax ( - ! foo)
    #map { s(^/)  (! );
    #	  s(\.\.)(-)g;
    #	  s(/)   ( )g;
    #      } @cmds ;

    my $new_node = $self->{current_node}->grab("@cmds");
    my $type     = $new_node->get_type;
    my $name     = $new_node->element_name;

    if ( defined $new_node && $type eq 'node' ) {
        $self->{current_node} = $new_node;
    }
    elsif ( defined $new_node && $type eq 'list' ) {
        print "Can't cd in a $type, please add an index (e.g. $name:0)\n";
    }
    elsif ( defined $new_node && $type eq 'hash' ) {
        print "Can't cd in a $type, please add an index (e.g. $name:foo)\n";
    }
    elsif ( defined $new_node && $type eq 'leaf' ) {
        print "Can't cd in a $type\n";
    }
    else {
        print "Cannot find @_\n";
    }

    return "";
};

my %run_dispatch = (
    help => sub { return $syntax; },
    set  => sub {
        my $self = shift;
        my $cmd  = shift;
        if ($cmd) {
            $cmd =~ s/\s*([=:])\s*/$1/;
            $self->{current_node}->load($cmd);
        }
        else {
            say "No command given.";
        }
        return "";
    },
    display => sub {
        my $self = shift;
        say "Nothing to display" unless @_;
        return $self->{current_node}->grab_value(@_);
    },
    ls => sub {
        my $self = shift;
        my $pattern = shift || '*';
        $pattern =~ s/\*/.*/g;

        my $i    = $self->{current_node}->instance;
        my @res  = grep {/^$pattern$/} $self->{current_node}->get_element_name;
        return join( ' ', @res );
    },
    tree => sub {
        my $self = shift;
        my $i    = $self->{current_node}->instance;
        my @res  = $self->{current_node}->dump_tree( full_dump => 1 );
        return join( ' ', @res );
    },
    delete => sub {
        my $self = shift;
        if ($_[0]) {
            my ( $elt_name, $key ) = split /\s*:\s*/, $_[0];
            my $elt = $self->{current_node}->fetch_element($elt_name);
            if ( length($key) ) {
                $elt->delete($key);
            }
            else {
                $elt->store(undef);
            }
        }
        else {
            say "delete what ?";
        }
        return '';
    },
    clear => sub {
        my ( $self, $elt_name ) = @_;
        if ($elt_name) {
            $self->{current_node}->fetch_element($elt_name)->clear();
        }
        else {
            say "Expected element name for clear command. I.e. one of ",
                join(' ',$self->{current_node}->get_element_name);
        }
        return '';
    },
    check => sub {
        my ( $self, $elt_name ) = @_;
        if ($elt_name) {
            $self->{current_node}->fetch_element($elt_name)->check();
        }
        else {
            $self->{current_node}->check;
        }
        return '';
    },
    fix => sub {
        my ( $self, $elt_name ) = @_;
        if ($elt_name eq '!') {
            $self->{root}->instance->apply_fixes;
        }
        elsif ($elt_name) {
            $self->{current_node}->fetch_element($elt_name)->apply_fixes;
        }
        else {
            $self->{current_node}->apply_fixes;
        }
        return '';
     },
    save => sub {
        my ($self) = @_;
        $self->{root}->instance->write_back();
        return "done";
    },
    changes => sub {
        my ( $self ) = @_;
        return $self->{root}->instance->list_changes;
    },
    ll          => $ll_sub,
    cd          => $cd_sub,
    description => $desc_sub,
    desc        => $desc_sub,
);

$run_dispatch{reset} = $run_dispatch{clear};
$run_dispatch{dump}  = $run_dispatch{tree};

sub simple_ui_commands {
    return sort keys %run_dispatch;
}

sub new {
    my $type = shift;
    my %args = @_;

    my $self = {};

    foreach my $p (qw/root title prompt/) {
        $self->{$p} = delete $args{$p}
            or croak "SimpleUI->new: Missing $p parameter";
    }

    $self->{current_node} = $self->{root};

    bless $self, $type;
}

sub run_loop {
    my $self = shift;

    my $user_cmd;
    print $self->prompt;
    while ( defined( $user_cmd = <STDIN> ) ) {
        chomp $user_cmd;
        last if $user_cmd eq 'exit' or $user_cmd eq 'quit';
        my $res = $self->run($user_cmd);
        print $res, "\n" if defined $res;
        print $self->prompt;
    }
    print "\n";

    my $instance = $self->{root}->instance;
    if ( $instance->c_count ) {
        my @changes = $instance->say_changes;
        if (@changes) {
            print "write back data before exit ? (Y/n)";
            $user_cmd = <STDIN>;
            $instance->write_back unless $user_cmd =~ /n/i;
            print "\n";
        }
    }

}

sub prompt {
    my $self = shift;
    my $ret  = $self->{prompt} . ':';
    my $loc  = $self->{current_node}->location_short;
    $ret .= " $loc " if $loc;
    return $ret . '$ ';
}

sub run {
    my ( $self, $user_cmd ) = @_;

    return '' unless $user_cmd =~ /\w/;

    my $re = $RE{delimited}{-delim=>q{'"}};
    my ( $action, @args ) = ( $user_cmd =~ /((?:[^\s"']|$re)+)/g );

    if ( defined $run_dispatch{$action} ) {
        my $res = eval { $run_dispatch{$action}->( $self, @args ); };
        print $@ if $@;
        return $res;
    }
    else {
        return "Unexpected command '$action'";
    }
}

sub list_cd_path {
    my $self   = shift;
    my $c_node = $self->{current_node};

    my @result;
    foreach my $elt_name ( $c_node->get_element_name ) {
        my $t = $c_node->element_type($elt_name);

        if ( $t eq 'list' or $t eq 'hash' ) {
            push @result,
                map { "$elt_name:$_" } $c_node->fetch_element($elt_name)->fetch_all_indexes;
        }
        else {
            push @result, $elt_name;
        }
    }

    return \@result;
}
1;

#ABSTRACT: Simple interface for Config::Model

=head1 SYNOPSIS

 use Config::Model;
 use Config::Model::SimpleUI ;

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

 my $ui = Config::Model::SimpleUI->new(
    root => $root ,
    title => 'My class ui',
    prompt => 'class ui',
 );

 # engage in user interaction
 $ui -> run_loop ;

 print $root->dump_tree ;

Once the synopsis above has been saved in C<my_test.pl>, you can do:

 $ perl my_test.pl
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

 class ui: hash_of_nodes:en $  ll
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

This module provides a pure ASCII user interface using STDIN and
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

=item clear elt

Clear leaf value (set to C<undef>) or removed all elements of hash or list.

=item delete elt

Delete leaf value.

=item delete elt:key

Delete a list or hash element

=item display node_name elt:key

Display a value

=item ls [ pattern ]

Show elements of current node. Can be used with a shell pattern.

=item ll [-nz] [-v] [ pattern ... ]

Describe elements of current node. Can be used with shell patterns or element names.
Skip empty element with C<-nz> option. Display more information with C<-v> option

=item tree

Show configuration tree from current node.

=item help

Show available commands.

=item desc[ription]

Show class description of current node.

=item desc(elt)

Show description of element from current node.

=item desc(value)

Show effect of value (for enum)

=item changes

Show unsaved changes

=item check

Without parameter, show warnings starting from current node. With an
element name as parameter, do the same on the element.

=item fix

Try to fix warning starting from current node. With an element name as parameter,
do the same on the element. With "C<!>" as parameter, try to fix warnings starting
from root node by calling L<apply_fixes|Config::Model::Instance/apply_fixes> there.

=item exit

Exit shell

=back

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

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,
L<Config::Model::Instance>,
L<Config::Model::Node>,

=cut
