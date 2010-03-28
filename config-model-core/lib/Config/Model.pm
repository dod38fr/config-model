# copyright at the end of the file in the pod section

package Config::Model ;
require Exporter;
use Carp;
use strict;
use warnings FATAL => qw(all);
use Storable ('dclone') ;
use Data::Dumper ();
use Log::Log4perl qw(get_logger :levels);


use Config::Model::Instance ;

# this class holds the version number of the package
use vars qw($VERSION @status @level @experience_list %experience_index) ;

$VERSION = '1.001';

=head1 NAME

Config::Model - Framework to create configuration validation tools and editors

=head1 SYNOPSIS

 # create new Model object
 my $model = Config::Model->new() ;

 # create config model
 $model ->create_config_class 
  (
   name => "SomeRootClass",
   element => [ ...  ]
  ) ;

 # create instance 
 my $instance = $model->instance (root_class_name => 'SomeRootClass', 
                                  instance_name => 'test1');

 # get configuration tree root
 my $cfg_root = $instance -> config_root ;

 # You can also use load on demand
 my $model = Config::Model->new() ;

 # this call will look for a AnotherClass.pl that will contain
 # the model
 my $inst2 = $model->instance (root_class_name => 'AnotherClass', 
                              instance_name => 'test2');

 # then get configuration tree root
 my $cfg_root = $inst2 -> config_root ;

=head1 DESCRIPTION

Using Config::Model, a typical configuration validation tool will be
made of 3 parts :

=over

=item 1

A reader and writer that will parse the configuration file and transform in a tree representation within Config::Model. The values contained in this configuration tree can be written back in the configuraiton file(s).

=item 2

A validation engine which is in charge of validating the content and
structure of configuration stored in the configuration tree. This
validation engine will follow the structure and constraint declared in
a configuration model. This model is a kind of schema for the
configuration tree.

=item 3

A user interface to modify the content of the configuration tree. A
modification will be validated instantly by the validation engine.

=back

=head1 Storage backend, configuration reader and writer

See L<Config::Model::AutoRead> for details

=head1 Validation engine

C<Config::Model> provides a way to get a validation engine from a set
of rules. This set of rules is called the configuration model. 

=head1 User interface

The user interface will use some parts of the API to set and get
configuration values. More importantly, a generic user interface will
need to explore the configuration model to be able to generate at
run-time relevant configuration screens.

Simple text interface if provided in this module. Curses and Tk interfaces are provided by L<Config::Model::CursesUI> and L<Config::Model::TkUI>.

=head1 Constructor

Simply call new without parameters:

 my $model = Config::Model -> new ;

This will create an empty shell for your model.

=cut

sub new {
    my $type = shift ;
    my %args = @_;

    my $skip =  $args{skip_include} || 0 ;

    my $self = { model_dir => $args{model_dir},
		 legacy    => $args{legacy}  || 'warn' ,
		 skip_include => $skip ,
	       } ;
    bless $self,$type ;

    if (defined $args{skip_inheritance}) {
	$self->legacy("skip_inheritance is deprecated, use skip_include") ;
	$self->{skip_include} = $args{skip_inheritance} ;
    }

    return $self ;
}

sub legacy {
    my $self = shift ;
    my $behavior = $self->{legacy} ;

    if ($behavior eq 'die') {
	die @_,"\n";
    }
    elsif ($behavior eq 'warn') {
	warn @_,"\n";
    }
}

=head1 Configuration Model

To validate a configuration tree, we must create a configuration model
that will set all the properties of the validation engine you want to
create.

The configuration model is expressed in a declarative form (i.e. a
Perl data structure which is always easier to maintain than a lot of
code)

Each configuration class contains a set of:

=over

=item *

node element that will refer to another configuration class

=item *

value element that will contains actual configuration data

=item *

List or hash of node or value elements

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

The C<name> of the class (mandatory)

=item *

A C<class_description> used in user interfaces (optional)

=item *

Optional include specification to avoid duplicate declaration of elements.

=item *

The class elements

=back

Each element will feature:

=over

=item 8

Most importantly, the type of the element (mostly C<leaf>, or C<node>)

=item *

The properties of each element (boundaries, check, integer or string,
enum like type ...)

=item *

The default values of parameters (if any)

=item *

Mandatory parameters

=item *

Targeted audience (beginner, advance, master)

=item *

On-line help (for each parameter or value of parameter)

=item *

The level of expertise of each parameter (to hide expert parameters
from newbie eyes)

=back

See L<Config::Model::Node> for details on how to declare a
configuration class.

Example:

 $ cat lib/Config/Model/models/Xorg.pl
 [
   {
     name => 'Xorg',
     class_description => 'Top level Xorg configuration.',
     include => [ 'Xorg::ConfigDir'],
     element => [
                 Files => {
                           type => 'node',
                           description => 'File pathnames',
                           config_class_name => 'Xorg::Files'
                          },
                 # snip
                ]
   },
   {
     name => 'Xorg::DRI',
     element => [
                 Mode => {
                          type => 'leaf',
                          value_type => 'uniline',
                          description => 'DRI mode, usually set to 0666'
                         }
                ]
   }
 ];

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

 # instance name is 'default' 
 my $inst = $model->instance (root_class_name => 'SomeRootClass');

You can create several separated instances from a model using 
C<name> option:

 # instance name is 'default' 
 my $inst = $model->instance (root_class_name => 'SomeRootClass', 
                              name            => 'test1');


Usually, model files will be loaded automatically depending on
C<root_class_name>. But you can choose to specify the file containing
the model with C<model_file> parameter. This is mostly useful for
tests.

=cut

