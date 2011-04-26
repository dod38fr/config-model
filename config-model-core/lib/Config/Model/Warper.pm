#    Copyright (c) 2005-2011 Dominique Dumont.
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

package Config::Model::Warper ;

use Any::Moose ;
use Log::Log4perl qw(get_logger :levels);
use Data::Dumper ;
use Storable qw/dclone/ ;
use Config::Model::Exception ;
use Carp;


has 'follow' => ( is => 'ro', isa => 'HashRef[Str]' , required => 1 );
has 'rules'  => ( is => 'ro', isa => 'ArrayRef' , required => 1 );
has 'warped_object'  => ( is => 'ro', isa => 'Config::Model::AnyThing' , 
        weak_ref => 1, required => 1 );

has '_values' => (  traits    => ['Hash'],
             is        => 'ro',
             isa       => 'HashRef[Str | Undef ]',
             default   => sub { {} },
             handles => { 
                    _set_value => 'set' ,
                    _get_value => 'get' ,
                    _value_keys => 'keys' ,
                } ,
  ) ;

has _computed_masters => ( is => 'rw',  isa => 'HashRef' , init_arg => undef ) ;

has _warped_nodes => ( is => 'rw',  isa => 'HashRef' , init_arg => undef, default   => sub { {} }, ) ;
has _registered_values => ( is => 'rw',  isa => 'HashRef' , init_arg => undef, default   => sub { {} }, ) ;

has allowed => ( is => 'rw',  isa => 'ArrayRef' ) ;
has morph => ( is => 'ro', isa => 'Bool' ) ;

my $logger = get_logger("Warper") ;

# create the object, check args, but don't do anything else
sub BUILD {
    my $self = shift ;
    
    $logger->debug( "Warper new: created for ".$self->name);
    $self->check_warp_args ;

    $self->register_to_all_warp_masters ;
    $self->refresh_values_from_master ;
    $self->do_warp ;
}

# should be called only at startup
sub register_to_all_warp_masters {
    my $self = shift ;
    
    my $follow = $self->follow;

    # now, follow is only { w1 => 'warp1', w2 => 'warp2'}
    foreach my $warper_name (keys %$follow) {
        $self->register_to_one_warp_master ($warper_name);
    }
    
}    

sub register_to_one_warp_master {
    my $self        = shift;
    my $warper_name = shift || die "register_to_one_warp_master: missing warper_name";

    my $follow      = $self->follow;
    my $warper_path = $follow->{$warper_name};
    $logger->debug( "Warper register_to_one_warp_master: ",
        $self->name, " follows $warper_name" );

    # need to register also to all warped_nodes found on the path
    my @command = ($warper_path);
    my $warper;
    my $warped_node ;
    my $obj = $self->warped_object;
    my $reg_values = $self->_registered_values ;

    return if defined $reg_values->{$warper_name} ;

    while (@command) {

        # may return undef object
        ( $obj, @command ) = $obj->grab(
            step               => \@command,
            mode               => 'step_by_step',
            grab_non_available => 1,
        );

        if ( not defined $obj ) {
            $logger->debug( "Warper register_to_one_warp_master: aborted steps. Left '@command'" );
            last;
        }

        my $obj_loc = $obj->location ;

        $logger->debug( "Warper register_to_one_warp_master: step to master $obj_loc");

        if ( $obj->isa('Config::Model::Value') ) {
            $warper = $obj;
            if (defined $warped_node) {
                # keep obj ref to be able to unregister later on
                $self->_warped_nodes->{$warped_node}{$warper_name} = $obj  ;
            }
            last;
        }

        if ( $obj->isa('Config::Model::WarpedNode') ) {
            $logger->debug( "Warper register_to_one_warp_master: register to warped_node $obj_loc");
             if (defined $warped_node) {
                # keep obj ref to be able to unregister later on
                $self->_warped_nodes->{$warped_node}{$warper_name} = $obj  ;
            }
            $warped_node = $obj_loc ;
            $obj->register( $self, $warper_name );
        }
    }

    if ( defined $warper and scalar @command ) {
        Config::Model::Exception::Model->throw(
            object => $self->warped_object,
            error => "Some steps are left (@command) from warper path $warper_path",
        );
    }

    $logger->debug(
        "Warper register_to_one_warp_master:",
        $self->name,
        " is warped by $warper_name => '$warper_path' location in tree is: '",
        defined $warper ? $warper->name : 'unknown' ,
        "'"
    );
    
    return unless defined $warper ;

    Config::Model::Exception::Model->throw(
        object => $self->warped_object,
        error  => "warper $warper_name => '$warper_path' is not a leaf"
    ) unless $warper->isa('Config::Model::Value') ;

    # warp will register this value object in another value object
    # (the warper).  When the warper gets a new value, it will
    # modify the warped object according to the data passed by the
    # user.

    my $type = $warper->register( $self, $warper_name );
    
    $reg_values->{$warper_name} = $warper ;

    # store current warp master value
    if ( $type eq 'computed' ) {
        $self->_computed_masters->{$warper_name} = $warper;
    }
}

