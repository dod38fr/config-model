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

package Config::Model::Value ;
use warnings ;
use strict;
use Scalar::Util qw(weaken) ;
use Data::Dumper ();
use Config::Model::Exception ;
use Config::Model::ValueComputer ;
use Config::Model::IdElementReference ;
use Log::Log4perl qw(get_logger :levels);
use Carp ;

use base qw/Config::Model::WarpedThing/ ;

# use vars qw($VERSION) ;


my $logger = get_logger("Tree::Element::Value") ;

=head1 NAME

Config::Model::Value - Strongly typed configuration value

=head1 SYNOPSIS

 my $model = Config::Model->new() ;
 $model ->create_config_class 
  (
   name => "SomeClass",
   element => [
     country => { 
       type =>       'leaf',
       value_type => 'enum',
       choice =>      [qw/France US/]
     },
     president => { 
       type =>        'leaf',
       value_type => 'string',
       warp => { 
         follow => { c => '- country'}, 
         rules  => {
           '$c eq "France"' => { default => 'Chirac' },
           '$c eq "US"'     => { default => 'Bush' }
         }
       },
     }
   ]
 );


=head1 DESCRIPTION

This class provides a way to specify configuration value with the
following properties:

=over

=item *

Strongly typed scalar: the value can either be an enumerated type, a boolean,
a number, an integer or a string

=item *

default parameter: a value can have a default value specified during
the construction. This default value will be written in the target
configuration file. (C<default> parameter)

=item *

upstream default parameter: specifies a default value that will be
used by the application when no information is provided in the
configuration file. This upstream_default value will not written in
the configuration files. Only the C<fetch_standard> method will return
the builtin value. This parameter was previously refered as
C<built_in> value. This may be used for audit
purpose. (C<upstream_default> parameter)

=item *

mandatory value: reading a mandatory value will raise an exception if the
value is not specified and has no default value.

=item *

dynamic change of property: A slave value can be registered to another
master value so that the properties of the slave value can change
according to the value of the master value. For instance, paper size value
can be 'letter' for country 'US' and 'A4' for country 'France'.

=item *

A reference to the Id of a hash of list element. In other word, the
value is an enumerated type where the possible values (choice) is
defined by the existing keys of a has element somewhere in the tree. See
L</"Value Reference">.

=back

=head1 Default values

There are several kind of default values. They depend on where these
values are defined (or found).

From the lowest default level to the "highest":

=over

=item *

C<upstream_default>: The value is knows in the application, but is not
written in the configuration file.

=item *

C<default>: The value is known by the model, but not by the
application. This value must be written in the configuration file.

=item *

C<computed>: The value is computed from other configuration
elements. This value must be written in the configuration file.


=item *

C<preset>: The value is not known by the model or by the
application. But it can be found by an automatic program and stored
while the configuration L<Config::Model::Instance|instance> is in 
L<Config::Model::Instance/"preset_start ()"|preset mode>

=back

Then there is the value entered by the user. This will override all
kind of "default" value.

The L<fetch_standard> function will return the "highest" level of
default value, but will not return a custom value, i.e. a value
entered by the user.

=head1 Constructor

Value object should not be created directly.

=head1 Value model declaration

A leaf element must be declared with the following parameters:

=over

=item value_type

Either C<boolean>, C<enum>, C<integer>, C<number>,
C<uniline>, C<string>. Mandatory. See L</"Value types">.

=item default

Specify the default value (optional)

=item upstream_default

Specify a built in default value (optional)

=cut

# internal method
sub set_default {
    my ($self,$arg_ref) = @_ ;

    if (exists $arg_ref->{built_in}) {
      $arg_ref->{upstream_default} = delete $arg_ref->{built_in};
      warn $self->name," warning: deprecated built_in parameter, ",
	"use upstream_default\n";
    }

    if (    defined $arg_ref->{default} 
	and defined $arg_ref->{upstream_default}
       ) {
	Config::Model::Exception::Model
	    -> throw (
		      object => $self,
		      error => "Cannot specify both 'upstream_default' and "
		      ."'default' parameters",
		     ) 
    }

    foreach my $item (qw/upstream_default default/) {
	my $def    = delete $arg_ref->{$item} ;

	next unless defined $def ;

	# will check default value
	my $ok = $self->check($def,0) ;
	Config::Model::Exception::Model
	    -> throw (
		      object => $self,
		      error => "Wrong $item value\n\t".
		      join("\n\t",@{$self->{error}})
		     ) 
	      unless $ok ;

	$logger
	  ->debug("Set $item value for ",$self->name,"") ;

	$self->{$item} = $def ;
    }
}

=item compute

Will compute a value according to a formula and other values. By default
a computed value cannot be set. See L<Config::Model::ValueComputer> for 
computed value declaration.

=cut

sub set_compute {
    my ($self, $arg_ref) = @_ ;

    my $c_ref = delete $arg_ref->{compute};

    $self->{allow_compute_override} = delete $c_ref->{allow_override}
      if defined $c_ref->{allow_override} ;

    if (ref($c_ref) eq 'HASH') {
	$self->{compute} = $c_ref ;
    }
    else {
	Config::Model::Exception::Model
	    -> throw (
		      object => $self,
		      error => "Compute value must be a hash ref not $c_ref"
		     ) ;
    }

    foreach my $item (qw/formula/) {
	next if defined $self->{compute}{$item} ;
	Config::Model::Exception::Model
	    -> throw (
		      object => $self,
		      error => "Missing compute $item"
		     ) ;
    }

    delete $self->{_compute} ;
}