sub instance {
    my $self = shift ;
    my %args = @_ ;

    my $instance_name =  delete $args{instance_name} || delete $args{name} 
      || 'default';

    if (defined $self->{instance}{$instance_name}) {
	return $self->{instance}{$instance_name} ;
    }

    my $root_class_name = delete $args{root_class_name}
      or croak "Model: can't create instance without root_class_name ";


    if (defined $args{model_file}) {
	my $file = delete $args{model_file} ;
	$self->load($root_class_name, $file) ;
    }

    my $i = Config::Model::Instance 
      -> new (config_model => $self,
	      root_class_name => $root_class_name,
	      name => $instance_name ,
	      %args                 # for optional parameters like *directory
	     ) ;

    $self->{instance}{$instance_name} = $i ;
    return $i ;
}

sub instance_names {
    my $self = shift ;
    return keys %{$self->{instance}} ;
}

=head1 Configuration class

A configuration class is made of series of elements which are detailed
in L<Config::Model::Node>.

Whatever its type (node, leaf,... ), each element of a node has
several other properties:

=over

=item experience

By using the C<experience> parameter, you can change the experience
level of each element. Possible experience levels are C<master>,
C<advanced> and C<beginner> (default).

=cut

@experience_list = qw/beginner advanced master/;

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

=item summary

Summary of the element. This description will be used when generating
user interfaces and may be used in comments when writing the
configuration file.

=item class_description

Description of the configuration class. This description will be used
when generating user interfaces.

=cut


my %default_property =
  (
   status      => 'standard',
   level       => 'normal',
   experience  => 'beginner',
   summary     => '',
   description => '',
  );

my %check;

{
  my $idx = 0 ;
  map ($check{level}{$_}=$idx++, @level);
  $idx = 0 ;
  map ($check{status}{$_}=$idx++, @status);
  $idx = 0 ;
  map ($experience_index{$_}=$idx++, @experience_list);
}

$check{experience}=\%experience_index ;

# unpacked model is:
# {
#   element_list  => [ ... ],
#   experience    => { element_name => <experience> },
#   status        => { element_name => <status>     },
#   description   => { element_name => <string> },
#   summary       => { element_name => <string> },
#   element       => { element_name => element_data (left as is)    },
#   class_description => <class description string>,
#   level         => { element_name => <level like important or normal..> },
#   include       => 'class_name',
#   include_after => 'element_name',
# }

=item generated_by

Mention with a descriptive string if this class was generated by a
program.  This parameter is currently reserved for
L<Config::Model::Itself> model editor.

=cut

my @legal_params = qw/experience status description summary element level
                      config_dir generated_by class_description
                      read_config read_config_dir write_config
                      write_config_dir/;

sub create_config_class {
    my $self=shift ;
    my %raw_model = @_ ;

    my $config_class_name = delete $raw_model{name} or
      croak "create_one_config_class: no config class name" ;

    get_logger("Model")->info("Creating class $config_class_name") ;

    if (exists $self->{model}{$config_class_name}) {
	Config::Model::Exception::ModelDeclaration->throw
	    (
	     error=> "create_one_config_class: attempt to clobber $config_class_name".
	     "config class name "
	    );
    }

    if (defined $raw_model{inherit_after}) {
	$self->legacy("Model $config_class_name: inherit_after is deprecated ",
	  "in favor of include_after" );
	$raw_model{include_after} = delete $raw_model{inherit_after} ;
    }
    if (defined $raw_model{inherit}) {
	$self->legacy("Model $config_class_name: inherit is deprecated in favor of include");
	$raw_model{include} = delete $raw_model{inherit} ;
    }

    $self->{raw_model}{$config_class_name} = \%raw_model ;

    # perform some syntax and rule checks and expand compacted
    # elements ie  [qw/foo bar/] => {...} is transformed into
    #  foo => {...} , bar => {...} before being stored

    my $raw_copy = dclone \%raw_model ;
    my %model = ( element_list => [] );

    # add included items
    if ($self->{skip_include} and defined $raw_copy->{include}) {
	my $inc = delete $raw_copy->{include} ;
	$model{include}       =  ref $inc ? $inc : [ $inc ];
	$model{include_after} = delete $raw_copy->{include_after}
	  if defined $raw_copy->{include_after};
    }
    else {
	$self->include_class($config_class_name, $raw_copy ) ; 
    }


    # check config class parameters
    $self->check_class_parameters($config_class_name, \%model, $raw_copy) ;

    my @left_params = keys %$raw_copy ;
    Config::Model::Exception::ModelDeclaration->throw
        (
         error=> "create class $config_class_name: unknown ".
	 "parameter '" . join("', '",@left_params)."', expected '".
	 join("', '",@legal_params,qw/class_description/)."'"
        )
	  if @left_params ;


    $self->{model}{$config_class_name} = \%model ;

    return $config_class_name ;
}

