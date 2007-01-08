# $Author: ddumont $
# $Date: 2007-01-08 12:48:23 $
# $Name: not supported by cvs2svn $
# $Revision: 1.4 $

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

package Config::Model::ValueComputer ;

use warnings ;
use strict;

use Scalar::Util qw(weaken) ;
use Carp ;
use Parse::RecDescent ;

use vars qw($VERSION $compute_grammar $compute_parser) ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;

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
            compute    => [ '$a + $b', a => '- av', b => '- bv' ],
            min        => -4,
            max        => 4,
          },
       [qw/sav sbv/] => {type => 'leaf',
                         value_type => 'string',
                      },
       compute_string =>
       => { type => 'leaf',
            value_type => 'string',
            compute => [ 'meet $a and $b', a => '- sav', b => '- sbv' ],
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
must have a C<compute> argument pointing to an array ref. 

This array ref contains:

=over

=item *

A string or a formula that use variables and subsitution function.

=item *

A set of variable and their relative location in the tree (using the
notation explained in 
L<grab() method|Config::Model::AnyThing/"grab(...)">

=item *

An optional set of substitution rules.

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
    compute => [ '$a + $b' , a => '- av', b => '- bv' ]
  }

In this string example, the default value of the C<Comp> element is
actually a string made of "C<macro is >" and the value of the
"C<macro>" element of the object located 2 nodes above:

   comp => { 
    type => 'leaf',
    value_type => 'string', 
    compute => [ '"macro is $m"' , m => '- - macro']]
   }

=head2 Compute substitution

Sometime, using the value of a tree leaf is not enough and you need to
substitute a replacement for any value you can get. This replacement
can be done using a hash like notation within the formula.

For instance, if you want to display a summary of a config, you can do :

 compute => [
   '$munge{$who} is the $munge{$what} of $munge{$country}'
    who   => '! who' ,
    what  => '! what' ,
    country => '- country',
    munge => {  chief => 'president', America => 'USA'}
    ]

=head2 Complex formula

C<&index>, C<&element>, and substitution can be combined. But the
argument of C<&element> or C<&index> can only be a value object
specification (I.e. something like 'C<- - foo>'), it cannot be a value
replacement of another C<&element> or C<&index>.

I.e. C<&element($foo)> is ok, but C<&element(&index($foo))> is not allowed.

=head2 computed variable

Compute variables can themselves be computed :

   compute => [
     'get_element is $element_table{$s}, indirect value is \'$v\'',
     's' => '! $where',
      where => '! where_is_element',
      v => '! $element_table{$s}',
      element_table => { qw/m_value_element m_value compute_element compute/ }
    ]

Be sure not to specify a loop when doing recursive computation.

=head2 compute override

In some case, a computed value must be interpreted as a default value
and the user must be able to override this computed default value.  In
this case, you must use C<< allow_compute_override => 1 >> with the
compute parameter:

   computed_value_with_override => { 
    type => 'leaf',
    value_type => 'string', 
    allow_compute_override => 1,
    compute => [ '"macro is $m"' , m => '- - macro']
   }

=cut

sub new {
    my $type = shift ;
    my %args = @_ ;
    my $self= {} ;

    foreach my $k (qw/user_formula user_var value_type value_object/) {
	$self->{$k}=delete $args{$k} || 
	  croak "Config::Model::ValueComputer:new undefined parameter $k";
    }

    die "Config::Model::ValueComputer:new unexpected parameter: ",
    join(' ',keys %args) if %args ;

    weaken($self->{value_object}) ;

    # create parser if needed 
    $compute_parser ||= Parse::RecDescent->new($compute_grammar) ;

    # must make a first pass at computation to subsitute index and
    # slot values.  leaves $xxx outside of $index or &slot untouched
    my $result = $compute_parser
      -> pre_compute
	(
	 $self->{user_formula},
	 1,
	 $self->{value_object},
	 $self->{user_var}
	) ;

    $self->{pre_formula} = $result ;

    bless $self,$type ;
}

