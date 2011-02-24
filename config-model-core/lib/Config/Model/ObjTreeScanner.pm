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

package Config::Model::ObjTreeScanner ;
use strict ;
use Config::Model::Exception ;
use Scalar::Util qw/blessed/ ;
use Carp::Assert::More ;
use Carp;
use warnings ;


use Carp qw/croak confess cluck/;

=head1 NAME

Config::Model::ObjTreeScanner - Scan config tree and perform call-backs

=head1 SYNOPSIS

 use Config::Model ;
 use Log::Log4perl qw(:easy) ;
 Log::Log4perl->easy_init($WARN);

 # define configuration tree object
 my $model = Config::Model->new ;
 $model ->create_config_class (
    name => "MyClass",
    element => [ 
        [qw/foo bar/] => { 
            type => 'leaf',
            value_type => 'string'
        },
        baz => { 
            type => 'hash',
            index_type => 'string' ,
            cargo => {
                type => 'leaf',
                value_type => 'string',
            },
        },
        
    ],
 ) ;

 my $inst = $model->instance(root_class_name => 'MyClass' );

 my $root = $inst->config_root ;

 # put some data in config tree the hard way
 $root->fetch_element('foo')->store('yada') ;
 $root->fetch_element('bar')->store('bla bla') ;
 $root->fetch_element('baz')->fetch_with_id('en')->store('hello') ;

 # put more data the easy way
 my $step = 'baz:fr=bonjour baz:hr="dobar dan"';
 $root->load( step => $step ) ;

 # define leaf call back
 my $disp_leaf = sub { 
      my ($scanner, $data_ref, $node,$element_name,$index, $leaf_object) = @_ ;
      $$data_ref .= "disp_leaf called for '". $leaf_object->name. 
	"' value '".$leaf_object->fetch."'\n";
    } ;

 # simple scanner, (print all values with 'beginner' experience
 $scan = Config::Model::ObjTreeScanner-> new
  (
   leaf_cb               => $disp_leaf, # only mandatory parameter
  ) ;

 my $result = '';
 $scan->scan_node(\$result, $root) ;
 print $result ;

=head1 DESCRIPTION

This module creates an object that will explore (depth first) a
configuration tree.

For each part of the configuration tree, ObjTreeScanner object will
call-back one of the subroutine reference passed during construction.

Call-back routines will be called:

=over

=item *

For each node containing elements (including root node)

=item *

For each element of a node. This element can be a list, hash, node or
simple leaf element.

=item *

For each item contained in a node, hash or list. This item can be a
simple leaf or another node.

=back

To continue the exploration, these call-backs must also call the
scanner. (i.e. perform another call-back). In other words the user's
subroutine and the scanner play a game of ping-pong until the tree is
completely explored.

The scanner provides a set of default callback for the nodes. This
way, the user only have to provide call-backs for the leaves.

The scan is started with a call to C<scan_node>. The first parameter
of scan_node is a ref that is passed untouched to all call-back. This
ref may be used to store whatever result you want.

=head1 CONSTRUCTOR

=head2 new ( ... )

One way or another, the ObjTreeScanner object must be able to find all
callback for all the items of the tree. All the possible call-back are
listed below:

=over

=item leaf callback:

C<leaf_cb> is a catch-all generic callback. All other are specialized
call-back : C<enum_value_cb>, C<integer_value_cb>, C<number_value_cb>,
C<boolean_value_cb>, C<string_value_cb>, C<uniline_value_cb>,
C<reference_value_cb>

=item node callback:

C<node_content_cb> , C<node_dispatch_cb>

=item element callback:

All these call-backs are called on the elements of a node:
C<list_element_cb>, C<check_list_element_cb>, C<hash_element_cb>,
C<node_element_cb>, C<node_content_cb>.

=back

The user may specify all of them by passing a sub ref to the
constructor:

   $scan = Config::Model::ObjTreeScanner-> new
  (
   list_element_cb => sub { ... },
   ...
  )

