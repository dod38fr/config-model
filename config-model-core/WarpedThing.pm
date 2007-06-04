# $Author: ddumont $
# $Date: 2007-06-04 11:27:19 $
# $Name: not supported by cvs2svn $
# $Revision: 1.7 $

#    Copyright (c) 2005-2007 Dominique Dumont.
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
use Carp;

use warnings FATAL => qw(all);

use vars qw($VERSION) ;
$VERSION = sprintf "%d.%03d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/;

use base qw/Config::Model::AnyThing/ ;

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

Warping an object means the the properties of the object will be
changed depending on the value of another object.

The changed object is refered as the I<warped> object.

The other object that holds the important value is referred as the
I<warp master> or the I<warper> object.

You can also set up several warp master for one warped object. This
means that the properties of the warped object will be changed
according to a combination of values of the warp master.

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

=head2 Warp rules argument

Hash or array ref that specify the warped object property changes.
These rules specfies the actual property changes for the warped object
depending on the value(s) of the warp master(s). E.g.:

 follow => [ '! macro1' ],
 rules => { A => { <effect for macro1 == A> },
            B => { <effect for macro1 == B> }
          }

In case of similar effects, you can group the rules:

  follow => [ '! macro1' ],
  rules => [ A => { <effect for macro1 == A> },
             ['B','C'] => { <effect for macro1 == B|C > }
           ]


In case of several warp masters, the rules must be an array ref:

 follow => [ '! macro1', '- macro2' ],
 rules => [
           [qw/A C/] => {<effect for macro1 == A and macro2 == C>},
           [qw/A D/] => {<effect for macro1 == A and macro2 == D>},
           [qw/B C/] => {<effect for macro1 == B and macro2 == C>},
           [qw/B D/] => {<effect for macro1 == B and macro2 == D>},
          ]

The C<rules> array structure is the same as the previous example, but
the interpretation is different because C<follow> points to more that
one item.

Of course some combinations of warp master values can have the same
effect:

 follow => [ '! macro1', '- macro2' ],
 rules => [
           [qw/A C/] => {<effect X>},
           [qw/A D/] => {<effect Y>},
           [qw/B C/] => {<effect Y>},
           [qw/B D/] => {<effect Y>},
          ]

In this case, you can use this notation to save typing:

 follow => [ '! macro1', '- macro2' ],
 rules => [
           [ 'A',  'C'      ] => {<effect X>},
           [ 'A',  'D'      ] => {<effect Y>},
           [ 'B', ['C','D'] ] => {<effect Y>},
          ]

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
    my $rules_ref = delete $arg_ref->{rules} ;
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

# $multi_follow $key_rule:               @exp_keys
#     0         'foo'                => ( foo )
#     0         [ 'foo', 'bar' ]     => ( 'foo', 'bar' )
#     1         [ 'foo', 'bar' ]     => ( [ 'foo', 'bar' ] )
#     1         [ [f1 ,f2 ] , bar ]  => ( [f1, bar ], [f2 , bar] )
# return a list of expanded rules from the passed rule.
sub _expand_key {
    my $multi_follow = shift ;

    if ($multi_follow) {
	# deep copy of keys, and store in an array
	my @exp_keys  = ( _dclone_key( shift ) ) ;

	for (my $i = 0; defined $exp_keys[$i]; $i ++) {
	    next unless ref $exp_keys[$i] ;

	    for (my $j = 0; defined $exp_keys[$i][$j]; $j ++) {
		next unless ref $exp_keys[$i][$j];

		my @a = @{$exp_keys[$i][$j]} ;
		$exp_keys[$i][$j] = shift @a ;
		map {
		    my ($b) = _dclone_key($exp_keys[$i] ) ;
		    push @exp_keys , $b ;
		    $b-> [$j] = $_ ;
		} @a ;
	    }
	}

	return @exp_keys ;
    }
    else {
	return map { ref $_ ? @$_ : $_ } @_ ;
    }
}

