# $Author: ddumont $
# $Date: 2007-05-04 11:37:24 $
# $Name: not supported by cvs2svn $
# $Revision: 1.5 $

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
use Data::Dumper ;

use vars qw($VERSION $compute_grammar $compute_parser) ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/;

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

    # value_object is mostly used for error messages
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
    my $result_r = $compute_parser
      -> pre_compute
	(
	 $self->{user_formula},
	 1,
	 $self->{value_object},
	 $self->{user_var}
	) ;

    $self->{pre_formula} = $$result_r ;

    bless $self,$type ;
}

sub user_formula { return shift->{user_formula} ;}
sub user_var     { return shift->{user_var} ;}

sub compute {
    my $self = shift ;

    my $pre_formula = $self->{pre_formula};

    my $user_var = $self->compute_user_var ;

    return unless defined $user_var ;

    my $formula_r = $compute_parser
      -> compute ($pre_formula, 1,$self->{value_object}, $user_var) ;

    my $formula = $$formula_r ;

    return undef unless defined $formula ;

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

    my $orig_user_var = $self->{user_var} ;
    my $user_var = $self->compute_user_var ;
    my $str = "value is computed from '$self->{user_formula}'";

    return $str unless defined $user_var ;

    #print Dumper $user_var ;

    if (%$user_var) {
        $str .= ", where " ;
        foreach my $k (sort keys %$user_var) {
	    my $u_val = $user_var->{$k} ;
	    if (ref($u_val)) {
		map {
		    $str.= "\n\t\t'\$$k" . "{$_} is converted to '$orig_user_var->{$k}{$_}'";
		    } sort keys %$u_val ;
 	    }
	    else {
		my $val = defined $u_val ? $self->{value_object} ->grab($u_val) ->fetch 
		        :                  undef ;
		$str.= "\n\t\t'$k' from path '$orig_user_var->{$k}' is ";
		$str.= defined $val ? "'$val'" : 'undef' ;
	    }
	}
    }

    #$str .= " (evaluated as '$self->{formula}')"
    #  if $self->{user_formula} ne $self->{formula} ;

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
            my $value = $user_var{$key} ; # value may be undef
            next unless (defined $value and $value =~ /\$/) ;
            next if ref($value); # skip replacement rules
            print "key '$key', value '$value', left $var_left\n" 
	      if $::debug;
            my $res_r = $compute_parser
	      -> compute ($value, 1,$self->{value_object}, \%user_var);
	    my $res = $$res_r ;
            #return undef unless defined $res ;
            $user_var{$key} = $res ;
	    {
		no warnings "uninitialized" ;
		print "\tresult '$res' left $var_left, did $did_something\n" 
		  if $::debug;
	    }
	}

        my @var_left =  grep {defined $user_var{$_} && $user_var{$_} =~ /\$/} 
	  sort keys %user_var;

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
# $Revision: 1.5 $

# This grammar is compatible with Parse::RecDescent < 1.90 or >= 1.90
use strict;
use warnings ;
}

# computed value may return undef even if parsing is done right. To
# avoid getting problems with Parse::RecDescent (where undef means
# that the parsing did not match), we will always return a scalar
# reference to the actual returned value

pre_compute: <skip:''> pre_value[@arg](s) { 
    # print "pre-compute on @{$item[-1]}\n";
    my $str = join ( '', map { $$_ } @{ $item[-1] } ) ;
    $return =  \$str;
}