sub compute {
    my $self = shift ;

    my $pre_formula = $self->{pre_formula};

    my $user_var = $self->compute_user_var ;

    return unless defined $user_var ;

    my $formula = $compute_parser
      -> compute ($pre_formula, 1,$self->{value_object}, $user_var) ;

    print "compute: pre_formula $pre_formula\n",
      "compute: rule to eval $formula\n" if $::debug;

    my $result = $self->{formula} = $formula ;

    if ($self->{value_type} =~ /(integer|number)/) {
        $result = eval $formula ;
        Config::Model::Exception::Formula
	    -> throw (
		      object => $self->{value_object},
		      error => "Rule $self->{compute}[0] "
		      . "(eval'ed as $formula) failed:\n$@"
		     ) 
	      if $@ ;
    }

    return $result ;
}

sub compute_info {
    my $self = shift;

    my $user_var = $self->compute_user_var ;
    my $str = "value is computed with '$self->{user_formula}'";

    return $str unless defined $user_var ;

    if (%$user_var) {
        $str .= " where " ;
        foreach my $k (sort keys %$user_var) {
            ## next if ref($user_var->{$k}) ;
            my $val 
	      = $self->{value_object}
		->grab($user_var->{$k})
		  ->fetch ;
            $val = '* MISSING *' unless defined $val ;
            $str.= "'$k'='$val', ";
	}
    }

    $str .= " (evaluated as '$self->{formula}')"
      if $self->{user_formula} ne $self->{formula} ;

    return $str ;
}

#internal
sub compute_user_var {
    my $self = shift ;

    # a shallow copy should be enough as we don't allow
    # substitution in replacement rules
    my %user_var = %{$self->{user_var}} ;

    # apply a compute on all user_var until no $var is left
    my $var_left = scalar (keys %user_var) + 1 ;

    while ($var_left) {
        my $old_var_left= $var_left ;
        my $did_something = 0 ;
        foreach my $key (keys %user_var) {
            my $value = $user_var{$key} ;
            next unless $value =~ /\$/ ;
            next if ref($value); # skip replacement rules
            print "key '$key', value '$value', left $var_left\n" 
	      if $::debug;
            my $res = $compute_parser
	      -> compute ($value, 1,$self->{value_object}, \%user_var);
            return undef unless defined $res ;
            $user_var{$key} = $res ;
            print "\tresult '$res' left $var_left, did $did_something\n" 
              if $::debug;
	}

        my @var_left =  grep {$user_var{$_} =~ /\$/} sort keys %user_var;
        $var_left = @var_left ;

        Config::Model::Exception::Formula
	    -> throw (
		      object => $self->{value_object},
		      error => "Can't resolve user variable: '"
		      . join ("','",@var_left) . "'"
		     ) 
	      unless ($var_left < $old_var_left);
    }

    return \%user_var ;
}

$compute_grammar = << 'END_OF_GRAMMAR' ;

{
# $Revision: 1.4 $

# This grammar is compatible with Parse::RecDescent < 1.90 or >= 1.90
use strict;
use warnings ;
}

pre_compute: <skip:''> pre_value[@arg](s) 
  { 
    my $str = join ('',@{$item[-1]}) ;
    $return =  $str;
  }

