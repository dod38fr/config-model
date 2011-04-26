package Config::Model;
use Any::Moose ;
use Any::Moose '::Util::TypeConstraints';
use Any::Moose 'X::StrictConstructor' ;

use Carp;
use Storable ('dclone') ;
use Data::Dumper ();
use Log::Log4perl 1.11 qw(get_logger :levels);
use Config::Model::Instance ;
use Hash::Merge qw/merge/ ;
use File::Path qw/make_path/;

# this class holds the version number of the package
use vars qw(@status @level @experience_list %experience_index
    %default_property) ;

%default_property =
  (
   status      => 'standard',
   level       => 'normal',
   experience  => 'beginner',
   summary     => '',
   description => '',
  );

enum LegacyTreament => qw/die warn ignore/;

has skip_include => ( isa => 'Bool', is => 'ro', default => 0 ) ;
has model_dir    => ( isa => 'Str',  is => 'ro', default => 'Config/Model/models' );
has legacy       => ( isa => 'LegacyTreament', is => 'ro', default => 'warn' ) ;
has instances    => ( isa => 'HashRef[Config::Model::Instance]', is => 'ro', default => sub { {} } ) ;

has models => ( 
    isa => 'HashRef', 
    is => 'ro' , 
    default => sub { {} } ,
    traits  => [ 'Hash' ],
    handles => {
        model_exists => 'exists',
        model_defined => 'defined',
        model => 'get',
    },
)  ;

has raw_models => ( 
    isa => 'HashRef', 
    is => 'ro' , 
    default => sub { {} } ,
    traits  => [ 'Hash' ],
    handles => {
        raw_model_exists => 'exists',
        raw_model_defined => 'defined',
        raw_model => 'get',
        raw_model_names => 'keys',
    },
)  ;


has skip_inheritance => ( 
    isa => 'Bool', is => 'ro', default => 0,
    trigger => sub { 
        my $self = shift ;
        $self->show_legacy_issue("skip_inheritance is deprecated, use skip_include") ;
        $self->skip_include = $self->skip_inheritance ;
    }
) ;

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my %args = @_ ;
    my %new = map { defined $args{$_} ? ( $_ => $args{$_} ) : () } keys %args ;

    return $class->$orig(%new);
  };


=head1 NAME

Config::Model - Create tools to validate, migrate and edit configuration files

=head1 SYNOPSIS

=head2 Perl program

 use Config::Model;
 use Log::Log4perl qw(:easy) ;
 Log::Log4perl->easy_init($WARN);

 # create new Model object
 my $model = Config::Model->new() ; # Config::Model object

 # create config model. Most users will want to store the model
 # in lib/Config/Model/models and run "config-edit -model MiniModel"
 # See below for details
 $model ->create_config_class (
   name => "MiniModel",
   element => [ [qw/foo bar baz/ ] => { type => 'leaf', value_type => 'uniline' }, ],
   read_config => { backend => 'IniFile', auto_create => 1,
                    config_dir => '.', file => 'mini.ini',
                  }
 ) ;

 # create instance (Config::Model::Instance object)
 my $instance = $model->instance (root_class_name => 'MiniModel');

 # get configuration tree root
 my $cfg_root = $instance -> config_root ; # C::M:Node object

 # load some dummy data
 $cfg_root -> load("bar=BARV foo=FOOV baz=BAZV") ;

 # write new ini file
 $instance -> write_back;

 # now look for new mini.ini file un current directory

=head2 More convenient

 $ mkdir -p lib/Config/Model/models/
 $ echo "[ { name => 'MiniModel',
             element => [ [qw/foo bar baz/ ] => { type => 'leaf', value_type => 'uniline' }, ],
             read_config => { backend => 'IniFile', auto_create => 1,
                              config_dir => '.', file => 'mini.ini',
                            }
           }
         ] ; " > lib/Config/Model/models/MiniModel.pl
 $ config-edit -model MiniModel -model_dir lib/Config/Model/models/ -ui none bar=BARV foo=FOOV baz=BAZV
 $ cat mini.ini

=head2 Look Ma, no Perl

 $ echo "Make sure that Config::Model::Itself is installed"
 $ mkdir -p lib/Config/Model/models/
 $ config-model-edit -model MiniModel -save \
   class:MiniModel element:foo type=leaf value_type=uniline - \
                   element:bar type=leaf value_type=uniline - \
                   element:baz type=leaf value_type=uniline - \
   read_config:0 backend=IniFile file=mini.ini config_dir=. auto_create=1 - - -
 $ config-edit -model MiniModel -model_dir lib/Config/Model/models/ -ui none bar=BARV foo=FOOV baz=BAZV
 $ cat mini.ini

=head1 DESCRIPTION

Config::Model enables a project developer to provide an interactive
configuration editor (graphical, curses based or plain terminal) to
his users. For this he must:

=over 

=item *

Describe the structure and constraints of his project's configuration
(fear not, a GUI is available)

=item *

Find a way to read and write configuration data using read/write backend
provided by Config::Model or other Perl modules.

=back

With the elements above, Config::Model will generate interactive
configuration editors (with integrated help and data validation).
These editors can be graphical (with L<Config::Model::TkUI>), curses
based (with L<Config::Model::CursesUI>) or based on ReadLine.