# internal: used to expand multi warp masters rules

# @rules is either:
# foo => {...} , bar => {...}
# [ f1, b1 ] => {..} ,[ f1,b2 ] => {...}, [f2,b1] => {...} ...
# [ [ f1a, f1b ] , b1 ] => {..} ,[ f1,b2 ] => {...}, ...
sub _expand_rules {
    my $multi_follow = shift ;
    my @rules = @_ ;

    my @expanded ;
    for (my $r_idx = 0; $r_idx < $#rules; $r_idx  += 2) {
	my $key_rule = $rules[$r_idx] ;
	map { push @expanded, $_ =>  $rules[$r_idx+1] } 
	  _expand_key($multi_follow, $key_rule) ;
    }

    return @expanded ;
}


# internal 
# Will get the warp master object from the configuration tree (using
# get_warper_object> and call register() on it.

sub submit_to_warp {
    my $self = shift ;
    my $info = shift ;

    my $follow = $info->{follow} ;
    my @rules  = @{$info->{rules}} ;

    $self->{warper_object} = [] unless defined $self->{warper_object} ;

    # follow is either ['warp1','warp2',...] or 'warp'
    my @warper_items = ref($follow) eq 'ARRAY' ? 
      @$follow : ($follow) ;

    print $self->name,": ",
      Data::Dumper->Dump([\@rules],['warp rules'])
	  if $::debug;

    # Accordingly, @rules is either:
    # [ f1, b1 ] => {..} ,[ f1,b2 ] => {...}, [f2,b1] => {...} ...
    # foo => {...} , bar => {...}

    # if a key of a rule (e.g. f1 or b1) is an array ref, all the
    # values passed in the array are considered as valid.
    # i.e. [ [ f1a, f1b] , b1 ] => { ... }
    # is equivalent to 
    # [ f1a, b1 ] => { ... }, [  f1b , b1 ] => { ... }

    my $multi_follow =  @warper_items > 1 ? 1 : 0;

    # check the number of keys in the @rules set if we have more
    # than one warper_items
    if ( $multi_follow ) {
	for (my $r_idx = 0; $r_idx < $#rules; $r_idx  += 2) {
	    my $key_set = $rules[$r_idx] ;
	    my @keys = ref($key_set) ? @$key_set : ($key_set) ;

	    Config::Model::Exception::Model
		-> throw (
			  object => $self,
			  error => "Warp rule error in object '".$self->name.
			  ": Wrong nb of keys in set '@keys',".
			  " Expected ".scalar @warper_items." keys"
			 ) unless @keys == @warper_items;
	}
    }

    my @expanded = _expand_rules( $multi_follow, @rules ) ;

    my $rules_h = {} ;
    for (my $r_idx = 0; $r_idx < $#expanded; $r_idx  += 2) {
        my $key_set = $expanded[$r_idx] ;
        my @keys = ref($key_set) ? @$key_set : ($key_set) ;

        # construct hash of hash
        my $last_key =  pop @keys ; 

        my $ref = $rules_h ;

        # first create the anonymous hash, then move the ref up
        map {$ref = $ref->{$_} ||= {} ;} @keys ;

	Config::Model::Exception::Model
	    -> throw (
		      object => $self,
		      error => "Warp rule error in object '".$self->name.
		      ": warp effect is clobbered by masters values '".
		      join("', '",@keys)."\n"
		     ) if defined $ref->{$last_key};
        $ref->{$last_key} = $expanded[$r_idx+1] ;
    }

    #print $self->name," rules_h: ", Dumper($rules_h) ;

    my @value = (undef) x scalar @warper_items ;
    my @comp_master ;
    $self->{warp_info} = {
                          value => \@value,
                          rule => $rules_h,
                          computed_master => \@comp_master
                         } ;

    my $idx = 0;
    foreach my $warper_item (@warper_items) {
        print ref($self).' '.$self->name." is warped by '$warper_item'\n"
          if $::debug;

        # warp will register this value object in another value object
        # (the warper).  When the warper gets a new value, it will
        # modify the warped object according to the data passed by the
        # user.

        my $warper = $self->get_warper_object($warper_item,$idx);
        print "\t'$warper_item' location in tree is: '",$warper->name,"'\n"
          if $::debug;

        for (my $r_idx = 0; $r_idx < $#expanded; $r_idx += 2) {
            # check the validity of the warp keys
            my $key_set = $expanded[$r_idx] ;
            my $key = ref($key_set) ? $key_set->[$idx] : $key_set ;
            my $ok = $warper->check_warp_keys($key) ;

            Config::Model::Exception::Model
		-> throw (
			  object => $self,
			  error => "Warp rule error in object '".$self->name.
			  "' warped by '".$warper->name.
			  "':\n\t". $warper->error_msg
			 ) unless $ok;
	}

        # warp_item is used as index so we can identify who is warping
        # us
        my $type = $warper -> register ($self,$idx) ;

        # store current warp master value
        if ($type eq 'computed') {
            my @store = ($warper,$idx) ;
            weaken ($store[0]) ;
            push @comp_master, \@store ;
	}

        # read all the warp master values, so I can warp myself 
        # just after.
        $value[$idx++] = $warper->fetch;
    }

    # now warp myself ...
    $self->_do_warp ;

    return $self ;
}