sub refresh_affected_registrations {
    my ($self, $warped_node_location) = @_ ;
    
    my $wnref = $self->_warped_nodes ;

    $logger->debug(
        "Warper refresh_affected_registrations: called on",
        $self->name,
        " from $warped_node_location'"
    );
   
    #return unless defined $wnref ;
    
    # remove and unregister obj affected by this warped node
    my $ref = delete $wnref->{$warped_node_location} ;
    
    foreach my $warper_name (keys %$ref) {
        $logger->debug(
            "Warper refresh_affected_registrations: ",
            $self->name,
            " unregisters from $warper_name'"
        );
        delete $self->_registered_values->{$warper_name} ;
        $ref -> {$warper_name} -> unregister( $self->name ) ;
    }

    $self->register_to_all_warp_masters ;
    #map {  $self->register_to_one_warp_master($_) } keys %$ref;
}


# should be called only at startup
sub refresh_values_from_master {
    my $self = shift;

    # should get new value from warp master

    my $follow = $self->follow;

    # now, follow is only { w1 => 'warp1', w2 => 'warp2'}

    # should try to get values only for unregister or computed warp masters
    foreach my $warper_name ( keys %$follow ) {
        my $warper_path = $follow->{$warper_name};
        $logger->debug( "Warper trigger: ",
            $self->name, " following $warper_name" );

       # warper can itself be warped out (part of a warped out node).
       # not just 'not available'.

        my $warper = $self->warped_object->grab(
            step => $warper_path,
            mode => 'loose',
        );

        if ( defined $warper ) {
            # read the warp master values, so I can warp myself just
            # after.
            my $warper_value = $warper->fetch('allow_undef') ;
            $logger->debug( "Warper: '$warper_name' value is: '"
                . ( defined $warper_value ? $warper_value : '<undef>' ) 
                . "'" );
            $self->_set_value( $warper_name => $warper_value );
        }
        else {
            # consider that the warp master value is undef
            $self->_set_value($warper_name,'');
            $logger->debug("Warper:  '$warper_name' is not available");
        }
    }

}

sub name {
    my $self = shift ;
    return "Warper of ".$self->warped_object->name ;
}

# And I'm going to warp them ...
sub warp_them
  {
    my $self = shift ;

    # retrieve current value if not provided
    my $value = @_ ? $_[0] 
              :      $self->fetch_no_check ;

    foreach my $ref ( @{$self->{warp_these_objects}})
      {
        my ($warped, $warp_index) = @$ref ;
        next unless defined $warped ; # $warped is a weak ref and may vanish

        # pure warp of object
        $logger->debug("Warper ",$self->name," warp_them: (value ", (defined $value ? $value : 'undefined'),
		  ") warping '",$warped->name, "'" );
        $warped->warp($value,$warp_index) ;
      }
  }



sub check_warp_args {
    my $self = shift ;

    # check that rules element are array ref and store them for
    # error checking
    my $rules_ref =  $self->rules ;

    my @rules 
      = ref $rules_ref eq 'HASH'  ? %$rules_ref :
	ref $rules_ref eq 'ARRAY' ? @$rules_ref :
	  Config::Model::Exception::Model
	      -> throw ( error => "warp error: warp 'rules' parameter "
			          ."is not a ref ($rules_ref)",
			 object => $self->warped_object
		       ) ;

    my $allowed = $self->allowed ;

    for (my $r_idx = 0; $r_idx < $#rules; $r_idx += 2) {
        my $key_set = $rules[$r_idx] ;
        my @keys = ref($key_set) ? @$key_set : ($key_set) ;

        my $v = $rules[$r_idx + 1] ;
        Config::Model::Exception::Model
	    -> throw (
		      object => $self->warped_object,
		      error => "rules value for @keys is not a hash ref ($v)"
		     ) 
	      unless ref($v) eq 'HASH' ;

        foreach my $pkey (keys %$v) {
            Config::Model::Exception::Model
		-> throw (
			  object => $self->warped_object,
			  error => "Warp rules error for '@keys': '$pkey' ".
			  "parameter is not allowed, ".
			  "expected '".join("' or '",@$allowed)."'"
			 ) 
		  unless grep( $pkey eq $_ , @$allowed) ;
	}
    }
}