pre_value: 
  <skip:''> object '{' /\s*/ pre_value[@arg] /\s*/ '}' {
     # print "pre_value handling \$foo{ ... }\n";
     my $pre_value = ${ $item{pre_value} } ;
     my $object = $item{object};
     my $result = exists $arg[1]->{$object}{$pre_value} ?
       $arg[1]->{$object}{$pre_value} : 
       "\$".$object.'{'.$pre_value.'}';
     $return = \$result ;
  }
  | <skip:''> function '(' /\s*/ object /\s*/ ')' {
     # print "pre_value handling &foo(...)\n";
 
     # get now the object refered
     my $fetch_str = $arg[1]->{$item{object}} ;
     Config::Model::Exception::Formula
	 -> throw (
		   object => $arg[0],
		   error => "Item $item{object} has no associated location string"
		  ) 
         unless defined $fetch_str;

     my $object = $arg[0]->grab($fetch_str) ;

     if ($item{function} eq 'element') {
         my $result = $object->element_name ;
	 Config::Model::Exception::Model
	     -> throw (
		       object => $arg[0],
		       error => "'",$object->name,"' has no element name"
		      ) 
             unless defined $result ;
         $return = \$result ;
     }
     elsif ($item{function} eq 'index') {
	 my $result = $object->index_value ;
	 Config::Model::Exception::Formula
	     -> throw (
		       object => $arg[0],
		       error => "'",$object->name,"' has no index value"
		      ) 
             unless defined $result ;
	 $return = \$result ;
     }
     else {
	 Config::Model::Exception::Formula
	     -> throw (
		       object => $arg[0],
		       error => "Unknown computation function &$item{function}, ".
		       "expected &element(...) or &index(...)"
		      );
     }
  }
  | <skip:''> '&' /\w+/ (/\(\s*\)/)(?) {
     # print "pre_value handling &foo()\n";
     my $f_name = $item[3] ;
     my $method_name = $f_name eq 'element' ? 'element_name' 
                     : $f_name eq 'index'   ? 'index_value'  
                     :                         undef         ;

    Config::Model::Exception::Formula
        -> throw (
                  object => $arg[0],
                  error => "Unknown computation function &$f_name, "
                         . "expected &element or &index"
                 )
         unless defined $method_name;

    my $result =  $arg[0]->$method_name(); 
    $return = \$result ;

    Config::Model::Exception::Formula
        -> throw (
                  object => $arg[0],
                  error => "Missing $f_name attribute (method '$method_name' on "
                         . ref($arg[0]) . ")\n"
                 )
	       unless defined $result ;
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

compute:  <skip:''> value[@arg](s) { 
     # if one value is undef, return undef;
     my @values = map { $$_ } @{$item[-1]} ;
     # print "compute return is '",join("','",@values),"'\n";

     my $result = '';

     # return undef if one value is undef
     foreach my $v (@values) {
	 if (defined $v) {
	     $result .= $v ;
	 }
	 else {
	     $result = undef;
	     last;
	 }
     } 

     $return = \$result ;
  }

value: 
  <skip:''> object '{' <commit> /\s*/ value[@arg] /\s*/ '}' {
     my $object = $item{object};
     my $value = ${ $item{value} } ;

     # print "value: replacement object '$object', value '$value'\n";
     Config::Model::Exception::Formula
         -> throw (
		   object => $arg[0],
		   error => "Unknown replacement rule: $object\n"
		  )  
	 unless defined $arg[1]->{$object} ;

     my $result ;
     if (defined $value and $value =~ /\$/) {
         # must keep original variable
         $result = '$'.$object.'{'.$value.'}';
       }
     elsif (defined $value)
       {
         Config::Model::Exception::Formula
             -> throw (
                       object => $arg[0],
                        error => "Unknown replacement value for rule '$object': "
                               . "'$value'\n"
                      )
             unless  defined $arg[1]->{$object}{$value} ;

	 $result = $arg[1]->{$object}{$value} ;
       }
     $return = \$result ;
    }
  | object <commit> {
     my $name=$item{object} ;
     my $path = $arg[1]->{$name} ; # can be a ref for test purpose
     my $my_res ;
     # print "value: replace \$$name with path $path...\n";

     if (defined $path and $path =~ /\$/) {
         # print "compute rule skip name $name path '$path'\n";
         $my_res = "\$$name" ; # restore name that contain '$var'
     }
     elsif (defined $path) {
         # print "fetching var object '$name' with '$path'\n";
         $my_res = $arg[0]->grab_value($path) ;
         # print "fetched var object '$name' with '$path', result '", defined $return ? $return : 'undef',"'\n";

     }

     # my_res stays undef if $path if not defined

     $return = \$my_res ; # So I can return undef ... or a ref to undef
    1 ;
  }
  |  <skip:''> /[^\$]*/ { 
     my $result = $item[-1] ;
     $return = \$result ;
  }

object: <skip:''> /\$/ /\w+/

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
