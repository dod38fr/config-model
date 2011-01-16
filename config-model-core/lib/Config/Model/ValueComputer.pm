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

package Config::Model::ValueComputer ;

use warnings ;
use strict;
use Scalar::Util qw(weaken) ;
use Carp ;
use Parse::RecDescent ;
use Data::Dumper () ;
use Log::Log4perl qw(get_logger :levels);

use vars qw($compute_grammar $compute_parser) ;

my $logger = get_logger("ValueComputer") ;

=head1 NAME

Config::Model::ValueComputer - Provides configuration value computation

=head1 SYNOPSIS

 my $model = Config::Model->new() ;

 $model ->create_config_class 
  (
   name => "Master",
   element 
   => [
       [qw/av bv/] => {type => 'leaf',
                       value_type => 'integer',
                      },
       compute_int 
       => { type => 'leaf',
            value_type => 'integer',
            compute    => { formula   => '$a + $b', 
                            variables => { a => '- av', b => '- bv'}
                          },
            min        => -4,
            max        => 4,
          },
       [qw/sav sbv/] => {type => 'leaf',
                         value_type => 'string',
                      },
       compute_string
       => { type => 'leaf',
            value_type => 'string',
            compute => { formula => 'meet $a and $b', 
                         variables => { '- sav', b => '- sbv' }
                       },
          },
       compute_with_replace 
       => { type => 'leaf',
            value_type => 'string',
            compute => {
               formula   => '$replace{$who} is the $replace{$what} of $replace{$country}',
               variables => {
                              who   => '! who' ,
                              what  => '! what' ,
                              country => '- country',
                             },
	       replace   => { chief => 'president', 
                              America => 'USA'
                            },
            },
       },

       url => { type => 'leaf', value_type => 'uniline'},
       extract_host_from_url
       => { type => 'leaf',
	    value_type => 'uniline',
	    compute    => { formula => '$old =~ m!http://([\w\.]+)!; $1 ;' , 
			    variables => { old => '- url' } ,
			    use_eval => 1 ,
			  },
	  },
     ]
 ) ;

=head1 DESCRIPTION

This class provides a way to compute a configuration value. This
computation uses a formula and some other configuration values from
the configuration tree.

The computed value can be overridden, in other words, the computed
value can be used as a defult value.

=head1 Computed value declaration

A computed value must be declared in a 'leaf' element. The leaf element
must have a C<compute> argument pointing to a hash ref. 

This array ref contains:

=over

=item *

A string formula that use variables and replace function.

=item *