Or use some default callback using the fallback parameter. Note that
at least one callback must be provided: C<leaf_cb>.

Optional parameter:

=over

=item fallback

If set to 'node', the scanner will provide default call-back for node
items. If set to 'leaf', the scanner will set all leaf callback (like
enum_value_cb ...) to string_value_cb or to the mandatory leaf_cb
value. "fallback" callback will not override callbacks provided by the
user.

If set to 'all', equivalent to 'node' and 'leaf'. By default, no
fallback is provided.

=item experience

Set the privilege level used for the scan (default 'beginner').

=item auto_vivify 

Whether to create the configuration items while scan (default is 1).

=item check 

C<yes>, C<no> or C<skip>.

=back

=head1 Callback prototypes

=head2 Leaf callback

C<leaf_cb> is called for each leaf of the tree. The leaf callback will
be called with the following parameters:

 ($scanner, $data_ref,$node,$element_name,$index, $leaf_object) 

where:

=over

=item *

C<$scanner> is the scanner object.

=item *

C<$data_ref> is a reference that is first passed to the first call of
the scanner. Then C<$data_ref> is relayed through the various
call-backs

=item *

C<$node> is the node that contain the leaf.

=item *

C<$element_name> is the element (or attribute) that contain the leaf.

=item *

C<$index> is the index (or hash key) used to get the leaf. This may
be undefined if the element type is scalar.

=item *

C<$leaf_object> is a L<Config::Model::Value> object.

=back

=head2 List element callback

C<list_element_cb> is called on all list element of a node, i.e. call
on the list object itself and not in the elements contained in the
list.

 ($scanner, $data_ref,$node,$element_name,@indexes)

C<@indexes> is a list containing all the indexes of the list.

Example:

  sub my_list_element_cb {
     my ($scanner, $data_ref,$node,$element_name,@idx) = @_ ;

     # custom code using $data_ref

     # resume exploration (if needed)
     map {$scanner->scan_list($data_ref,$node,$element_name,$_)} @idx ;

     # note: scan_list and scan_hash are equivalent
  }

=head2 Check list element callback

C<check_list_element_cb>: Like C<list_element_cb>, but called on a
check_list element.

 ($scanner, $data_ref,$node,$element_name,@check_items)

C<@check_items> is a list containing all the items of the check_list.

=head2 Hash element callback

C<hash_element_cb>: Like C<list_element_cb>, but called on a
hash element.

 ($scanner, $data_ref,$node,$element_name,@keys)

C<@keys> is an list containing all the keys of the hash.

Example:

  sub my_hash_element_cb {
     my ($scanner, $data_ref,$node,$element_name,@keys) = @_ ;

     # custom code using $data_ref

     # resume exploration
     map {$scanner->scan_hash($data_ref,$node,$element_name,$_)} @keys ;
  }

=head2 Node content callback

C<node_content_cb>: This call-back is called foreach node (including
root node).

 ($scanner, $data_ref,$node,@element_list)

C<@element_list> contains all the element names of the node.

Example:

  sub my_content_cb = { 
     my ($scanner, $data_ref,$node,@element) = @_ ;

     # custom code using $data_ref

     # resume exploration
     map {$scanner->scan_element($data_ref, $node,$_)} @element ;
  }

=head2 Dispatch node callback

C<node_dispatch_cb>: Any callback specified in the hash will be called for 
each instance of the specified configuration class.
(this may include the  root node).

For instance, if you have:

  node_dispach_cb => {
    ClassA => \&my_class_a_dispatch_cb,
    ClassB => \&my_class_b_dispatch_cb,
  }

C<&my_class_a_dispatch_cb> will be called for each instance of C<ClassA> and 
C<&my_class_b_dispatch_cb> will be called for each instance of C<ClassB>.

They will be called with the following parameters:

 ($scanner, $data_ref,$node,@element_list)

