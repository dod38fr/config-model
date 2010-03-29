
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
our $VERSION="1.201";

use Scalar::Util qw(weaken) ;
use Carp ;

# use vars qw($VERSION) ;



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
                      computed_refer_to 
                      => { formula => '  ! host:$h if ',
                           variables => { h => '- node_host' }
                         }
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
L<Config::Model::HashId> or the content of a L<Config::Model::ListId>
object.

This class is also used by L<Config::Model::CheckList> to define the
cheklist items from the keys of another hash (or content of a list).

=head1 CONSTRUCTOR

Construction is handled by the calling object. 

=cut

# config_elt is a reference to the object that called new

sub new {
    my $type = shift ;
    my %args = @_ ;
    my $self = {} ;

    if ($::debug) {
	my %show = %args ;
	delete $show{config_elt} ;
	print Data::Dumper->Dump([\%show],['IdElementReference_new_args']) ;
    }

    my $obj = $self->{config_elt} = delete $args{config_elt} || 
      croak "Config::Model::IdElementReference:new undefined parameter config_elt";

    bless $self,$type ;

    my $found = 0 ;
    map { $self->{$_} = delete $args{$_}; $found++ } 
      grep {defined $args{$_}} qw/refer_to computed_refer_to/ ;

    if (not $found ) {
	Config::Model::Exception::Model 
	    -> throw (
		      object => $obj,
		      message => "missing " 
                               . "refer_to or computed_refer_to parameter"
		     ) ;
    }
    elsif ($found > 1 ) {
	Config::Model::Exception::Model 
	    -> throw (
		      object => $obj,
		      message => "cannot specify both "
                               . "refer_to and computed_refer_to parameters" 
		     ) ;
    }

    Config::Model::Exception::Model 
	    -> throw (
		      object => $obj,
		      message => "IdElementReference unexpected parameter: "
		               . join(' ',keys %args)
		      ) 
	      if %args ;

    weaken($self->{config_elt}) ;


    my $rft  = $self->{refer_to};
    my $crft = $self->{computed_refer_to} || {} ;
    my %c_args = %$crft ;

    my $refer_path = defined $rft ? $rft
                   :                delete $c_args{formula} ;


    # split refer_path on + then create as many ValueComputer as
    # required
    my @references =  split /\s+\+\s+/, $refer_path ;

    foreach my $single_path (@references) {
	push @{$self->{compute}}, Config::Model::ValueComputer
	  -> new (
		  formula => $single_path ,
		  variables => {} ,
		  %c_args,
		  value_object => $self->{config_elt} ,
		  value_type => 'string'   # a reference is always a string
		 );
    }

    return $self ;
}

=head1 Config class parameters

=over

=item refer_to

C<refer_to> is used to specify a hash element that will be used as a
reference. C<refer_to> points to an array or hash element in the
configuration tree using the path syntax (See
L<Config::Model::Node/grab> for details).

=item computed_refer_to

When C<computed_refer_to> is used, the path is computed using values
from several elements in the configuration tree. C<computed_refer_to>
is a hash with 2 mandatory elements: C<formula> and C<variables>.

=back

The available choice of this (computed or not) reference value is made
from the available keys of the refered_to hash element or the values
of the refered_to array element.

The example means the the value must correspond to an existing host:

 value_type => 'reference',
 refer_to => '! host' 

This example means the the value must correspond to an existing lan
within the host whose Id is specified by hostname:

 value_type => 'reference',
 computed_refer_to => { formula => '! host:$a lan', 
                        variables => { a => '- hostname' }
                      }

If you need to combine possibilities from several hash, use the "C<+>"
token to separate 2 paths:

 value_type => 'reference',
 computed_refer_to => { formula => '! host:$a lan + ! host:foobar lan', 
                        variables => { a => '- hostname' }
                      }

You can specify C<refer_to> or C<computed_refer_to> with a C<choice>
argument so the possible enum value will be the combination of the
specified choice and the refered_to values.

=cut


# internal
sub get_choice_from_refered_to {
    my $self = shift ;

    my $config_elt = $self->{config_elt} ;
    my @enum_choice = $config_elt -> get_default_choice ;

    foreach my $compute_obj (@{$self->{compute}}) {
	my $user_spec = $compute_obj->compute ;

	next unless defined $user_spec ;

	my @path = split (/\s+/,$user_spec) ;

	print "get_choice_from_refered_to:\n\tpath: @path\n"
	  if $::debug ;

	my $refered_to = 
	  eval { 
	    $config_elt->grab("@path"); 
	} ;

	if ($@) {
	    my $e = $@ ;
	    my $msg = $e ? $e->full_message : '' ;
	    Config::Model::Exception::Model
		-> throw (
			  object => $config_elt,
			  error => "'refer_to' parameter: " . $msg
			 ) ;
	}

	my $element = pop @path ;
	my $obj = $refered_to -> parent ;
	my $type = $obj->element_type($element) ;

	my @choice ;
	if ($type eq 'check_list') {
	    @choice = $obj->fetch_element($element)->get_checked_list();
	}
	elsif ( $type eq 'hash') {
	    @choice = $obj->fetch_element($element)->get_all_indexes();
	}
	elsif ( $type eq 'list') {
	    my $list_obj = $obj->fetch_element($element) ;
	    my $ct = $list_obj-> get_cargo_type ;
	    if ($ct eq 'leaf') {
		@choice = $list_obj->fetch_all_values();
	    }
	    else {
		Config::Model::Exception::Model 
		    -> throw (
			  object => $obj,
			      message => "element '$element' cargo_type is $ct. "
			      ."Expected 'leaf'"
			     ) ;
	    }
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
	push @enum_choice, @choice ;
    }

    # prune out repeated items
    my %h ;
    my @unique = grep { my $found = $h{$_} || 0; $h{$_} = 1; not $found ; }
      @enum_choice ; 

    my @res ;
    if ($config_elt->value_type eq 'check_list' and $config_elt->ordered) {
	@res = @unique ;
    } 
    else {
	@res = sort @unique ;
    }

    print "get_choice_from_refered_to:\n\tSetting choice to '", 
      join("','",@res),"'\n"
	if $::debug ;

    $config_elt->setup_reference_choice(@res) ;
}

=head1 Methods

=head2 reference_info

Returns a human readable string with explains how is retrieved the
reference. This method is mostly used to construct an error messages.

=cut

sub reference_info {
    my $self = shift ;
    my $str = "choice was retrieved with: " ;

    foreach my $compute_obj (@{$self->{compute}}) {
	my $path = $compute_obj->formula ;
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
    return map { $_ -> formula } @{$self->{compute}}
}

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Value>,
L<Config::Model::AnyId>, L<Config::Model::CheckList>

=cut

1;