A set of variable and their relative location in the tree (using the
notation explained in 
L<grab() method|Config::Model::AnyThing/"grab(...)">

=item *

An optional set of replace rules.

=item *

An optional parameter to force a Perl eval of a string. 

=back

=head2 Compute formula

The first element of the C<compute> array ref must be a string that
contains the computation algorithm (i.e. a formula for arithmetic
computation for integer values or a string template for string
values).

This string or formula should contain variables (like C<$foo> or
C<$bar>). Note that these variables are not interpolated by perl.

For instance:

  'My cat has $nb legs'
  '$m * $c**2'

This string or formula may also contain:

=over 

=item *

The index value of the current object : C<&index> or C<&index()>.

=item *

The index value of another object: C<&index($other)>

=item *

The element name of the current object: C<&element> or C<&element()>.

=item *

The element name of another object: C<&element($other)>

=back

For instance, you could have this template string:

   'my element is &element, my index is &index' .
    'upper element is &element($up), upper index is &index($up)',

If you need to perform more complex operations than substition, like
extraction with regular expressions, you can force an eval done by
Perl with C<< use_eval => 1 >>. In this case, the result of the eval
will be used as the computed value.

For instance:

  # extract host from url
  compute => { formula => '$old =~ m!http://[\w\.]+(?::\d+)?(/.*)!; $1 ;', 
	       variables => { old => '- url' } ,
	       use_eval => 1 ,
	     },

  # capitalize
  compute => { formula => 'uc($old)',
	       variables => { old => '- small_caps' } ,
	       use_eval => 1 
             }

=head2 Compute variables

The following arguments will be a set of C<< key => value >> to define
the variables used in the formula. The key is a variable name used in
the computation string. The value is a string that will be used to get
the correct Value object.

In this numeric example, C<result> default value is C<av + bv>:

 element => [
  av => { 
    type => 'leaf',
    value_type => 'integer'
  },
  bv => { 
    type => 'leaf',
    value_type => 'integer'
  },
  result => { 
    type => 'leaf',
    value_type => 'integer', 
    compute => { formula => '$a + $b' , 
                 variables => { a => '- av', b => '- bv' },
               }
  }

In this string example, the default value of the C<Comp> element is
actually a string made of "C<macro is >" and the value of the
"C<macro>" element of the object located 2 nodes above:

   comp => { 
    type => 'leaf',
    value_type => 'string', 
    compute => { formula => '"macro is $m"' ,
                 variables => { m => '- - macro' }
               }
   }

=head2 Compute replace

Sometime, using the value of a tree leaf is not enough and you need to
substitute a replacement for any value you can get. This replacement
can be done using a hash like notation within the formula using the
C<%replace> hash.

For instance, if you want to display a summary of a config, you can do :

       compute_with_replace 
       => {
            formula => '$replace{$who} is the $replace{$what} of $replace{$country}',
            variables => {
                           who   => '! who' ,
                           what  => '! what' ,
                           country => '- country',
                         },
            replace => {  chief => 'president', 
                          America => 'USA'
                       },

=head2 Complex formula

C<&index>, C<&element>, and replace can be combined. But the
argument of C<&element> or C<&index> can only be a value object
specification (I.e. something like 'C<- - foo>'), it cannot be a value
replacement of another C<&element> or C<&index>.

I.e. C<&element($foo)> is ok, but C<&element(&index($foo))> is not allowed.

=head2 computed variable

Compute variables can themselves be computed :

   compute => {
     formula => 'get_element is $replace{$s}, indirect value is \'$v\'',
     variables => { 's' => '! $where',
                     where => '! where_is_element',
                     v => '! $replace{$s}',
                  }
     replace   => { m_value_element => 'm_value',
                    compute_element => 'compute' 
                  }
    }

Be sure not to specify a loop when doing recursive computation.

=head2 compute override

In some case, a computed value must be interpreted as a default value
and the user must be able to override this computed default value.  In
this case, you must use C<< allow_override => 1 >> with the
compute parameter:

   computed_value_with_override => { 
    type => 'leaf',
    value_type => 'string', 
    compute => { formula => '"macro is $m"' , 
                 variables => { m => '- - macro' } ,
                 allow_override => 1,
               }
   }

=cut

# allow_override is intercepted and handled by Value object

sub new {
    my $type = shift ;
    my %args = @_ ;
    my $self= {} ;

    if ($::debug) {
	my %show = %args ;
	delete $show{value_object} ;
	print Data::Dumper->Dump([\%show],['Computedvalue_new_args']) ;
    }

    # value_object is mostly used for error messages
    foreach my $k (qw/formula value_type value_object/) {
	$self->{$k} = delete $args{$k} || 
	  croak "Config::Model::ValueComputer:new undefined parameter $k";
    }

    foreach my $k (qw/variables replace/) {
	$self->{$k} = delete $args{$k} || {} ;
    }

    $self->{use_eval} = delete $args{use_eval} || 0 ;

    die "Config::Model::ValueComputer:new unexpected parameter: ",
      join(' ',keys %args) if %args ;


    weaken($self->{value_object}) ;

    # create parser if needed 
    $compute_parser ||= Parse::RecDescent->new($compute_grammar) ;

    # must make a first pass at computation to subsitute index and
    # slot values.  leaves $xxx outside of &index or &element untouched
    my $result_r = $compute_parser
      -> pre_compute
	(
	 $self->{formula},
	 1,
	 $self->{value_object},
	 $self->{variables},
	 $self->{replace}
	) ;

    $self->{pre_formula} = $$result_r ;

    bless $self,$type ;
}

sub formula { return shift->{formula} ;}
sub variables     { return shift->{variables} ;}

sub compute {
    my $self = shift ;
    my %args = @_ ;
    my $check = $args{check} || 'yes' ;

    my $pre_formula = $self->{pre_formula};

    my $variables = $self->compute_variables(check => $check) ;

    return unless defined $variables ;

    my $need_quote = 0;
    $need_quote = 1 if $self->{use_eval} and $self->{value_type} !~ /(integer|number|boolean)/;

    my $formula_r = $compute_parser
      -> compute ($pre_formula, 1,$self->{value_object}, $variables, 
		  $self->{replace},$check,$need_quote) ;

    my $formula = $$formula_r ;

    return unless defined $formula ;

    print "compute $self->{value_type}: pre_formula $pre_formula\n",
      "compute $self->{value_type}: rule to eval $formula\n" if $::debug;

    my $result = $self->{computed_formula} = $formula ;

    if ($self->{use_eval} or $self->{value_type} =~ /(integer|number|boolean)/) {
        $result = eval $formula ;
	if ($@) {
	    Config::Model::Exception::Formula
		-> throw (
			  object => $self->{value_object},
			  error => "Eval of formula '$formula' failed:\n$@"
			  . "Make sure that your element is indeed "
			  . "'$self->{value_type}'"
			 ) ;
	}
    }

    return $result ;
}

sub compute_info {
    my $self = shift;
    my %args = @_ ;
    my $check = $args{check} || 'yes' ;

    my $orig_variables = $self->{variables} ;
    my $variables = $self->compute_variables ;
    my $str = "value is computed from '$self->{formula}'";

    return $str unless defined $variables ;

    #print Dumper $variables ;

    if (%$variables) {
        $str .= ", where " ;
        foreach my $k (sort keys %$variables) {
	    my $u_val = $variables->{$k} ;
	    if (ref($u_val)) {
		map {
		    $str.= "\n\t\t'\$$k" . "{$_} is converted to '$orig_variables->{$k}{$_}'";
		    } sort keys %$u_val ;
 	    }
	    else {
		my $val ;
		if (defined $u_val) {
		  my $obj = eval { $self->{value_object} ->grab($u_val) };
		  if ($@) {
		    my $e = $@ ;
		    my $msg = $e ? $e->full_message : '' ;
		    Config::Model::Exception::Model
			-> throw (
				  object => $self,
				  error => "Compute variable:\n". $msg
				 ) ;
		  }
		  $val = $obj->get_type eq 'node' ? '<node>' : $obj->fetch(check => $check) ;
		}
		$str.= "\n\t\t'$k' from path '$orig_variables->{$k}' is ";
		$str.= defined $val ? "'$val'" : 'undef' ;
	    }
	}
    }

    #$str .= " (evaluated as '$self->{computed_formula}')"
    #  if $self->{formula} ne $self->{computed_formula} ;

    return $str ;
}

#internal
sub compute_variables {
    my $self = shift ;
    my %args = @_ ;
    my $check = $args{check} || 'yes';

    # a shallow copy should be enough as we don't allow
    # replace in replacement rules
    my %variables = %{$self->{variables}} ;

    # apply a compute on all variables until no $var is left
    my $var_left = scalar (keys %variables) + 1 ;

    while ($var_left) {
        my $old_var_left= $var_left ;
        my $did_something = 0 ;
        foreach my $key (keys %variables) {
            my $value = $variables{$key} ; # value may be undef
            next unless (defined $value and $value =~ /\$|&/) ;
            #next if ref($value); # skip replacement rules
            print "key '$key', value '$value', left $var_left\n" 
	      if $::debug;
	    my $pre_res = $compute_parser
	      -> pre_compute ($value, 1,$self->{value_object}, \%variables, $self->{replace},$check);
            print "key '$key', pre res '$pre_res', left $var_left\n" 
	      if $::debug;
            my $res_r = $compute_parser
	      -> compute ($pre_res, 1,$self->{value_object}, \%variables, $self->{replace},$check);
	    my $res = $$res_r ;
            #return undef unless defined $res ;
            $variables{$key} = $res ;
	    {
		no warnings "uninitialized" ;
		print "\tresult '$res' left $var_left, did $did_something\n" 
		  if $::debug;
	    }
	}

        my @var_left =  grep {defined $variables{$_} && $variables{$_} =~ /\$/} 
	  sort keys %variables;

        $var_left = @var_left ;

        Config::Model::Exception::Formula
	    -> throw (
		      object => $self->{value_object},
		      error => "Can't resolve user variable: '"
		      . join ("','",@var_left) . "'"
		     ) 
	      unless ($var_left < $old_var_left);
    }

    return \%variables ;
}

sub _pre_replace {
    my ( $replace_h, $pre_value ) = @_;

    my $result =
      exists $replace_h->{$pre_value}
      ? $replace_h->{$pre_value}
      : '$replace{' . $pre_value . '}';
    return \$result;
}

sub _replace {
    my ( $replace_h, $value, $value_object ) = @_;

    # print "value: replacement, value '$value'\n";
    my $result;
    if ( defined $value and $value =~ /\$/ ) {

        # must keep original variable
        $result = '$replace{' . $value . '}';
    }
    elsif ( defined $value ) {
        Config::Model::Exception::Formula->throw(
            object => $value_object,
            error  => "Unknown replacement value for replace: " . "'$value'\n"
        ) unless defined $replace_h->{$value};

        $result = $replace_h->{$value};
    }
    return \$result;
}

sub _function_on_object {

    # print "pre_value handling &foo(...)\n";
    my ( $object, $function, $return, $value_object, $variables_h, $replace_h,
        $check, $need_quote )
      = @_;

    # get now the object refered
    my $fetch_str = $variables_h->{$object};
    Config::Model::Exception::Formula->throw(
        object => $value_object,
        error  => "Item $object has no associated location string"
    ) unless defined $fetch_str;

    my $target =
      eval { $value_object->grab( step => $fetch_str, check => $check ) };

    if ($@) {
        my $e = $@;
        my $msg = $e ? $e->full_message : '';
        Config::Model::Exception::Model->throw(
            object => $value_object,
            error  => "Compute function argument '$fetch_str':\n" . $msg
        );
    }

    if ( $function eq 'element' ) {
        my $result = $target->element_name;
        Config::Model::Exception::Model->throw(
            object => $value_object,
            error  => "'",
            $object->name, "' has no element name"
        ) unless defined $result;
        $return = \$result;
    }
    elsif ( $function eq 'index' ) {
        my $result = $target->index_value;
        Config::Model::Exception::Formula->throw(
            object => $value_object,
            error  => "'",
            $object->name, "' has no index value"
        ) unless defined $result;
        $return = \$result;
    }
    else {
        Config::Model::Exception::Formula->throw(
            object => $value_object,
            error  => "Unknown computation function &$function, "
              . "expected &element(...) or &index(...)"
        );
    }

    # print "\&foo(...) result = ",$$return," \n";

    # make sure that result of function is quoted (avoid bareword errors)
    my $vt = $value_object->value_type;
    if ( $vt =~ /^integer|number|boolean$/ ) {
        $$return = '"' . $$return . '"';
    }

    return $return;
}

sub _function_alone {
    my ( $f_name, $return, $value_object, $variables_h, $replace_h, $check,
        $need_quote )
      = @_;

    # print "pre_value handling &foo()\n";

    my $method_name =
        $f_name eq 'element' ? 'element_name'
      : $f_name eq 'index'   ? 'index_value'
      :                        undef;

    Config::Model::Exception::Formula->throw(
        object => $value_object,
        error  => "Unknown computation function &$f_name, "
          . "expected &element or &index"
    ) unless defined $method_name;

    my $result = $value_object->$method_name();

    my $vt = $value_object->value_type;
    if ( $vt =~ /^integer|number|boolean$/ ) {
        $result = '"' . $result . '"';
    }

    $return = \$result;

    Config::Model::Exception::Formula->throw(
        object => $value_object,
        error  => "Missing $f_name attribute (method '$method_name' on "
          . ref($value_object) . ")\n"
    ) unless defined $result;
    return $return;
}

sub _compute {
    my ( $value_ref, $return,
        $value_object, $variables_h, $replace_h, $check, $need_quote )
      = @_;

    my @values = map { $$_ } @{$value_ref};

    # print "compute return is '",join("','",@values),"'\n";

    my $result = '';

    # return undef if one value is undef
    foreach my $v (@values) {
        if ( defined $v ) {
            $result .= $v;
        }
        else {
            $result = undef;
            last;
        }
    }

    return \$result;
}

sub _value_from_object {
    my ( $name, $value_object, $variables_h, $replace_h, $check, $need_quote ) =
      @_;

    my $path = $variables_h->{$name};    # can be a ref for test purpose
    my $my_res;

    # print "value: replace \$$name with path $path...\n";

    if ( defined $path and $path =~ /\$/ ) {

        # print "compute rule skip name $name path '$path'\n";
        $my_res = "\$$name";             # restore name that contain '$var'
    }
    elsif ( defined $path ) {

        # print "fetching var object '$name' with '$path'\n";
        $my_res =
          eval { $value_object->grab_value( step => $path, check => $check ); };
        if ($@) {
            my $e = $@;
            my $msg = $e ? $e->full_message : '';
            Config::Model::Exception::Model->throw(
                object => $value_object,
                error  => "Compute argument '$name', error with '$path':\n"
                  . $msg
            );
        }

# print "fetched var object '$name' with '$path', result '", defined $return ? $return : 'undef',"'\n";

    }

    # my_res stays undef if $path if not defined

    # quote result if asked when calling compute
    my $quote = $need_quote || 0;
    $my_res = "'$my_res'" if $quote && $my_res;

    return \$my_res;    # So I can return undef ... or a ref to undef
}

$compute_grammar = << 'END_OF_GRAMMAR' ;
{

# This grammar is compatible with Parse::RecDescent < 1.90 or >= 1.90
use strict;
use warnings ;
}

# computed value may return undef even if parsing is done right. To
# avoid getting problems with Parse::RecDescent (where undef means
# that the parsing did not match), we will always return a scalar
# reference to the actual returned value

# @arg is value_object, $variables_h,  $replace_h, $check,$need_quote

pre_compute: <skip:''> pre_value[@arg](s) { 
    # print "pre-compute on @{$item[-1]}\n";
    my $str = join ( '', map { $$_ } @{ $item[-1] } ) ;
    $return =  \$str;
}

pre_value: 
  <skip:''> '$replace' '{' /\s*/ pre_value[@arg] /\s*/ '}' {
    $return = Config::Model::ValueComputer::_pre_replace($arg[2], ${ $item{pre_value} } ) ;
  }
  | <skip:''> function '(' /\s*/ object /\s*/ ')' {
    $return = Config::Model::ValueComputer::_function_on_object($item{object},$item{function},$return,@arg ) ;
  }
  | <skip:''> '&' /\w+/ func_param(?) {
    $return = Config::Model::ValueComputer::_function_alone($item[3],$return,@arg ) ;
  }
  |  <skip:''> /\$\d+/ {
     my $result = $item[-1] ;
     $return = \$result ;
  }
  | object {
     # print "pre_value handling \$foo\n";
     my $object = $item{object};
     my $result ="\$".$object ;
     $return = \$result ;
  }
  |  <skip:''> /[^\$&]*/ {
     # print "pre_value copying '$item[-1]'\n";
     my $result = $item[-1] ;
     $return = \$result ;
  }

func_param: /\(\s*\)/

compute:  <skip:''> value[@arg](s) { 
    # if one value is undef, return undef;
    Config::Model::ValueComputer::_compute($item[-1],$return,@arg ) ;
}

value: 
  <skip:''> '$replace' '{' <commit> /\s*/ value[@arg] /\s*/ '}' {
    $return = Config::Model::ValueComputer::_replace($arg[2], ${ $item{value} },@arg ) ;
  }
  |  <skip:''> /\$\d+/ { 
     my $result = $item[-1] ;
     $return = \$result ;
  }
  | <skip:''> object <commit> {
    $return = Config::Model::ValueComputer::_value_from_object($item{object},@arg ) ;
    1;
  }
  |  <skip:''> /[^\$]*/ { 
     my $result = $item[-1] ;
     $return = \$result ;
  }

object: <skip:''> /\$/ /[a-zA-Z]\w*/

function: <skip:''> '&' /\w+/

END_OF_GRAMMAR

1;


__END__


=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::Value>

=cut