sub _dclone_key {
    return map { ref $_ ? [ @$_ ] : $_ } @_ ;
}


# Internal. This method will change element properties (like level and
# experience) according to the warp effect.  For instance, if a warp
# rule make a node no longer available in a model, its level must
# change to 'hidden'
sub set_parent_element_property {
    my ( $self, $arg_ref ) = @_;

    my $warped_object = $self->warped_object ;

    my @properties = qw/level experience/ ;

    if ( defined $warped_object->index_value ) {
        $logger->debug("Warper set_parent_element_property: called on hash or list, aborted" );
        return ;
    }
    
    my $parent = $warped_object->parent ;
    my $elt_name = $warped_object->element_name ;
    foreach my $property_name (@properties) {
        my $v = $arg_ref->{$property_name};
        if ( defined $v ) {
            $logger->debug("Warper set_parent_element_property: set '",
                $parent->name," $elt_name' $property_name with $v" );
            $parent->set_element_property(
                property => $property_name,
                element  => $elt_name,
                value    => $v,
            );
        }
        else {

            # reset ensures that property is reset to known state by default
            $logger->debug("Warper set_parent_element_property: reset $property_name" );
            $parent->reset_element_property(
                property => $property_name,
                element  => $elt_name ,
            );
        }
    }
}

# try to actually warp (change properties) of a warped object.
sub trigger {
    my $self = shift;

    my %old_value_set  = %{ $self->_values } ;

    if (@_) {
        my ($value,$warp_name) = @_ ;
        $logger -> debug( "Warper: trigger called on ",$self->name, " with value '", 
		   defined $value ? $value : '<undef>',
		   "' name $warp_name");
        $self->_set_value($warp_name => $value || '') ;
    }

    # read warp master values that are computed 
    my $cm = $self->_computed_masters ;
    foreach my $name (keys %$cm ) {
        $self->_set_value($name => $cm->{$name}->fetch) ;
    }

    # check if new values are different from old values
    my $same = 1 ;
    foreach my $name ($self->_value_keys) {
        my $old = $old_value_set   {$name};
        my $new = $self->_get_value($name);
        $same = 0 if ( $old ? 1 : 0  xor $new ? 1 : 0 )
	  or ($old and $new and $new ne $old) ;
    }

    if ($same) {
	no warnings "uninitialized" ;
        if ($logger->is_debug) {
            $logger ->debug("Warper: warp skipped because no change in value set ",
		  "(old: '",join("' '", %old_value_set),"' new: '",
		  join("' '",%{ $self->_values() }),"')");
        }
        return ;
    }

    $self->do_warp ;
}

# undef values are changed to '' so compute_bool no longer returns
# undef. It returns either 1 or 0
sub compute_bool {
    my $self = shift ;
    my $expr = shift ;

    $logger ->debug("Warper compute_bool: called for '$expr'") ;

#    my $warp_value_set = $self->_values   ;
    $logger ->debug("Warper compute_bool: data:\n", 
		    Data::Dumper->Dump([$self->_values],['data']));

    $expr =~ s/&(\w+)/\$self->warped_object->$1/g;

    my @init_code ;
    foreach my $warper_name ($self->_value_keys) {
	my $v = $self->_get_value($warper_name) ;

	my $code_v = (defined $v and $v =~ m/^[\d\.]$/) ? "$v"
	           :  defined $v                        ? "'$v'"
	           :                                      'undef' ;

	push @init_code, "my \$$warper_name = $code_v ;" ;
    }

    my $perl_code = join("\n",@init_code, $expr);
    $logger ->debug("Warper compute_bool: eval code '$perl_code'") ;

    my $ret;
    {
	no warnings "uninitialized" ;
	$ret = eval($perl_code) ;
    }

    if ($@) {
        Config::Model::Exception::Model
	    -> throw (
		      object => $self->warped_object ,
		      error => "Warp boolean expression failed:\n$@"
		      . "eval'ed code is: \n$perl_code"
		     ) 
    }

    $logger->debug("compute_bool: eval result: ", ($ret ? 'true' : 'false'));
    return $ret ;
}

