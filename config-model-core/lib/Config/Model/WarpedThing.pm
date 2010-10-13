
#    Copyright (c) 2005-2010 Dominique Dumont.
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

package Config::Model::WarpedThing ;
use strict;
use Scalar::Util qw(weaken) ;
use Data::Dumper ;
use Config::Model::ValueComputer ;
use Config::Model::Exception ;
use Log::Log4perl qw(get_logger :levels);
use Carp;

use warnings FATAL => qw(all);


use base qw/Config::Model::AnyThing/ ;

my $logger = get_logger("Tree::Element::Warped") ;

=head1 NAME

Config::Model::WarpedThing - Base class for warped classes

=head1 SYNOPSIS

 use base qw/Config::Model::WarpedThing/ ;

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

The changed object is refered as the I<warped> object.

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

Note that the boolean expression will be sanitised and used in a Perl
eval, so you can use most Perl syntax and regular expressions.

=cut

sub check_warp_args {
    my ($self,$allowed, $arg_ref) = @_ ;

    Config::Model::Exception::Model
	-> throw (
		  object => $self,
		  error => "warp argument must be a hash ref"
		 ) 
	  unless ref($arg_ref) eq 'HASH' ;

    map {
        Config::Model::Exception::Model
	    -> throw (
		      object => $self,
		      error => "warp error: Undefined warp '$_' parameter. (".
		                join(' ',keys %$arg_ref).")"
		     ) 
	      unless defined $arg_ref->{$_} ;
    } qw/follow rules/ ;

    # check that rules element are array ref and store them for
    # error checking
    my $rules_ref =  $arg_ref->{rules} ;
    my @rules 
      = ref $rules_ref eq 'HASH'  ? %$rules_ref :
	ref $rules_ref eq 'ARRAY' ? @$rules_ref :
	  Config::Model::Exception::Model
	      -> throw ( error => "warp error: warp 'rules' parameter "
			          ."is not a ref ($rules_ref)",
			 object => $self
		       ) ;

    for (my $r_idx = 0; $r_idx < $#rules; $r_idx += 2) {
        my $key_set = $rules[$r_idx] ;
        my @keys = ref($key_set) ? @$key_set : ($key_set) ;

        my $v= $rules[$r_idx + 1] ;
        Config::Model::Exception::Model
	    -> throw (
		      object => $self,
		      error => "rules value for @keys is not a hash ref ($v)"
		     ) 
	      unless ref($v) eq 'HASH' ;

        foreach my $pkey (keys %$v) {
            Config::Model::Exception::Model
		-> throw (
			  object => $self,
			  error => "Warp rules error for '@keys': '$pkey' ".
			  "parameter is not allowed, ".
			  "expected '".join("' or '",@$allowed)."'"
			 ) 
		  unless grep( $pkey eq $_ , @$allowed) ;
	}
    }

    $self->{warp} = { follow => $arg_ref->{follow}, 
		      rules  => \@rules } ;

    $self->{warp}{morph} = delete $arg_ref->{morph} 
      if defined $arg_ref->{morph};
}

sub _dclone_key {
    return map { ref $_ ? [ @$_ ] : $_ } @_ ;
}

# internal 
# Will get the warp master object from the configuration tree (using
# get_warper_object> and call register() on it.

sub submit_to_warp {
    my $self = shift ;
    my $info = shift ;

    $self->{warper_object} = {} unless defined $self->{warper_object} ;

    my $follow = $info->{follow} ;

    # now, follow is only { w1 => 'warp1', w2 => 'warp2'}
    my @warper_paths = values %$follow ;

    my $multi_follow =  @warper_paths > 1 ? 1 : 0;

    my $rules = $info->{rules}; # array ref

    my %value ;
    my @comp_master ;
    $self->{warp_info} = {
                          value => \%value,
                          rules => $rules,
			  rule_hash => { @$rules } ,
                          computed_master => \@comp_master
                         } ;

    foreach my $warper_name (keys %$follow) {
	my $warper_path = $follow -> {$warper_name} ;
	my $warper = $self->get_warper_object($warper_path,1);

        $logger->debug( ref($self),' ',$self->name,
			" is warped by $warper_name => '$warper_path'\n,",
			"\t$warper_name ($warper_path) location in tree is: '",
			$warper->name,"'");


        # warp will register this value object in another value object
        # (the warper).  When the warper gets a new value, it will
        # modify the warped object according to the data passed by the
        # user.

	my $type = $warper -> register ($self,$warper_name) ;

        # store current warp master value
        if ($type eq 'computed') {
            my @store = ($warper,$warper_name) ;
            weaken ($store[0]) ;
            push @comp_master, \@store ;
	}

	# check if the warp master is available
	my $available 
	  = $warper->parent->is_element_available(name => $warper->element_name,
						  experience => 'master') ;

	if ($available) {
	    # read the warp master values, so I can warp myself just
	    # after.
	    my $warper_value = $warper->fetch('allow_undef');
	    $logger->debug("\t'$warper_name' value is: '", 
			   defined $warper_value ? $warper_value : '<undef>',
			   "'");
	     $value{$warper_name} = $warper_value ;
	}
	else {
	    # consider that the warp master value is undef
	    $value{$warper_name} = undef ;
	    $logger->debug("\t'$warper_name' is not available");
	}
    }

    # now warp myself ...
    $self->_do_warp ;

    return $self ;
}

