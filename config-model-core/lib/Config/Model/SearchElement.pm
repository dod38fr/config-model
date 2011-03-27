
#    Copyright (c) 2006-2011 Dominique Dumont.
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

package Config::Model::SearchElement;
use Log::Log4perl qw(get_logger :levels);
use Carp;
use strict;
use warnings ;

use Config::Model::Exception ;


my $logger = get_logger("Model::Searcher") ;

=head1 NAME

Config::Model::SearchElement - Search an element in a configuration model

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
    ],
 ) ;

 my $inst = $model->instance(root_class_name => 'MyClass' );

 my $root = $inst->config_root ;

 # put data
 my $step = 'foo=FOO hash_of_nodes:fr foo=bonjour -
   hash_of_nodes:en foo=hello ';
 $root->load( step => $step );

 # create searcher for manual search
 my $searcher = $root->searcher();

 # looking for foo element in the tree
 $searcher -> prepare (element => 'foo') ;
 my @next = $searcher->next_step() ; 

 print "next possible steps: @next\n";
 # next possible steps: foo hash_of_nodes

 # Looking for foo below hash_of_nodes
 $searcher->choose('hash_of_nodes') ;
 @next = $searcher->next_step() ; 

 print "next possible steps: @next\n";
 # next possible steps: en fr

 # Looking for foo below fr
 $searcher->choose('fr') ;
 @next = $searcher->next_step() ; 

 print "next possible steps: @next\n";
 # next possible steps: foo

 # last step
 $searcher->choose('foo') ;
 my $target = $searcher->current_object;

 print "Found '",$target->location,"'\n";
 # Found 'hash_of_nodes:fr foo'

 # automatic search setup
 my $element_call_back = sub { return 'hash_of_nodes' ;} ;
 my $id_call_back      = sub { return 'en' ;} ;

 $searcher->reset ;
 $target = $searcher->auto_choose($element_call_back, $id_call_back) ;
  print "Automatic search found '",$target->location,"'\n";
 # Automatic search found 'hash_of_nodes:en foo'


=head1 DESCRIPTION

This modules provides a way to search for a configuration element in a
configuration tree by exploring the configuration model. 

For instance, suppose that you have a xorg.conf model and you know
that you need to tune the C<MergedXinerama> parameter, but you don't
remember where is this parameter in the configuration tree. This module
will guide you through the tree to the(s) node(s) that contain this
parameter.

This class should be invaluable to construct interactive user interfaces.

This module provides 2 search modes:

=over

=item *

A manual search where you are guided step by step to the element
you're looking for. At each step, the module will return you the
possible paths to choose from. The user will have to choose the
correct path from the available paths. Most of the time, only one
possibility will be returned, so the user choice should be
straightforward. In other case (more that one choice), the user will
have to decide the next step.

=item *

An automatic search where you provide call-back that will resolve the
ambiguities in case of multiple paths.

=back

=head1 CONSTRUCTOR

The constructor should be used only by L<Config::Model::Node>.

=cut

sub new {
    my $type = shift; 
    my %args = @_ ;

    my $self = {} ;
    foreach my $p (qw/model node/) {
	$self->{$p} = delete $args{$p} or
	  croak "Searcher->new: Missing $p parameter" ;
    }

    bless $self, $type ;

    $self->{privilege} = $args{privilege} || 'master' ;

    my $root_class = $self->{node}->config_class_name ;

    $self->{data} = $self->_sniff_class($root_class, $self->{privilege}, {}) ;

    return $self;
}

# to verify the data structure returned by search_element, you can used
# either Data::Dumper or Tk::ObjScanner (both are available on CPAN)

sub _sniff_class {
    my ($self,$class,$privilege, $found_ref) = @_;

    my @lines ;
    my %h ;
    my $model =  $self->{model} ;
    my $c_model = $model->get_model($class) ;

    $logger->debug("sniffing config class $class") ;

    croak "Recursive config class $class detected, aborting..."
      if defined $found_ref -> {$class} ;

    $found_ref -> {$class} = 1 ;

    my @elements = $model->get_element_name(class => $class,
					    for => $privilege
					   ) ;

    foreach my $element (@elements) {
	my $element_model = $c_model->{element}{$element};
	my $element_type  = $element_model->{type};
	my $cargo         = $element_model->{cargo} ;
	my $c_type        = defined $cargo ? $cargo->{type} : '';
	my $cfg_class_name = defined $cargo ? $cargo->{config_class_name}
	                   :                  $element_model->{config_class_name};
	my %local_found = %$found_ref ;

	if (   $element_type =~ /(warped_)?node/ 
	    or $c_type       =~ /(warped_)?node/ 
	   ) {
	    my $tmp 
	      = $element_type eq 'node' || $c_type eq 'node'
		? $self->_sniff_class($cfg_class_name,
				      $privilege, \%local_found) 
		: $self->_sniff_warped_node($element_model,
					    $privilege, \%local_found);

	    # merge all tmp in %h
	    map { $h{$_}{next_step}{$element} = $tmp->{$_} ; } keys %$tmp ;
	}
	else {
	    $h{$element}{next_step}{$element} = '' ;
	}
    }
    $logger->debug("done sniffing config class $class") ;
    return \%h ;
}