sub check_class_parameters {
    my $self  = shift;
    my $config_class_name = shift || die ;
    my $model = shift || die ;
    my $raw_model = shift || die ;

    my @element_list ;

    # first get the element list
    my @compact_list = @{$raw_model->{element} || []} ;
    while (@compact_list) {
	my ($item,$info) = splice @compact_list,0,2 ;
	# store the order of element as declared in 'element'
	push @element_list, ref($item) ? @$item : ($item) ;
    }

    # get data read/write information (if any)
    $model->{read_config_dir} = $model->{write_config_dir}
      = delete $raw_model->{config_dir} ;
    foreach my $rw_info (qw/read_config  read_config_dir 
                            write_config write_config_dir/) {
	next unless defined $raw_model->{$rw_info} ;
	$model->{$rw_info} = delete $raw_model->{$rw_info} ;
    }

    # this parameter is filled by class generated by a program. It may
    # be used to avoid interactive edition of a generated model
    $model->{generated_by} = delete $raw_model->{generated_by} ;

    # class_description cannot be handled in the next loop
    $model->{class_description} = delete $raw_model->{class_description} 
      if defined $raw_model->{class_description}  ;


    # check for duplicate in @element_list.
    my %check_list ;
    map { $check_list{$_}++ } @element_list ;
    my @extra = grep { $check_list{$_} > 1 } keys %check_list ;
    if (@extra) {
	Config::Model::Exception::ModelDeclaration->throw
	    (
	     error=> "class $config_class_name: @extra element ".
	              "is declared more than once. Check the included parts"
	    ) ;
    }

    $self->translate_legacy_permission($config_class_name, $raw_model, $raw_model ) ;

    foreach my $info_name (@legal_params) {
	# fill default info (but do not clobber already existing info)
	map {$model->{$info_name}{$_} ||= $default_property{$info_name}; }
	  @element_list 
	    if defined $default_property{$info_name};

	my $compact_info = delete $raw_model->{$info_name} ;
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

	    # check for duplicate elements
	    Config::Model::Exception::ModelDeclaration->throw
		(
		 error=> "create class $config_class_name: unknown ".
		 "value for $info_name: '$info'. Expected '".
		 join("', '",keys %{$check{$info_name}})."'"
		)
		  if defined $check{$info_name} 
		    and not defined $check{$info_name}{$info} ;

	    if ($info_name eq 'element') {
		foreach my $info_to_move (qw/description level summary experience status/) {
		    # FIXME: Should we consider this as legacy ?
		    my $moved_data = delete $info->{$info_to_move}  ;
		    next unless defined $moved_data ;
		    map {$model->{$info_to_move}{$_} = $moved_data ; }
			 @element_names ;
		}

		if (defined $info->{permission}) {
		    $self->translate_legacy_permission($config_class_name, 
						       $info, $info ) ;
		}
	    }

	    # warp can be found only in element item 
	    if (ref $info eq 'HASH') {
		$self->translate_legacy_info($config_class_name,
					     $element_names[0], $info) ;
	    }

	    foreach my $name (@element_names) {
		$model->{$info_name}{$name} = $info ;
	    }
	}
    }

    Config::Model::Exception::ModelDeclaration->throw
	(
	 error => "create class $config_class_name: unexpected "
	        . "parameters '". join (', ', keys %$raw_model) ."' "
	        . "Expected '".join("', '",@legal_params)."'"
	)
	  if keys %$raw_model ;

    $model->{element_list} = \@element_list;
}

sub translate_legacy_permission {
    my ($self, $config_class_name, $model, $raw_model ) = @_  ;

    my $raw_experience = delete $raw_model -> {permission} ;
    return unless defined $raw_experience ;

    print Data::Dumper->Dump([$raw_model ] , ['permission to translate' ] ) ,"\n" 
	if $::debug;

    $self->legacy("$config_class_name: parameter permission is deprecated "
                  ."in favor of 'experience'");

    # now change intermediate in beginner
    if (ref $raw_experience eq 'HASH') {
	map { $_ = 'beginner' if $_ eq 'intermediate' } values %$raw_experience;
    }
    elsif (ref $raw_experience eq 'ARRAY') {
	map { $_ = 'beginner' if $_ eq 'intermediate' } @$raw_experience;
    }
    else {
	$raw_experience = 'beginner' if $raw_experience eq 'intermediate';
    }

    $model -> {experience} = $raw_experience ;

    print Data::Dumper->Dump([$model ] , ['translated_permission' ] ) ,"\n" 
	if $::debug;
}

sub translate_legacy_info {
    my $self = shift ;
    my $config_class_name = shift || die ;
    my $elt_name = shift ;
    my $info = shift ;

    #translate legacy warp information
    if (defined $info->{warp}) {
	$self->translate_warp_info($config_class_name,$elt_name, $info->{type}, $info->{warp});
    }

    $self->translate_cargo_info($config_class_name,$elt_name, $info);

    if (    defined $info->{cargo} 
	and defined $info->{cargo}{warp}) {
	$self->translate_warp_info($config_class_name,$elt_name, $info->{cargo}{type} ,
				   $info->{cargo}{warp});
    }

    if (   defined $info->{cargo} 
        && defined $info->{cargo}{type} 
	&& $info->{cargo}{type} eq 'warped_node') {
	$self->translate_warp_info($config_class_name,$elt_name, 'warped_node',$info->{cargo});
    }

    if (defined $info->{type} && $info->{type} eq 'warped_node') {
	$self->translate_warp_info($config_class_name,$elt_name, 'warped_node',$info);
    }

    # compute cannot be warped
    if (defined $info->{compute}) {
	$self->translate_compute_info($config_class_name,$elt_name, $info,
				      'compute');
	$self->translate_allow_compute_override($config_class_name,$elt_name, 
						$info);
    }
    if (    defined $info->{cargo} 
	and defined $info->{cargo}{compute}) {
	$self->translate_compute_info($config_class_name,$elt_name, 
				      $info->{cargo},'compute');
	$self->translate_allow_compute_override($config_class_name,$elt_name, 
						$info->{cargo});
    }

    # refer_to cannot be warped
    if (defined $info->{refer_to}) {
	$self->translate_compute_info($config_class_name,$elt_name, $info,refer_to => 'computed_refer_to');
    }
    if (    defined $info->{cargo} 
	and defined $info->{cargo}{refer_to}) {
	$self->translate_compute_info($config_class_name,$elt_name, 
				      $info->{cargo},refer_to => 'computed_refer_to');
    }

    # translate id default param
    # default cannot be stored in cargo since is applies to the id itself
    if ( defined $info->{type} 
         and ($info->{type} eq 'list' or $info->{type} eq 'hash')
       ) {
	if (defined $info->{default}) {
	    $self->translate_id_default_info($config_class_name,$elt_name, $info);
	} 
	if (defined $info->{auto_create}) {
	    $self->translate_id_auto_create($config_class_name,$elt_name, $info);
	} 
	$self->translate_id_min_max($config_class_name,$elt_name, $info);
	$self->translate_id_names($config_class_name,$elt_name,$info) ;
	if (defined $info->{warp} ) {
	    my $rules_a = $info->{warp}{rules} ;
	    my %h = @$rules_a ;
	    foreach my $rule_effect (values %h) {
		$self->translate_id_names($config_class_name,$elt_name, $rule_effect) ;
	$self->translate_id_min_max($config_class_name,$elt_name, $rule_effect);
		next unless defined $rule_effect->{default} ;
		$self->translate_id_default_info($config_class_name,$elt_name, $rule_effect);
	    }
	}
    }

    if ( defined $info->{type} and ($info->{type} eq 'leaf')) {
	$self->translate_legacy_builtin($config_class_name, $info, $info, );
    }

    if ( defined $info->{type} and ($info->{type} eq 'check_list')) {
	$self->translate_legacy_built_in_list($config_class_name, $info, $info, );
    }

    print Data::Dumper->Dump([$info ] , ['translated_'.$elt_name ] ) ,"\n" if $::debug;
}