# set up relation between objects required by the compute constructor
# parameters
sub submit_to_compute {
    my $self = shift ;

    my $c_info = $self->{compute} ;
    $self->{_compute} = Config::Model::ValueComputer
      -> new (
	      formula      => $c_info->{formula} ,
	      variables    => $c_info->{variables} ,
	      replace      => $c_info->{replace},
	      value_object => $self ,
	      value_type   => $self->{value_type},
	      use_eval     => $c_info->{use_eval},
	     );

    # resolve any recursive variables before registration
    my $v = $self->{_compute}->compute_variables ;

    $self->register_in_other_value( $v ) ;
}


# internal
sub compute {
    my $self = shift ;

    $self->submit_to_compute unless defined $self->{_compute} ;

    confess unless ref($self->{_compute}) eq 'Config::Model::ValueComputer' ;

    my $result = $self->{_compute} -> compute ;

    #print "compute: result $result\n" ;
    # check if the computed result fits with the constraints of the
    # Value object
    my $ok = $self->check($result) ;

    #print "check result: $ok\n";
    if (not $ok) {
        my $error =  join("\n\t",@{$self->{error}}) .
          "\n\t".$self->compute_info;

        Config::Model::Exception::WrongValue
	    -> throw (
		      object => $self,
		      error => "computed value error:\n\t". $error 
		     );
    }

    return $ok ? $result : undef ;
}

# internal, used to generate error messages
sub compute_info {
    my $self = shift;
    $self->{_compute} -> compute_info ;
}

=item migrate_from

This is a special parameter to cater for smooth configuration
upgrade. This parameter can be used to copy the value of a deprecated
parameter to its replacement. See L<"/upgrade"> for details.

=cut

sub set_migrate_from {
    my ($self, $arg_ref) = @_ ;

    my $mig_ref = delete $arg_ref->{migrate_from};

    if (ref($mig_ref) eq 'HASH') {
	$self->{migrate_from} = $mig_ref ;
    }
    else {
	Config::Model::Exception::Model
	    -> throw (
		      object => $self,
		      error => "migrate_from value must be a hash ref not $mig_ref"
		     ) ;
    }

    $self->{_migrate_from} = Config::Model::ValueComputer
      -> new (
	      formula      => $mig_ref->{formula} ,
	      variables    => $mig_ref->{variables} ,
	      replace      => $mig_ref->{replace},
	      use_eval     => $mig_ref->{use_eval},
	      value_object => $self ,
	      value_type   => $self->{value_type}
	     );

    # resolve any recursive variables before registration
    $self->{instance}->push_no_value_check('fetch') ;
    my $v = $self->{_migrate_from}->compute_variables ;
    $self->{instance}->pop_no_value_check ;
}

# FIXME: should it be used only once ???
sub migrate_value {
    my $self = shift ;

    my $i = $self->instance;

    # avoid warning when reading deprecated values
    $i->push_no_value_check('fetch') ;
    my $result = $self->{_migrate_from} -> compute ;
    $i ->pop_no_value_check ;

    # check if the migrated result fits with the constraints of the
    # Value object
    my $ok = $self->check_value($result) ;

    #print "check result: $ok\n";
    if (not $ok) {
        my $error =  join("\n\t",@{$self->{error}}) .
          "\n\t".$self->{_migrate_from}->compute_info;

        Config::Model::Exception::WrongValue
	    -> throw (
		      object => $self,
		      error => "migrated value error:\n\t". $error 
		     );
    }

    return $ok ? $result : undef ;
}

=item convert => [uc | lc ]

When stored, the value will be converted to uppercase (uc) or
lowercase (lc).

=cut

sub set_convert {
    my ($self, $arg_ref) = @_ ;

    my $convert = delete $arg_ref->{convert} ;
    # convert_sub keeps a subroutine reference
    $self->{convert_sub} = $convert eq 'uc' ? sub {uc(shift)} :
      $convert eq 'lc' ? sub {lc(shift)} : undef;

    Config::Model::Exception::Model
	-> throw (
		  object => $self,
		  error => "Unexpected convert value: $convert, "
		  ."expected lc or uc"
		 ) 
	  unless defined $self->{convert_sub};
}

=item min

Specify the minimum value (optional, only for integer, number)

=item max

Specify the maximum value (optional, only for integer, number)

=item mandatory

Set to 1 if the configuration value B<must> be set by the
configuration user (default: 0)

=item choice

Array ref of the possible value of an enum. Example :

 choice => [ qw/foo bar/]

=cut

sub setup_enum_choice {
    my $self = shift ;

    my @choice = ref $_[0] ? @{$_[0]} : @_ ;

    $logger
      ->debug($self->name, " setup_enum_choice with '",join("','",@choice));

    $self->{choice}  = \@choice ;

    # store all enum values in a hash. This way, checking
    # whether a value is present in the enum set is easier
    delete $self->{choice_hash} if defined $self->{choice_hash} ;

    map {$self->{choice_hash}{$_} =  1;} @choice ;

    # delete the current value if it does not fit in the new
    # choice
    map {
	delete $self->{$_}
	  if (defined  $self->{$_} and not $self->check($self->{$_},1)) ;
    } qw/data preset/;
}

=item match

Perl regular expression. The value will be match with the regex to
assert its validity. Example C<< match => '^foo' >> means that the
parameter value must begin with "foo". Valid only for C<string> or
C<uniline> values.

=cut