C<@element_list> contains all the element names of the node.

Example:

  sub my_class_a_dispatch_cb = { 
     my ($scanner, $data_ref,$node,@element) = @_ ;

     # custom code using $data_ref

     # resume exploration
     map {$scanner->scan_element($data_ref, $node,$_)} @element ;
  }

=head2 Node element callback

C<node_element_cb> is called for each node contained within a node
(i.e not with root node). This node can be held by a plain element or
a hash element or a list element:

 ($scanner, $data_ref,$node,$element_name,$key, $contained_node)

C<$key> may be undef if C<$contained_node> is not a part of a hash or
a list. C<$element_name> and C<$key> specifies the element name and
key of the the contained node you want to scan. (passed with
C<$contained_node>) Note that C<$contained_node> may be undef if
C<auto_vivify> is 0.

Example:

  sub my_node_element_cb {
    my ($scanner, $data_ref,$node,$element_name,$key, $contained_node) = @_;

    # your custom code using $data_ref

    # explore next node 
    $scanner->scan_node($data_ref,$contained_node);
  }

=cut

sub new {
    my $type = shift ;
    my %args = @_;

    my $self = { experience => 'beginner' , auto_vivify => 1, check => 'yes' } ;
    bless $self,$type ;

    $self->{leaf_cb} = delete $args{leaf_cb} or
	croak __PACKAGE__,"->new: missing leaf_cb parameter" ;

    # we may use leaf_cb
    $self->create_fallback(delete $args{fallback} || 'all') ;

    if (defined $args{permission}) {
	$args{experience} = delete $args{permission} ;
	carp "ObjTreeScanner new: permission is deprecated in favor of experience";
    }

    # get all call_backs
    my @value_cb = map {$_.'_value_cb'} 
	qw/boolean enum string uniline integer number reference/; 

    foreach my $param (qw/check node_element_cb hash_element_cb 
                          list_element_cb check_list_element_cb node_content_cb
                          experience auto_vivify up_cb/, @value_cb) {
        $self->{$param} = $args{$param} if defined $args{$param};
	delete $args{$param} ; # may exists but be undefined
        croak __PACKAGE__,"->new: missing $param parameter"
          unless defined $self->{$param} ;
    }

    # this parameter is optional and does not need a fallback
    $self->{node_dispatch_cb} = delete $args{node_dispatch_cb} || {} ;
    
    croak __PACKAGE__,"->new: node_dispatch_cb is not a hash ref" 
	unless ref($self->{node_dispatch_cb}) eq 'HASH';

    croak __PACKAGE__,"->new: unexpected check: $self->{check}" 
	unless $self->{check} =~ /yes|no|skip/;

    croak __PACKAGE__,"->new: unexpected parameter: ",join (' ',keys %args)
      if scalar %args ;

    return $self ;
}

# internal
sub create_fallback {
    my $self = shift ;
    my $fallback = shift;

    return if not defined $fallback or $fallback eq 'none' ;

    my $done = 0 ;

    if ($fallback eq 'node' or $fallback eq 'all') {
        $done ++ ;
        my $node_content_cb = sub {
            my ($scanner, $data_r,$node,@element) = @_ ;
            map {$scanner->scan_element($data_r,$node,$_)} @element ;
	} ;

        my $node_element_cb = sub {
            my ($scanner, $data_r,$node,$element_name,$key, $next_node) = @_ ;
            $scanner->scan_node($data_r,$next_node);
	} ;

        my $hash_element_cb = sub {
            my ($scanner, $data_r,$node,$element_name,@keys) = @_ ;
            map {$scanner->scan_hash($data_r,$node,$element_name,$_)} @keys ;
	};

        $self->{list_element_cb}        = $hash_element_cb;
        $self->{hash_element_cb}        = $hash_element_cb;
        $self->{node_element_cb}        = $node_element_cb;
        $self->{node_content_cb}        = $node_content_cb ;
	$self->{up_cb}          = sub {} ; # do nothing
    }

    if ($fallback eq 'leaf' or $fallback eq 'all') {
        $done ++ ;
        my $l = $self->{string_value_cb} ||= $self->{leaf_cb} ;

        $self->{check_list_element_cb}  ||= $l ;
        $self->{enum_value_cb}          ||= $l ;
        $self->{integer_value_cb}       ||= $l ;
        $self->{number_value_cb}        ||= $l ;
        $self->{boolean_value_cb}       ||= $l ;
        $self->{reference_value_cb}     ||= $l ;
        $self->{uniline_value_cb}       ||= $l ;
      }

    croak __PACKAGE__,"->new: Unexpected fallback value '$fallback'. ",
      "Expected 'node', 'leaf', 'all' or 'none'" if not $done;
}