sub translate_cargo_info {
    my $self = shift;
    my $config_class_name = shift ;
    my $elt_name = shift ;
    my $info = shift;

    my $c_type = delete $info->{cargo_type} ;
    return unless defined $c_type;
    $self->legacy("$config_class_name->$elt_name: parameter cargo_type is deprecated.");
    my %cargo ;

    if (defined $info->{cargo_args}) {
       %cargo = %{ delete $info->{cargo_args}} ;
       $self->legacy("$config_class_name->$elt_name: parameter cargo_args is deprecated.");
    }

    $cargo{type} = $c_type;

    if (defined $info->{config_class_name}) {
	$cargo{config_class_name} = delete $info->{config_class_name} ;
	$self->legacy("$config_class_name->$elt_name: parameter config_class_name is ",
	     "deprecated. This one must be specified within cargo. ",
	     "Ie. cargo=>{config_class_name => 'FooBar'}");
    }

    $info->{cargo} = \%cargo ;
    print Data::Dumper->Dump([$info ] , ['translated_'.$elt_name ] ) ,"\n" if $::debug;
}

sub translate_id_names {
    my $self = shift;
    my $config_class_name = shift ;
    my $elt_name = shift ;
    my $info = shift;
    $self->translate_name($config_class_name,$elt_name, $info, 'allow',     'allow_keys') ;
    $self->translate_name($config_class_name,$elt_name, $info, 'allow_from','allow_keys_from') ;
    $self->translate_name($config_class_name,$elt_name, $info, 'follow',    'follow_keys_from') ;
}

sub translate_name {
    my $self     = shift;
    my $config_class_name = shift ;
    my $elt_name = shift ;
    my $info     = shift;
    my $from     = shift ;
    my $to       = shift ;

    if (defined $info->{$from}) {
	$self->legacy("$config_class_name->$elt_name: parameter $from is deprecated in favor of $to");
	$info->{$to} = delete $info->{$from}  ;
    }
}

sub translate_allow_compute_override {
    my $self = shift ;
    my $config_class_name = shift ;
    my $elt_name = shift ;
    my $info = shift ;

    if (defined $info->{allow_compute_override}) {
	$self->legacy("$config_class_name->$elt_name: parameter allow_compute_override is deprecated in favor of compute -> allow_override");
	$info->{compute}{allow_override} = delete $info->{allow_compute_override}  ;
    }
}