sub setup_match_regexp {
    my ($self,$ref) = @_ ;

    my $str = $self->{match} = delete $ref->{match} ;
    return unless defined $str ;
    my $vt = $self->{value_type} ; 

    if ($vt ne 'uniline' and $vt ne 'string') {
	Config::Model::Exception::Model
		-> throw (
			  object => $self,
			  error => "Can't use match regexp with $vt, "
			         . "expected 'uniline' or 'string'"
			 ) ;
    }

    $logger -> debug($self->name, " setup_match_regexp with '$str'");
    $self->{regexp} = eval { qr/$str/ ;} ;

    if ($@) {
	Config::Model::Exception::Model
		-> throw (
			  object => $self,
			  error => "Unvalid match regexp for '$str': $@"
			 ) ;
    }
}

=item replace

Hash ref. Used for enum to substitute one value with another. This
parameter must be used to enable user to upgrade a configuration with
obsolete values. For instance, if the value C<foo> is obsolete and
replaced by C<foo_better>, you will need to declare:

  replace => { foo => 'foo_better' }

=item refer_to

Specify a path to an id element used as a reference. See L<Value
Reference> for details.

=item computed_refer_to

Specify a pathto an id element used as a computed reference. See
L<Value Reference> for details.

=item warp

See section below: L</"Warp: dynamic value configuration">.

=item help

You may provide detailed description on possible values with a hash
ref. Example:

 help => { oui => "French for 'yes'", non => "French for 'no'"}

=back

=cut


my @warp_accessible_params =  qw/min max mandatory default 
				 choice convert upstream_default replace match/ ;

my @accessible_params =  (@warp_accessible_params, 
			  qw/index_value element_name value_type
			     refer_to computed_refer_to/ ) ;

my @allowed_warp_params = (@warp_accessible_params, qw/level experience help/);

sub new {
    my $type = shift;
    my %args = @_ ;

    my $self={} ;
    bless $self,$type;

    $self->{mandatory} = $self->{allow_compute_override} = 0 ;

    $self->{element_name} = delete $args{element_name} 
      || croak "Value new: no 'element_name' defined" ;
    $self->{index_value} = delete $args{index_value} ; 
    $self->{id_owner}    = delete $args{id_owner} ; 

    $self->_set_parent(delete $args{parent}) ;

    $self->{instance} = delete $args{instance} 
      || croak "Value: missing 'instance' parameter" ;

    # refer_to cannot be warped because of registration
    $self->{refer_to} = delete $args{refer_to};
    $self->{computed_refer_to} = delete $args{computed_refer_to};

    Config::Model::Exception::Model
	-> throw (
		  error=> "$type creation error: missing value_type or "
		  ."warp parameter",
		  object => $self
		 ) 
	  unless (   defined $args{value_type} 
		  or defined $args{warp});

    Config::Model::Exception::Model
	-> throw (
		  error=> "$type creation error: "
		  ."compute value must be a hash ref",
		  object => $self
		 ) 
	  if (defined $args{compute} and ref($args{compute}) ne 'HASH') ;

    my $warp_info = delete $args{warp} ;

    $self->{backup}  = \%args ;

    $self->set_properties() ; # set will use backup data


    if (defined $warp_info) {
	$self->check_warp_args( \@allowed_warp_params, $warp_info) ;
    }

    $self->submit_to_warp($self->{warp}) if $self->{warp} ;

    $self->_init ;

    return $self ;
}

# warning : call to 'set' are not cumulative. Default value are always
# restored. Lest keeping track of what was modified with 'set' is
# too confusing.
sub set_properties {
    my $self = shift ;

    # cleanup all parameters that are handled by warp
    map(delete $self->{$_}, @allowed_warp_params ) ;

    # merge data passed to the constructor with data passed to set_properties
    my %args = (%{$self->{backup}},@_ );

    my $logger = $logger ;
    if ($logger->is_debug) {
	$logger->debug("Leaf '".$self->name."' set_properties called with '",
		       join("','",sort keys %args),"'");
    }

    # this code may be dead as warping value_type is no longer
    # authorized. But we keep it in case this has to be authorized
    # again.
    if ( not          defined $args{value_type} 
	 or (         defined $args{value_type} 
	      and     $args{value_type} eq 'enum'
	      and not defined $args{choice}
	    )
       ) {
	$args{level} = 'hidden';
	$self->set_owner_element_property ( \%args );
	return ;
    }

    $self->set_owner_element_property ( \%args );

    if ($args{value_type} eq 'reference' and not defined $self->{refer_to}
	and not defined $self->{computed_refer_to}
       ) {
	Config::Model::Exception::Model
	    -> throw (
		      object => $self,
		      error => "Missing 'refer_to' or 'computed_refer_to' "
		             . "parameter with 'reference' value_type "
		     ) 
	};


    map { $self->{$_} =  delete $args{$_} if defined $args{$_} }
      qw/min max mandatory replace/;

    $self->set_help           ( \%args );
    $self->set_value_type     ( \%args );
    $self->set_default        ( \%args );
    $self->set_compute        ( \%args ) if defined $args{compute};
    $self->set_convert        ( \%args ) if defined $args{convert};
    $self->setup_match_regexp ( \%args ) if defined $args{match};

    # cannot be warped
    $self->set_migrate_from   ( \%args ) if defined $args{migrate_from};

    Config::Model::Exception::Model
	-> throw (
		  object => $self,
		  error => "Unexpected parameters :".join(' ', keys %args )
		 ) 
	  if scalar keys %args ;

    if (defined $self->{warp_these_objects}) {
        my $value = $self->_fetch_no_check ;
        $self->warp_them($value)  ;
    }

    return $self; 
}