# Internal. This method will change element proerties (like level and
# permission) according to the warp effect.  For instance, if a warp
# rule make a node no longer available in a model, its level must
# change to 'hidden'
sub set_parent_element_property {
    my $self = shift ;
    my $arg_ref = shift ;

    my $config_class_name = $arg_ref->{config_class_name};
    my $new_permission    = $arg_ref->{permission} ;

    if (not defined $config_class_name) {
        # warp out object
        $self->parent
	  ->set_element_property( property => 'level',
				  element  => $self->{element_name},
				  value    => 'hidden') ;
        delete $self->{data} ;
    } else {
        $self->parent
	  ->reset_element_property(property => 'level',
				   element  => $self->{element_name});
    }

    if (defined $new_permission) {
        $self->parent
	  -> set_element_property(property => 'permission',
				  element  => $self->{element_name},
				  value    => $new_permission) ;
    }
    else {
        $self->parent
	  ->reset_element_property(property => 'permission',
				   element  => $self->{element_name});
    }
}

# try to actually warp (change properties) of a warped object.
sub warp {
    my $self = shift;

    confess $self->name," internal error: warp was called before ",
      "submit_to_warp" unless defined $self->{warp_info} ;

    my $warp_value_set = $self->{warp_info}{value} ;
    my @old_value_set = @$warp_value_set ;

    if (@_) {
        my ($value,$warp_idx) = @_ ;
        print "Warp called with value $value, index $warp_idx\n"
          if $::debug;
        $warp_value_set->[$warp_idx] = $value ;
    }

    # read warp master values that are computed 
    foreach my $cwm (@{$self->{warp_info}{computed_master}}) {
        my ($master,$idx) = @$cwm;
        $warp_value_set->[$idx] = $master->fetch ;
    }

    # check if new values are different from old values
    my $same = 1 ;
    map {
        my $old = $old_value_set[$_];
        my $new = $warp_value_set->[$_] ;
        $same = 0 if (defined $old xor defined $new)
	  or (defined $old and defined $new and $new ne $old) ;
    } (0 .. @old_value_set) ;

    if ($same) {
	no warnings "uninitialized" ;
        print "Warp skipped because no change in value set ",
	  "(old: '",join("' '",@old_value_set),"' new: '",
	    join("' '",@$warp_value_set),"')\n"
	      if $::debug;
        return ;
    }

    $self->_do_warp ;
}

