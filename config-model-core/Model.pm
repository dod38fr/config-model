# $Author: ddumont $
# $Date: 2006-03-10 15:57:54 $
# $Name: not supported by cvs2svn $
# $Revision: 1.10 $

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

package Config::Model ;
require Exporter;
use Carp;
use strict;
use warnings FATAL => qw(all);
use vars qw/@ISA @EXPORT @EXPORT_OK $VERSION/;

use Config::Model::Instance ;

# this class holds the version number of the package
use vars qw($VERSION @status @level @permission_list %permission_index) ;

$VERSION = '0.502';

=head1 NAME

Config::Model - Model to create configuration validation tool

=head1 DESCRIPTION

Using Config::Model, a typical configuration validation tool will be
made of 3 parts :

=over

=item 1

The user interface

=item 2

The validation engine which is in charge of validating all the
configuration information provided by the user.

=item 3

The storage facility that store the configuration information

=back

C<Config::Model> provides a B<validation engine> according to a set of
rules.

=head1 User interface

The user interface will use some parts of the API to set and get
configuration values. More importantly, a generic user interface will
need to explore the configuration model to be able to generate at
run-time relevant configuration screens.

A generic Curses interface is under development. More on this later.

One can also consider to use Webmin (L<http://www.webmin.com>) on top
of config model.

=head1 Storage

The storage will often be a way to store configuration in usual
configuration files, like C</etc/X11/xorg.conf>

One can also consider storing configuration data in a database, ldap
directory or using elektra project L<http://www.libelektra.org/>

=head1 Validation engine

C<Config::Model> provides a way to get a validation engine from a set
of rules. This set of rules is now called the configuration model. 

=head1 Configuration Model

Before talking about a configuration tree, we must create a
configuration model that will set all the properties of the validation
engine you want to create.

=head2 Constructor

Simply call new without parameters:

 my $model = Config::Model -> new ;

This will create an empty shell for you model.

=cut

sub new {
    my $type = shift ;
    bless {},$type;
}

=head2 declaring the model

The configuration model is expressed in a declarative form (i.e. a
Perl data structure which is always easier to maintain than a lot of
code.)

Each node of the configuration tree is attached to a configuration
class whose properties you must declare by calling
L</"create_config_class">.

Each configuration class contains mostly 2 types of elements:

=over

=item *

A node type element that will refer to another configuration class

=item *

A value element that will contains actual configuration data

=back

By declaring a set of configuration classes and refering them in node
element, you will shape the structure of your configuration tree.

The structure of the configuration data must be based on a tree
structure. This structure has several advantages:

=over

=item *

Unique path to get to a node or a leaf.

=item *

Simpler exploration and query

=item *

Simple hierarchy. Deletion of configuration items is simpler to grasp:
when you cut a branch, all the leaves attaches to that branch go down.

=back

But using a tree has also some drawbacks:

=over 4

=item *

A complex configuration cannot be mapped on a simple tree.  Some more
relation between nodes and leaves must be added.

=item *

Some configuration part are actually graph instead of a tree (for
instance, any configuration that will map a service to a
resource). The graph relation must be decomposed in a tree with
special I<reference> relation. See L<Config::Model::Value/Value Reference>

=back

Note: a configuration tree is a tree of objects. The model is declared
with classes. The classes themselves have relations that closely match
the relation of the object of the configuration tree. But the class
need not to be declared in a tree structure (always better to reuse
classes). But they must be declared as a DAG (directed acyclic graph).

=begin html

<a href="http://en.wikipedia.org/wiki/Directed_acyclic_graph">More on DAGs</a>

=end html

Each configuration class declaration specifies:

=over 8

=item *

Most importantly, the type of the element (mostly C<leaf>, or C<node>)

=item *

The properties of each element (boundaries, check, integer or string,
enum like type ...)

=item *

The default values of parameters (if any)

=item *

Mandatory parameters

=item *

Targeted audience (intermediate, advance, master)

=item *

On-line help (for ach parameter or value of parameter)

=item *

The level of expertise of each parameter (to hide expert parameters
from newbie eyes)

=back

See L<Config::Model::Node> for details on how to declare a
configuration class.

=cut


=head1 Configuration instance

A configuration instance if the staring point of a configuration tree.
When creating a model instance, you must specify the root class name, I.e. the
configuration class that is used by the root node of the tree. 

 my $model = Config::Model->new() ;
 $model ->create_config_class 
  (
   name => "SomeRootClass",
   element => [ ...  ]
  ) ;

 my $inst = $model->instance (root_class_name => 'SomeRootClass', 
                              instance_name => 'test1');

You can create several separated instances from a model.

=cut

sub instance {
    my $self = shift ;
    my %args = @_ ;
    my $root_class_name =  $args{root_class_name}
      or croak "Model: can't create instance without root_class_name ";
    my $instance_name =  $args{instance_name}
      or croak "Model: can't create instance without instance_name ";

    if (defined $self->{instance}{$instance_name}{$root_class_name}) {
	return $self->{instance}{$instance_name}{$root_class_name} ;
    }

    my $i = Config::Model::Instance 
      -> new (config_model => $self,
	      root_class_name => $root_class_name) ;

    $self->{instance}{$instance_name}{$root_class_name} = $i ;
    return $i ;
}

=head1 Configuration class

A configuration class is made of series of elements which are detailed
in L<Config::Model::Node>.

Whatever its type (node, leaf,... ), each element of a node has
several other properties:

=over

=item permission

By using the C<permission> parameter, you can change the permission
level of each element. Authorized privilege values are C<master>,
C<advanced> and C<intermediate>.

=cut

@permission_list = qw/intermediate advanced master/;

=item level

Level is C<important>, C<normal> or C<hidden>. 

The level is used to set how configuration data is presented to the
user in browsing mode. C<Important> elements will be shown to the user
no matter what. C<hidden> elements will be explained with the I<warp>
notion.

=cut

@level = qw/hidden normal important/;

=item status

Status is C<obsolete>, C<deprecated> or C<standard> (default).

Using a deprecated element will issue a warning. Using an obsolete
element will raise an exception.

=cut

@status = qw/obsolete deprecated standard/;

=item description

Description of the element. This description will be used when
generating user interfaces.

=back 

Example:

  my $model = Config::Model -> new ;

  $model->create_config_class 
  (
   config_class_name => 'SomeRootClass',
   permission        => [ [ qw/tree_macro warp/ ] => 'advanced'] ,
   description       => [ X => 'X-ray' ],
   class_description => "SomeRootClass description",
   element           => [ ... ] 
  ) ;

Again, see L<Config::Model::Node> for more details on configuration
class declaration.

=cut

my %default_property =
  (
   status     => 'standard',
   level      => 'normal',
   permission => 'intermediate',
   description=> ''
  );

my %check;

{
  my $idx = 0 ;
  map ($check{level}{$_}=$idx++, @level);
  $idx = 0 ;
  map ($check{status}{$_}=$idx++, @status);
  $idx = 0 ;
  map ($permission_index{$_}=$idx++, @permission_list);
}

$check{permission}=\%permission_index ;

# unpacked model is:
# {
#   element_list => [ ... ],
#   permission   => { element_name => <permission> },
#   status       => { element_name => <status>     },
#   description  => { element_name => <string> },
#   element      => { element_name => element_data (left as is)    },
#   class_description => <class description string>,
#   level        => { element_name => <level like important or normal..> },
# }

sub create_config_class {
    my $self=shift ;
    my %raw_model = @_ ;

    my $config_class_name = delete $raw_model{name} or
      croak "create_one_config_class: no config class name" ;

    if (exists $self->{model}{$config_class_name}) {
	Config::Model::Exception::ModelDeclaration->throw
	    (
	     error=> "create_one_config_class: attempt to clobber $config_class_name".
	     "config class name "
	    );
    }

    $self->{raw_model}{$config_class_name} = \%raw_model ;

    # perform some syntax and rule checks and expand compacted
    # elements ie  [qw/foo bar/] => {...} is transformed into
    #  foo => {...} , bar => {...} before being stored

    my %raw_copy = %raw_model ;
    my @element_list ;

    # first get the element list
    my @compact_list = @{$raw_copy{element}} ;
    while (@compact_list) {
	my ($item,$info) = splice @compact_list,0,2 ;
	# store the order of element as declared in 'element'
	push @element_list, ref($item) ? @$item : ($item) ;
    }

    my %model = (element_list => \@element_list);

    my @legal_params = qw/permission status description element level/;

    foreach my $info_name (@legal_params) {
	# fill default info
	map {$model{$info_name}{$_} = $default_property{$info_name}; }
	  @element_list 
	    if defined $default_property{$info_name};

	my $compact_info = delete $raw_copy{$info_name} ;
	next unless defined $compact_info ;

	Config::Model::Exception::ModelDeclaration->throw
	    (
	     error=> "Data for parameter $info_name of $config_class_name"
	     ." is not an array ref"
	    ) unless ref($compact_info) eq 'ARRAY' ;

	my @info = @$compact_info ; 
	while (@info) {
	    my ($item,$info) = splice @info,0,2 ;
	    my @element_names = ref($item) ? @$item : ($item) ;

	    Config::Model::Exception::ModelDeclaration->throw
		(
		 error=> "create class $config_class_name: unknown ".
		 "value for $info_name: '$info'. Expected '".
		 join("', '",keys %{$check{$info_name}})."'"
		)
		  if defined $check{$info_name} 
		    and not defined $check{$info_name}{$info} ;

	    foreach my $name (@element_names) {
		$model{$info_name}{$name} = $info ;
	    }
	}
    }

    # copy description of configuration class
    $model{class_description} = delete $raw_copy{class_description} ;

    my @left_params = keys %raw_copy ;
    Config::Model::Exception::ModelDeclaration->throw
        (
         error=> "create class $config_class_name: unknown ".
	 "parameter '" . join("', '",@left_params)."', expected '".
	 join("', '",@legal_params,qw/class_description/)."'"
        )
	  if @left_params ;


    $self->{model}{$config_class_name} = \%model ;

    return $self ;
}

=head1 Model query

=head2 get_model( config_class_name )

Return a hash containing the model declaration.

=cut

sub get_model {
    my $self =shift ;
    my $config_class_name = shift ;

    return $self->{model}{$config_class_name} ||
      croak "get_model error: unknown config class name: $config_class_name";
}

=head2 get_element_name( class => Foo, for => advanded )

Get all names of the elements of class C<Foo> that are accessible for
level C<advanded>. 

Level can be C<master> (default), C<advanded> or C<intermediate>.

=cut

sub get_element_name {
    my $self = shift ;
    my %args = @_ ;

    my $class = $args{class} || 
      croak "get_element_name: missing 'class' parameter" ;
    my $for = $args{for} || 'master' ;

    croak "get_element_name: wrong 'for' parameter. Expected ", 
      join (' or ', @permission_list) 
	unless defined $permission_index{$for} ;

    my @catalogs 
      = ( @permission_list[ $permission_index{$for} .. $#permission_list ] );
    my @array
      = $self->get_element_with_permission($class,@catalogs);

    return wantarray ? @array : join( ' ', @array );
}

# internal
sub get_element_with_permission {
    my $self      = shift ;
    my $class     = shift ;

    my $model = $self->get_model($class) ;
    my @result ;

    # this is a bit convoluted, but the order of the returned element
    # must respect the order of the elements declared in the model by
    # the user
    foreach my $elt (@{$model->{element_list}}) {
	foreach my $permission (@_) {
	    push @result, $elt
	      if $model->{level}{$elt} ne 'hidden' 
		and $model->{permission}{$elt} eq $permission ;
	}
    }

    return @result ;
}

#internal
sub get_element_property {
    my $self = shift ;
    my %args = @_ ;

    my $elt = $args{element} || 
      croak "get_element_property: missing 'element' parameter";
    my $prop = $args{property} || 
      croak "get_element_property: missing 'property' parameter";
    my $class = $args{class} || 
      croak "get_element_property:: missing 'class' parameter";

    return $self->{model}{$class}{$prop}{$elt} ;
}

=head1 Error handling

Errors are handled with an exception mechanism (See
L<Exception::Class>).

When a strongly typed Value object gets an authorized value, it raises
an exception. If this exception is not catched, the programs exits.

See L<Config::Model::Exception|Config::Model::Exception> for details on
the various exception classes provided with C<Config::Model>.

=head1 Log and Traces

Currently a rather lame trace mechanism is provided:

=over

=item *

Set C<$::debug> to 1 to get debug messages on STDOUT.

=item *

Set C<$::verbose> to 1 to get verbose messages on STDOUT.

=back

Depending on available time, a better log/error system may be
implemented.

=head1 AUTHOR

Dominique Dumont, domi@komarr.grenoble.hp.com

=head1 SEE ALSO

L<Config::Model::Instance>, 
L<Config::Model::Node>, 
L<Config::Model::HashId>,
L<Config::Model::ListId>,
L<Config::Model::Value>

=cut