# simple but may be overridden
sub set_help {
    my ($self,$args) = @_ ;
    return unless defined $args->{help} ;
    $self->{help} =  delete $args->{help};
}

=head2 Value types

This modules can check several value types:

=over

=item C<boolean>

Accepts values C<1> or C<0>, C<yes> or C<no>, C<true> or C<false>. The
value read back is always C<1> or C<0>.

=item C<enum>

Enum choices must be specified by the C<choice> parameter.

=item C<integer>

Enable positive or negative integer

=item C<number>

The value can be a decimal number

=item C<uniline>

A one line string. I.e without "\n" in it.

=item C<string>

Actually, no check is performed with this type.

=item C<reference>

Like an C<enum> where the possible values (aka choice) is defined by
another location if the configuration tree. See L</Value Reference>.

=back

=cut

sub set_value_type {
    my ($self, $arg_ref) = @_ ;

    my $value_type = delete $arg_ref->{value_type};

    Config::Model::Exception::Model
	-> throw (
		  object => $self,
		  error => "Value set: undefined value_type"
		 ) 
	  unless defined $value_type ;

    $self->{value_type} = $value_type ;

    if ($value_type eq 'boolean') {
        # convert any value to boolean
        $self->{data} = $self->{data} ? 1 : 0 if defined $self->{data};
        $self->{preset} = $self->{preset} ? 1 : 0 if defined $self->{preset};
    }
    elsif (   $value_type eq 'reference' 
	   or $value_type eq 'enum' 
	  ) {
        my $choice = delete $arg_ref->{choice} ;
        $self->setup_enum_choice($choice) if defined $choice ;
    }
    elsif (   $value_type eq 'string' 
	   or $value_type eq 'integer' 
	   or $value_type eq 'number'
	   or $value_type eq 'uniline'
	  ) {
        Config::Model::Exception::Model
	    -> throw (
		      object => $self,
		      error => "'choice' parameter forbidden with type "
		      . $value_type
		     ) 
	      if defined $arg_ref->{choice};
    }
    else {
	my $msg = "Unexpected value type : '$value_type' ".
	  "expected 'boolean', 'enum', 'uniline', 'string' or 'integer'."
	    ."Value type can also be set up with a warp relation" ;
        Config::Model::Exception::Model
	    -> throw (object => $self, error => $msg) 
	      unless defined $self->{warp};
    }
}

=head1 Warp: dynamic value configuration

The Warp functionality enable a C<Value> object to change its
properties (i.e. default value or its type) dynamically according to
the value of another C<Value> object locate elsewhere in the
configuration tree. (See L<Config::Model::WarpedThing> for an
explanation on warp mechanism).

For instance if you declare 2 C<Value> element this way:

 $model ->create_config_class (
   name => "TV_config_class",
   element => [
     country => {
       type => 'leaf',
       value_type => 'enum', 
       choice => [qw/US Europe Japan/]
     },
     tv_standard => {
       type => 'leaf',
       value_type => 'enum',
       choice => [qw/PAL NTSC SECAM/]  
       warp => { 
         follow => { c => '- country' }, # this points to the warp master
         rules => { 
           '$c eq "US"'     => { default => 'NTSC'  },
           '$c eq "France"' => { default => 'SECAM' },
           '$c eq "Japan"'  => { default => 'NTSC'  },
           '$c eq "Europe"' => { default => 'PAL'   },
         }
       }
     },
   ]
 );

Setting C<country> element to C<US> will mean that C<tv_standard> has
a default value set to C<NTSC> by the warp mechanism.

Likewise, the warp mechanism enables you to dynamically change the
possible values of an enum element:

 state => {
      type => 'leaf',
      value_type => 'enum', # example is admittedly silly
      warp =>{ 
         follow => { c => '- country' },
         rules => { 
           '$c eq "US"'     => { choice => ['Kansas', 'Texas'    ]},
           '$c eq "Europe"' => { choice => ['France', 'Spain'    ]},
           '$c eq "Japan"'  => { choice => ['Honshu', 'Hokkaido' ]}
         }
      }
   }

=cut

# Now I'm a warper !
sub register
  {
    my ($self, $warped, $w_idx) = @_ ;

    # weaken only applies to the passed reference, and there's no way
    # to duplicate a weak ref. Only a strong ref is created. See
    #  qw(weaken) module for weaken()
    my @tmp = ($warped, $w_idx) ;
    weaken ($tmp[0]) ;
    push @{$self->{warp_these_objects}} , \@tmp ;

    return defined $self->{compute} ? 'computed' : 'regular' ;
  }

sub check_warp_keys
  {
    my ($self, @warp_keys) = @_ ;

    # check the warping rules keys (which must be valid values for
    # this object) (cannot check rules if we are also warped by
    # another object ...
    return 1 if defined $self->{warp} ;

    my $ok =1 ;

    map { $ok = 0 unless $self->check($_) ; } @warp_keys ;

    return $ok ;
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
        get_logger("Tree::Element::Warper")
	  ->debug("warp_them: (value ", (defined $value ? $value : 'undefined'),
		  ") warping '",$warped->name );
        $warped->warp($value,$warp_index) ;
      }
  }


=head2 Cascaded warping

Warping value can be cascaded: C<A> can be warped by C<B> which can be
warped by C<C>. But this feature should be avoided since it can lead
to a model very hard to debug. Bear in mind that:

=over

=item *

Warp loop are not detected and will end up in "deep recursion
subroutine" failures.

=item *