sub do_warp {
    my $self = shift ;

    my $warp_value_set = $self->_values   ;
    my $rules          = dclone ($self->rules)   ;
    my %rule_hash = @$rules ;

    # try all boolean expression with warp_value_set to get the
    # correct rule

    my $found_rule = {};
    my $found_bool ='' ; # this variable may be used later in error message

    foreach my $bool_expr (@$rules) {
	next if ref($bool_expr) ; # it's a rule not a bool expr
	my $res = $self -> compute_bool( $bool_expr );
	next unless $res ;
	$found_bool = $bool_expr ;
	$found_rule = $rule_hash{$bool_expr} || {};
	$logger->debug("do_warp found rule for '$bool_expr':\n", 
		       Data::Dumper->Dump ([$found_rule],['found_rule']));
	last;
    }

    if ($logger->is_info) {
        my @warp_str = map { defined $_ ? $_ : 'undef' } keys %$warp_value_set ;

        $logger->info("do_warp: warp called from '$found_bool' on '",$self->warped_object->name,
		      "' with elements '",join("','",@warp_str),
		      "', warp rule is ", (scalar %$found_rule ? "" : 'not ') , 
		      "found");
    }

    $logger->debug("do_warp: call set_parent_element_property on '",$self->name,"' with ",
	Data::Dumper->Dump ([$found_rule],['found_rule']));

    $self->set_parent_element_property ( $found_rule ) ;

    $logger->debug("do_warp: call set_properties on '",$self->warped_object->name,"' with ",
	Data::Dumper->Dump ([$found_rule],['found_rule']));
    eval { $self->warped_object->set_properties(%$found_rule) ; };

    if ($@) {
        my @warp_str = map { defined $_ ? $_ : 'undef' } keys %$warp_value_set ;
	my $e = $@ ;
	my $msg = ref $e ? $e->as_string : $e ;
	Config::Model::Exception::Model
	    -> throw (
		      object => $self->warped_object,
		      error => "Warp failed when following '" . join("','",@warp_str)
		             . "' from \"$found_bool\". Check model rules:\n\t"
		             . $msg
		     ) ;
    }
}

# Usually a warp error occurs when the item is not actually available
# or when a setting is wrong. Then guiding the user toward a warp
# master value that has a rule attached to it is a good idea.

# But sometime, the user wants to remove and item. In this case it
# must be warped out by setting a warp master value that has not rule
# attached. This case is indicated when $want_remove is set to 1
sub warp_error {
    my ($self) = @_ ;

    return '' unless defined $self->{warp} ;
    my $follow = $self->{warp}{follow} ;
    my @rules  = @{$self->{warp}{rules}} ;

    # follow is either ['warp1','warp2',...] 
    # or { warp1 => {....} , ...} or 'warp'
    my @warper_paths = ref($follow) eq 'ARRAY' ? @$follow 
                     : ref($follow) eq 'HASH'  ? values %$follow
                     :                           ($follow) ;

    my $str = "You may solve the problem by modifying ".
      (@warper_paths>1 ? "one or more of ": '').
        "the following configuration parameters:\n" ;

    my $expected_error = 'Config::Model::Exception::UnavailableElement';

    foreach my $warper_path ( @warper_paths ) {
	my $warper_value ;
	my $warper ;

	# try 
	eval {
	    $warper = $self->get_warper_object($warper_path);
	    $warper_value = $warper->fetch ;
	};

	# catch
	if ( my $e = Exception::Class->caught($expected_error) )
        {
	    $str .= "\t'$warper_path' which is unavailable\n" ;
	    next ;
        }

        $warper_value = 'undef' unless defined $warper_value ;

        my @choice = defined $warper->choice ? @{$warper->choice} :
	  $warper->{value_type} eq 'boolean' ? (0,1) : () ;

        my @try = sort grep { $_ ne $warper_value } @choice ;

        $str .= "\t'".$warper->location. "': Try " ;

        my $a = $warper->{value_type} =~ /^[aeiou]/ ? 'an' : 'a' ;

        $str .= @try ? "'".join ("' or '",@try)."' instead of " :
          "$a $warper->{value_type} value different from " ;

        $str .= "'$warper_value'\n" ;

        if (defined $warper->{compute}) {
            $str .= "\n\tHowever, '".$warper->name. "' ". 
              $warper->compute_info."\n" ;
	}
    }

    $str .= "Warp parameters:\n". Data::Dumper->Dump([$self->{warp}],['warp'])
      if $logger->is_debug ;

    return $str ;
}

no Any::Moose ;
1;

=head1 NAME

Config::Model::WarpedThing - Base class for warped classes

=head1 SYNOPSIS

 # internal class

=head1 DESCRIPTION

This class must be inherited by all classes that can be warped by
L<Config::Model::Value>. This class provides a set of methods that are
expected by a warp master from a warped class.

Currently this class is inherited by L<Config::Model::Value>, 
L<Config::Model::AnyId> and L<Config::Model::WarpedNode>.

