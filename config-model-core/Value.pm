# $Author: ddumont $
# $Date: 2007-01-08 12:39:05 $
# $Name: not supported by cvs2svn $
# $Revision: 1.8 $

#    Copyright (c) 2005,2006 Dominique Dumont.
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
use Data::Dumper ;
use Parse::RecDescent ;
use Config::Model::Exception ;
use Config::Model::ValueComputer ;
use Error qw(:try); 
use Carp ;

use base qw/Config::Model::WarpedThing/ ;

use vars qw($VERSION) ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/;

=head1 NAME

Config::Model::Value - Strongly typed configuration value

=head1 SYNOPSIS

 my $model = Config::Model->new() ;
 $model ->create_config_class 
  (
   name => "SomeClass",
   element => [
     country  => { type =>       'leaf',
                   value_type => 'enum',
                   choice =>      [qw/France US/]
                 },
     president => { type =>        'leaf',
                    value_type => 'string',
                    warp => [ '- country', 
                             France => { default => 'Chirac' },
                             US     => { default => 'Bush' }]
                  },
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
the construction.

=item *

built-in default parameter: specifies the default value that is built
in the application to be configured. This built-in default value will
not written in the configuration files. Only the C<fetch_standard>
method will return the built-in default value. This may be used for
audit purpose.

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

=head1 Constructor

Value object should not be created directly.

=head1 Value model declaration

A leaf element must be declared with the following parameters:

=over

=item value_type

Either C<boolean>, C<enum>, C<integer>, C<enum_integer>, C<number>,
C<string>. Mandatory. See L</"Value types">.

=item default

Specify the default value (optional)

=item built_in

Specify a built in default value (optional)

=cut

# internal method
sub set_default {
    my ($self,$arg_ref) = @_ ;

    if (defined $arg_ref->{default} and defined $arg_ref->{built_in}) {
	Config::Model::Exception::Model
	    -> throw (
		      object => $self,
		      error => "Cannot specify both 'built_in' and "
		      ."'default' parameters",
		     ) 
    }

    foreach my $item (qw/built_in default/) {
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

	print "Set $item value for ",$self->name,"\n" if $::debug ;

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

    Config::Model::Exception::Model
	-> throw (
		  object => $self,
		  error => "Compute value must be an array ref"
		 ) 
	  unless ref($arg_ref->{compute}) eq 'ARRAY' ;

    $self->{compute} = delete $arg_ref->{compute};
    delete $self->{_compute} ;
}

# set up relation between objects required by the compute constructor
# parameters
sub submit_to_compute {
    my $self = shift ;
    my ($user_formula,%var) = @{$self->{compute}} ;

    $self->{_compute} = Config::Model::ValueComputer
      -> new (
	      user_formula => $user_formula ,
	      user_var => \%var ,
	      value_object => $self ,
	      value_type => $self->{value_type}
	     );

    $self->register_in_other_value(\%var) ;
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

Specify the minimum value (optional, only for integer, number or
enum_integer)

=item max

Specify the maximum value (optional, only for integer, number or
enum_integer)

=item mandatory

Set to 1 if the configuration value B<must> be set by the
configuration user (default: 0)

=item choice

Array ref of the possible value of an enum. Example :

 choice => [ qw/foo bar/]

=cut

sub setup_enum_choice {
    my ($self,$choice) = @_ ;

    my @choice = ref $choice ? @$choice : ($choice) ;

    # store all enum values in a hash. This way, checking
    # whether a value is present in the enum set is easier
    delete $self->{choice_hash} if defined $self->{choice_hash} ;
    map {$self->{choice_hash}{$_} =  1;} @choice ;

    $self->{choice}  = \@choice ;

    # delete the current value if it does not fit in the new
    # choice
    delete $self->{data}
      if (defined  $self->{data} and not $self->check($self->{data},1)) ;
}

=item refer_to

See L</"Value reference">.

=cut

sub set_refer_to {
    my ($self, $arg_ref) = @_ ;

    $self->{refer_to} = delete $arg_ref->{refer_to};
}


=item warp

See section below: </"Warp: dynamic value configuration">.

=item help

You may provide detailed description on possible values of this tied
scalar with a hash ref. Example:

 help => { oui => "French for 'yes'", non => "French for 'no'"}

=back

=cut

my @accessible_params =  qw/min max mandatory default value_type
                             choice convert built_in/ ;

my @allowed_warp_params = (@accessible_params, qw/level permission/);

sub new {
    my $type = shift;
    my %args = @_ ;

    my $self={} ;
    bless $self,$type;

    $self->{mandatory} = $self->{allow_compute_override} = 0 ;

    # this parameter is internal and is used only by CheckList
    $self->{unique_value} = delete $args{unique_value} || 0 ;

    $self->{element_name} = delete $args{element_name} 
      || croak "Value new: no 'element_name' defined" ;
    $self->{index_value} = delete $args{index_value} ; 

    $self->_set_parent(delete $args{parent}) ;

    $self->{instance} = delete $args{instance} 
      || croak "Value: missing 'instance' parameter" ;


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
		  ."compute value must be an array ref",
		  object => $self
		 ) 
	  if (defined $args{compute} and ref($args{compute}) ne 'ARRAY') ;

    my $warp_info = delete $args{warp} ;

    $self->{help} = delete $args{help} ;

    $self->{backup}  = \%args ;

    $self->set() ; # set will use backup data

    if (defined $warp_info) {
	$self->check_warp_args( \@allowed_warp_params, $warp_info) ;
    }

    $self->submit_to_warp($self->{warp}) if $self->{warp} ;

    $self->_init ;

    return $self ;
}

# warning : call to 'set' are not cumulative. Default value are always
# restored. Lest keeping track of what was modified with 'set' is
# too hard for the user.
sub set {
    my $self = shift ;

    # cleanup all parameters that are handled by warp
    map(delete $self->{$_}, 
        qw/min max mandatory default built_in value_type choice
           allow_compute_override refer_to/) ;

    # merge data passed to the constructor with data passed to set
    my %args = (%{$self->{backup}},@_ );

    print "'".$self->name."' set called with \n", Dumper(\%args)
      if $::debug ;

    if ( not          defined $args{value_type} 
	 or (         defined $args{value_type} 
	      and     $args{value_type} =~ 'enum'
	      and not defined $args{choice}
	    )
       ) {
        $self->{parent}
	      -> set_element_property(property => 'level',
				      element  => $self->{element_name},
				      value    =>'hidden') ;
        delete $self->{data} ;
        return ;
    }

    if ($args{value_type} eq 'reference' and not defined $args{refer_to}) {
	Config::Model::Exception::Model
	    -> throw (
		      object => $self,
		      error => "Missing 'refer_to' parameter with "
		             . "'reference' value_type "
		     ) 
	};

    map { $self->{$_} =  delete $args{$_} if defined $args{$_} }
      qw/name min max mandatory allow_compute_override/;

    $self->set_properties ( \%args );
    $self->set_value_type ( \%args );
    $self->set_default    ( \%args ) if (    exists $args{default} 
					  or exists $args{built_in} );
    $self->set_compute    ( \%args ) if defined $args{compute};
    $self->set_convert    ( \%args ) if defined $args{convert};

    Config::Model::Exception::Model
	-> throw (
		  object => $self,
		  error => "Unexpected parameters :".join(' ', keys %args )
		 ) 
	  if scalar keys %args ;

    if (defined $self->{warp_these_objects}) {
        my $value = defined $self->{data} ? $self->{data} :
          defined $self->{compute} ? $self->compute :
            $self->{default} ;
        $self->warp_them($value)  ;
    }

    return $self; 
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

=item C<enum_integer>

C<enum_integer> authorise the value to be an integer or a value
specified by the C<choice> parameter. This type is used to specify a
value which can be an integer or be disabled.

=item C<number>

The value can be a decimal number

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
    }
    elsif (   $value_type eq 'reference' 
	   or $value_type eq 'enum' 
	   or $value_type eq 'enum_integer'
	  ) {
	$self->set_refer_to ($arg_ref) if $value_type eq 'reference';
        my $choice = delete $arg_ref->{choice} ;
        $self->setup_enum_choice($choice) if defined $choice ;
    }
    elsif (   $value_type eq 'string' 
	   or $value_type eq 'integer' 
	   or $value_type eq 'number') {
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
	  "expected 'boolean', 'enum', 'string' or 'integer'."
	    ."Value type can also be set up with a warp relation" ;
        Config::Model::Exception::Model
	    -> throw (object => $self, error => $msg) 
	      unless defined $self->{warp};
    }
}

sub set_properties {
    my ($self, $arg_ref) = @_ ;

    foreach my $property_name (qw/level permission/) {
	if (defined $arg_ref->{$property_name}) {
	    my $v = delete $arg_ref->{$property_name} ;
	    $self->{parent}
	      -> set_element_property (
				       property=> $property_name,
				       element => $self->{element_name},
				       value   => $v,
				     );
	}
	else {
	    $self->{parent}
	      ->reset_element_property(property => $property_name,
				       element  => $self->{element_name});
	}
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
       warp => { follow => '- country', # this points to the warp master
                 rules => { US     => { default => 'NTSC'  },
                            France => { default => 'SECAM' },
                            Japan  => { default => 'NTSC'  },
                            Europe => { default => 'PAL'   },
                          }
               }
       ],
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
      warp => [ follow => '- country',
                rules => { US     => { choice => ['Kansas', 'Texas'    ]},
                           Europe => { choice => ['France', 'Spain'    ]},
                           Japan  => { choice => ['Honshu', 'Hokkaido' ]}
                         }
      ]
 }

Note that the C<state> element is not available while C<country> is
undefined.

As syntactic sugar, similar rules can be grouped within an array ref
instead of a hash ref. I.e., you can specify

                 rules => [ 
                            [qw/UK Germany Italy/] => { default => 'PAL'  },
                            US     => { default => 'NTSC'  },
                          ]

instead of :
                 rules => { 
                            UK      => { default => 'PAL'  },
                            Germany => { default => 'PAL'  },
                            Italy   => { default => 'PAL'  },
                            US      => { default => 'NTSC'  },
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
    my $value = @_ ? $_[0] :
      defined $self->{data} ? $self->{data} : $self->{default}  ;

    foreach my $ref ( @{$self->{warp_these_objects}})
      {
        my ($warped, $warp_index) = @$ref ;
        next unless defined $warped ; # $warped is a weak ref and may vanish

        # pure warp of object
        print "warp_them: (value ", 
          defined $value ? $value : 'undefined',
            ") warping '",$warped->name,"'\n" 
              if $::debug;
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
key of a L<Config::Model::AnyId> object, you must set C<value_type>
to C<reference>.

=cut

sub submit_to_refer_to {
    my $self = shift ;

    my $refto = $self->{refer_to} ;
    my ($refer_path,%var) = ref $refto ? @$refto : ($refto) ;

    $self->{refer_compute} = Config::Model::ValueComputer
      -> new (
	      user_formula => $refer_path ,
	      user_var => \%var ,
	      value_object => $self ,
	      value_type => $self->{value_type}
	     );

    $self->register_in_other_value(\%var) ;
  }



=pod

When C<value_type> is a reference, you must also set the C<refer_to>
parameter. 

=over

=item * 

The first argument of C<refer_to> points to an array or hash element
in the configuration tree using the path syntax (See
L<Config::Model::Node/grab> for details). This path is treated like a
computaion formula. Hence it can contain variable and substitution
like a computation formula.

=item *

The following arguments of C<refer_to> define the variable used in the
path formula.

=item *

The available choice of this reference value is made from the
available keys of the refered_to hash element or the range of the
refered_to array element.

=back

The example means the the value must correspond to an existing host:

 value_type => 'reference',
 refer_to => '! host' 

This example means the the value must correspond to an existing lan
within the host whose Id is specified by hostname:

 value_type => 'reference',
 refer_to => ['! host:$a lan', a => '- hostname' ]

If you need to combine possibilities from several hash, use the "C<+>"
token to separate 2 paths:

 value_type => 'reference',
 refer_to => ['! host:$a lan + ! host:foobar lan', 
              a => '- hostname' ]

You can specify C<refer_to> with a C<choice> argument so the possible
enum value will be the combination of the specified choice and the
refered_to values.

=cut

# internal
sub get_choice_from_refered_to {
    my $self = shift ;

    $self->submit_to_refer_to if ($self->{refer_to} and 
				  not defined $self->{refer_compute}) ;

    my $user_spec = $self->{refer_compute}->compute ;
    my %enum_choice = map { ($_ => 1 ) } $self->get_choice ;

    my @references =  split /\s+\+\s+/, $user_spec ;
    $self->{refered_to_path} = \@references ;

    for my $reference ( @references ) {
	my @path = split (/\s+/,$reference) ;

	my $element = pop @path ;

	print "get_choice_from_refered_to:\n\tpath: @path, element $element\n"
	  if $::debug ;

	my $obj = $self->grab("@path");

	Config::Model::Exception::UnknownElement
	    -> throw (
		      object => $obj,
		      element => $element,
		      info => "Error related to 'refer_to' element of '".
		      $self->parent->config_class_name() . "'"
		     ) 
	      unless  $obj->is_element_available(name => $element) ;

	my $type = $obj->element_type($element) ;

	Config::Model::Exception::Model 
	    -> throw (
		      object => $obj,
		      message => "element '$element' type is $type. "
		      ."Expected hash or list or check_list"
		     )
	      unless $type eq 'hash' or $type eq 'list' 
		or $type eq 'check_list';

	# use a hash so choices are unique
	map { $enum_choice{$_} = 1 }
	  $obj->fetch_element($element)->get_all_indexes();
    }

    print "get_choice_from_refered_to:\n\tSetting choice to '", 
      join("','",sort keys %enum_choice),"'\n"
	if $::debug ;

    $self->setup_enum_choice([sort keys %enum_choice]) ;
}



=head2 Value reference example

## FIXME: get an example...

=head1 Introspection methods

The following methods returns the current value of the Id object (as
declared in the model unless they were warped):

=over

=item min 

=item max 

=item mandatory 

=item choice

=item convert

=item value_type 

=item default 

=item built_in

=item index_value

=item element_name

=back


=cut

# accessor to get some fields through methods (See man perltootc)
foreach my $datum (@accessible_params, qw/index_value element_name/) {
    no strict "refs";       # to register new methods in package
    *$datum = sub {
	my $self= shift;
	return $self->{$datum};
    } ;
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

sub get_choice
  {
    my $self = shift ;
    return @{$self->{choice}} if defined $self->{choice};
    return () ;
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

    return undef ;
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

    my @choice = map( "'$_'", @{$self->{choice}});
    my $var = $self->{value_type} ;
    push @choice, $var if ($var =~ s/enum_//) ;
    push @error, "$self->{value_type} type does not know '$value'. Expected ".
      join(" or ",@choice) ; 
    push @error, "Expected list is given by '".
      join("', '", @{$self->{refered_to_path}})."'" if $var eq 'reference';
    push @error, $self->warp_error if $self->{warp};

    return @error ;
}

# internal. Check if passed value is acceptable or not.
sub check {
    my ($self,$value,$quiet) = @_ ;

    # when $quiet is non null, the routine will not try to get extra
    # informations from the tree. This is required in some cases to
    # avoid loops in check, get_info, get_warp_info, re-check ...

    $quiet = 0 unless defined $quiet ;

    my @error  ;

    if (not defined $value) {
        return 1 unless $self->{mandatory} ;
        $self->{error} = ["Mandatory value is not defined"] ;
        return 0 ;
    }

    if (not defined $self->{value_type} ) {
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
    elsif (   $self->{value_type} =~ 'enum' 
	   or $self->{value_type} eq 'reference'
	  ) {
        push @error, ($quiet ? 'enum error' : $self->enum_error($value))
          unless defined $self->{choice_hash} and 
            defined $self->{choice_hash}{$value} ;
    }
    elsif ($self->{value_type} eq 'boolean') {
        push @error, ($quiet ? "boolean error" :"'$value' is not '1' or '0'" )
          unless $value =~ /^[01]$/ ;
    }
    elsif (   $self->{value_type} =~ /integer/ 
	   or $self->{value_type} =~ /number/
	  ) {
        push @error,"Value '$value' is not of type ". $self->{value_type};
    }
    elsif ($self->{value_type} eq 'string') {
        # accepted, no more check
    }
    else {
	my $msg = "Cannot check value_type '".
	  $self->{value_type}. "' (value '$value'".
	    (defined $self->{choice} ? ", choice @{$self->{choice}})" : ')');
        Config::Model::Exception::Model 
	    -> throw (object => $self, message => $msg) ;
    }

    $self->{error} = \@error ;
    return not scalar @error ;
}

=head1 Information management

=head2 store( value )

Store value in leaf element.

=cut

sub store {
    my $self = shift ;

    my ($ok,$value) = $self->pre_store(@_) ;

    if ($ok) {
        $self->{data} = $value ; # may be undef

	if ($self -> {unique_value}) {
	    my $parent = $self->parent ;
	    my $reference = $parent->fetch_element($self->{element_name}) ;
	    $reference -> store_value ($self->index_value , $value) ;
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
      if ($self->{warp} and @{$self->{warp_info}{computed_master}});

    if (defined $self->{compute} 
	and not $self->{allow_compute_override}) {
	my $msg = 'assignment to a computed value is forbidden unless '
	  .'allow_compute_override is set.' ;
	Config::Model::Exception::Model
	    -> throw (object => $self, message => $msg) 
	      if $inst->get_value_check('store') ;
        return 1 ; # ok, but don't store a value
    }

    if (defined $self->{refer_to}) {
	$self->get_choice_from_refered_to ;
    }

    # check if the object was initialized
    if (not defined $self->{value_type}
        and $inst->get_value_check('type')
       ) {
        $self->_value_type_error ;
    }

    if ($self->{value_type} eq 'boolean' and defined $value) {
        # convert yes no to 1 or 0 
        $value = 1 if ($value =~ /^y/i or $value =~ /true/i) ;
        $value = 0 if ($value =~ /^n/i or $value =~ /false/i );
    }

    $value = $self->{convert_sub}($value) 
      if (defined $self->{convert_sub} and defined $value) ;

    $self->check_unique($value) if $self->{unique_value} ;

    my $ok = $self->store_check($value) ;

    if (     $ok 
	 and defined $value 
	 and defined $self->{warp_these_objects}
         and (    not defined $self->{data} 
	       or $value ne $self->{data}
	     )
       ) {
        $self->warp_them($value) ;
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

# there's no allow override for this type.
sub check_unique {
    my ($self,$value) = @_ ;

    my $parent = $self->parent ;
    my $reference = $parent->fetch_element($self->{element_name}) ;

    my ($known, $other_idx) 
      = $reference -> is_value_known ($self->index_value, $value) ;
    if ( $known ) {
	Config::Model::Exception::User
	    -> throw (
		      object => $self,
		      message => "Value '$value' is already stored in element '"
		      . $parent->name . " $self->{element_name}:$other_idx'"
		     ) ;
    }
}

=head2 fetch_custom

Returns the stored value if this value is different from a standard
setting. In other words, returns undef if the stored value is
identical to the default value or the computed value.

=cut

sub fetch_custom {
    my $self = shift ;
    my $std_value = $self->fetch_standard ;

    no warnings "uninitialized" ;
    return ($self->{data} ne $std_value) ? $self->{data} : undef ;
}

=head2 fetch_standard

Returns the standard value as defined by the configuration model. The
standard value can be either a computed value, a default value or a
built-in default value.

=cut

sub fetch_standard {
    my $self = shift ;
    my $pre_fetch = $self->_pre_fetch ;
    return defined $pre_fetch ? $pre_fetch : $self->{built_in} ;
}

sub _init {
    my $self = shift ;

    $self->warp 
      if ($self->{warp} and @{$self->{warp_info}{computed_master}});

    if (defined $self->{refer_to}) {
	$self->get_choice_from_refered_to ;
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

    try {
	$std_value = defined $self->{compute} ? $self->compute :
           $self->{default} ;
    }
    catch Config::Model::Exception::User with { 
	if ($self->instance->get_value_check('fetch')) {
	    shift->throw ; 
	}
	$std_value = undef ;
    } ;

    return $std_value ;
}

=head1 fetch()

Fetch value from leaf element

=cut

sub fetch {
    my $self = shift ;
    my $inst = $self->instance ;

    # allways call to perform submit_to_warp
    my $std_value = $self->_pre_fetch ;

    my $value = defined $self->{data} ? $self->{data} : $std_value ;

    if (defined $value) {
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
	  ) {
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

    return undef ;
}

=head2 user_value

Returns the value entered by the user. Does not use the default or
computed value. Returns undef unless a value was actually stored.

=cut

sub user_value {
    return shift->{data} ;
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

1;

__END__



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


=cut

