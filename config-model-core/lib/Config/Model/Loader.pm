# $Author$
# $Date$
# $Revision$

#    Copyright (c) 2006-2008,2010 Dominique Dumont.
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

package Config::Model::Loader;
use Carp;
use strict;
use warnings ;

use Config::Model::Exception ;
use Log::Log4perl qw(get_logger :levels);

use vars qw($VERSION);
$VERSION = sprintf "1.%04d", q$Revision$ =~ /(\d+)/;

my $logger = get_logger("Loader") ;

=head1 NAME

Config::Model::Loader - Load serialized data into config tree

=head1 SYNOPSIS

 use Config::Model ;

 # create your config model
 my $model = Config::Model -> new ;
 $model->create_config_class( ... ) ;

 # create instance
 my $inst = $model->instance (root_class_name => 'FooBar', 
			      instance_name => 'test1');

 # create root of config
 my $root = $inst -> config_root ;

 # put some data in config tree
 my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata"';
 $root->load( step => $step ) ;

=head1 DESCRIPTION

This module is used directly by L<Config::Model::Node> to load
serialized configuration data into the configuration tree.

Serialized data can be written by the user or produced by
L<Config::Model::Dumper> while dumping data from a configuration tree.

=head1 CONSTRUCTOR

=head2 new ( )

No parameter. The constructor should be used only by
L<Config::Model::Node>.

=cut

## load stuff, similar to grab, but used to set items in the tree
## staring from this node

sub new {
    bless {}, shift ;
}

=head1 load string syntax

The string is made of the following items separated by spaces:

=over 8

=item -

Go up one node

=item !

Go to the root node of the configuration tree.

=item xxx

Go down using C<xxx> element. (For C<node> type element)

=item xxx:yy

Go down using C<xxx> element and id C<yy> (For C<hash> or C<list>
element with C<node> cargo_type)

=item xxx=~/yy/

Go down using C<xxx> element and loop over the ids that match the regex.
(For C<hash>)

For instance, with OpenSsh model, you could do 

 Host=~/.*.debian.org/ user='foo-guest'

to set "foo-user" users for all your debian accounts.

=item xxx~yy

Delete item referenced by C<xxx> element and id C<yy>. For a list,
this is equivalent to C<splice xxx,yy,1>. This command does not go
down in the tree (since it has just deleted the element). I.e. a
'C<->' is generally not needed afterwards.

=item xxx=zz

Set element C<xxx> to value C<yy>. load also accepts to set elements
with a quoted string. (For C<leaf> element)

For instance C<foo="a quoted string">. Note that you cannot embed
double quote in this string. I.e C<foo="a \"quoted\" string"> will
fail.

C<foo=''> will set foo to C<undef>.

=item xxx=z1,z2,z3

Set list element C<xxx> to list C<z1,z2,z3>. Use C<,,> for undef
values, and C<""> for empty values.

I.e, for a list C<('a',undef,'','c')>, use C<a,,"",c>.

=item xxx:yy=zz

For C<hash> element containing C<leaf> cargo_type. Set the leaf
identified by key C<yy> to value C<zz>.

Using C<xxx=~/yy/=zz> is also possible.

=item xxx.=zzz

Will append C<zzz> value to current values (valid for C<leaf> elements).

=back

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

=item experience

Specify the experience level used during the load (default:
C<master>). The experience can be C<intermediate advanced master>.
The load will raise an exception if the step of the load string tries
to access an element with experience higher than user's experience.

=back

=cut

sub load {
    my $self = shift ;

    my %args = @_ ;

    my $node = delete $args{node} ;

    croak "load error: missing 'node' parameter" unless defined $node ;

    my $step = delete $args{step} ;
    croak "load error: missing 'step' parameter" unless defined $step ;

    my $experience = delete $args{experience} || 'master' ;
    my $inst = $node->instance ;

    # tune value checking
    my $tune_check 
      = defined $args{check_store} 
	and $args{check_store} == 0 ? 1 : 0 ;
    $inst->push_no_value_check('store') if $tune_check ;

    # accept commands
    my $huge_string = ref $step ? join( ' ', @$step) : $step ;

    # do a split on ' ' but take quoted string into account
    my @command = 
      ( 
       $huge_string =~ 
       m/
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
        /gx       # 'g' means that all commands are fed into @command array
       ) ; #"asdf ;

    #print "command is ",join('+',@command),"\n" ;

    my $ret = $self->_load($node, $experience, \@command,1) ;

    if (@command) {
        my $str = "Error: command '@command' was not executed, you may have".
          " specified too many '-' in your command (ret is $ret)\n" ;
        Config::Model::Exception::Load
	    -> throw (
		      error => $str,
		      object => $node
		     ) if $node->instance->get_value_check('store') ;
    }

    # restore default value checks
    $inst->pop_no_value_check  if $tune_check ;

    return $ret ;
}

