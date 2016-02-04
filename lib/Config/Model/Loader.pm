package Config::Model::Loader;

use Carp;
use strict;
use warnings;
use 5.10.1;

use Config::Model::Exception;
use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger("Loader");

## load stuff, similar to grab, but used to set items in the tree
## starting from this node

sub new {
    bless {}, shift;
}

sub load {
    my $self = shift;

    my %args = @_;

    my $node = delete $args{node};

    croak "load error: missing 'node' parameter" unless defined $node;

    my $step = delete $args{step};
    croak "load error: missing 'step' parameter" unless defined $step;

    if (delete $args{experience}) {
        carp "load: experience parameter is deprecated";
    }

    my $inst = $node->instance;

    # tune value checking
    my $check = delete $args{check} || 'yes';
    croak __PACKAGE__, "load: unexpected check $check" unless $check =~ /yes|no|skip/;

    # accept commands
    my $huge_string = ref $step ? join( ' ', @$step ) : $step;

    # do a split on ' ' but take quoted string into account
    my @command = (
        $huge_string =~ m/
         (         # begin of *one* command
          (?:        # group parts of a command (e.g ...:...=... )
           [^\s"]+  # match anything but a space and a quote
           (?:        # begin quoted group
             "         # begin of a string
              (?:        # begin group
                \\"       # match an escaped quote
                |         # or
                [^"]      # anything but a quote
              )*         # lots of time
             "         # end of the string
           )          # end of quoted group
           ?          # match if I got more than one group
          )+      # can have several parts in one command
         )        # end of *one* command
        /gx    # 'g' means that all commands are fed into @command array
    );         #"asdf ;

    #print "command is ",join('+',@command),"\n" ;

    my $current_node = $node;
    my $ret;
    do {
        $ret = $self->_load( $current_node, $check, \@command, 1 );
        $logger->debug("_load returned $ret");

        # found '!' command
        if ( $ret eq 'root' ) {
            $logger->debug("Setting current_node to root node");
            $current_node = $current_node->root;
        }
    } while ( $ret eq 'root' );

    if (@command) {
        my $str = "Error: could not execute the required command, ";
        if ($command[0] =~ m!^/([\w-]+)!) {
            $str .=  "the searched item '$1' was not found" ;
        }
        else {
            $str .= "you may have specified too many '-' in your command";
        }
        Config::Model::Exception::Load->throw(
            command => $command[0],
            error  => $str,
            object => $node
        ) if $check eq 'yes';
    }

    if (%args) {
        Config::Model::Exception::Internal->throw(
            error => __PACKAGE__ . " load: unexpected parameters: " . join( ', ', keys %args ) );
    }

    return $ret;
}

# returns elt action id subaction value
sub _split_cmd {
    my $cmd = shift;

    my $quoted_string = qr/"(?: \\" | [^"] )* "/x;    # quoted string

    # do a split on ' ' but take quoted string into account
    my @command = (
        $cmd =~ m!^
	 (\w[\w-]*)? # element name can be alone
	 (?:
            (:~|:-[=~]?|:=~|:\.\w+|:[=<>@]?|~)       # action
            (?:
                  (?: \( ( $quoted_string | [^)]+ ) \) )  # capture parameters between braces
                | (
                    /[^/]+/      # regexp
                    | (?:
                       $quoted_string
                       | [^#=\.<>]+    # non action chars
                      )+
                  )
            )?
         )?
	 (?:
            (=~|.=|[=<>])          # apply regexp or assign or append
	    (
              (?:
                $quoted_string
                | [^#\s]                # or non whitespace
              )+                       # many
            )
	 )?
	 (?:
            \#              # optional annotation
	    (
              (?:
                 $quoted_string
                | [^\s]                # or non whitespace
              )+                       # many
            )
	 )?
         !gx
    );

    return wantarray ? @command : \@command;
}

my %load_dispatch = (
    node        => \&_walk_node,
    warped_node => \&_walk_node,
    hash        => \&_load_hash,
    check_list  => \&_load_check_list,
    list        => \&_load_list,
    leaf        => \&_load_leaf,
);

# return 'done', 'root', 'up', 'error'
sub _load {
    my ( $self, $node, $check, $cmdref, $at_top_level ) = @_;
    $at_top_level ||= 0;
    my $node_name = "'" . $node->name . "'";
    $logger->debug("_load: called on node $node_name");

    my $inst = $node->instance;

    my $cmd;
    while ( $cmd = shift @$cmdref ) {
        if ( $logger->is_debug ) {
            my $msg = $cmd;
            $msg =~ s/\n/\\n/g;
            $logger->debug("_load: Executing cmd '$msg' on node $node_name");
        }

        next if $cmd =~ /^\s*$/;

        if ( $cmd eq '!' ) {
            $logger->debug("_load: going to root, at_top_level is $at_top_level");

            # Do not change current node as we don't want to mess up =~ commands
            return 'root';
        }

        if ( $cmd eq '-' ) {
            $logger->debug("_load: going up");
            return 'up';
        }

        if ( $cmd =~ m!^/([\w-]+)! ) {
            my $search = $1;
            if ($node->has_element($search)) {
                $logger->debug("_load: search found node with element $search");
                $cmd =~ s!^/!! ;
            } else {
                $logger->debug("_load: searching node with element $search, going up");
                unshift @$cmdref, $cmd;
                return 'up';
            }
        }

        my @instructions = _split_cmd($cmd);
        my ( $element_name, $action, $function_param, $id, $subaction, $value, $note ) =
            @instructions;

        if ( $logger->is_debug ) {
            my @disp = map { defined $_ ? "'$_'" : '<undef>' } @instructions;
            $logger->debug("_load instructions: @disp");
        }

        if ( not defined $element_name and not defined $note ) {
            Config::Model::Exception::Load->throw(
                command => $cmd,
                error   => 'Syntax error: cannot find ' . 'element in command'
            );
        }

        unless ( defined $node ) {
            Config::Model::Exception::Load->throw(
                command => $cmd,
                error   => "Error: Got undefined node"
            );
        }

        unless ( $node->isa("Config::Model::Node")
            or $node->isa("Config::Model::WarpedNode") ) {
            Config::Model::Exception::Load->throw(
                command => $cmd,
                error   => "Error: Expected a node (even a warped node), got '" . $node->name . "'"
            );

            # below, has_element method from WarpedNode will raise
            # exception if warped_node is not available
        }

        if ( not defined $element_name and defined $note ) {
            $node->annotation($note);
            next;
        }

        unless ( $node->has_element($element_name) ) {
            Config::Model::Exception::UnknownElement->throw(
                object  => $node,
                element => $element_name,
            ) if $check eq 'yes';
            unshift @$cmdref, $cmd;
            return 'error';
        }

        unless ( $node->is_element_available( name => $element_name ) ) {
            Config::Model::Exception::UnavailableElement->throw(
                object  => $node,
                element => $element_name
            ) if $check eq 'yes';
            unshift @$cmdref, $cmd;
            return 'error';
        }

        unless ( $node->is_element_available( name => $element_name ) ) {
            Config::Model::Exception::RestrictedElement->throw(
                object  => $node,
                element => $element_name,
            ) if $check eq 'yes';
            unshift @$cmdref, $cmd;
            return 'error';
        }

        my $element_type = $node->element_type($element_name);

        my $method = $load_dispatch{$element_type};

        croak "_load: unexpected element type '$element_type' for $element_name"
            unless defined $method;

        $logger->debug("_load: calling $element_type loader on element $element_name");
        my $ret = $self->$method( $node, $check, \@instructions, $cmdref );
        die "Internal error: method dispatched for $element_type returned an undefined value "
            unless defined $ret;

        if ( $ret eq 'error' or $ret eq 'done' ) {
            $logger->debug("_load return: $node_name got $ret");
            return $ret;
        }
        if ( $ret eq 'root' and not $at_top_level ) {
            $logger->debug("_load return: $node_name got $ret");
            return 'root';
        }

        # ret eq up or ok -> go on with the loop
    }

    return 'done';
}

sub _load_note {
    my ( $self, $target_obj, $note, $instructions, $cmdref ) = @_;

    unquote($note);

    # apply note on target object
    if ( defined $note ) {
        if ( defined $target_obj ) {
            $target_obj->annotation($note);
        }
        else {
            Config::Model::Exception::Load->throw(
                command => $$cmdref,
                error   => "Error: cannot set annotation with '"
                    . join( "','", grep { defined $_ } @$instructions ) . "'"
            );
        }
    }
}

sub _walk_node {
    my ( $self, $node, $check, $inst, $cmdref ) = @_;

    my $element_name = shift @$inst;
    my $note         = pop @$inst;
    my $element      = $node->fetch_element($element_name);
    $self->_load_note( $element, $note, $inst, $cmdref );

    my @left = grep { defined $_ } @$inst;
    if (@left) {
        Config::Model::Exception::Load->throw(
            command => $inst,
            error   => "Don't know what to do with '@left' "
                . "for node element "
                . $element->element_name
        );
    }

    $logger->info( "Opening node element ", $element->name );

    return $self->_load( $element, $check, $cmdref );
}

sub unquote {
    map {
        if (defined $_) {
            s/\\n/\n/g;
            s/^"// && s/"$// && s!\\"!"!g;
        }
    } @_;
}

sub _load_check_list {
    my ( $self, $node, $check, $inst, $cmdref ) = @_;
    my ( $element_name, $action, $f_arg, $id, $subaction, $value, $note ) = @$inst;

    my $element = $node->fetch_element( name => $element_name, check => $check );

    if ( defined $note and not defined $action and not defined $subaction ) {
        $self->_load_note( $element, $note, $inst, $cmdref );
        return 'ok';
    }

    if ( defined $subaction and $subaction eq '=' ) {
        $logger->debug("_load_check_list: set whole list");

        # valid for check_list or list
        $logger->info( "Setting check_list element ", $element->name, " with value ", $value );
        $element->load( $value, check => $check );
        $self->_load_note( $element, $note, $inst, $cmdref );
        return 'ok';
    }

    if ( not defined $action and defined $subaction ) {
        Config::Model::Exception::Load->throw(
            object  => $element,
            command => join( '', grep ( defined $_, @$inst ) ),
            error   => "Wrong assignment with '$subaction' on check_list"
        );
    }

    my $a_str = defined $action ? $action : '<undef>';

    Config::Model::Exception::Load->throw(
        object  => $element,
        command => join( '', map { $_ || '' } @$inst ),
        error   => "Wrong assignment with '$a_str' on check_list"
    );

}

# sub is called with  ( $self, $element, $check, $instance, @function_args )
# function_args are the arguments passed to the load command
my %dispatch_action = (
    list_leaf => {
        ':.sort'          => sub { $_[1]->sort; },
        ':.push'          => sub { $_[1]->push( @_[ 4 .. $#_ ] ); },
        ':.unshift'       => sub { $_[1]->unshift( @_[ 4 .. $#_ ] ); },
        ':.insert_at'     => sub { $_[1]->insert_at( @_[ 4 .. $#_ ] ); },
        ':.insort'        => sub { $_[1]->insort( @_[ 4 .. $#_ ] ); },
        ':.insert_before' => \&_insert_before,
    },
    'hash_*' => {
        ':.sort'          => sub { $_[1]->sort; },
        ':@'              => sub { $_[1]->sort; },
        ':.copy'          => sub { $_[1]->copy( $_[4], $_[5] ); },
    },
    leaf => {
        ':-=' => \&_remove_by_value,
        ':-~' => \&_remove_matched_value,
        ':=~' => \&_substitute_value,
    },
    fallback => {
        ':-' => \&_remove_by_id,
        '~'  => \&_remove_by_id,
    } );

my @equiv = qw/:@ :.sort :< :.push :> :.unshift/;
while (@equiv) {
    my ( $to, $from ) = splice @equiv, 0, 2;
    $dispatch_action{list_leaf}{$to} = $dispatch_action{list_leaf}{$from};
}

sub _insert_before {
    my ( $self, $element, $check, $inst, $before_str, @values ) = @_;
    my $before = $before_str =~ m!^/! ? eval "qr$before_str" : $before_str;
    $element->insert_before( $before, @values );
}

sub _remove_by_id {
    my ( $self, $element, $check, $inst, $id ) = @_;
    $logger->debug("_remove_by_id: removing id $id");
    $element->remove($id);
    return 'ok';
}

sub _remove_by_value {
    my ( $self, $element, $check, $inst, $rm_val ) = @_;

    $logger->debug("_remove_by_value value $rm_val");
    foreach my $idx ( $element->fetch_all_indexes ) {
        my $v = $element->fetch_with_id($idx)->fetch;
        $element->delete($idx) if defined $v and $v eq $rm_val;
    }

    return 'ok';
}

sub _remove_matched_value {
    my ( $self, $element, $check, $inst, $rm_val ) = @_;

    $logger->debug("_remove_matched_value $rm_val");

    $rm_val =~ s!^/|/$!!g;

    foreach my $idx ( $element->fetch_all_indexes ) {
        my $v = $element->fetch_with_id($idx)->fetch;
        $element->delete($idx) if defined $v and $v =~ /$rm_val/;
    }

    return 'ok';
}

sub _substitute_value {
    my ( $self, $element, $check, $inst, $s_val ) = @_;

    $logger->debug("_substitute_value $s_val");

    foreach my $idx ( $element->fetch_all_indexes ) {
        my $l = $element->fetch_with_id($idx);
        $self->_load_value( $l, $check, '=~', $s_val, $inst );
    }

    return 'ok';
}

sub _load_list {
    my ( $self, $node, $check, $inst, $cmdref ) = @_;
    my ( $element_name, $action, $f_arg, $id, $subaction, $value, $note ) = @$inst;

    my $element = $node->fetch_element( name => $element_name, check => $check );

    my @f_args = grep { defined } ( ( $f_arg // $id // '' ) =~ /([^,"]+)|"([^"]+)"/g );

    my $elt_type   = $node->element_type($element_name);
    my $cargo_type = $element->cargo_type;

    if ( defined $note and not defined $action and not defined $subaction ) {
        $self->_load_note( $element, $note, $inst, $cmdref );
        return 'ok';
    }

    if ( defined $action and $action eq ':=' and $cargo_type eq 'leaf' ) {
        $logger->debug("_load_list: set whole list with ':=' action");

        # valid for check_list or list
        $logger->info( "Setting $elt_type element ", $element->name, " with '$id'" );
        $element->load( $id, check => $check );
        $self->_load_note( $element, $note, $inst, $cmdref );
        return 'ok';
    }

    # compat mode for list=a,b,c,d commands
    if (    not defined $action
        and defined $subaction
        and $subaction eq '='
        and $cargo_type eq 'leaf' ) {
        $logger->debug("_load_list: set whole list with '=' subaction'");

        # valid for check_list or list
        $logger->info( "Setting $elt_type element ", $element->name, " with '$value'" );
        $element->load( $value, check => $check );
        $self->_load_note( $element, $note, $inst, $cmdref );
        return 'ok';
    }

    unquote( $id, $value, $note );

    if ( defined $action ) {
        my $dispatch =
               $dispatch_action{ 'list_' . $cargo_type }{$action}
            || $dispatch_action{ 'list_*'}{$action}
            || $dispatch_action{$cargo_type}{$action}
            || $dispatch_action{'fallback'}{$action};
        if ($dispatch) {
            $dispatch->( $self, $element, $check, $inst, @f_args );
            return 'ok';
        }
    }

    if ( not defined $action and defined $subaction ) {
        Config::Model::Exception::Load->throw(
            object  => $element,
            command => join( '', grep ( defined $_, @$inst ) ),
            error   => "Wrong assignment with '$subaction' on "
                . "element type: $elt_type, cargo_type: $cargo_type"
        );
    }

    if ( defined $action and $action eq ':' ) {
        unquote($id);
        my $obj = $element->fetch_with_id( index => $id, check => $check );
        $self->_load_note( $obj, $note, $inst, $cmdref );

        if ( $cargo_type =~ /node/ ) {

            # remove possible leading or trailing quote
            $logger->debug("_load_list: calling _load on node id $id");
            return $self->_load( $obj, $check, $cmdref );
        }

        return 'ok' unless defined $subaction;

        if ( $cargo_type =~ /leaf/ ) {
            $logger->debug("_load_list: calling _load_value on $cargo_type id $id");
            $self->_load_value( $obj, $check, $subaction, $value )
                and return 'ok';
        }
    }

    my $a_str = defined $action ? $action : '<undef>';

    Config::Model::Exception::Load->throw(
        object  => $element,
        command => join( '', map { $_ || '' } @$inst ),
        error   => "Wrong assignment with '$a_str' on "
            . "element type: $elt_type, cargo_type: $cargo_type"
    );

}

sub _load_hash {
    my ( $self, $node, $check, $inst, $cmdref ) = @_;
    my ( $element_name, $action, $f_arg, $id, $subaction, $value, $note ) = @$inst;

    unquote( $id, $value, $note );

    my $element = $node->fetch_element( name => $element_name, check => $check );
    my $cargo_type = $element->cargo_type;

    if ( defined $note and not defined $action ) {
        $self->_load_note( $element, $note, $inst, $cmdref );
        return 'ok';
    }

    if ( not defined $action ) {
        Config::Model::Exception::Load->throw(
            object  => $element,
            command => join( '', map { $_ || '' } @$inst ),
            error   => "Missing assignment on " . "element type: hash, cargo_type: $cargo_type"
        );
    }

    if ( $action eq ':~' ) {
        my @keys = $element->fetch_all_indexes;
        my $ret  = 'ok';
        $logger->debug("_load_hash: looping with regex $id on keys @keys");
        $id =~ s!^/!!;
        $id =~ s!/$!!;
        my @saved_cmd = @$cmdref;
        foreach my $loop_id ( grep /$id/, @keys ) {
            @$cmdref = @saved_cmd;    # restore command before loop
            $logger->debug("_load_hash: loop on id $loop_id");
            my $sub_elt = $element->fetch_with_id($loop_id);
            if ( $cargo_type =~ /node/ ) {

                # remove possible leading or trailing quote
                $ret = $self->_load( $sub_elt, $check, $cmdref );
            }
            elsif ( $cargo_type =~ /leaf/ ) {
                $ret = $self->_load_value( $sub_elt, $check, $subaction, $value );
            }
            else {
                Config::Model::Exception::Load->throw(
                    object  => $element,
                    command => join( '', @$inst ),
                    error   => "Hash assignment with '$action' on unexpected "
                        . "cargo_type: $cargo_type"
                );
            }

            if ( $ret eq 'error' or $ret eq 'root' ) { return $ret; }
        }
        return $ret;
    }

    my @f_args = grep { defined } ( ( $f_arg // $id // '' ) =~ /([^,"]+)|"([^"]+)"/g );

    if ( defined $action ) {
        my $dispatch =
               $dispatch_action{ 'hash_' . $cargo_type }{$action}
            || $dispatch_action{ 'hash_*'}{$action}
            || $dispatch_action{$cargo_type}{$action}
            || $dispatch_action{'fallback'}{$action};
        if ($dispatch) {
            # todo missing arguments
            $dispatch->( $self, $element, $check, $inst, @f_args );
            return 'ok';
        }
    }

    my $obj = $element->fetch_with_id( index => $id, check => $check );
    $self->_load_note( $obj, $note, $inst, $cmdref );

    if ( $action eq ':' and $cargo_type =~ /node/ ) {

        # remove possible leading or trailing quote
        $logger->debug("_load_hash: calling _load on node $id");
        if ( defined $subaction ) {
            Config::Model::Exception::Load->throw(
                object  => $element,
                command => join( '', @$inst ),
                error   => qq!Hash assignment with '$action"$id"$subaction"$value"' on unexpected !
                    . "cargo_type: $cargo_type"
            );
        }
        return $self->_load( $obj, $check, $cmdref );
    }
    elsif ( $action eq ':' and defined $subaction and $cargo_type =~ /leaf/ ) {
        $logger->debug("_load_hash: calling _load_value on leaf $id");
        $self->_load_value( $obj, $check, $subaction, $value )
            and return 'ok';
    }
    elsif ( $action eq ':' and defined $note ) {

        # action was just to store annotation
        return 'ok';
    }
    elsif ($action) {
        Config::Model::Exception::Load->throw(
            object  => $element,
            command => join( '', grep { defined $_ } @$inst ),
            error   => "Hash assignment with '$action' on unexpected " . "cargo_type: $cargo_type"
        );
    }
}

sub _load_leaf {
    my ( $self, $node, $check, $inst, $cmdref ) = @_;
    my ( $element_name, $action, $f_arg, $id, $subaction, $value, $note ) = @$inst;

    unquote( $id, $value );

    my $element = $node->fetch_element( name => $element_name, check => $check );
    $self->_load_note( $element, $note, $inst, $cmdref );

    if ( defined $action and $element->isa('Config::Model::Value')) {
        if ($action eq '~') {
            $logger->debug("_load_leaf: action '$action' deleting value");
            $element->store(undef);
        }
        elsif ($action eq ':') {
            Config::Model::Exception::Load->throw(
                object  => $element,
                command => $inst,
                error   => "Error: list or hash command (':') detected on a leaf."
                . "(element '" . $element->name . "')"
            );
        }
        else {
            Config::Model::Exception::Load->throw(
                object  => $element,
                command => $inst,
                error   => "Load error on leaf with "
                . "'$element_name$action$id' command "
                . "(element '" . $element->name . "')"
            );
        }
    }

    return 'ok' unless defined $subaction;

    if ( $logger->is_debug ) {
        my $msg = defined $value ? $value : '<undef>';
        $msg =~ s/\n/\\n/g;
        $logger->debug("_load_leaf: action '$subaction' value '$msg'");
    }

    my $res = $self->_load_value( $element, $check, $subaction, $value, $inst );

    return $res if $res ;

    Config::Model::Exception::Load->throw(
        object  => $element,
        command => $inst,
        error   => "Load error on leaf with "
            . "'$element_name$subaction$value' command "
            . "(element '"
            . $element->name . "')"
    );
}

sub _load_value {
    my ( $self, $element, $check, $subaction, $value, $inst ) = @_;

    $logger->debug("_load_value: action '$subaction' value '$value' check $check");
    if ( $subaction eq '=' and $element->isa('Config::Model::Value') ) {
        $element->store( value => $value, check => $check );
    }
    elsif ( $subaction eq '.=' and $element->isa('Config::Model::Value') ) {
        my $orig = $element->fetch( check => $check );
        $element->store( value => $orig . $value, check => $check );
    }
    elsif ( $subaction eq '=~' and $element->isa('Config::Model::Value') ) {
        my $orig = $element->fetch( check => $check );
        if ( defined $orig ) {
            eval("\$orig =~ $value;");
            if ($@) {
                Config::Model::Exception::Load->throw(
                    object  => $element,
                    command => $inst,
                    error => "Failed regexp '$value' on " . "element '" . $element->name . "' : $@"
                );
            }
            $element->store( value => $orig, check => $check );
        }
    }
    else {
        return undef;
    }

    return 'ok';
}

1;

# ABSTRACT: Load serialized data into config tree

__END__

=head1 SYNOPSIS

 use Config::Model;
 use Log::Log4perl qw(:easy);
 Log::Log4perl->easy_init($WARN);

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
        [qw/lista listb/] => {
			      type => 'list',
			      cargo =>  {type => 'leaf',
					 value_type => 'string'
					}
			      },
    ],
 ) ;

 my $inst = $model->instance(root_class_name => 'MyClass' );

 my $root = $inst->config_root ;

 # put data
 my $step = 'foo=FOO hash_of_nodes:fr foo=bonjour -
   hash_of_nodes:en foo=hello
   ! lista=foo,bar lista:2=baz
     listb:0=foo listb:1=baz';
 $root->load( step => $step );

 print $root->describe,"\n" ;
 # name         value        type         comment
 # foo          FOO          string
 # bar          [undef]      string
 # hash_of_nodes <Foo>        node hash    keys: "en" "fr"
 # lista        foo,bar,baz  list
 # listb        foo,baz      list


 # delete some data
 $root->load( step => 'lista~2' );

 print $root->describe(element => 'lista'),"\n" ;
 # name         value        type         comment
 # lista        foo,bar      list

 # append some data
 $root->load( step => q!hash_of_nodes:en foo.=" world"! );

 print $root->grab('hash_of_nodes:en')->describe(element => 'foo'),"\n" ;
 # name         value        type         comment
 # foo          "hello world" string

=head1 DESCRIPTION

This module is used directly by L<Config::Model::Node> to load
serialized configuration data into the configuration tree.

Serialized data can be written by the user or produced by
L<Config::Model::Dumper> while dumping data from a configuration tree.

=head1 CONSTRUCTOR

=head2 new ( )

No parameter. The constructor should be used only by
L<Config::Model::Node>.

=head1 load string syntax

The string is made of the following items (also called C<actions>)
separated by spaces. These actions can be divided in 4 groups:

=over

=item *

navigation: moving up and down the configuration tree.

=item *

list and hash operation: select, add or delete hash or list item (also
known as C<id> items)

=item *

leaf operation: select, modify or delecte leaf value

=item *

annotation: modify or delete configuration annotation (aka comment)

=back

=head2 navigation

=over 8

=item -

Go up one node

=item !

Go to the root node of the configuration tree.

=item xxx

Go down using C<xxx> element. (For C<node> type element)

=item /xxx

Go up until the element C<xxx> is found. This search can be combined with one of the
command specified below, e.g C</a_string="foo bar">

=back

=head2 list and hash operation

=over


=item xxx:yy

Go down using C<xxx> element and id C<yy> (For C<hash> or C<list>
element with C<node> cargo_type). Literal C<\n> will be replaced by
real C<\n> (LF in Unix).

=item xxx:~/yy/

Go down using C<xxx> element and loop over the ids that match the regex.
(For C<hash>)

For instance, with C<OpenSsh> model, you could do

 Host:~/.*.debian.org/ user='foo-guest'

to set "foo-user" users for all your debian accounts.

=item xxx:-yy

Delete item referenced by C<xxx> element and id C<yy>. For a list,
this is equivalent to C<splice xxx,yy,1>. This command does not go
down in the tree (since it has just deleted the element). I.e. a
'C<->' is generally not needed afterwards.

=item xxx:-=yy

Remove the element whose value is C<yy>. For list or hash of leaves.
Will not complain if the value to delete is not found.

=item xxx:-~/yy/

Remove the element whose value matches C<yy>. For list or hash of leaves.
Will not complain if no value were deleted.

=item xxx:=~s/yy/zz/

Substitute a value with another. Perl switches can be used(e.g. C<xxx:=~s/yy/zz/gi>)

=item xxx:<yy or xxx:.push(yy)

Push C<yy> value on C<xxx> list

=item xxx:>yy or xxx:.unshift(yy)

Unshift C<yy> value on C<xxx> list

=item xxx:@ or xxx:.sort

Sort the list

=item xxx:.insert_at(yy,zz)

Insert C<zz> value on C<xxx> list before B<index> C<yy>.

=item  xxx:.insert_before(yy,zz)

Insert C<zz> value on C<xxx> list before B<value> C<yy>.

=item xxx:.insert_before(/yy/,zz)

Insert C<zz> value on C<xxx> list before B<value> matching C<yy>.

=item xxx:.insort(zz)

Insert C<zz> value on C<xxx> list so that existing alphanumeric order is preserved.

=item xxx:=z1,z2,z3

Set list element C<xxx> to list C<z1,z2,z3>. Use C<,,> for undef
values, and C<""> for empty values.

I.e, for a list C<('a',undef,'','c')>, use C<a,,"",c>.

=item xxx:yy=zz

For C<hash> element containing C<leaf> cargo_type. Set the leaf
identified by key C<yy> to value C<zz>.

Using C<xxx:~/yy/=zz> is also possible.

=item xxx:.copy(yy,zz)

copy item C<yy> in C<zz>

=back

=head2 leaf operation

=over

=item xxx=zz

Set element C<xxx> to value C<yy>. load also accepts to set elements
with a quoted string. (For C<leaf> element) Literal C<\n> will be replaced by
real C<\n> (LF in Unix).


For instance C<foo="a quoted string"> or C<foo="\"bar\" and \"baz\"">.

=item xxx=~s/foo/bar/

Apply the substitution to the value of xxx. C<s/foo/bar/> is the standard Perl C<s>
substitution pattern.

If your patten needs white spaces, you will need to surround the pattern with quotes:

  xxx=~"s/foo bar/bar baz/"

Perl pattern modifiers are accepted

  xxx=~s/FOO/bar/i

=item xxx~

Undef element C<xxx>

=item xxx.=zzz

Will append C<zzz> value to current values (valid for C<leaf> elements).

=back

=head2 annotation

=over

=item xxx#zzz or xxx:yyy#zzz

Element annotation. Can be quoted or not quoted. Note that annotations are
always placed at the end of an action item.

I.e. C<foo#comment>, C<foo:bar#comment> or C<foo:bar=baz#comment> are valid.
C<foo#comment:bar> is B<not> valid.

=back

=head2 Quotes

You can surround indexes and values with double quotes. E.g.:

  a_string="\"foo\" and \"bar\""

=head1 Examples

You can use L<cme> to modify configuration with C<cme modify> command.

For instance, if L<Config::Model::Ssh> is installed, you can run:

 cme modify ssh 'ControlMaster=auto ControlPath="~/.ssh/master-%r@%n:%p"'

To delete C<Host *> entry:

 cme modify ssh 'Host:-"*"'

To specify 2 C<Host> with a single command:

 cme modify ssh 'Host:"foo* bar*" ForwardX11=yes HostName="foo.com" - Host:baz HostName="baz.com"'

Note the 'C<->' used to go up one node before "C<Host:baz>". In this
case, "up one node" leads to the "root node", so "C<!>" could also be
used instead of "C<->":

 cme modify ssh 'Host:"foo* bar*" ForwardX11=yes HostName="foo.com" ! Host:baz HostName="baz.com"'

Let's modify now the host name of using a C<.org> domain instead of
C<.com>. The C<:~> operator uses a regexp to loop over several Host
entries:

 cme modify ssh 'Host:~/ba[rz]/ HostName=~s/.com$/.org/'

Now that ssh config is mucked up with dummy entries, let's clean up:

 cme modify ssh 'Host:-"baz" Host:-"foo* bar*"'

=head1 Methods

=head2 load ( ... )

Load data into the node tree (from the node passed with C<node>)
and fill values as we go following the instructions passed with
C<step>.  (C<step> can also be an array ref).

Parameters are:

=over

=item node

node ref of the root of the tree (of sub-root) to start the load from.

=item step

A string or an array ref containing the steps to load. See above for a
description of the string.

=item check

Whether to check values while loading. Either C<yes> (default), C<no> or C<skip>.
Loading with C<skip> will discard bad values.

=back

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,L<Config::Model::Node>,L<Config::Model::Dumper>

=cut