=head1 METHODS

=head2 scan_node ($data_r,$node)

Explore the node and call either C<node_dispatch_cb> (if the node class 
name matches the dispatch_node hash) B<or> (e.g. xor) C<node_element_cb> passing 
all element names.

After the first callback has returned, C<up_cb> will be called.

=cut

sub scan_node {
    my ($self,$data_r,$node) = @_ ;

    #print "scan_node ",$node->name,"\n";
    # get all elements according to catalog

    Config::Model::Exception::Internal
	-> throw (
		  error => "'$node' is not a Config::Model object" 
		 ) 
	  unless blessed($node) and $node->isa("Config::Model::AnyThing") ;

    # skip exploration of warped out node
    if ($node->isa('Config::Model::WarpedNode')) {
	$node = $node->get_actual_node ;
	return unless defined $node ;
    }

    my $config_class = $node->config_class_name ;
    my $node_dispatch_cb = $self->{node_dispatch_cb}{$config_class} ;
    
    my $actual_cb = $node_dispatch_cb || $self->{node_content_cb};
    
    my @element_list= $node->get_element_name(
        for => $self->{experience}, 
        check => $self->{check}
    ) ;

    # we could add here a "last element" call-back, but it's not
    # very useful if the last element is a hash.
    $actual_cb->($self, $data_r,$node,@element_list) ;

    $self->{up_cb}->($self, $data_r,$node) ;
}

=head2 scan_element($data_r,$node,$element_name)

Explore the element and call either C<hash_element_cb>,
C<list_element_cb>, C<node_content_cb> or a leaf call-back (the leaf
call-back called depends on the Value object properties: enum, string,
integer and so on)

=cut

sub scan_element {
    my ($self,$data_r,$node,$element_name) = @_ ;

    my $element_type = $node->element_type($element_name);

    return unless defined $element_type; # element may not be initialized
    my $autov = $self->{auto_vivify} ;

    #print "scan_element $element_name ";
    if ($element_type eq 'hash') {
        #print "type hash\n";
        my @keys = $self->get_keys($node,$element_name) ;
        # if hash element grab keys and perform callback
        $self->{hash_element_cb}->($self, $data_r,$node,$element_name,@keys);
    }
    elsif ($element_type eq 'list') {
        #print "type list\n";
        my @keys = $self->get_keys($node,$element_name) ;
        $self->{list_element_cb}->($self, $data_r,$node,$element_name, @keys);
    }
    elsif ($element_type eq 'check_list') {
        #print "type list\n";
	my $cl_elt = $node->fetch_element(name => $element_name, check => $self->{check}) ;
        $self->{check_list_element_cb}->($self, $data_r,$node,$element_name, undef, $cl_elt);
    }
    elsif ($element_type eq 'node') {
        #print "type object\n";
	# avoid auto-vivification
	my $next_obj = ($autov or $node->is_element_defined($element_name))
	             ? $node->fetch_element(name => $element_name, check => $self->{check}) 
	             : undef ;

        # if obj element, cb
        $self->{node_element_cb}-> ($self, $data_r, $node,
				    $element_name,undef, $next_obj ) ;
    }
    elsif ($element_type eq 'warped_node') {
        #print "type warped\n";
	my $next_obj = ($autov or $node->is_element_defined($element_name))
	             ? $node->fetch_element(name => $element_name, check => $self->{check}) 
	             : undef ;
        $self->{node_element_cb}-> ($self, $data_r,$node,
				    $element_name, undef, $next_obj) ;
    }
    elsif ($element_type eq 'leaf') {
	my $next_obj = $node->fetch_element(name => $element_name, check => $self->{check});
	my $type = $next_obj->value_type ;
	return unless $type;
	my $cb_name = $type.'_value_cb' ;
	my $cb = $self->{$cb_name};
	croak "scan_element: No call_back specified for '$cb_name'" 
	  unless defined $cb ;
	$cb-> ($self, $data_r,$node,$element_name,undef,$next_obj);
    }
    else {
	croak "Unexpected element_type: $element_type";
    }
}