# returns elt action id subaction value
sub _split_cmd {
    my $cmd = shift ;

        # do a split on ' ' but take quoted string into account
    my @command = 
      ( 
       $cmd =~ 
       m!
	 (\w+)          # element name can be alone
	 (?:
            (:|=~|~)       # action
            ( /[^/]+/      # regexp
	      |            # or
	       "           # quote
               (?: \\" | [^"] )* # escaped quote or non quote
               "           # quote
              |
	       [^"=\.~]+    # non action chars
            )
         )?
	 (?:
            (=|.=)         # assign or append
	    ( 
              (?:
                " (?: \\" | [^"] )* "  # quoted string
                | [^\s]                # or non whitespace
              )+                       # many
            )
	 )?
         !gx
       ) ; 
    unquote (@command) ;

    return wantarray ? @command : \@command ;
}

my %load_dispatch = (
		     node        => \&_walk_node,
		     warped_node => \&_walk_node,
		     hash        => \&_load_hash,
		     check_list  => \&_load_list,
		     list        => \&_load_list,
		     leaf        => \&_load_leaf,
		    ) ;

# return 'done', 'root', 'up', 'error'
sub _load {
    my ($self, $node, $experience, $cmdref,$is_root) = @_ ;
    $is_root ||= 0;
    my $node_name = "'".$node->name."'" ;
    $logger->debug("_load: called on node $node_name");

    my $inst = $node->instance ;

    my $cmd ;
    while ($cmd = shift @$cmdref) {
	if ($logger->is_debug) {
	    my $msg = $cmd ;
	    $msg =~ s/\n/\\n/g;
	    $logger->debug("_load: Executing cmd '$msg' on node $node_name");
	}

        next if $cmd =~ /^\s*$/ ;

        if ($cmd eq '!') {
	    next if $is_root ;
	    return 'root' ;
	}

	if ($cmd eq '-') {
	    return 'up';
	}

	my @instructions = _split_cmd($cmd);
	my $element_name = $instructions[0] ;

        unless (defined $element_name) {
	    Config::Model::Exception::Load
		-> throw (
			  command => $cmd ,
			  error => 'Syntax error: cannot find '
			  .'element in command'
			 );
	}

        unless (defined $node) {
	    Config::Model::Exception::Load
		-> throw (
			  command => $cmd ,
			  error => "Error: Got undefined node"
			 );
	}

        unless (   $node->isa("Config::Model::Node") 
		or $node->isa("Config::Model::WarpedNode")) {
	    Config::Model::Exception::Load
		-> throw (
			  command => $cmd ,
			  error => "Error: Expected a node (even a warped node), got '"
			  .$node -> name. "'"
			 );
	    # below, has_element method from WarpedNode will raise
	    # exception if warped_node is not available
	}

        unless ($node->has_element($element_name)) {
            Config::Model::Exception::UnknownElement
		-> throw (
			  object => $node,
			  element => $element_name,
			 ) if $inst->get_value_check('store');
            unshift @$cmdref,$cmd ;
            return 'error' ;
	}

        unless ($node->is_element_available(name => $element_name,
					    experience => 'master')) {
	    Config::Model::Exception::UnavailableElement
		-> throw (
			  object => $node,
			  element => $element_name
			 ) if $inst->get_value_check('fetch_or_store') ;
            unshift @$cmdref,$cmd ;
            return 'error';
	}

        unless ($node->is_element_available(name => $element_name, 
					    experience => $experience)) {
            Config::Model::Exception::RestrictedElement
		-> throw (
			  object => $node,
			  element => $element_name,
			  level => $experience,
			 ) if $inst->get_value_check('fetch_or_store');
            unshift @$cmdref,$cmd ;
            return 'error' ;
	}

	my $element_type = $node -> element_type($element_name) ;

	my $method = $load_dispatch{$element_type} ;

	croak "_load: unexpected element type '$element_type' for $element_name"
	  unless defined $method ;

	my $ret = $self->$method($node,$experience,
				 \@instructions,$cmdref) ;

	if ($ret eq 'error' or $ret eq 'done') { return $ret; }
	return 'root' if $ret eq 'root' and not $is_root ;
	# ret eq up or ok -> go on with the loop 
    }

    return 'done' ;
}


sub _walk_node {
    my ($self,$node,$experience,$inst,$cmdref) = @_ ;

    my $element_name = shift @$inst ;
    my $element = $node -> fetch_element($element_name) ;

    my @left = grep {defined $_} @$inst ;
    if (@left) {
	Config::Model::Exception::Load
	    -> throw (
		      command => $inst,
		      error => "Don't know what to do with '@left' ".
		      "for node element" . $element -> element_name
		     ) ;
    }

    $logger->info("Opening node element ", $element->name);

    return $self->_load($element, $experience, $cmdref);
}

sub unquote {
    map { s/^"// && s/"$// && s/\\"/"/g if defined $_;  } @_ ;
}

# used for list and check lists
sub _load_list {
    my ($self,$node,$experience,$inst,$cmdref) = @_ ;
    my ($element_name,$action,$id,$subaction,$value) = @$inst ;

    my $element = $node -> fetch_element($element_name) ;

    my $elt_type   = $node -> element_type( $element_name ) ;
    my $cargo_type = $element->cargo_type ;

    if (not defined $action and $subaction eq '=' 
	and $cargo_type eq 'leaf'
       ) {
	# valid for check_list or list
	$logger->info("Setting $elt_type element ",$element->name,
		      " with '$value'");
	$element->load( $value ) ;
	return 'ok';
    }

    if ($elt_type eq 'list' and $action eq '~') {
	# remove possible leading or trailing quote
	unquote ($id) ;
	$element->remove($id) ;
	return 'ok' ;
    }

    if ($elt_type eq 'list' and $action eq ':' and $cargo_type =~ /node/) {
	# remove possible leading or trailing quote
	unquote ($id) ;
	my $newnode = $element->fetch_with_id($id) ;
	return $self->_load($newnode, $experience, $cmdref);
    }

    if ($elt_type eq 'list' and $action eq ':' and $cargo_type =~ /leaf/) {
	unquote($value) ;
	$self->_load_value($element->fetch_with_id($id),$subaction,$value) 
	  and return 'ok';
    }


    Config::Model::Exception::Load
	-> throw (
		  object => $element,
		  command => join('',@$inst) ,
		  error => "Wrong assignment with '$action' on "
		  ."element type: $elt_type, cargo_type: $cargo_type"
		 ) ;

}

sub _load_hash {
    my ($self,$node,$experience,$inst,$cmdref) = @_ ;
    my ($element_name,$action,$id,$subaction,$value) = @$inst ;

    my $element = $node -> fetch_element($element_name) ;
    my $cargo_type = $element->cargo_type ;

    if ($action eq '=~') {
	my @keys = $element->get_all_indexes;
	my $ret ;
	$logger->debug("_load_hash: looping with regex $id");
	$id =~ s!^/!!; 
	$id =~ s!/$!! ;
	my @saved_cmd = @$cmdref ;
	foreach my $loop_id (grep /$id/,@keys) {
	    @$cmdref = @saved_cmd ; # restore command before loop
	    $logger->debug("_load_hash: loop on id $loop_id");
	    my $sub_elt =  $element->fetch_with_id($loop_id) ;
	    if ($cargo_type =~ /node/) {
		# remove possible leading or trailing quote
		$ret = $self->_load($sub_elt, $experience, $cmdref);
	    }
	    elsif ($cargo_type =~ /leaf/) {
		$ret = $self->_load_value($sub_elt,$subaction,$value) ;
	    }
	    else {
		Config::Model::Exception::Load
		    -> throw (
			      object => $element,
			      command => join('',@$inst) ,
			      error => "Hash assignment with '$action' on unexpected "
			      ."cargo_type: $cargo_type"
			     ) ;
	    }

	    if ($ret eq 'error' or $ret eq 'done') { return $ret; }
	}
	return $ret ;
    }


    if ($action eq '~') {
	# remove possible leading or trailing quote
	unquote ($id) ;
	$element->delete($id) ;
	return 'ok' ;
    }

    if ($action eq ':' and $cargo_type =~ /node/) {
	# remove possible leading or trailing quote
	unquote ($id) ;
	my $newnode = $element->fetch_with_id($id) ;
	return $self->_load($newnode, $experience, $cmdref);
    }
    elsif ($action eq ':' and $cargo_type =~ /leaf/) {
	unquote($id,$value) ;
	$self->_load_value($element->fetch_with_id($id),$subaction,$value) 
	  and return 'ok';
    }
    else {
	Config::Model::Exception::Load
	    -> throw (
		      object => $element,
                      command => join('',@$inst) ,
		      error => "Hash assignment with '$action' on unexpected "
		      ."cargo_type: $cargo_type"
		     ) ;
    }
}

sub _load_leaf {
    my ($self,$node,$experience,$inst,$cmdref) = @_ ;
    my ($element_name,$action,$id,$subaction,$value) = @$inst ;

    my $element = $node -> fetch_element($element_name) ;
    unquote($value) ;

    if ($logger->is_debug) {
	my $msg = $value ;
	$msg =~ s/\n/\\n/g;
	$logger->debug("_load_leaf: action '$subaction' value '$msg'");
    }

    return $self->_load_value($element,$subaction,$value)
      or Config::Model::Exception::Load
	-> throw (
		  object => $element,
		  command => $inst ,
		  error => "Load error on leaf with "
		  ."'$element_name$subaction$value' command "
		  ."(element '".$element->name."')"
		 ) ;
}

sub _load_value {
    my ($self,$element,$action,$value) = @_ ;

    if ($action eq '=' and $element->isa('Config::Model::Value')) {
	$element->store($value) ;
    }
    elsif ($action eq '.=' and $element->isa('Config::Model::Value')) {
	my $orig = $element->fetch() ;
	$element->store($orig.$value) ;
    }
    else {
	return undef ;
    }

    return 'ok' ;
}


1;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,L<Config::Model::Node>,L<Config::Model::Dumper>

=cut