# Internal. This method will change element properties (like level and
# experience) according to the warp effect.  For instance, if a warp
# rule make a node no longer available in a model, its level must
# change to 'hidden'
sub set_parent_element_property {
    my ($self, $arg_ref) = @_ ;

    foreach my $property_name (qw/level experience/) {
	my $v = delete $arg_ref->{$property_name} ;
	if (defined $v) {
	    $self->{parent}
	      -> set_element_property (
				       property=> $property_name,
				       element => $self->{element_name},
				       value   => $v,
				     );
	}
	else {
	    # reset ensures that property is reset to known state by default
	    $self->{parent}
	      ->reset_element_property(property => $property_name,
				       element  => $self->{element_name});
	}
    }
}

sub set_owner_element_property {
    my $self = shift ;
    my $ref = shift ;

    my $next = $self->{id_owner} || $self ;
    $next -> set_parent_element_property($ref) ;
}

# try to actually warp (change properties) of a warped object.
sub warp {
    my $self = shift;

    confess $self->name," internal error: warp was called before ",
      "submit_to_warp" unless defined $self->{warp_info} ;

    my $warp_value_set = $self->{warp_info}{value} ;
    my %old_value_set  = %$warp_value_set ;

    if (@_) {
        my ($value,$warp_name) = @_ ;
        get_logger("Tree::Element::Warped")
	  ->debug( "Warp called with value '", 
		   defined $value ? $value : '<undef>',
		   "' name $warp_name");
        $warp_value_set->{$warp_name} = $value ;
    }

    # read warp master values that are computed 
    foreach my $cwm (@{$self->{warp_info}{computed_master}}) {
        my ($master,$name) = @$cwm;
        $warp_value_set->{$name} = $master->fetch ;
    }

    # check if new values are different from old values
    my $same = 1 ;
    foreach my $name (keys %$warp_value_set) {
        my $old = $old_value_set   {$name};
        my $new = $warp_value_set->{$name};
        $same = 0 if (defined $old xor defined $new)
	  or (defined $old and defined $new and $new ne $old) ;
    }

    if ($same) {
	no warnings "uninitialized" ;
        get_logger("Tree::Element::Warped")
	  ->debug("Warp skipped because no change in value set ",
		  "(old: '",join("' '", %old_value_set),"' new: '",
		  join("' '",%$warp_value_set),"')");
        return ;
    }

    $self->_do_warp ;
}

# undef values are changed to '' so compute_bool no longer returns
# undef. It returns either 1 or 0
sub compute_bool {
    my $self = shift ;
    my $expr = shift ;

    $logger ->debug("compute_bool: called for '$expr'") ;

    my $warp_value_set = $self->{warp_info}{value}   ;
    $logger ->debug("compute_bool: data:\n", 
		    Data::Dumper->Dump([$warp_value_set],['data']));

    my @init_code ;
    foreach my $warper_name (keys %$warp_value_set) {
	my $v = $warp_value_set->{$warper_name} ;

	my $code_v = (defined $v and $v =~ m/^[\d\.]$/) ? "$v"
	           :  defined $v                        ? "'$v'"
	           :                                      'undef' ;

	push @init_code, "my \$$warper_name = $code_v ;\n" ;
    }

    my $perl_code = join('',@init_code)."\n$expr";

    my $ret;
    {
	no warnings "uninitialized" ;
	$ret = eval($perl_code) ;
    }

    if ($@) {
        Config::Model::Exception::Model
	    -> throw (
		      object => $self ,
		      error => "Warp boolean expression failed:\n$@"
		      . "eval'ed code is: \n$perl_code"
		     ) 
    }

    $logger->debug("compute_bool: eval result: ", ($ret ? 'true' : 'false'));
    return $ret ;
}