WarpThing does not provide a constructor.

=head1 Warper and warped

Warping an object means that the properties of the object will be
changed depending on the value of another object.

The changed object is referred as the I<warped> object.

The other object that holds the important value is referred as the
I<warp master> or the I<warper> object.

You can also set up several warp master for one warped object. This
means that the properties of the warped object will be changed
according to a combination of values of the warp masters.

=head1 Warp arguments

Warp arguments are passed in a hash ref whose keys are C<follow> and
and C<rules>:

=head2 Warp follow argument

L<Grab string|Config::Model::AnyThing/"grab(...)"> leading to the
C<Config::Model::Value> warp master. E.g.: 

 follow => '! tree_macro' 

In case of several warp master, C<follow> will be set to an array ref 
of several L<grab string|Config::Model::AnyThing/"grab(...)">:

 follow => [ '! macro1', '- macro2' ]

You can also use named parameters:

 follow => { m1 => '! macro1', m2 => '- macro2' }

=head2 Warp rules argument

String, hash ref or array ref that specify the warped object property
changes.  These rules specifies the actual property changes for the
warped object depending on the value(s) of the warp master(s). 

E.g. for a simple case (rules is a hash ref) :

 follow => '! macro1' ,
 rules => { A => { <effect for macro1 == A> },
            B => { <effect for macro1 == B> }
          }

In case of similar effects, you can use named parameters and
a boolean expression to specify the effect. The first match will
be applied. In this case, rules is a list ref:

  follow => { m => '! macro1' } ,
  rules => [ '$m eq "A"'               => { <effect for macro1 == A> },
             '$m eq "B" or $m eq"C "'  => { <effect for macro1 == B|C > }
           ]


In case of several warp masters, C<follow> must use named parameters, and
rules must use boolean expression:

 follow => { m1 => '! macro1', m2 => '- macro2' } ,
 rules => [
           '$m1 eq "A" && $m2 eq "C"' => { <effect for A C> },
           '$m1 eq "A" && $m2 eq "D"' => { <effect for A D> },
           '$m1 eq "B" && $m2 eq "C"' => { <effect for B C> },
           '$m1 eq "B" && $m2 eq "D"' => { <effect for B D> },
          ]

Of course some combinations of warp master values can have the same
effect:

 follow => { m1 => '! macro1', m2 => '- macro2' } ,
 rules => [
           '$m1 eq "A" && $m2 eq "C"' => { <effect X> },
           '$m1 eq "A" && $m2 eq "D"' => { <effect Y> },
           '$m1 eq "B" && $m2 eq "C"' => { <effect Y> },
           '$m1 eq "B" && $m2 eq "D"' => { <effect Y> },
          ]

In this case, you can use different boolean expression to save typing:

 follow => { m1 => '! macro1', m2 => '- macro2' } ,
 rules => [
           '$m1 eq "A" && $m2 eq "C"' => { <effect X> },
           '$m1 eq "A" && $m2 eq "D"' => { <effect Y> },
           '$m1 eq "B" && ( $m2 eq "C" or $m2 eq "D") ' => { <effect Y> },
          ]

Note that the boolean expression will be sanitized and used in a Perl
eval, so you can use most Perl syntax and regular expressions.

Function (like C<&foo>) will be called like C<< $self->foo >> before evaluation\
of the boolean expression.

=cut

=head1 Methods

=head2 warp_error()

This method returns a string describing:

=over

=item *

The location(s) of the warp master

=item *

The current value(s) of the warp master(s)

=item *

The other values accepted by the warp master that can be tried (if the
warp master is an enumerated type)

=back

=cut


=head1 How does this work ?

=over

=item Registration

=over

=item *

When a warped object is created, the constructor will register to the
warp masters. The warp master are found by using the special string
passed to the C<follow> parameter. As explained in 
L<grab method|Config::Model::AnyThing/"grab(...)">,
the string provides the location of the warp master in the
configuration tree using a symbolic form. 

=item *

Then the warped object retrieve the value(s) of the warp master(s)

=item *

Then the warped object warps itself using the above
value(s). Depending on these value(s), the properties of the warped
object will be modified.

=back

=item Master update

=over

=item *

When a warp master value is updated, the warp master will call I<all>
its warped object and pass them the new master value.

=item *

Then each warped object will modify its properties according to the
new warp master value.

=back

=back

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model::AnyThing>,
L<Config::Model::HashId>,
L<Config::Model::ListId>,
L<Config::Model::WarpedNode>,
L<Config::Model::Value>

=cut