sub _sniff_warped_node {
    my ($self,$element_model,$privilege, $found_ref) = @_;

    my %warp_tmp ;
    my $ref = $element_model->{rules} ;
    my @rules = ref $ref eq 'HASH' ? %$ref : @$ref ;

    for (my $r_idx = 0; $r_idx < $#rules; $r_idx += 2) {
	my $res = $rules[$r_idx+1]{config_class_name} ;
	my $sub_class = ref $res ? $res->[0] : $res ;

	# sniff all classes mentionned in warped node rules
	my %local_found = %$found_ref ;
	my $tmp = $self->_sniff_class($sub_class, $privilege, \%local_found);

	# merge all tmp in %warp_tmp
	map { $warp_tmp{$_}{next_class}{$sub_class} = $tmp->{$_} ;} keys %$tmp;
    }

    return \%warp_tmp ;
}

=head1 Methods

=head2 get_searchable_elements

Return the list of elements found in model that can be searched in the
configuration tree.

=cut

sub get_searchable_elements {
    my $self= shift ;
    sort keys %{$self->{data}} ;
}

=head2 prepare(element => ...)

Prepare the searcher to look for the element passed in the argument.
Returns the searcher object (i.e. $self).

=cut

sub prepare {
    my $self =shift ;
    my %args = @_ ;

    foreach my $p (qw/element/) {
	$self->{$p} = delete $args{$p} or
	  croak "Searcher->prepare: Missing $p parameter" ;
    }

    $self->reset ; # initialize the search engine

    unless (defined $self->{search_tree}) {
	my $searched = $self->{element} ;
	my $root_class = $self->{node}->config_class_name ;
	Config::Model::Exception::User
	    -> throw (
		      message   => "Searcher cannot find element '$searched' "
		      . "from $root_class. Found only "
		      . join (' ', sort keys %{$self->{data}})
		     );
    }

    return $self ;
}


=head2 reset

Re-initialize the search engine to redo the search from start

=cut

sub reset {
    my $self = shift ;

    my $searched = $self->{element} ;
    $self->{search_tree}      = $self->{data}{$searched} ;
    $self->{current}{object}    = $self->{node} ;
    $self->{current}{element_name} = 'Root' ;
    $self->{current}{element_type} = 'node' ;
}

=head2 searched

Returns the searched element name.

=cut

sub searched {
    return shift->{element} ;
}


=head1 Manual search

=head2 next_step()

Returns an array (or a ref depending on context) 
containing the next possible step to find the
element you're looking for. The array ref can contain 1 or more
elements.

If the array ref is empty, you can get the target element with 
L</"current_object()">.

=cut

sub next_step {
    my $self = shift ;

    my $current_obj = $self->{current}{object} ;

    my @result ;
    if ($current_obj->get_type =~ /list|hash/) {
	@result = $current_obj -> get_all_indexes ;
    }
    else {
	my $next_step = $self->{search_tree}{next_step} ;

	@result =  ref     $next_step ? sort keys %$next_step 
	        :  defined $next_step ? die "next_step error"
		:                       ()                    ;
    }
	#my $name = $self->{current}{element_name} ;
	#print "From $name, next_step is @result\n";
    return wantarray ? @result : \@result ;
}

=head2 next_choice()

Returns an array ref containing the next non-obvious choice to find
the element you're looking for.

If the array ref is empty, you can get the target element with 
L</"current_object()">.

=cut

sub next_choice {
    my $self = shift ;
    my $result ;

    while (1) {
	$result = $self->next_step ;
	$logger->debug("next_choice: result is @$result") ;
	return $result if  scalar @$result != 1 ;

	$self->choose(@$result) ;
    } 

}

=head2 choose( <chosen_element_name> )

Tell the search engine your choice. The chosen element name must be
one of the possibilities given by L</"next_step()">.

=cut

# TBD if choice is an id, Node is a hash...

sub choose {
    my $self = shift ;
    my $choice = shift ;

    #print "choose $choice from node\n";
    my $obj = $self->{current}{object} ;
    if ($obj->get_type =~ /hash|list/) {
	$self->choose_from_id_element($choice) ;
    }
    else {
	$self->choose_from_node($choice) ;
    }
}