If you declare "diamond" shaped warp dependencies, the results will
depend on the order of the warp algorithm and can be unpredictable.

=item *

The keys declared in the warp rules (C<US>, C<Europe> and C<Japan> in
the example above) cannot be checked at start time against the warp
master C<Value>. So a wrong warp rule key will be silently ignored
during start up and will fail at run time.

=back

=head1 Value Reference

To set up an enumerated value where the possible choice depends on the
key of a L<Config::Model::AnyId> object, you must:

=over

=item * 

Set C<value_type> to C<reference>.

=item *

Specify the C<refer_to> or C<computed_refer_to> parameter. 
See L<refer_to parameter|Config::Model::IdElementReference/"Config class parameters">.

=back

In this case, a C<IdElementReference> object is created to handle the
relation between this value object and the refered Id. See
L<Config::Model::IdElementReference> for details.

=cut

sub submit_to_refer_to {
    my $self = shift ;

    if (defined $self->{refer_to}) {
	$self->{ref_object} = Config::Model::IdElementReference 
	  -> new ( refer_to   => $self->{refer_to} ,
		   config_elt => $self,
		 ) ;
    }
    elsif (defined $self->{computed_refer_to}) {
	$self->{ref_object} = Config::Model::IdElementReference 
	  -> new ( computed_refer_to => $self->{computed_refer_to} ,
		   config_elt => $self,
		 ) ;
	# refer_to registration is done for all element that are used as
	# variable for complex reference (ie '- $foo' , {foo => '- bar'} )
	$self->register_in_other_value($self->{computed_refer_to}{variables}) ;
    }
    else {
	croak "value's submit_to_refer_to: undefined refer_to or computed_refer_to" ;
    }
}

sub setup_reference_choice {
    my $self = shift ;
    $self->setup_enum_choice(@_) ;
}

sub reference_object {
    my $self = shift ;
    return $self->{ref_object} ;
}

=head1 Introspection methods

The following methods returns the current value of the parameter of
the value object (as declared in the model unless they were warped):

=over

=item min 

=item max 

=item mandatory 

=item choice

=item convert

=item value_type 

=item default 

=item upstream_default

=item index_value

=item element_name

=back


=cut

# accessor to get some fields through methods (See man perltootc)
foreach my $datum (@accessible_params) {
    next if $datum eq 'index_value' ; #provided by AnyThing
    no strict "refs";       # to register new methods in package
    *$datum = sub {
	my $self= shift;
	return $self->{$datum};
    } ;
}

sub built_in { 
  carp "warning: built_in sub is deprecated, use upstream_default";
  goto &upstream_default ;
}

=head2 name()

Returns the object name. 

=cut

## FIXME::what about id ??
sub name {
    my $self = shift ;
    my $name =  $self->{parent}->name . ' '.$self->{element_name} ;
    $name .= ':'.$self->{index_value} if defined $self->{index_value} ;
    return $name ;
}

=head2 get_type

Returns C<leaf>.

=cut

sub get_type {
    return 'leaf' ;
}

sub get_cargo_type {
    return 'leaf' ;
}

=head2 can_store()

Returns true if the value object can be assigned to. Return 0 for a
read-only value (i.e. a computed value with no override allowed).

=cut

sub can_store {
    my $self= shift;

    return not defined $self->{compute} || $self->{allow_compute_override} ;
}

=head2 get_choice()

Query legal values (only for enum types). Return an array (possibly
empty).

=cut

sub get_default_choice {
    goto &get_choice ;
}

sub get_choice {
    my $self = shift ;

    return @{$self->{choice} || [] } ;
}

=head2 get_help ( [ on_value ] )

Returns the help strings passed to the constructor.

With C<on_value> parameter, returns the help string dedicated to the
passed value or undef.

Without parameter returns a hash ref that contains all the help strings.

=cut

sub get_help {
    my $self= shift;

    my $help = $self->{help} ;

    return $help unless @_ ;

    my $on_value = shift ;
    return $help->{$on_value} if defined $help and defined $on_value ;

    return ;
}

# internal
sub error_msg {
    return join("\n\t",@{ shift ->{error}}) ;
}

# construct an error message for enum types
sub enum_error {
    my ($self,$value) = @_ ;
    my @error ;

    if (not defined $self->{choice}) {
        push @error,"$self->{value_type} type has no defined choice",
          $self->warp_error;
        return @error ;
    }

    my @choice = map( "'$_'", $self->get_choice);
    my $var = $self->{value_type} ;
    push @error, "$self->{value_type} type does not know '$value'. Expected ".
      join(" or ",@choice) ; 
    push @error, "Expected list is given by '".
      join("', '", @{$self->{refered_to_path}})."'" 
	if $var eq 'reference' && defined $self->{refered_to_path};
    push @error, $self->warp_error if $self->{warp};

    return @error ;
}

=head2 check_value ( value , [ 0 | 1 ] )

Check the consistency of the value. Does not check for undefined
mandatory values.

When the 2nd parameter is non null, check will not try to get extra
information from the tree. This is required in some cases to avoid
loops in check, get_info, get_warp_info, re-check ...

In scalar context, return 0 or 1.

In array context, return an empty array when no error was found. In
case of errors, returns an array of error strings that should be shown
to the user.

=cut

