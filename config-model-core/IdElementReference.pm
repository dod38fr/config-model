# $Author: ddumont $
# $Date: 2007-07-26 12:21:14 $
# $Name: not supported by cvs2svn $
# $Revision: 1.2 $

#    Copyright (c) 2007 Dominique Dumont.
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

package Config::Model::IdElementReference ;

use warnings ;
use strict;

use Scalar::Util qw(weaken) ;
use Carp ;

use vars qw($VERSION) ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;


=head1 NAME

Config::Model::IdElementReference - Refer to id element(s) and extract keys

=head1 SYNOPSIS

 # used from a value class
 element => [
            node_host => { type => 'leaf',
			   value_type => 'reference' ,
			   refer_to => '! host'
			 },
            if   => { type => 'leaf',
                      value_type => 'reference' ,
                      refer_to => [ '  ! host:$h if ', h => '- node_host' ]
                    },
            ],

  # used from checklist
  element => [
	      # simple reference, checklist items are given by the
	      # keys of my_hash
	      refer_to_list => { type => 'check_list',
				 refer_to => '- my_hash'
			       },

	      # checklist items are given by combining my_hash*
	      refer_to_2_list
                            => { type => 'check_list',
				 refer_to => '- my_hash + - my_hash2   + - my_hash3'
			       },
             ]


=head1 DESCRIPTION

This class is user by L<Config::Model::Value> to set up an enumerated
value where the possible choice depends on the key of a
L<Config::Model::AnyId> object. 

This class is also used by L<Config::Model::CheckList> to define the
cheklist items from the keys of another hash.

=head1 CONSTRUCTOR

Construction is handled by the calling object. 

=cut

# config_elt is a reference to the object that called new

sub new {
    my $type = shift ;
    my %args = @_ ;
    my $self= {} ;

    foreach my $k (qw/config_elt refer_to/) {
	$self->{$k} = delete $args{$k} || 
	  croak "Config::Model::IdElementReference:new undefined parameter $k";
    }

    croak "Config::Model::IdElementReference:new unexpected parameter: ",
      join(' ',keys %args) if %args ;

    weaken($self->{config_elt}) ;

    bless $self,$type ;

    my $refto = $self->{refer_to} ;
    my ($refer_path,%var) = ref $refto ? @$refto : ($refto) ;

    # split refer_path on + then create as many ValueComputer as
    # required
    my @references =  split /\s+\+\s+/, $refer_path ;

    foreach my $single_path (@references) {
	push @{$self->{compute}}, Config::Model::ValueComputer
	  -> new (
		  user_formula => $single_path ,
		  user_var => \%var ,
		  value_object => $self->{config_elt} ,
		  value_type => 'string'   # a reference is always a string
		 );
    }

    return $self ;
}

=head1 Config class parameters

=head2 refer_to parameter

C<refer_to> is used to spepify the hash element that will be used as a
reference.

=over

=item * 

The first argument of C<refer_to> points to an array or hash element
in the configuration tree using the path syntax (See
L<Config::Model::Node/grab> for details). This path is treated like a
computation formula. Hence it can contain variable and substitution
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

    my %enum_choice = map { ($_ => 1 ) } 
      $self->{config_elt}->get_default_choice ;

    foreach my $compute_obj (@{$self->{compute}}) {
	my $user_spec = $compute_obj->compute ;

	next unless defined $user_spec ;

	my @path = split (/\s+/,$user_spec) ;

	my $element = pop @path ;

	print "get_choice_from_refered_to:\n\tpath: @path, element $element\n"
	  if $::debug ;

	my $obj = $self->{config_elt}->grab("@path");

	Config::Model::Exception::UnknownElement
	    -> throw (
		      object => $obj,
		      element => $element,
		      info => "Error related to 'refer_to' element of '".
		      $self->{config_elt}->parent->config_class_name() . "'"
		      .$self->reference_info() 
		     ) 
	      unless  $obj->is_element_available(name => $element) ;

	my $type = $obj->element_type($element) ;

	my @choice ;
	if ($type eq 'check_list') {
	    @choice = $obj->fetch_element($element)->get_checked_list();
	}
	elsif ( $type eq 'hash' or $type eq 'list') {
	    @choice = $obj->fetch_element($element)->get_all_indexes();
	}
	else {
	    Config::Model::Exception::Model 
		-> throw (
			  object => $obj,
			  message => "element '$element' type is $type. "
			  ."Expected hash or list or check_list"
			 ) ;
	}

	# use a hash so choices are unique
	map { $enum_choice{$_} = 1 } @choice ;
    }

    print "get_choice_from_refered_to:\n\tSetting choice to '", 
      join("','",sort keys %enum_choice),"'\n"
	if $::debug ;

    $self->{config_elt}->setup_reference_choice(sort keys %enum_choice) ;
}

=head1 Methods

=head2 reference_info

Returns a human readable string with explains how is retrieved the
reference. This method is mostly used to construct an error messages.

=cut

sub reference_info {
    my $self = shift ;
    my $str = "Choice was retrieved with: " ;

    foreach my $compute_obj (@{$self->{compute}}) {
	my $path = $compute_obj->user_formula ;
	$path = defined $path ? "'$path'" : 'undef' ;
	$str .= "\n\tpath $path" ;
	$str .= "\n\t" . $compute_obj->compute_info ;
    }
    return $str ;
}

sub compute_obj {
    my $self = shift ;
    return @{$self->{compute}} ;
}

sub reference_path {
    my $self = shift ;
    return map { $_ -> user_formula } @{$self->{compute}}
}

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Value>,
L<Config::Model::AnyId>, L<Config::Model::CheckList>

=cut

1;