Smaller models targeted for configuration upgrades can also be created:

=over

=item *

only upgrade and migration specifications are required

=item *

unknown parameters can be accepted 

=back

A command line is provided to perform configuration upgrade with a
single command.

=head2 How does this work ?

Using this project, a typical configuration editor/validator/upgrader
will be made of 3 parts :



  GUI <--------> |---------------|
  CursesUI <---> | |---------|   |
                 | | Model   |   |
  ShellUI <----> | |---------|   |<-----read-backend------- |-------------|
                 |               |----write-backend-------> | config file |
  FuseUI <-----> | Config::Model |                          |-------------|
                 |---------------|

=over

=item 1.

A reader and writer that will parse the configuration file and transform
in a tree representation within Config::Model. The values contained in this
configuration tree can be written back in the configuration file(s).

=item 2.

A validation engine which is in charge of validating the content and
structure of configuration stored in the configuration tree. This
validation engine will follow the structure and constraint declared in
a configuration model. This model is a kind of schema for the
configuration tree.

=item 3.

A user interface to modify the content of the configuration tree. A
modification will be validated instantly by the validation engine.

=back

The important part is the configuration model used by the validation
engine. This model can be created or modified with a graphical editor
(Config::Model::Iself).

=head1 Question you may ask yourself

=head2 Don't we already have some configuration validation tools ?

You're probably thinking of tools like webmin. Yes, these tools exist
and work fine, but they have their set of drawbacks.

Usually, the validation of configuration data is done with a script
which performs semantic validation and often ends up being quite
complex (e.g. 2500 lines for Debian's xserver-xorg.config script which
handles C<xorg.conf> file).

In most cases, the configuration model is expressed in instructions
(whatever programming language is used) and interspersed with a lot of
processing to handle the actual configuration data.

=head2 What's the advantage of this project ?

Config::Model projects provide a way to get a validation engine where
the configuration model is completely separated from the actual
processing instructions.

A configuration model can be created and modified with the graphical
interface provide by L<Config::Model::Itself>. The model is saved in a
declarative form (currently, a Perl data structure). Such a model is
easier to maintain than a lot of code.

The model specifies:

=over 

=item *

The structure of the configuration data (which can be queried by
generic user interfaces)

=item *

The properties of each element (boundaries check, integer or string,
enum like type, default value ...)

=item *

The targeted audience (beginner, advanced, master)

=item *

The on-line help

=back

So, in the end:

=over

=item *

Maintenance and evolution of the configuration content is easier

=item *

User will see a *common* interface for *all* programs using this
project.

=item *

Beginners will not see advanced parameters (advanced and master
parameters are hidden from beginners)

=item *

Upgrade of configuration data is easier and sanity check is
performed during the upgrade.

=item *

Audit of configuration is possible to check what was modified by the
user compared to default values

=back

=head2 What about the user interface ?

L<Config::Model> interface can be:

=over

=item *

a shell-like interface (plain or based on Term::ReadLine).

=item *

Graphical with L<Config::Model::TkUI> (Perl/Tk interface).

=item *

based on curses with L<Config::Model::CursesUI>. This interface can be
handy if your X server is down.

=item *

Through a virtual file system where every configuration parameter is mapped to a file.
(Linux only)

=back

All these interfaces are generated from the configuration model.

And configuration model can be created or modified with a graphical
user interface (with Config::Model::Itself)

=head2 What about configuration data storage ?

Since the syntax of configuration files vary wildly form one application
to another, people who want to use this framework may have to
provide a dedicated parser/writer.

To help with this task, this project provides writer/parsers for common
format: INI style file and perl file. With the additional
Config::Model::Backend::Augeas, Augeas library can be used to read and
write some configuration files. See http://augeas.net for more
details.

=head2 Is there an example of a configuration model ?

The "example" directory contains a configuration model example for
C</etc/fstab> file. This example includes a small program that use
this model to show some ways to extract configuration information.

=head1 Mailing lists

For more question, please send a mail to:

 config-model-users at lists.sourceforge.net

=head1 Suggested reads to start

=head2 Beginners

=over

=item *

L<Config::Model::Manual::ModelCreationIntroduction>:

=item *

L<Config::Model::Cookbook::CreateModelFromDoc>

=back

=head2 Advanced 

=over

=item *

L<Config::Model::Manual::ModelCreationAdvanced>

=back

=head2 Masters

use the source, Luke

=head1 STOP

The documentation below is quite detailed and is more a reference doc regarding
C<Config::Model> class.

For an introduction to model creation, please check:
L<http://sourceforge.net/apps/mediawiki/config-model/index.php?title=Creating_a_model>

Dedicated Config::Model::Manual pages will follow soon.

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

Simple text interface if provided in this module. Curses and Tk
interfaces are provided by L<Config::Model::CursesUI> and
L<Config::Model::TkUI>.

=head1 Constructor

Simply call new without parameters:

 my $model = Config::Model -> new ;

This will create an empty shell for your model.

=cut