=head2 scan_hash ($data_r,$node,$element_name,$key)

Explore the hash member (or hash value) and call either C<node_content_cb> or
a leaf call-back.

=cut

sub scan_hash {
    my ($self,$data_r,$node,$element_name,$key) = @_ ;

    assert_like($node->element_type($element_name), qr/(hash|list)/);

    #print "scan_hash ",$node->name," element $element_name key $key ";
    my $item = $node -> fetch_element(name => $element_name, check => $self->{check}) ;


    my $cargo_type = $item->cargo_type($element_name);
    my $next_obj = $item->fetch_with_id(index  => $key, check => $self->{check}) ;

    if ($cargo_type =~ /node$/) {
        #print "type object or warped\n";
        $self->{node_element_cb}-> ($self, $data_r,$node,
				    $element_name,$key, $next_obj) ;
    }
    elsif ($cargo_type eq 'leaf') {
	my $cb_name = $next_obj->value_type.'_value_cb' ;
	my $cb = $self->{$cb_name};
	croak "scan_hash: No call_back specified for '$cb_name'" 
	  unless defined $cb ;
	$cb-> ($self, $data_r,$node,$element_name,$key,$next_obj);
    }
    else {
	croak "Unexpected cargo_type: $cargo_type";
    }
}

=head2 scan_list ($data_r,$node,$element_name,$index)

Just like C<scan_hash>: Explore the list member and call either
C<node_content_cb> or a leaf call-back.

=cut

sub scan_list {
    goto &scan_hash ;
}

=head2 get_keys ($node, $element_name)

Returns an list containing the sorted keys of a hash element or returns
an list containing (0.. last_index) of an list element.

Throws an exception if element is not an list or a hash element.

=cut

sub get_keys {
    my ($self,$node,$element_name) = @_ ;

    my $element_type = $node->element_type($element_name);
    my $item = $node->fetch_element(name => $element_name, check => $self->{check}) ;

    return $item->get_all_indexes 
      if    $element_type eq 'hash' 
	 || $element_type eq 'list' ;

    Config::Model::Exception::Internal
	->throw (
		 error => "called get_keys on non hash or non list"
		 ." element $element_name",
		 object => $node
		) ;

}

=head2 experience ( [ new_experience ] )

Set or query the experience level of the scanner

=cut

sub experience {
    my ($self,$new_perm) = @_ ;
    $self->{experience} = $new_perm if defined $new_perm ;
    return $self->{experience} ;
}

=head2 get_experience_ref ( )

Get a SCALAR reference on experience. Use with care.

=cut

sub get_experience_ref {
    my $self = shift ;
    return \$self->{experience} ;
}

sub get_permission_ref {
    carp "get_permission_ref: deprecated";
    goto &get_experience_ref ;
}

1;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,L<Config::Model::Node>,L<Config::Model::Instance>, 
L<Config::Model::HashId>,
L<Config::Model::ListId>,
L<Config::Model::CheckList>,
L<Config::Model::Value>

=cut