sub check_value {
    my ($self,$value,$quiet) = @_ ;

    $quiet = 0 unless defined $quiet ;

    my @error  ;

    if ( $self->{hidden}) {
        push @error, "value is hidden" ;
    }
    elsif (not defined $value) {
	# accept with no other check
    }
    elsif (not defined $self->{value_type} ) {
	push @error,"Undefined value_type" ;
    }
    elsif ( ($self->{value_type} =~ /integer/ and $value =~ /^-?\d+$/) 
	    or
	    ($self->{value_type} =~ /number/  and $value =~ /^-?\d+(\.\d+)?$/)
	  ) {
        # correct number or integer. check min max 
        push @error,"value $value > max limit $self->{max}"
            if defined $self->{max} and $value > $self->{max};
        push @error,"value $value < min limit $self->{min}"
            if defined $self->{min} and $value < $self->{min};
    }
    elsif ($self->{value_type} =~ /integer/ and $value =~ /^-?\d+(\.\d+)?$/) {
        push @error,"Type $self->{value_type}: value $value is a number ".
	  "but not an integer";
    }
    elsif (   $self->{value_type} eq 'enum' 
	   or $self->{value_type} eq 'reference'
	  ) {
        push @error, ($quiet ? 'enum error' : $self->enum_error($value))
          unless defined $self->{choice_hash} and 
            defined $self->{choice_hash}{$value} ;
    }
    elsif ($self->{value_type} eq 'boolean') {
        push @error, "boolean error: $value' is not '1' or '0'" 
          unless $value =~ /^[01]$/ ;
    }
    elsif (   $self->{value_type} =~ /integer/ 
	   or $self->{value_type} =~ /number/
	  ) {
        push @error,"Value '$value' is not of type ". $self->{value_type};
    }
    elsif ($self->{value_type} eq 'uniline') {
	push @error,'"uniline" value must not contain embedded newlines (\n)'
	  if $value =~ /\n/;
    }
    elsif ($self->{value_type} eq 'string') {
        # accepted, no more check
    }
    else {
	my $choice_msg = '';
	$choice_msg .= ", choice ". join(" ",$self->get_choice).")"
	    if defined $self->{choice};

	my $msg = "Cannot check value_type '".
	    $self->{value_type}. "' (value '$value'$choice_msg)";
        Config::Model::Exception::Model 
	    -> throw (object => $self, message => $msg) ;
    }

    if (defined $self->{regexp} and defined $value) {
	push @error,"value '$value' does not match regexp "
	    .$self->{match} 
		unless $value =~ $self->{regexp} ;
    }

    $self->{error} = \@error ;
    return wantarray ? @error : not scalar @error ;
}

=head2 check( value , [ 0 | 1 ] )

Like L</check_value>. Also ensure that mandatory value are defined

=cut

sub check {
    my ($self,$value,$quiet) = @_ ;

    $quiet = 0 unless defined $quiet ;

    my @error = $self->check_value($value,$quiet) ;

    if (not $self->{hidden} and not defined $value and $self->{mandatory}) {
        push @error, "Mandatory value is not defined" ;
    }

    $self->{error} = \@error ;
    return wantarray ? @error : not scalar @error ;
}


=head1 Information management

=head2 store( value )

Store value in leaf element.

=cut

sub store {
    my $self = shift ;

    my ($ok,$value) = $self->pre_store(@_) ;

    if ($ok) {
	if ($self->instance->preset) {
	    $self->{preset} = $value ;
	} 
	else {
	    $self->{data} = $value ; # may be undef
	}
    }
    elsif ($self->instance->get_value_check('store')) {
        Config::Model::Exception::WrongValue 
	    -> throw ( error => join("\n\t",@{$self->{error}}),
		       object => $self) ;
    }

    return $value;
}

# internal. return ( 1|0, value)
# May return an undef value if actual store should be skipped
sub pre_store {
    my ($self,$value) = @_ ;

    my $inst = $self->instance ;

    $self->warp 
      if ($self->{warp} and defined $self->{warp_info} and @{$self->{warp_info}{computed_master}});

    if (defined $self->{compute} 
	and not $self->{allow_compute_override}) {
	my $msg = 'assignment to a computed value is forbidden unless '
	  .'compute -> allow_override is set.' ;
	Config::Model::Exception::Model
	    -> throw (object => $self, message => $msg) 
	      if $inst->get_value_check('store') ;
        return 1 ; # ok, but don't store a value
    }

    if (defined $self->{refer_to} or defined $self->{computed_refer_to}) {
	$self->{ref_object}->get_choice_from_refered_to ;
    }

    # check if the object was initialized
    if (not defined $self->{value_type}) {
        $self->_value_type_error if ($self->instance->get_value_check('fetch_and_store') 
				     and $inst->get_value_check('type')) ;
	return 0 ;
    }

    if ($self->{value_type} eq 'boolean' and defined $value) {
        # convert yes no to 1 or 0 
        $value = 1 if ($value =~ /^y/i or $value =~ /true/i) ;
        $value = 0 if ($value =~ /^n/i or $value =~ /false/i );
    }

    $value = $self->{convert_sub}($value) 
      if (defined $self->{convert_sub} and defined $value) ;

    $value = $self->{replace}{$value} 
      if defined $self->{replace} and defined $self->{replace}{$value} ;

    my $ok = $self->store_check($value) ;

    if (     $ok 
	 and defined $value 
	 and defined $self->{warp_these_objects}
       ) {
	my $current = $self->_fetch_no_check ;
	if (      not defined $current 
	       or $value ne $current
	   ) {
	    $self->warp_them($value) ;
	}
    }

    return ($ok,$value);
}

# dummy routine to enable special store check in inherited classes
sub store_check {
    goto &check ;
}