sub choose_from_id_element {
    my $self = shift ;
    my $choice = shift ;

    #print "choose $choice from id\n";
    my $id_obj = $self->{current}{object} ;
    my $class  = $id_obj->config_class_name ;

    # the following line may trigger an exception for warped out
    # elements
    my $next_node = $id_obj->fetch_with_id ($choice); 

    $self->{current}{object}       = $next_node ;
    return $next_node ;
}

sub choose_from_node {
    my $self = shift ;
    my $choice = shift ;

    #print "choose $choice from node\n";
    my $next = $self->{search_tree}{next_step} ;
    my $node = $self->{current}{object} ;
    my $node_class = $node->config_class_name ;

    if (ref($next) and not defined $next->{$choice}) {
	Config::Model::Exception::User
	    -> throw (
		      message   => "Searcher: wrong choice '$choice' "
		      . "from $node_class. expected "
		      . join (' ', sort keys %$next)
		     );
    }

    # the following line may trigger an exception for warped out
    # elements
    my $next_node = $node->fetch_element($choice); 

    # $next is a scalar for leaf element of a ref for node element
    if ($next->{$choice}) {
	my $data = $next->{$choice} ;

	# gobble next_class for warped_node element
	if (defined $data->{next_class}) {
	    my $chosen_class = $next_node->config_class_name ;
	    $data = $data->{next_class}{$chosen_class} ;
	    unless (defined $data) {
		Config::Model::Exception::User
		    -> throw (
			      message   => "Searcher: choice '$choice' "
			      ."from $node_class leads to a warped out node: "
			      . $next_node->warp_error 
			     );
	    }
	}

	$self->{search_tree} = $data ;
    }
    else {
	$self->{search_tree}  = {next_step => undef } ;
	$next_node = $node->fetch_element($choice);
    }

    $self->{current}{object}       = $next_node ;
    $self->{current}{element_type} = $node->element_type($choice) ;
    $self->{current}{element_name} = $choice ;
    return $next_node ;
}

=head2 current_object()

Returns the object where the search engine is. It can be 
a L<node|Config::Model::Node>, 
a L<list|Config::Model::ListId>, 
a L<hash|Config::Model::HashId>, or 
a L<leaf element|Config::Model::Value>.

=cut

sub current_object {
    my $self = shift ;
    return $self->{current}{object} ;
}

=head1 Automatic search

=head2 auto_choose ( element_callback, id_call_back)

Finds the searched element with minimal user interaction.

C<element_callback> will be called when the search engine finds a node
where more than one element can lead to the searched item. 

C<id_call_back> will be called when the search engine finds a hash
element or a list element which contain B<no> or B<more than 1>
elements. In this case the call-back will have return an id that will
be used by the search engine to get the target element.

Both call-back arguments will be:

=over

=item *

The current object (as returned by L</"current_object()">)

=item *

A list of possible choices

=back

For instances, your callback will be :

 my $id_cb = sub {
    my ($object,@choices) = @_ ;
    ....
    return $choice[1] ;
 }


Both call-back are expected to return a scalar value that is either:

=over

=item *

An element name

=item *

An id valid for the list or hash element returned by L</"current_object()">.

=back

=cut

sub auto_choose {
    my $self = shift ;
    my $elt_cb = shift || croak "auto_choose: missing element call back";
    my $id_cb  = shift || croak "auto_choose: missing id call back";

    my $object = $self->{current}{object} ;
    while (1) {
	my $next_step = $self->next_step;
	if (scalar @$next_step == 0) {
	    # found target
	    return $self->{current}{object} ;
	}

	my $next_choice =  (scalar @$next_step == 1) ?
	  $next_step->[0] : $elt_cb->($object, @$next_step) ;

	$self->_auto_choose_elt($next_choice,$id_cb) ;
    }
}

sub _auto_choose_elt {
    my $self = shift ;
    my $next_choice = shift ;
    my $id_cb = shift;

    $self->choose($next_choice) ;


    my $elt_type = $self->{current}{element_type} ;
    if ($elt_type =~ /list|hash/) {
	my $object   = $self->{current}{object} ;
	my @choice = $object->get_all_indexes() ;

	my $id = @choice == 1 ? $choice[0] 
	       :                $id_cb->($object, @choice ) ;

	$self->{current}{object} = $object->fetch_with_id($id);
    }
}

1;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,
L<Config::Model::Node>,
L<Config::Model::AnyId>,
L<Config::Model::ListId>,
L<Config::Model::HashId>,
L<Config::Model::Value>,

=cut