sub show_legacy_issue {
    my $self = shift ;
    my $behavior = $self->legacy ;

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

By declaring a set of configuration classes and referring them in node
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

=over

=item *

The C<name> of the class (mandatory)

=item *

A C<class_description> used in user interfaces (optional)

=item *

Optional include specification to avoid duplicate declaration of elements.

=item *

The class elements

=back

Each element will specify:

=over

=item *

Most importantly, the type of the element (mostly C<leaf>, or C<node>)

=item *

The properties of each element (boundaries, check, integer or string,
enum like type ...)

=item *

The default values of parameters (if any)

=item *

Whether the parameter is mandatory

=item *

Targeted audience (beginner, advance, master), i.e. the level of
expertise required to tinker a parameter (to hide expert parameters
from newbie eyes)

=item *

On-line help (for each parameter or value of parameter)

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

    # could add more syntactic suger with 'hash' trait
    # see Moose::Meta::Attribute::Native
    if (defined $self->instances->{$instance_name}) {
        return $self->instances->{$instance_name} ;
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

    $self->instances->{$instance_name} = $i ;
    return $i ;
}

sub instance_names {
    my $self = shift ;
    return keys %{$self->instances} ;
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
{
  my $idx = 0 ;
  map ($experience_index{$_}=$idx++, @experience_list);
}

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


# unpacked model is:
# {
#   element_list  => [ ... ],
#   element       => { element_name => element_data (left as is)    },
#   class_description => <class description string>,
#   include       => 'class_name',
#   include_after => 'element_name',
# }
# description, experience, summary, level, status are moved
# into element description.

=item generated_by

Mention with a descriptive string if this class was generated by a
program.  This parameter is currently reserved for
L<Config::Model::Itself> model editor.

=cut

my @legal_params = qw/element experience status description summary level
                      config_dir
                      read_config read_config_dir write_config
                      write_config_dir accept/;
my @static_legal_params = qw/class_description copyright author license generated_by/ ;                      

sub create_config_class {
    my $self=shift ;
    my %raw_model = @_ ;

    my $config_class_name = delete $raw_model{name} or
        croak "create_config_class: no config class name" ; 

    get_logger("Model")->info("Creating class $config_class_name") ;

    if ($self->model_exists($config_class_name)) {
        Config::Model::Exception::ModelDeclaration->throw
            (
             error=> "create_config_class: attempt to clobber $config_class_name".
             " config class name "
            );
    }

    if (defined $raw_model{inherit_after}) {
        $self->show_legacy_issue("Model $config_class_name: inherit_after is deprecated ",
          "in favor of include_after" );
        $raw_model{include_after} = delete $raw_model{inherit_after} ;
    }
    if (defined $raw_model{inherit}) {
        $self->show_legacy_issue("Model $config_class_name: inherit is deprecated in favor of include");
        $raw_model{include} = delete $raw_model{inherit} ;
    }

    my ($model, $raw_copy) = $self->load_raw_model ($config_class_name, \%raw_model);
    $self->raw_models->{$config_class_name} = \%raw_model ;


    $self->_create_config_class ($config_class_name, $model, $raw_copy);
    return $config_class_name ;
}

#
# New subroutine "load_raw_model" extracted - Sat Nov 27 17:01:30 2010.
#
sub load_raw_model {
    my ($self, $config_class_name, $raw_model) = @_;
    
    # perform some syntax and rule checks and expand compacted
    # elements ie  [qw/foo bar/] => {...} is transformed into
    #  foo => {...} , bar => {...} before being stored

    my $raw_copy = dclone $raw_model ;

    my %model = ( element_list => [] );

    # add included items
    if ($self->skip_include and defined $raw_copy->{include}) {
        my $inc = delete $raw_copy->{include} ;
        $model{include}       =  ref $inc ? $inc : [ $inc ];
        $model{include_after} = delete $raw_copy->{include_after}
          if defined $raw_copy->{include_after};
    }
    else {
        # include class in raw_copy, raw_model is left as is
        $self->include_class($config_class_name, $raw_copy ) ;
    }
    return (\%model, $raw_copy);
}

#
# New subroutine "_create_config_class" extracted - Sat Nov 27 17:06:42 2010.
#
sub _create_config_class {
    my $self = shift;
    my $config_class_name = shift;
    my $model = shift;
    my $raw_copy = shift;

    
    # check config class parameters and fill %model
    $self->check_class_parameters($config_class_name, $model, $raw_copy) ;

    my @left_params = keys %$raw_copy ;
    Config::Model::Exception::ModelDeclaration->throw
        (
         error=> "create class $config_class_name: unknown ".
         "parameter '" . join("', '",@left_params)."', expected '".
         join("', '",@legal_params, @static_legal_params)."'"
        )
          if @left_params ;


    $self->models->{$config_class_name} = $model ;

    return (\@left_params);
}

sub check_class_parameters {
    my $self  = shift;
    my $config_class_name = shift || die ;
    my $model = shift || die ;
    my $raw_model = shift || die ;


    my @element_list ;

    # first construct the element list
    my @compact_list = @{$raw_model->{element} || []} ;
    while (@compact_list) {
        my ($item,$info) = splice @compact_list,0,2 ;
        # store the order of element as declared in 'element'
        push @element_list, ref($item) ? @$item : ($item) ;
    }

    # optional parameter to force element order. Useful when parameters declarations
    # are grouped. Although interaction with include may be tricky. Let's not advertise it.
    # yet.

    if (defined $raw_model->{force_element_order}) {
        my @forced_list = @{delete $raw_model->{force_element_order}} ;
        my %forced = map { ($_ => 1 ) } @forced_list ;
        foreach (@element_list) {
            next if delete $forced{$_};
            Config::Model::Exception::ModelDeclaration->throw
            (
             error=> "class $config_class_name: element $_ is not in force_element_order list"
            ) ;
        }
        if (%forced) {
            Config::Model::Exception::ModelDeclaration->throw
            (
             error=> "class $config_class_name: force_element_order list has unknown elements "
                . join(' ',keys %forced)
            ) ;
        }
    }



    # get data read/write information (if any)
    $model->{read_config_dir} = $model->{write_config_dir}
      = delete $raw_model->{config_dir}
        if defined $raw_model->{config_dir};

    my @info_to_move = (
        qw/read_config  read_config_dir
           write_config write_config_dir/, # read/write stuff

        # this parameter is filled by class generated by a program. It may
        # be used to avoid interactive edition of a generated model
        'generated_by',
        qw/class_description author copyright license/
    ) ;

    foreach my $info (@info_to_move) {
        next unless defined $raw_model->{$info} ;
        $model->{$info} = delete $raw_model->{$info} ;
    }

    # handle accept parameter
    my @accept_list ;
    my %accept_hash ;
    my $accept_info = delete $raw_model->{'accept'} || [] ;
    while (@$accept_info) {
        my $name_match = shift @$accept_info ; # should be a regexp

        # handle legacy
        if (ref $name_match) {
            my $implicit = defined $name_match->{name_match} ? '' :'implicit ';
            unshift @$accept_info, $name_match; # put data back in list
            $name_match  = delete $name_match->{name_match} || '.*' ;
            warn "class $config_class_name: name_match ($implicit$name_match)",
                " in accept is deprecated\n" ;
        }
        
        push @accept_list, $name_match ;
        $accept_hash{$name_match} = shift @$accept_info;
    }

    $model->{accept}  = \%accept_hash ;
    $model->{accept_list}  = \@accept_list ;

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

    # element is handled first
    foreach my $info_name (qw/element experience status description summary level/) {
        my $raw_compact_info = delete $raw_model->{$info_name} ;

        next unless defined $raw_compact_info ;

        Config::Model::Exception::ModelDeclaration->throw
            (
             error=> "Data for parameter $info_name of $config_class_name"
             ." is not an array ref"
            ) unless ref($raw_compact_info) eq 'ARRAY' ;


        my @raw_info = @$raw_compact_info ;
        while (@raw_info) {
            my ($item,$info) = splice @raw_info,0,2 ;
            my @element_names = ref($item) ? @$item : ($item) ;

            # move element informations (handled first)
            if ($info_name eq 'element') {

                # warp can be found only in element item
                $self->translate_legacy_info($config_class_name,
                                             $element_names[0], $info) ;

                if (defined $info->{permission}) {
                    $self->translate_legacy_permission($config_class_name,
                                                       $info, $info ) ;
                }

                # copy in element data *after* legacy translation
                map {$model->{element}{$_} = dclone($info) ;} @element_names;
            }

            # move some information into element declaration (without clobberring)
            elsif ($info_name =~ /description|level|summary|experience|status/) {
                foreach (@element_names) {
                    Config::Model::Exception::ModelDeclaration->throw
                      (
                        error => "create class $config_class_name: '$info_name' "
                               . "declaration for non declared element '$_'"
                      ) unless defined $model->{element}{$_} ;

                    $model->{element}{$_}{$info_name} ||= $info ;
                }
            }
            else {
                die "Unexpected element $item in $config_class_name model";
            }

        }
    }

    Config::Model::Exception::ModelDeclaration->throw
        (
         error => "create class $config_class_name: unexpected "
                . "parameters '". join (', ', keys %$raw_model) ."' "
                . "Expected '".join("', '",@legal_params, @static_legal_params)."'"
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

    $self->show_legacy_issue("$config_class_name: parameter permission is deprecated "
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
        $self->translate_compute_info($config_class_name,$elt_name, $info,
                                      refer_to => 'computed_refer_to');
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
    $self->show_legacy_issue("$config_class_name->$elt_name: parameter cargo_type is deprecated.");
    my %cargo ;

    if (defined $info->{cargo_args}) {
       %cargo = %{ delete $info->{cargo_args}} ;
       $self->show_legacy_issue("$config_class_name->$elt_name: parameter cargo_args is deprecated.");
    }

    $cargo{type} = $c_type;

    if (defined $info->{config_class_name}) {
        $cargo{config_class_name} = delete $info->{config_class_name} ;
        $self->show_legacy_issue("$config_class_name->$elt_name: parameter config_class_name is ",
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
        $self->show_legacy_issue("$config_class_name->$elt_name: parameter $from is deprecated in favor of $to");
        $info->{$to} = delete $info->{$from}  ;
    }
}

sub translate_allow_compute_override {
    my $self = shift ;
    my $config_class_name = shift ;
    my $elt_name = shift ;
    my $info = shift ;

    if (defined $info->{allow_compute_override}) {
        $self->show_legacy_issue("$config_class_name->$elt_name: parameter allow_compute_override is deprecated in favor of compute -> allow_override");
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

        $self->show_legacy_issue("$config_class_name->$elt_name: specifying compute info with ",
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
        $self->show_legacy_issue($warn,"Use default_with_init") ;
    }
    elsif (ref($def_info) eq 'ARRAY') {
        $info->{default_keys} = $def_info ;
        $self->show_legacy_issue($warn,"Use default_keys") ;
    }
    else {
        $info->{default_keys} = [ $def_info ] ;
        $self->show_legacy_issue($warn,"Use default_keys") ;
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
        $self->show_legacy_issue($warn,"Use auto_create_keys") ;
    }
    elsif ($info->{type} eq 'list') {
        $info->{auto_create_ids} = $ac_info ;
        $self->show_legacy_issue($warn,"Use auto_create_ids") ;
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
    elsif (defined $raw_follow) {
        # follow is a simple string
        return { f1 => $raw_follow } ;
    }
    else {
        return {} ;
    }
}

sub translate_rules_arg {
    my ($self,$config_class_name, $elt_name,$type, $warper_items,
        $raw_rules) = @_ ;

    my $multi_follow =  @$warper_items > 1 ? 1 : 0;
    my $follow = @$warper_items ;

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
        @rules = $follow ? map { ( "\$f1 eq '$_'" , $h->{$_} ) } keys %$h : keys %$h;
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
                my @bool_expr = $follow ? map { /\$/ ? $_ : "\$f1 eq '$_'" } @keys : @keys ;
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

    $self->show_legacy_issue("$config_class_name: parameter 'built_in' is deprecated "
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

    $self->show_legacy_issue("$config_class_name: parameter 'built_in_list' is deprecated "
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
        elsif ( not grep { $_ eq $included_item; } @static_legal_params ) {
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


=head1 Load predeclared model

You can also load predeclared model.

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

This method will also look in C<Foo/Bar.d> directory for additional model information. 
Model snippet found there will be loaded with L<augment_config_class>.

Returns a list containing the names of the loaded classes. For instance, if
C<Foo/Bar.pl> contains a model for C<Foo::Bar> and C<Foo::Bar2>, C<load>
will return C<( 'Foo::Bar' , 'Foo::Bar2' )>.



=cut

# load a model from file
sub load {
    my $self = shift ;
    my $load_model = shift ; # model name like Foo::Bar
    my $load_file = shift ;  # model file (override model name), used for tests

    my $load_path = $load_model ;
    $load_path =~ s/::/\//g;

    $load_file ||=  $self->model_dir . '/' . $load_path  . '.pl';

    my $model = $self->_do_model_file ($load_model,$load_file);

    my @loaded ;
    foreach my $config_class_info (@$model) {
        my @data = ref $config_class_info eq 'HASH' ? %$config_class_info
                 : ref $config_class_info eq 'ARRAY' ? @$config_class_info
                 : croak "load $load_file: config_class_info is not a ref" ;
        push @loaded, $self->create_config_class(@data) ;
    }

    # look for additional model information
    my $snippet_dir =  $self->model_dir . '/' . $load_path  . '.d';
    get_logger("Model::Loader")-> info("looking for snippet in $snippet_dir") ;
    if (-d $snippet_dir) {
        foreach my $snippet_file (glob ("$snippet_dir/*.pl")) {
            get_logger("Model::Loader")-> info("Found snippet $snippet_file") ;
            my $snippet_model = $self->_do_model_file ($load_model,$snippet_file);
            foreach my $snippet_info (@$snippet_model) {
                my @data = ref $snippet_info eq 'HASH'  ? %$snippet_info
                         : ref $snippet_info eq 'ARRAY' ? @$snippet_info
                         : croak "load $load_file: config_class_info is not a ref" ;
                $self->augment_config_class(@data) ;
            }
        }
    }

    return @loaded
}


#
# New subroutine "_do_model_file" extracted - Sun Nov 28 17:25:35 2010.
#
# $load_model is used only for error message
sub _do_model_file {
    my ($self,$load_model,$load_file) = @_ ;

    get_logger("Model::Loader")-> info("load model $load_file") ;

    my $err_msg = '';
    my $model = do $load_file ;

    unless ($model) {
        if ($@) {$err_msg =  "couldn't parse $load_file: $@"; }
        elsif (not defined $model) {$err_msg = "couldn't do $load_file: $!"}
        else {$err_msg = "couldn't run $load_file" ;}
    }
    elsif (ref($model) ne 'ARRAY') {
        $model = [ $model ];
    }

    Config::Model::Exception::ModelDeclaration
            -> throw (message => "model $load_model: $err_msg")
                if $err_msg ;

    return $model;
}


=head1 Model plugin

Config::Model can also use model plugins. Each model can be augmented by model snippets
stored into directory C<< <model_name>.d >>. All files found there will be merged to existing model.

For instance, this model:

 {
    name => "Master",
    element => [
	fs_vfstype => {
            type => 'leaf',
            value_type => 'enum',
            choice => [ qw/ext2 ext3/ ],
        },
        fs_mntopts => {
            type => 'warped_node',
            follow => { 'f1' => '- fs_vfstype' },
            rules => [
                '$f1 eq \'ext2\'', { 'config_class_name' => 'Fstab::Ext2FsOpt' },
                '$f1 eq \'ext3\'', { 'config_class_name' => 'Fstab::Ext3FsOpt' }, 
            ],
        }
    ]
 }

can be augmented with:

 {
    name => "Fstab::Fsline",
    element => [
 	fs_vfstype => { choice => [ qw/ext4/ ], },
        fs_mntopts => {
            rules => [
                q!$f1 eq 'ext4'!, { 'config_class_name' => 'Fstab::Ext4FsOpt' }, 
            ],
        },
    ]
 } ;
 
Then, the merged model will feature C<fs_vfstype> with choice C<ext2 ext4 ext4>. 
Likewise, C<fs_mntopts> will feature rules for the 3 filesystems. 


=head2 augment_config_class (name => '...', class_data )

Enhance the feature of a configuration class. This method uses the same parameters
as L<create_config_class>.

=cut

sub augment_config_class {
    my ($self,%augment_data) = @_ ;
    # %args must contain existing class name to augment 

    # plus other data to merge to raw model
    my $config_class_name = delete $augment_data{name} ||
        croak "augment_config_class: missing class name" ;
    
    # check config class parameters and fill %model
    my ( $model_to_merge, $augment_copy) = $self->load_raw_model ($config_class_name, \%augment_data);
    
    my $orig_model = $self->get_model($config_class_name) ;
    croak "unknown class to augment: $config_class_name" unless defined $orig_model ;
    
    $self->check_class_parameters($config_class_name, $model_to_merge, $augment_copy) ;

    my $model = merge ($orig_model, $model_to_merge) ;
    
    # remove duplicates in element_list and accept_list while keeping order
    foreach my $list_name (qw/element_list accept_list/) {
        my %seen ;
        my @newlist ;
        foreach (@{$model->{$list_name}}) {
            push @newlist, $_ unless $seen{$_} ;
            $seen{$_}= 1;
        }
    
        $model->{$list_name} = \@newlist;
    }
    
    $self->models->{$config_class_name} = $model ;
}

=head1 Model query

=head2 get_model( config_class_name )

Return a hash containing the model declaration (in a deep clone copy of the hash).
You may modify the hash at leisure.

=cut

sub get_model {
    my $self =shift ;
    my $config_class_name = shift
      || die "Model::get_model: missing config class name argument" ;

    $self->load($config_class_name)
      unless $self->model_exists($config_class_name) ;

    my $model = $self->model($config_class_name) ||
      croak "get_model error: unknown config class name: $config_class_name";

    return dclone($model) ;
}

=head2 get_model_doc 

Generate POD document for configuration class.

=cut

sub get_model_doc {
    my ( $self, $top_class_name ) = @_;

    if ( not defined $self->model($top_class_name) ) {
        croak
          "get_model_doc error : unknown config class name: $top_class_name";
    }

    my @classes = ($top_class_name);
    my %result;

    while (@classes) {
        my $class_name = shift @classes;
        next if defined $result{$class_name};
        my $c_model   = $self->get_model($class_name)
          || croak "get_model_doc model error : unknown config class name: $class_name";

        my $full_name = "Config::Model::models::$class_name" ;

        my %see_also ;

        my @pod = (
            "=head1 NAME",                                    '',
            "$full_name - Configuration class " . $class_name,                    '',
            "=head1 DESCRIPTION",                             '',
            "Configuration classes used by L<Config::Model>", ''
        );

        my %legalese;

        my $i = 0;

        my $class_desc = $c_model->{class_description};
        push @pod, $class_desc, '' if defined $class_desc;

        my @elt = ( "=head1 Elements", '' );
        foreach my $elt_name ( @{ $c_model->{element_list} } ) {
            my $elt_info = $c_model->{element}{$elt_name};
            my $summary = $elt_info->{summary} || '';
            $summary &&= " - $summary" ;
            push @elt, "=head2 $elt_name$summary", '';
            push @elt, $self->get_element_description($elt_info) , '' ;

            foreach ($elt_info,$elt_info->{cargo}) { 
                my $ccn = $_->{config_class_name};
                next unless defined $ccn ;
                push @classes, $ccn ;
                $see_also{$ccn} = 1;
            }
        }

        foreach my $what (qw/author copyright license/) {
            my $item = $c_model->{$what};
            push @{ $legalese{$what} }, $item if $item;
        }

        my @end;
        foreach my $what (qw/author copyright license/) {
            next unless @{ $legalese{$what} || [] };
            push @end, "=head1 " . uc($what), '', '=over', '',
              ( map { ( "=item $_", '' ); } map {ref $_ ? @$_ : $_ } @{ $legalese{$what} } ),
              '', '=back', '';
        }

        my @see_also =  (
            "=head1 SEE ALSO",'',"=over",'',"=item *",'',"L<config-edit>",'',
            ( map { ( "=item *",'',"L<Config::Model::models::$_>",'') ; } sort keys %see_also ),
            "=back",'') ;

        $result{$full_name} = join( "\n", @pod, @elt, @see_also, @end,'=cut','' ) . "\n";
    }
    return \%result ;
}

sub get_element_description {
    my ( $self, $elt_info ) = @_;

    my $type  = $elt_info->{type};
    my $cargo = $elt_info->{cargo};
    my $vt    = $elt_info->{value_type} ;

    my $of         = '';
    my $cargo_type = $cargo->{type};
    my $cargo_vt   = $cargo->{value_type};
    $of = " of " . ( $cargo_vt or $cargo_type ) if defined $cargo_type;

    my $desc = $elt_info->{description} || '';
    if ($desc) {
        $desc .= '.' unless $desc =~ /\.$/ ;
        $desc .= ' ' unless $desc =~ /\s$/ ;
    }
    
    my $info = $elt_info->{mandatory} ? 'Mandatory. ' : 'Optional. ' ;

    $info .= "Type ". ($vt || $type) . $of.'. ';
    
    foreach (qw/choice default upstream_default/) {
        my $item = $elt_info->{$_} ;
        next unless defined $item ;
        my @list = ref($item) ? @$item : ($item) ;
        $info .= "$_: '". join("', '",@list)."'. " ;
    } 
    
    my $elt_help = $self->get_element_value_help ($elt_info) ;
    
    return $desc."I<< $info >>" .$elt_help;
}

sub get_element_value_help {
    my ( $self, $elt_info ) = @_;

    my $help = $elt_info->{help} ;
    return '' unless defined $help ;
    
    my $help_text = "\n\nHere are some explanations on the possible values:\n\n=over\n\n" ;
    foreach my $v (sort keys %$help) {
        $help_text .= "=item $v\n\n$help->{$v}\n\n" ;
    }
    
    return $help_text."=back\n\n" ;
}

=head2 generate_doc ( top_class_name , [ directory ] )

Generate POD document for configuration class top_class_name 
and write them on STDOUT or in specified directory.

Returns a list of written file names.

=cut

sub generate_doc {
    my ( $self, $top_class_name, $dir ) = @_;

    my $res  = $self->get_model_doc($top_class_name) ;
    my @wrote ;

    if (defined $dir and $dir) {
        foreach my $class_name (keys %$res) {
            my $file = $class_name;
            $file =~ s!::!/!g ;
            my $pl_file   = $self->model_dir."/$file.pl";
            my $pod_file  = $dir."/$file.pod";
            my $pod_dir = $pod_file ;
            $pod_dir =~ s!/[^/]+$!!;
            make_path($pod_dir,{ mode => 0755} ) unless -d $pod_dir ;
            if (not -e $pod_file or not -e $pl_file or -M $pl_file > -M $pod_file ) {
                my $fh = IO::File->new($pod_file,'>') || die "Can't open $pod_file: $!";
                $fh->binmode(":utf8");
                $fh->print($res->{$class_name});
                $fh->close ;
                print "Wrote documentation in $pod_file\n";
                push @wrote, $pod_file ;
            }
        }
    }
    else {
        foreach my $class_name (keys %$res) {
            print "########## $class_name ############ \n\n";
            print $res->{$class_name} ;
        }
    }
    return @wrote ;
}

=head2 get_element_model( config_class_name , element)

Return a hash containing the model declaration for the specified class
and element.

=cut

sub get_element_model {
    my $self =shift ;
    my $config_class_name = shift
      || die "Model::get_element_model: missing config class name argument" ;
    my $element_name = shift
      || die "Model::get_element_model: missing element name argument" ;

    $self->load($config_class_name)
      unless $self->model_defined($config_class_name) ;

    my $model = $self->model($config_class_name) ||
      croak "get_element_model error: unknown config class name: $config_class_name";

    my $element_m = $model->{element}{$element_name} ||
      croak "get_element_model error: unknown element name: $element_name";

    return dclone($element_m) ;
}

# returns a hash ref containing the raw model, i.e. before expansion of
# multiple keys (i.e. [qw/a b c/] => ... )
# internal. For now ...
sub get_raw_model {
    my $self =shift ;
    my $config_class_name = shift ;

    $self->load($config_class_name)
      unless defined $self->raw_model($config_class_name) ;

    my $raw_model = $self->raw_model($config_class_name) ||
      croak "get_raw_model error: unknown config class name: $config_class_name";

    return dclone($raw_model) ;
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
        my $elt_data = $model->{element}{$elt} ;
        my $l = $elt_data->{level} || $default_property{level} ;
        foreach my $experience (@_) {
            my $xp = $elt_data->{experience} || $default_property{experience} ;
            push @result, $elt if ($l ne 'hidden' and $xp eq $experience );
        }
    }

    return @result ;
}

=head2 get_element_property

Returns the property of an element from the model.

Parameters are:

=over 

=item class 

=item element 

=item property

=back 

=cut


sub get_element_property {
    my $self = shift ;
    my %args = @_ ;

    my $elt = $args{element} ||
      croak "get_element_property: missing 'element' parameter";
    my $prop = $args{property} ||
      croak "get_element_property: missing 'property' parameter";
    my $class = $args{class} ||
      croak "get_element_property:: missing 'class' parameter";

    my $model = $self->model($class) ;
    # must take into account 'accept' model parameter
    if (not defined $model->{element}{$prop} ) {
        
        foreach my $acc_re ( @{$model->{accept_list}} ) {
            return $model->{accept}{$acc_re}{$prop} || $default_property{$prop}
                if $elt =~ /^$acc_re$/;
        }
    }

    return $self->model($class)->{element}{$elt}{$prop}
        || $default_property{$prop} ;
}

=head2 list_class_element

Returns a string listing all the class and elements. Useful for
debugging your configuration model.

=cut

sub list_class_element {
    my $self = shift ;
    my $pad  =  shift || '' ;

    my $res = '';
    foreach my $class_name ($self->raw_model_names) {
        $res .= $self->list_one_class_element($class_name) ;
    }
    return $res ;
}

sub list_one_class_element {
    my $self = shift ;
    my $class_name = shift ;
    my $pad  =  shift || '' ;

    my $res = $pad."Class: $class_name\n";
    my $c_model = $self->raw_model($class_name);
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

=head1 Available models

Returns an array of 3 hash refs:

=over 

=item *

category (system or user or application) => application list. E.g. 

 { system => [ 'popcon' , 'fstab'] }

=item *

application => { model => 'model_name', ... }

=item *

application => model_name

=back

=cut

sub available_models {
   
    my $path = $INC{"Config/Model.pm"} ;
    $path =~ s/\.pm// ;
    my (%categories, %appli_info, %applications ) ;

    get_logger("Model")->trace("available_models: path is $path");
    foreach my $dir (glob("$path/*.d")) {
        my ($cat) = ( $dir =~ m!.*/([\w\-]+)\.d! );
        
        get_logger("Model")->trace("available_models: category dir $dir");
        
        foreach my $file (sort glob("$dir/*")) {
            next if $file =~ m!/README! ;
            my ($appli) = ($file =~ m!.*/([\w\-]+)! );
            get_logger("Model")->debug("available_models: opening file $file");
            open (F, $file) || die "Can't open file $file:$!" ;
            while (<F>) {
                chomp ;
                s/^\s+// ;
                s/\s+$// ;
                s/#.*// ;
                my ($k,$v) = split /\s*=\s*/ ;
                next unless $v ;
                push @{$categories{$cat}} , $appli if $k =~ /model/i;
                $appli_info{$appli}{$k} = $v ; 
                $applications{$appli} = $v if $k =~ /model/i; 
            }
        }
    }
    return \%categories, \%appli_info, \%applications ;
}

no Any::Moose ;
__PACKAGE__->meta->make_immutable ;

1;

=head1 Error handling

Errors are handled with an exception mechanism (See
L<Exception::Class>).

When a strongly typed Value object gets an authorized value, it raises
an exception. If this exception is not caught, the programs exits.

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

=head1 BUGS

Given Murphy's law, the author is fairly confident that you will find
bugs or miss some features. Please report them to config-model at
rt.cpan.org, or through the web interface at 
https://rt.cpan.org/Public/Bug/Report.html?Queue=config-model . 
The author will be notified, and then you'll automatically be
notified of progress on your bug.

=head1 FEEDBACK

Feedback from users are highly desired. If you find this module useful, please
share your use cases, success stories with the author or with the config-model-
users mailing list. 

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 LICENSE

    Copyright (c) 2005-2011 Dominique Dumont.

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

L<http://sourceforge.net/apps/mediawiki/config-model/index.php?title=Creating_a_model>

=head2 Model elements

The arrow shows the inheritance of the classes

=over

=item *

L<Config::Model::Node> <- L<Config::Model::AutoRead> <- L<Config::Model::AnyThing>

=item *

L<Config::Model::HashId> <- L<Config::Model::AnyId> <- L<Config::Model::AnyThing>

=item *

L<Config::Model::ListId> <- L<Config::Model::AnyId> <- L<Config::Model::AnyThing>

=item *

L<Config::Model::Value> <- L<Config::Model::AnyThing>

=item *

L<Config::Model::CheckList> <- L<Config::Model::AnyThing>

=item *

L<Config::Model::WarpedNode> <- L<Config::Model::AnyThing>


=back

=head2 command line

L<config-edit>

=head2 Read and write backends

=over

=item *

L<Config::Model::Backend::Fstab> <- L<Config::Model::Backend::Any>

=item *

L<Config::Model::Backend::IniFile> <- L<Config::Model::Backend::Any>

=item *

L<Config::Model::Backend::PlainFile> <- L<Config::Model::Backend::Any>

=item *

L<Config::Model::Backend::ShellVar> <- L<Config::Model::Backend::Any>

=item *

L<Config::Model::Backend::Yaml> <- L<Config::Model::Backend::Any>

=back

=head2 Model utilities

=over

=item *

L<Config::Model::Annotation>

=item *

L<Config::Model::Describe>

=item *

L<Config::Model::Dumper>

=item *

L<Config::Model::DumpAsData>

=item *

L<Config::Model::IdElementReference>

=item *

L<Config::Model::Loader>

=item *

L<Config::Model::ObjTreeScanner>

=item *

L<Config::Model::Report>

=item *

L<Config::Model::Searcher>

=item *

L<Config::Model::SimpleUI>

=item *

L<Config::Model::TermUI>

=item *

L<Config::Model::Iterator>

=item *

L<Config::Model::AutoRead>

=item *

L<Config::Model::ValueComputer>

=item *

L<Config::Model::Warper>

=back

=cut