pre_value: 
  <skip:''> object '{' /\s*/ pre_value[@arg] /\s*/ '}' 
    {
     # print "pre_value handling \$foo{ ... }\n";
     my $pre_value = $item{pre_value} ;
     my $object = $item{object};
     $return = exists $arg[1]->{$object}{$pre_value} ?
       $arg[1]->{$object}{$pre_value} : 
       "\$".$object.'{'.$pre_value.'}';
    }
  | <skip:''> function '(' /\s*/ object /\s*/ ')'
  {
      # print "pre_value handling &foo(...)\n";
 
   # get now the object refered
   my $fetch_str = $arg[1]->{$item{object}} ;
   Config::Model::Exception::Formula->throw
    (
      object => $arg[0],
      error => "Item $item{object} has no associated location string"
    ) unless defined $fetch_str;

   my $object = $arg[0]->grab($fetch_str) ;

   if ($item{function} eq 'element')
   {
     my $result = $object->element_name ;
     Config::Model::Exception::Model->throw
     (
       object => $arg[0],
       error => "'",$object->name,"' has no element name"
     ) unless defined $result ;
     $return = $result ;
   }
   elsif ($item{function} eq 'index')
   {
     my $result = $object->index_value ;
     Config::Model::Exception::Formula->throw
     (
      object => $arg[0],
      error => "'",$object->_name,"' has no index value"
     ) unless defined $result ;
     $return = $result ;
   }
   else
   {
     Config::Model::Exception::Formula->throw
     (
      object => $arg[0],
      error => "Unknown computation function &$item{function}, ".
               "expected &element(...) or &index(...)"
     );
   }
  }
  | <skip:''> '&' /\w+/ (/\(\s*\)/)(?)  
  {
    # print "pre_value handling &foo()\n";
    my $f_name = $item[3] ;
    my $method_name = $f_name eq 'element' ? 'element_name' : 
      $f_name eq 'index' ? 'index_value' : undef;

    Config::Model::Exception::Formula->throw
     (
      object => $arg[0],
      error => "Unknown computation function &$f_name, ".
               "expected &element or &index"
     ) unless defined $method_name;

    $return = $arg[0]->$method_name();

    Config::Model::Exception::Formula->throw
     (
      object => $arg[0],
      error => "Missing $f_name attribute (method '$method_name' on "
                . ref($arg[0]) . ")\n"
     ) unless defined $return ;
  }
  | object 
  {
    # print "pre_value handling \$foo\n";
    my $object = $item{object};
    $return ="\$".$object ;
  }
  |  <skip:''> /[^\$&]*/

compute:  <skip:''> value[@arg](s) 
  { 
    # if one value is undef, return undef;
    my @values = @{$item[-1]} ;
    # print "compute return is '",join("','",@values),"'\n";

    $return = join ('',@values) ;
  }

value: 
  <skip:''> object '{' <commit> /\s*/ value[@arg] /\s*/ '}' 
    {
     my $object = $item{object};
     my $value = $item{value} ;

     # print "value: replacement object '$object', value '$value'\n";
     Config::Model::Exception::Formula->throw
     (
      object => $arg[0],
      error => "Unknown replacement rule: $object\n"
     )  unless defined $arg[1]->{$object} ;

     if ($value =~ /\$/)
       {
         # must keep original variable
         $return = '$'.$object.'{'.$value.'}';
       }
     else
       {
         Config::Model::Exception::Formula->throw
           (
             object => $arg[0],
             error => "Unknown replacement value for rule '$object': "
                  ."'$value'\n"
           ) unless  defined $arg[1]->{$object}{$value} ;

	 $return = $arg[1]->{$object}{$value} ;
       }
    }
  | object <commit>
  {
    my $name=$item{object} ;
    my $path = $arg[1]->{$name} ; # can be a ref for test purpose
    # print "value: replace \$$name...\n";

    Config::Model::Exception::Formula->throw
      (
         object => $arg[0],
         error => "undefined formula variable: '$name', expected '".
	           join("','", keys(%{$arg[1]}))."'"
      ) unless defined $path;

    if ($path =~ /\$/)
      {
        # print "compute rule skip name $name path '$path'\n";
        $return = "\$$name" ; # restore name that contain '$var'
      }
    else
      {
        # print "fetching var object '$name' with '$path'\n";
        $return = $arg[0]->grab_value($path) ;
        # print "fetched var object '$name' with '$path', result '", defined $return ? $return : 'undef',"'\n";

        Config::Model::Exception::WrongValue->throw
          (
            object => $arg[0],
            error => "formula variable grabbed with '$path' has an undefined value"
          ) unless defined $return ;
       }
    1 ;
  }
  |  <skip:''> /[^\$]*/

object: <skip:''> /\$/ /\w+/

function: <skip:''> '&' /\w+/

END_OF_GRAMMAR

1;

__END__


=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::Value>

=cut