# print a hopefully helpful error message when value_type is not
# defined
sub _value_type_error {
    my $self = shift ;

    Config::Model::Exception::Model
	-> throw (
		  object => $self,
		  message => 'value_type is undefined' 
		 ) 
	  unless defined $self->{warp};

    my $str = "Item ".$self->{element_name}. 
      " is not available. ". $self->warp_error ;

    Config::Model::Exception::User
	-> throw (
		  object => $self,
		  message => $str
		 ) ;
}

=head2 load_data( scalar_value )

Load scalar data. Data is simply forwarded to L<store>.

=cut

sub load_data {
    my $self = shift ;
    my $data  = shift ;

    if (ref $data) {
	Config::Model::Exception::LoadData
	    -> throw (
		      object => $self,
		      message => "load_data called with non scalar arg",
		      wrong_data => $data,
		     ) ;
    }
    else {
	if ($logger->is_info) {
	    $logger->info("Value load_data (",$self->location,") will store value $data");
	}
	$self->store($data) ;
    }
}


=head2 fetch_custom

Returns the stored value if this value is different from a standard
setting or built in seting. In other words, returns undef if the
stored value is identical to the default value or the computed value
or the built in value.

=cut

sub fetch_custom {
    my $self = shift ;
    my $std_value = $self->fetch_standard ;

    no warnings "uninitialized" ;
    my $data = $self->_fetch_no_check ;

    return ($data ne $std_value) ? $data : undef ;
}

=head2 fetch_standard

Returns the standard value as defined by the configuration model. The
standard value can be either a preset value, a computed value, a
default value or a built-in default value.

=cut

sub fetch_standard {
    my $self = shift ;
    my $pre_fetch = $self->_pre_fetch ;
    return defined $pre_fetch ? $pre_fetch : $self->{upstream_default} ;
}

sub _init {
    my $self = shift ;

    $self->warp 
      if ($self->{warp} and defined $self->{warp_info} 
          and @{$self->{warp_info}{computed_master}});

    if (defined $self->{refer_to} or defined $self->{computed_refer_to}) {
	$self->submit_to_refer_to ;
	$self->{ref_object}->get_choice_from_refered_to ;
    }
}

sub _pre_fetch {
    my $self = shift ;

    $self->_init ;

    my $inst = $self->instance ;

    if (     not defined $self->{value_type} 
	 and $inst->get_value_check('type')
       ) {
        $self->_value_type_error ;
    }

    # get stored value or computed value or default value
    my $std_value ;

    eval {
	$std_value 
	  = defined $self->{preset}        ? $self->{preset}
          : defined $self->{compute}       ? $self->compute 
          :                                  $self->{default} ;
    };

    my $e ;
    if ($e = Exception::Class->caught('Config::Model::Exception::User')) { 
	if ($self->instance->get_value_check('fetch')) {
	    $e->throw ; 
	}
	$std_value = undef ;
    }
    elsif ($e = Exception::Class->caught()) {
	$e->rethrow;
    } 

    return $std_value ;
}

=head2 fetch_no_check

Fetch value from leaf element without checking the value.

=cut

my %old_mode = ( built_in => 'upstream_default',
		 non_built_in => 'non_upstream_default',
	       );

my %accept_mode = map { ( $_ => 1) } 
                      qw/custom standard preset default upstream_default
			non_upstream_default allow_undef/;

sub fetch_no_check {
    my $self = shift ;
    my $mode = shift || '';

    # always call to perform submit_to_warp
    my $std = $self->_pre_fetch ;
    my $data = $self->{data} ;

    if (not defined $data and defined $self->{_migrate_from}) {
	$data =  $self->migrate_value ;
    }

    foreach my $k (keys %old_mode) {
	next unless $mode eq $k;
	$mode = $old_mode{$k} ;
	carp $self->location," warning: deprecated mode parameter: $k, ",
	    "expected $mode\n";
    }

    if ($mode and not defined $accept_mode{$mode}) {
	croak "fetch_no_check: expected ", 
	    join (' or ',keys %accept_mode),
		" parameter, not $mode" ;
    }

    if ($mode eq 'custom') {
	no warnings "uninitialized" ;
	my $cust ;
	$cust = $data if $data ne $std and $data ne $self->{upstream_default} ;
	return $cust;
    }

    if ($mode eq 'non_upstream_default') {
	no warnings "uninitialized" ;
	my $nbu = defined $data && $data ne $self->{upstream_default} ? $data 
	        : defined $std  && $std  ne $self->{upstream_default} ? $std 
                :                                                      undef ;

	return $nbu;
    }

    return $mode eq 'preset'                   ? $self->{preset}
         : $mode eq 'default'                  ? $self->{default}
         : $mode eq 'standard' && defined $std ? $std 
         : $mode eq 'standard'                 ? $self->{upstream_default}
	 : $mode eq 'upstream_default'         ? $self->{upstream_default}
	 : defined $data                       ? $data
         :                                       $std ;

}

# likewise but without any warp, etc related check
sub _fetch_no_check {
    my $self = shift ;
     return defined $self->{data}    ? $self->{data}
          : defined $self->{preset}  ? $self->{preset}
          : defined $self->{compute} ? $self->compute 
          : defined $self->{_migrate_from} ? $self->migrate_value
          :                            $self->{default} ;
}

=head2 fetch( [ custom | preset | standard | default ] )

Check and fetch value from leaf element.

With a parameter, this method will return either:

=over

=item custom

The value entered by the user (if different from built in, preset,
computed or default value)

=item preset

The value entered in preset mode

=item standard

The preset or computed or default or built in value.