sub _do_warp {
    my $self= shift ;
    my $warp_value_set = $self->{warp_info}{value} ;

    # scan all warp_value_set to get the correct rules
    my $hop = $self->{warp_info}{rule} ;
    foreach my $a_value (@$warp_value_set) {
        unless (defined $a_value) {
            $hop = undef ;
            last ;
	}
        $hop = $hop->{$a_value} ;
        next unless defined $hop ;
    }

    if ($::verbose) {
        my @warp_str = map { defined $_ ? $_ : 'undef' } @$warp_value_set ;

        print "warp called on '",$self->name,
          "' with '",join("','",@warp_str),"', \n",
            "\twarp rule is ", (defined $hop ? "" : 'not ') , "found\n";
    }

    my @set_arg = defined $hop ? %$hop : () ;
    print "warp_them: call set on '",$self->name,"'\n" 
      if $::debug;

    $self->set(@set_arg) ;
}

sub get_master_object {
    my ($self, $master_path) = @_ ;

    print "Retrieving master object from '", $self->name, 
      "' with path '$master_path'\n" if $::debug;

    Config::Model::Exception::Internal
	-> throw (
		  object => $self,
		  error => "get_master_object: parameter must be a string ".
		  "or an array ref"
		 )
	  unless ref $master_path eq 'ARRAY' || not ref $master_path ;

    my $master = $self->grab($master_path);

    Config::Model::Exception::Internal
	-> throw (
		  object =>$self,
		  error => "Could not find master object with '$master_path'"
		 ) unless defined $master ;

    print "Found master object '",$master->name || '???' ,"' with ",
      "'$master_path' ".
        "from object '",$self->name , "'\n"
	  if $::debug ;

    return $master ;
}

sub get_warper_object {
    my ($self, $warper_path,$idx) = @_ ;

    confess "Internal error: get_warper_object called without idx"
      unless defined $idx ;

    my $ref = $self->{warper_object} ;

    # better to cache the warper_object to gain speed and to avoid a
    # strange behavior where the tied object attached to type cannot be
    # found while I'm deep in the STORE call of type
    return $ref->[$idx] if defined $ref->[$idx];

    weaken( $ref->[$idx] = $self->get_master_object($warper_path) ) ;
    return $ref->[$idx] ;
}

sub get_all_warper_object {
    my $self = shift ;
    confess "Internal error: get_all_warper_object called before submit_to_warp"
      unless defined $self->{warper_object} ;

    return @{$self->{warper_object}} ;
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
        elsif (not ref $path) {
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

    # follow is either ['warp1','warp2',...] or 'warp'
    my @warper_items = ref($follow) eq 'ARRAY' ? 
      @$follow : ($follow) ;

    my $str = "You may solve the problem by modifying ".
      (@warper_items>1 ? "one or more of ": '').
        "the following configuration parameters:\n" ;

    for (my $idx = 0; $idx < @warper_items; $idx++) {
        my $warper =$self->get_warper_object($warper_items[$idx],$idx);
        my $warper_value = $warper->fetch ;
        $warper_value = 'undef' unless defined $warper_value ;

        my @choice = defined $warper->choice ? @{$warper->choice} :
            $warper->{value_type} eq 'boolean' ? (0,1) : () ;

        my @try = sort grep { $_ ne $warper_value } @choice ;

        $str .= "\t'".$warper->name. "': Try " ;

        my $a = $warper->{value_type} =~ /^[aeiou]/ ? 'an' : 'a' ;

        $str .= @try ? "'".join ("' or '",@try)."' instead of " :
          "$a $warper->{value_type} value different from " ;

        $str .= "'$warper_value'\n" ;

        if (defined $warper->{compute}) {
            $str .= "\n\tHowever, '".$warper->name. "' ". 
              $warper->compute_info."\n" ;
	}
    }

    $str .= "Warp parameters:\n".Data::Dumper->Dump([$self->{warp}],['warp'])
      if $::debug ;

    return $str ;
}

1;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model::AnyThing>,
L<Config::Model::HashId>,
L<Config::Model::ListId>,
L<Config::Model::WarpedNode>,
L<Config::Model::Value>

=cut