sub _do_warp {
    my $self = shift ;
    my $warp_value_set = $self->{warp_info}{value}   ;
    my $rules          = $self->{warp_info}{rules}   ;

    # try all boolean expression with warp_value_set to get the
    # correct rule

    my $found_rule = {};
    my $found_bool ='' ; # this variable may be used later in error message

    foreach my $bool_expr (@$rules) {
	next if ref($bool_expr) ; # it's a rule not a bool expr
	my $res = $self -> compute_bool( $bool_expr );
	next unless $res ;
	$found_bool = $bool_expr ;
	$found_rule = $self->{warp_info}{rule_hash}{$bool_expr} || {};
	$logger->debug("_do_warp found rule for '$bool_expr':\n", 
		       Data::Dumper->Dump ([$found_rule],['found_rule']));
	last;
    }

    if ($logger->is_info) {
        my @warp_str = map { defined $_ ? $_ : 'undef' } keys %$warp_value_set ;

        $logger->info("_do_warp: warp called from '$found_bool' on '",$self->name,
		      "' with elements '",join("','",@warp_str),
		      "', warp rule is ", (scalar %$found_rule ? "" : 'not ') , 
		      "found");
    }

    $logger->debug("warp_them: call set_properties on '",$self->name,"' with ",
	Data::Dumper->Dump ([$found_rule],['found_rule']));

    eval { $self->set_properties(%$found_rule) ; };

    if ($@) {
        my @warp_str = map { defined $_ ? $_ : 'undef' } keys %$warp_value_set ;
	my $e = $@ ;
	my $msg = ref $e ? $e->as_string : $e ;
	Config::Model::Exception::Model
	    -> throw (
		      object => $self,
		      error => "Warp failed when following '" . join("','",@warp_str)
		             . "' from \"$found_bool\". Check model rules:\n\t"
		             . $msg
		     ) ;
    }
}

sub get_master_object {
    my ($self, $master_path, $grab_non_available ) = @_ ;

    $grab_non_available = 0 unless defined $grab_non_available ;

    $logger->debug("Retrieving master object from '", $self->name, 
		   "' with path '$master_path'");

    Config::Model::Exception::Internal
	-> throw (
		  object => $self,
		  error => "get_master_object: parameter must be a string ".
		  "or an array ref"
		 )
	  unless ref $master_path eq 'ARRAY' || not ref $master_path ;

    my $master 
      = eval {$self->grab(step => $master_path, 
			  grab_non_available => $grab_non_available) ;
	    };

    if ($@) {
      my $e = $@ ;
      my $msg = $e ? $e->full_message : '' ;
      Config::Model::Exception::Model
	  -> throw (
		    object => $self,
		    error => "path '$master_path' has error:\n"
		    . $msg
		   ) ;
    }

    Config::Model::Exception::Internal
	-> throw (
		  object =>$self,
		  error => "Could not find master object with '$master_path'"
		 ) unless defined $master ;

    $logger->debug( "Found master object '",$master->name || '???' ,
		    "' with '$master_path' ".
		    "from object '",$self->name , "'");

    return $master ;
}

sub get_warper_object {
    my ($self, $warper_path, $get_non_available) = @_ ;

    my $ref = $self->{warper_object} ;

    $ref->{$warper_path} = $self->get_master_object($warper_path, $get_non_available) ;
    weaken( $ref->{$warper_path} );
    return $ref->{$warper_path} ;
}

sub get_all_warper_object {
    my $self = shift ;
    confess "Internal error: get_all_warper_object called before submit_to_warp"
      unless defined $self->{warper_object} ;

    return values %{$self->{warper_object}} ;
}

sub register_in_other_value {
    my $self = shift;
    my $var = shift ;

    # register compute or refer_to dependency. This info may be used
    # by other tools
    foreach my $path (values %$var) {
        if (ref $path eq 'HASH') {
            # check replace rule
            map {
                Config::Model::Exception::Formula
		    -> throw (
			      error => "replace arg '$_' is not alphanumeric"
			     ) if /\W/ ;
	    }  (%$path) ;
	}
        elsif (defined $path and not ref $path) {
	    # is ref during test case
	    #print "path is '$path'\n";
            next if $path =~ /\$/ ; # next if path also contain a variable
            my $master = $self->get_master_object($path);
            next unless $master->can('register_dependency');
            $master->register_dependency($self) ;
	}
    }
}

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
      if $::debug ;

    return $str ;
}

1;

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