=item default

The default value (defined by the configuration model)

=item upstream_default

The upstream_default value. (defined by the configuration model)

=item non_upstream_default

The custom or preset or computed or default value. Will return undef
if either of this value is identical to the upstream_default value. This
feature is useful to reduce data to write in configuration file.

=item allow_undef

This mode will accept to return undef for mandatory values. Normally,
trying to fetch an undefined manadatory value leads to an exception.

=back


=cut

sub fetch {
    my $self = shift ;
    my $mode = shift || '';
    my $inst = $self->instance ;

    my $value = $self->fetch_no_check($mode) ;

    if ($mode and not defined $accept_mode{$mode}) {
	croak "fetch: expected ", 
	    join (' or ',keys %accept_mode),
		" parameter, not $mode" ;
    }

    if (defined $value) {
	# check validity (all modes)
        return $value if $self->check($value) ;

        Config::Model::Exception::WrongValue
	    -> throw (
		      object => $self,
		      error => join("\n\t",@{$self->{error}})
		     ) 
	      if $inst->get_value_check('fetch') ;
    }
    elsif (     $self->{mandatory}
	    and $inst->get_value_check('fetch') 
	    and (not $mode or $mode eq 'custom' )
            and ($mode ne 'allow_undef')
	    and (not defined $self->fetch_no_check() )
	  ) {
	# check only custom or "empty" mode. But undef custom value is
	# authorized if standard value is defined (that's what is
	# important)
        my @error ;
        push @error, "Undefined mandatory value."
          if $self->{mandatory} ;
        push @error, $self->warp_error 
          if defined $self->{warped_attribute}{default} ;
        Config::Model::Exception::WrongValue
	    -> throw (
		      object => $self,
		      error => join("\n\t",@error)
		     );
    }

    return ;
}

=head2 user_value

Returns the value entered by the user. Does not use the default or
computed value. Returns undef unless a value was actually stored.

=cut

sub user_value {
    return shift->{data} ;
}

=head2 fetch_preset

Returns the value entered in preset mode. Does not use the default or
computed value. Returns undef unless a value was actually stored in
preset mode.

=cut

sub fetch_preset {
    return shift->{preset} ;
}


=head2 get( path , [ custom | preset | standard | default ])

Get a value from a directory like path.

=cut

sub get {
    my $self = shift ;
    my $path = shift ;
    if ($path) {
	Config::Model::Exception::User
	    -> throw (
		      object => $self,
		      message => "get() called with a value with non-empty path: '$path'"
		     ) ;
    }
    return $self->fetch(@_) ;
}

=head2 set( path , value )

Set a value from a directory like path.

=cut

sub set {
    my $self = shift ;
    my $path = shift ;
    if ($path) {
	Config::Model::Exception::User
	    -> throw (
		      object => $self,
		      message => "set() called with a value with non-empty path: '$path'"
		     ) ;
    }
    return $self->store(@_) ;
}

#These methods are important when this leaf value is used as a warp
#master, or a variable in a compute formula.

# register a dependency, This information may be used by external
# tools
sub register_dependency {
    my $self = shift ;
    my $slave = shift ;

    unshift @{$self->{depend_on_me}}, $slave ;
    # weaken only applies to the passed reference, and there's no way
    # to duplicate a weak ref. Only a strong ref is created.
    weaken($self->{depend_on_me}[0]) ; 
}

sub get_depend_slave {
    my $self = shift ;

    my @result = () ;
    push @result, @{$self->{depend_on_me}} if defined $self->{depend_on_me} ;

    if (defined $self->{warp_these_objects}) {
        push @result, map ($_->[0],@{$self->{warp_these_objects}})  ;
    }

    return @result ;
  }

1;

__END__

=head1 Upgrade

Upgrade is a special case when the configuration of an application has
changed. Some parameters can be removed and replaced by another
one. To avoid trouble on the application user side, Config::Model
offers a possibility to handle the migration of configuration data
through a special declaration in the configuration model.

This declaration must:

=over

=item *

Declare the deprecated parameter with a C<status> set to C<deprecated>

=item *

Declare the new parameter with the intructions to load the semantic
content from the deprecated parameter. These instructions are declared
in the C<migrate_from> parameters (which is similar to the C<compute>
parameter)

=back

Here an example where a url parameter is changed to a set of 2
parameters (host and path):

       'old_url' => { type => 'leaf',
		      value_type => 'uniline',
		      status => 'deprecated',
		    },
       'host' 
       => { type => 'leaf',
	    value_type => 'uniline',
            # the formula must end with '$1' so the result of the capture is used
            # as the host value
	    migrate_from => { formula => '$old =~ m!http://([\w\.]+)!; $1 ;' , 
			      variables => { old => '- old_url' } ,
			      use_eval => 1 ,
			    },
			},
       'path' => { type => 'leaf',
		   value_type => 'uniline',
		   migrate_from => { formula => '$old =~ m!http://[\w\.]+(/.*)!; $1 ;', 
				     variables => { old => '- old_url' } ,
				     use_eval => 1 ,
				   },
		 },


=head1 EXCEPTION HANDLING

When an error is encountered, this module may throw the following
exceptions:

 Config::Model::Exception::Model
 Config::Model::Exception::Formula
 Config::Model::Exception::WrongValue
 Config::Model::Exception::WarpError

See L<Config::Model::Exception> for more details.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Node>,
L<Config::Model::AnyId>, L<Config::Model::WarpedThing>, L<Exception::Class>
L<Config::Model::ValueComputer>,

=cut