sub translate_compute_info {
    my $self = shift ;
    my $config_class_name = shift ;
    my $elt_name = shift ;
    my $info = shift ;
    my $old_name = shift ;
    my $new_name = shift || $old_name ;

    if (ref($info->{$old_name}) eq 'ARRAY') {
	my $compute_info = delete $info->{$old_name} ;
	print "translate_compute_info $elt_name input:\n", 
	  Data::Dumper->Dump( [$compute_info ] , [qw/compute_info/ ]) ,"\n"
	      if $::debug ;

	$self->legacy("$config_class_name->$elt_name: specifying compute info with ",
	  "an array ref is deprecated"); 

	my ($user_formula,%var) = @$compute_info ;
	my $replace_h ;
	map { $replace_h = delete $var{$_} if ref($var{$_})} keys %var ;

	# cleanup user formula
	$user_formula =~ s/\$(\w+){/\$replace{/g ;

	# cleanup variable
	map { s/\$(\w+){/\$replace{/g } values %var ;

	# change the hash *in* the info structure
	$info->{$new_name} = { formula => $user_formula,
			       variables => \%var,
			     } ;
	$info->{$new_name}{replace} = $replace_h if defined $replace_h ;

	print "translate_warp_info $elt_name output:\n",
	  Data::Dumper->Dump([$info->{$new_name} ] , ['new_'.$new_name ] ) ,"\n"
	      if $::debug ;
    }
}


# internal: translate default information for id element
sub translate_id_default_info {
    my $self = shift ;
    my $config_class_name = shift || die;
    my $elt_name = shift ;
    my $info = shift ;

    print "translate_id_default_info $elt_name input:\n", 
      Data::Dumper->Dump( [$info ] , [qw/info/ ]) ,"\n"
	  if $::debug ;

    my $warn = "$config_class_name->$elt_name: 'default' parameter for list or " 
             . "hash element is deprecated. ";

    my $def_info = delete $info->{default} ;
    if (ref($def_info) eq 'HASH') {
	$info->{default_with_init} = $def_info ;
	$self->legacy($warn,"Use default_with_init") ;
    }
    elsif (ref($def_info) eq 'ARRAY') {
	$info->{default_keys} = $def_info ;
	$self->legacy($warn,"Use default_keys") ;
    }
    else {
	$info->{default_keys} = [ $def_info ] ;
	$self->legacy($warn,"Use default_keys") ;
    }
    print "translate_id_default_info $elt_name output:\n",
      Data::Dumper->Dump([$info ] , [qw/new_info/ ] ) ,"\n"
	  if $::debug ;
}

# internal: translate auto_create information for id element
sub translate_id_auto_create {
    my $self = shift ;
    my $config_class_name = shift || die;
    my $elt_name = shift ;
    my $info = shift ;

    print "translate_id_auto_create $elt_name input:\n", 
      Data::Dumper->Dump( [$info ] , [qw/info/ ]) ,"\n"
	  if $::debug ;

    my $warn = "$config_class_name->$elt_name: 'auto_create' parameter for list or " 
             . "hash element is deprecated. ";

    my $ac_info = delete $info->{auto_create} ;
    if ($info->{type} eq 'hash') {
	$info->{auto_create_keys} 
	  = ref($ac_info) eq 'ARRAY' ? $ac_info : [ $ac_info ] ;
	$self->legacy($warn,"Use auto_create_keys") ;
    }
    elsif ($info->{type} eq 'list') {
	$info->{auto_create_ids} = $ac_info ;
	$self->legacy($warn,"Use auto_create_ids") ;
    }
    else {
	die "Unexpected element ($elt_name) type $info->{type} ",
	  "for translate_id_auto_create";
    }

    print "translate_id_default_info $elt_name output:\n",
      Data::Dumper->Dump([$info ] , [qw/new_info/ ] ) ,"\n"
	  if $::debug ;
}

sub translate_id_min_max {
    my $self = shift ;
    my $config_class_name = shift || die;
    my $elt_name = shift ;
    my $info = shift ;

    foreach my $bad ( qw/min max/) {
	next unless defined $info->{$bad} ;

	print "translate_id_min_max $elt_name $bad:\n"
	    if $::debug ;

	my $good = $bad.'_index' ;
	my $warn = "$config_class_name->$elt_name: '$bad' parameter for list or " 
	    . "hash element is deprecated. Use '$good'";

	$info->{$good} = delete $info->{$bad} ;
    }
}

# internal: translate warp information into 'boolean expr' => { ... }
sub translate_warp_info {
    my ($self,$config_class_name,$elt_name,$type,$warp_info) = @_ ;

    print "translate_warp_info $elt_name input:\n", 
      Data::Dumper->Dump( [$warp_info ] , [qw/warp_info/ ]) ,"\n"
	  if $::debug ;

    my $follow = $self->translate_follow_arg($config_class_name,$elt_name,$warp_info->{follow}) ;

    # now, follow is only { w1 => 'warp1', w2 => 'warp2'}
    my @warper_items = values %$follow ;

    my $multi_follow =  @warper_items > 1 ? 1 : 0;

    my $rules = $self->translate_rules_arg($config_class_name,$elt_name,$type,
					   \@warper_items, $warp_info->{rules});

    $warp_info->{follow} = $follow;
    $warp_info->{rules}  = $rules ;

    print "translate_warp_info $elt_name output:\n",
      Data::Dumper->Dump([$warp_info ] , [qw/new_warp_info/ ] ) ,"\n"
	  if $::debug ;
}

# internal
sub translate_multi_follow_legacy_rules {
    my ($self, $config_class_name , $elt_name , $warper_items, $raw_rules) = @_ ;
    my @rules ;

    # we have more than one warper_items

    for (my $r_idx = 0; $r_idx < $#$raw_rules; $r_idx  += 2) {
	my $key_set = $raw_rules->[$r_idx] ;
	my @keys = ref($key_set) ? @$key_set : ($key_set) ;

	# legacy: check the number of keys in the @rules set 
	if ( @keys != @$warper_items and $key_set !~ /\$\w+/) {
	    Config::Model::Exception::ModelDeclaration
		-> throw (
			  error => "Warp rule error in "
                                . "'$config_class_name->$elt_name'"
			        . ": Wrong nb of keys in set '@keys',"
			        . " Expected " . scalar @$warper_items . " keys"
			 )  ;
	}
	# legacy:
	# if a key of a rule (e.g. f1 or b1) is an array ref, all the
	# values passed in the array are considered as valid.
	# i.e. [ [ f1a, f1b] , b1 ] => { ... }
	# is equivalent to 
	# [ f1a, b1 ] => { ... }, [  f1b , b1 ] => { ... }

	# now translate [ [ f1a, f1b] , b1 ] => { ... }
	# into "( $f1 eq f1a or $f1 eq f1b ) and $f2 eq b1)" => { ... }
	my @bool_expr ;
	my $b_idx = 0;
	foreach my $key (@keys) {
	    if (ref $key ) {
		my @expr = map { "\$f$b_idx eq '$_'" } @$key ;
		push @bool_expr , "(" . join (" or ", @expr ). ")" ;
	    }
	    elsif ($key !~ /\$\w+/) {
		push @bool_expr, "\$f$b_idx eq '$key'" ;
	    }
	    else {
		push @bool_expr, $key ;
	    }
	    $b_idx ++ ;
	}
	push @rules , join ( ' and ', @bool_expr),  $raw_rules->[$r_idx+1] ;
    }
    return @rules ;
}

sub translate_follow_arg {
    my $self = shift ;
    my $config_class_name = shift ;
    my $elt_name = shift ;
    my $raw_follow = shift ;

    if (ref($raw_follow) eq 'HASH') {
	# follow is { w1 => 'warp1', w2 => 'warp2'} 
	return $raw_follow ;
    }
    elsif (ref($raw_follow) eq 'ARRAY') {
	# translate legacy follow arguments ['warp1','warp2',...]
	my $follow = {} ;
	my $idx = 0;
	map { $follow->{'f' . $idx++ } = $_ } @$raw_follow ;
	return $follow ;
    }
    else {
	# follow is a simple string
	return { f1 => $raw_follow } ;
    }
}

sub translate_rules_arg {
    my ($self,$config_class_name, $elt_name,$type, $warper_items,
	$raw_rules) = @_ ;

    my $multi_follow =  @$warper_items > 1 ? 1 : 0;

    # $rules is either:
    # { f1 => { ... } }  (  may be [ f1 => { ... } ] ?? )
    # [ 'boolean expr' => { ... } ]
    # legacy:
    # [ f1, b1 ] => {..} ,[ f1,b2 ] => {...}, [f2,b1] => {...} ...
    # foo => {...} , bar => {...}
    my @rules ;
    if (ref($raw_rules) eq 'HASH') {
	# transform the simple hash { foo => { ...} }
	# into array ref [ '$f1 eq foo' => { ... } ]
	my $h = $raw_rules ;
	@rules = map { ( "\$f1 eq '$_'" , $h->{$_} ) } keys %$h ;
    } 
    elsif (ref($raw_rules) eq 'ARRAY') {
	if ( $multi_follow ) {
	    push @rules, 
	      $self->translate_multi_follow_legacy_rules( $config_class_name,$elt_name, 
							  $warper_items,
							  $raw_rules ) ;
	}
	else {
	    # now translate [ f1a, f1b]  => { ... }
	    # into "$f1 eq f1a or $f1 eq f1b " => { ... }
	    my @raw_rules = @{$raw_rules} ;
	    for (my $r_idx = 0; $r_idx < $#raw_rules; $r_idx  += 2) {
		my $key_set = $raw_rules[$r_idx] ;
		my @keys = ref($key_set) ? @$key_set : ($key_set) ;
		my @bool_expr = map { /\$/ ? $_ : "\$f1 eq '$_'" } @keys ;
		push @rules , join ( ' or ', @bool_expr),  $raw_rules[$r_idx+1] ;
	    }
	}
    }
    elsif (defined $raw_rules) {
	Config::Model::Exception::ModelDeclaration
	    -> throw (
		      error => "Warp rule error in element "
                             . "'$config_class_name->$elt_name': "
		             . "rules must be a hash ref. Got '$raw_rules'"
		     ) ;
    }

    for (my $idx=1; $idx < @rules ; $idx += 2) {
	next unless (ref $rules[$idx] eq 'HASH') ; # other cases are illegal and trapped later
	$self->translate_legacy_permission($config_class_name, $rules[$idx], $rules[$idx]);
	next unless defined $type and $type eq 'leaf';
	$self->translate_legacy_builtin($config_class_name, $rules[$idx], $rules[$idx]);
     }

    return \@rules ;
}

sub translate_legacy_builtin {
    my ($self, $config_class_name, $model, $raw_model ) = @_  ;

    my $raw_builtin_default = delete $raw_model -> {built_in} ;
    return unless defined $raw_builtin_default ;

    print Data::Dumper->Dump([$raw_model ] , ['builtin to translate' ] ) ,"\n" 
	if $::debug;

    $self->legacy("$config_class_name: parameter 'built_in' is deprecated "
                  ."in favor of 'upstream_default'");

    $model -> {upstream_default} = $raw_builtin_default ;

    print Data::Dumper->Dump([$model ] , ['translated_builtin' ] ) ,"\n" 
	if $::debug;
}

sub translate_legacy_built_in_list {
    my ($self, $config_class_name, $model, $raw_model ) = @_  ;

    my $raw_builtin_default = delete $raw_model -> {built_in_list} ;
    return unless defined $raw_builtin_default ;

    print Data::Dumper->Dump([$raw_model ] , ['built_in_list to translate' ] ) ,"\n" 
	if $::debug;

    $self->legacy("$config_class_name: parameter 'built_in_list' is deprecated "
                  ."in favor of 'upstream_default_list'");

    $model -> {upstream_default_list} = $raw_builtin_default ;

    print Data::Dumper->Dump([$model ] , ['translated_built_in_list' ] ) ,"\n" 
	if $::debug;
}

=item include

Include element description from another class. 

  include => 'AnotherClass' ,

or

  include => [qw/ClassOne ClassTwo/]

In a configuration class, the order of the element is important. For
instance if C<foo> is warped by C<bar>, you must declare C<bar>
element before C<foo>.

When including another class, you may wish to insert the included
elements after a specific element of your including class:

  # say AnotherClass contains element xyz
  include => 'AnotherClass' ,
  include_after => "foo" ,
  element => [ bar => ... , foo => ... , baz => ... ]

Now the element of your class will be:

  ( bar , foo , xyz , baz )

=back 

=cut

sub include_class {
    my $self       = shift;
    my $class_name = shift || croak "include_class: undef includer" ;
    my $raw_model  = shift || die "include_class: undefined raw_model";

    my $include_class = delete $raw_model->{include} ;

    return () unless defined $include_class ;

    my $include_after       = delete $raw_model->{include_after} ;

    my @includes = ref $include_class ? @$include_class : ($include_class) ;

    # use reverse because included classes are *inserted* in front 
    # of the list (or inserted after $include_after
    foreach my $inc (reverse @includes) {
	$self->include_one_class($class_name, $raw_model, $inc, $include_after) ;
    }
}

sub include_one_class {
    my $self          = shift;
    my $class_name    = shift || croak "include_class: undef includer" ;
    my $raw_model     = shift || croak "include_class: undefined raw_model";
    my $include_class = shift || croak "include_class: undef include_class param" ;;
    my $include_after = shift ;

    if (defined $include_class and 
        defined $self->{included_class}{$class_name}{$include_class}) {
	Config::Model::Exception::ModelDeclaration
		-> throw (error => "Recursion error ? $include_class has "
			         . "already been included by $class_name.") ;
    }
    $self->{included_class}{$class_name}{$include_class} = 1;

    my $included_raw_model = dclone $self->get_raw_model($include_class) ;

    # takes care of recursive include
    $self->include_class( $class_name, $included_raw_model ) ;

    my %include_item = map { $_ => 1 } @legal_params ;

    # now include element (special treatment because order is
    # important)
    if (defined $include_after and defined $included_raw_model->{element}) {
	my %elt_idx ;
	my @raw_elt = @{$raw_model->{element}} ;

	for (my $idx = 0; $idx < @raw_elt ; $idx += 2) {
	    my $elt = $raw_elt[$idx] ;
	    map { $elt_idx{$_} = $idx } ref $elt ? @$elt : ($elt) ;
	}

	if (not defined $elt_idx{$include_after}) {
	    my $msg =  "Unknown element for 'include_after': "
		        . "$include_after, expected ". join(' ', keys %elt_idx) ;
	    Config::Model::Exception::ModelDeclaration
		-> throw (error => $msg) ;
	}

	# + 2 because we splice *after* $include_after
	my $splice_idx = $elt_idx{$include_after} + 2;
	my $to_copy = delete $included_raw_model->{element} ;
	splice ( @{$raw_model->{element}}, $splice_idx, 0, @$to_copy) ;
    }

    # now included_raw_model contains all information to be merged to
    # raw_model

    my $included_model ;
    foreach my $included_item (keys %$included_raw_model) {
	if (defined $include_item{$included_item}) {
	    my $to_copy = $included_raw_model->{$included_item} ;
	    if (ref($to_copy) eq 'HASH') {
		map { $raw_model->{$included_item}{$_} = $to_copy->{$_} } 
		  keys %$to_copy ;
	    }
	    elsif (ref($to_copy) eq 'ARRAY') {
		unshift @{$raw_model->{$included_item}}, @$to_copy;
	    }
	    else {
		$raw_model->{$included_item} = $to_copy ;
	    }
	}
	else {
	    Config::Model::Exception::ModelDeclaration->throw
		(
		 error => "Cannot include '$included_item', "
		 . "expected @legal_params"
		) ;
	}
    }

    # check that elements are not clobbered
    my %elt_name ;
    my @raw_elt = @{$raw_model->{element}} ;
    for (my $idx = 0; $idx < @raw_elt ; $idx += 2) {
	my $elt = $raw_elt[$idx] ;
	if (defined $elt_name{$elt})  {
	    Config::Model::Exception::ModelDeclaration->throw
		(
		 error => "Cannot clobber element '$elt' in $class_name"
		 . " (included from $include_class)"
		) ;
	}
	$elt_name{$elt} = 1;
    }
}



=pod

Example:

  my $model = Config::Model -> new ;

  $model->create_config_class 
  (
   config_class_name => 'SomeRootClass',
   experience        => [ [ qw/tree_macro warp/ ] => 'advanced'] ,
   description       => [ X => 'X-ray' ],
   level             => [ 'tree_macro' => 'important' ] ,
   class_description => "SomeRootClass description",
   element           => [ ... ] 
  ) ;

Again, see L<Config::Model::Node> for more details on configuration
class declaration.

For convenience, C<experience>, C<level> and C<description> parameters
can also be declared within the element declaration:

  $model->create_config_class 
  (
   config_class_name => 'SomeRootClass',
   class_description => "SomeRootClass description",
   'element'
   => [ 
        tree_macro => { level => 'important',
                        experience => 'advanced',
                      },
        warp       => { experience => 'advanced', } ,
        X          => { description => 'X-ray', } ,
      ] 
  ) ;


=head1 Load pre-declared model

You can also load pre-declared model.

=head2 load( <model_name> )

This method will open the model directory and execute a C<.pl>
file containing the model declaration,

This perl file must return an array ref to declare models. E.g.:

 [
  [
   name => 'Class_1',
   element => [ ... ]
  ],
  [
   name => 'Class_2',
   element => [ ... ]
  ]
 ]; 

do not put C<1;> at the end or C<load> will not work

If a model name contain a C<::> (e.g C<Foo::Bar>), C<load> will look for
a file named C<Foo/Bar.pl>.

Returns a list containining the names of the loaded classes. For instance, if 
C<Foo/Bar.pl> contains a model for C<Foo::Bar> and C<Foo::Bar2>, C<load>
will return C<( 'Foo::Bar' , 'Foo::Bar2' )>.

=cut


sub load {
    my $self = shift ;
    my $load_model = shift ;
    my $load_file = shift ;

    my $load_path = $load_model . '.pl' ;
    $load_path =~ s/::/\//g;

    $load_file ||=  ($self->{model_dir} || 'Config/Model/models') 
                 . '/'. $load_path ;

    get_logger("Model::Loader")-> info("load model $load_file") ;

    my $err_msg = '';
    my $model = do $load_file ;

    unless ($model) {
	if ($@) {$err_msg =  "couldn't parse $load_file: $@"; }
	elsif (not defined $model) {$err_msg = "couldn't do $load_file: $!"}
	else {$err_msg = "couldn't run $load_file" ;}
    }
    elsif (ref($model) ne 'ARRAY') {
	$err_msg = "Model file $load_file does not return an array ref" ;
    }

    Config::Model::Exception::ModelDeclaration
	    -> throw (message => "model $load_model: $err_msg")
		if $err_msg ;

    my @loaded ;
    foreach my $config_class_info (@$model) {
	my @data = ref $config_class_info eq 'HASH' ? %$config_class_info
	         : ref $config_class_info eq 'ARRAY' ? @$config_class_info
	         : croak "load $load_file: config_class_info is not a ref" ;
	push @loaded, $self->create_config_class(@data) ;
    }

    return @loaded
}

# TBD: For a proper model plugin, scan directory <model_name>.d and
# load in merge mode all pieces of model found there merge mode: model
# data is added to main model before running create_config_class

=head1 Model query

=head2 get_model( config_class_name )

Return a hash containing the model declaration.

=cut

sub get_model {
    my $self =shift ;
    my $config_class_name = shift 
      || die "Model::get_model: missing config class name argument" ;

    $self->load($config_class_name) 
      unless defined $self->{model}{$config_class_name} ;

    my $model = $self->{model}{$config_class_name} ||
      croak "get_model error: unknown config class name: $config_class_name";

    return dclone($model) ;
}

# returns a hash ref containing the raw model, i.e. before expansion of 
# multiple keys (i.e. [qw/a b c/] => ... )
# internal. For now ...
sub get_raw_model {
    my $self =shift ;
    my $config_class_name = shift ;

    $self->load($config_class_name) 
      unless defined $self->{model}{$config_class_name} ;

    my $model = $self->{raw_model}{$config_class_name} ||
      croak "get_raw_model error: unknown config class name: $config_class_name";

    return dclone($model) ;
}

=head2 get_element_name( class => Foo, for => advanced )

Get all names of the elements of class C<Foo> that are accessible for
experience level C<advanced>. 

Level can be C<master> (default), C<advanced> or C<beginner>.

=cut

sub get_element_name {
    my $self = shift ;
    my %args = @_ ;

    my $class = $args{class} || 
      croak "get_element_name: missing 'class' parameter" ;
    my $for = $args{for} || 'master' ;

    if ($for eq 'intermediate') {
	carp "get_element_name: 'intermediate' is deprecated in favor of beginner";
	$for = 'beginner' ;
    }

    croak "get_element_name: wrong 'for' parameter. Expected ", 
      join (' or ', @experience_list) 
	unless defined $experience_index{$for} ;

    my @experiences 
      = @experience_list[ 0 .. $experience_index{$for} ] ;
    my @array
      = $self->get_element_with_experience($class,@experiences);

    return wantarray ? @array : join( ' ', @array );
}

# internal
sub get_element_with_experience {
    my $self      = shift ;
    my $class     = shift ;

    my $model = $self->get_model($class) ;
    my @result ;

    # this is a bit convoluted, but the order of the returned element
    # must respect the order of the elements declared in the model by
    # the user
    foreach my $elt (@{$model->{element_list}}) {
	foreach my $experience (@_) {
	    push @result, $elt
	      if $model->{level}{$elt} ne 'hidden' 
		and $model->{experience}{$elt} eq $experience ;
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

=head2 list_class_element

Returns a string listing all the class and elements. Useful for
debugging your configuration model.

=cut

sub list_class_element {
    my $self = shift ;
    my $pad  =  shift || '' ;

    my $res = '';
    foreach my $class_name (keys %{$self->{raw_model}}) {
	$res .= $self->list_one_class_element($class_name) ;
    }
    return $res ;
}

sub list_one_class_element {
    my $self = shift ;
    my $class_name = shift ;
    my $pad  =  shift || '' ;

    my $res = $pad."Class: $class_name\n";
    my $c_model = $self->{raw_model}{$class_name};
    my $elts = $c_model->{element} ; # array ref

    my $include = $c_model->{include} ;
    my $inc_ref = ref $include ? $include : [ $include ] ;
    my $inc_after = $c_model->{include_after} ;

    if (defined $include and not defined $inc_after) {
	map { $res .=$self->list_one_class_element($_,$pad.'  ') ;} @$inc_ref ;
    }

    return $res unless defined $elts ;

    for (my $idx = 0; $idx < @$elts; $idx += 2) {
	my $elt_info = $elts->[$idx] ;
	my @elt_names = ref $elt_info ? @$elt_info : ($elt_info) ;
	my $type = $elts->[$idx+1]{type} ;

	foreach my $elt_name (@elt_names) {
	    $res .= $pad."  - $elt_name ($type)\n";
	    if (defined $include and defined $inc_after 
		and $inc_after eq $elt_name
	       ) {
		map { $res .=$self->list_one_class_element($_,$pad.'  ') ;} @$inc_ref ;
	    }
	}
    }
    return $res ;
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

Dominique Dumont, (ddumont at cpan dot org)

=head1 LICENSE

    Copyright (c) 2005-2010 Dominique Dumont.

    This file is part of Config-Model.

    Config-Model is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser Public License as
    published by the Free Software Foundation; either version 2.1 of
    the License, or (at your option) any later version.

    Config-Model is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser Public License for more details.

    You should have received a copy of the GNU Lesser Public License
    along with Config-Model; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
    02110-1301 USA

=head1 SEE ALSO

L<Config::Model::Instance>, 

http://sourceforge.net/apps/mediawiki/config-model/index.php?title=Creating_a_model

=head2 Model elements

The arrow shows the inheritance of the classes

=over

=item * 

L<Config::Model::Node> <- L<Config::Model::AutoRead> <- L<Config::Model::AnyThing> 

=item *

L<Config::Model::HashId> <- L<Config::Model::AnyId> <- L<Config::Model::WarpedThing> <- L<Config::Model::AnyThing> 

=item *

L<Config::Model::ListId> <- L<Config::Model::AnyId> <- L<Config::Model::WarpedThing> <- L<Config::Model::AnyThing> 

=item *

L<Config::Model::Value> <- L<Config::Model::WarpedThing> <- L<Config::Model::AnyThing> 

=item *

L<Config::Model::CheckList> <- L<Config::Model::WarpedThing> <- L<Config::Model::AnyThing> 

=item *

L<Config::Model::WarpedNode> <- <- L<Config::Model::WarpedThing> <- L<Config::Model::AnyThing> 


=back

=head2 command line

L<config-edit>

=head2 Model utilities

=over

=item * 

L<Config::Model::Describe>

=item * 

L<Config::Model::Dumper>

=item * 

L<Config::Model::DumpAsData>

=item * 

L<Config::Model::Loader>

=item * 

L<Config::Model::ObjTreeScanner>

=item * 

L<Config::Model::Report>

=item * 

L<Config::Model::Searcher>

=item * 

L<Config::Model::TermUI>

=item * 

L<Config::Model::WizardHelper>

=item * 

L<Config::Model::AutoRead>

=item * 

L<Config::Model::ValueComputer>

=back

=cut
