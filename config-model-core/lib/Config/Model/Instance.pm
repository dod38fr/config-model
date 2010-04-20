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

package Config::Model::Instance;
use Scalar::Util qw(weaken) ;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

use Config::Model::Annotation;
use Config::Model::Exception ;
use Config::Model::Node ;
use Config::Model::Loader;
use Config::Model::Searcher;
use Config::Model::WizardHelper;

use strict ;
use Carp;
use warnings FATAL => qw(all);
use warnings::register ;

our $VERSION="1.202";

use Carp qw/croak confess cluck/;

my $logger = get_logger("Instance") ;

=head1 NAME

Config::Model::Instance - Instance of configuration tree

=head1 SYNOPSIS

 my $model = Config::Model->new() ;
 $model ->create_config_class ( ... ) ;

 my $inst = $model->instance (root_class_name => 'SomeRootClass', 
                              instance_name    => 'some_name');

=head1 DESCRIPTION

This module provides an object that holds a configuration tree. 

=head1 CONSTRUCTOR

An instance object is created by calling 
L<instance method|Config::Model/"Configuration instance"> on 
an existing model:

 my $inst = $model->instance (root_class_name => 'SomeRootClass', 
                              instance_name => 'test1');

The directory (or directories) holding configuration files is
specified within the configuration model. For test purpose you can
change the "root" directory with C<root_dir> parameter:

=over

=item root_dir

Pseudo root directory where to read I<and> write configuration files

=item backend

Specify which backend to use. See L</write_back ( ... )> for details

=item skip_read

When set, configuration files will not be read when creating
configuration tree.

=back

Note that the root directory specified within the configuration model
will be overridden by C<root_dir> parameter.

If you need to load configuration data that are not correct, you can
use C<< force_load => 1 >>. Then, wrong data will be discarded.

=cut

sub new {
    my $proto = shift ;
    my $class = ref($proto) || $proto ;
    my %args = @_ ;

    my $root_class_name = delete $args{root_class_name} || 
      confess __PACKAGE__," error: missing root_class_name parameter" ;

    my $config_model = delete $args{config_model} || 
      confess __PACKAGE__," error: missing config_model parameter" ;

    confess __PACKAGE__," error: config_model is not a Config::Model object"
      unless $config_model->isa('Config::Model') ; 

    my $force_load = delete $args{force_load} || 0 ;

    my $self 
      = {
	 # stack used to store whether read and/or write check must 
	 # be done in tree objects (Value, Id ...)
	 check_stack => [ { fetch => 1,
			    store => 1,
			    type  => 1 } ],

	 # a unique (instance wise) placeholder for various tree objects
	 # to store information
	 safe => {
		 } ,

	 # preset mode to load values found by HW scan or other
	 # automatic scheme
	 preset => 0,

	 config_model => $config_model ,
	 root_class_name => $root_class_name ,

	 # This array holds a set of sub ref that will be invoked when
	 # the users requires to write all configuration tree in their
	 # backend storage.
	 write_back => [] ,

	 # used for auto_read auto_write feature
	 name            =>  delete $args{name} ,
	 root_dir        =>  delete $args{root_dir},

	 backend         =>  delete $args{backend} || '',
	 skip_read       =>  delete $args{skip_read} || 0,
	};

    my @left = keys %args ;
    croak "Instance->new: unexpected parameter: @left" if @left ;

    # cleanup paths
    map { $self->{$_} .= '/' if defined $self->{$_} and $self->{$_} !~ m!/$!}
      qw/root_dir/;

    weaken($self->{config_model}) ;

    bless $self, $class;

    $self->push_no_value_check('store','fetch','type') if $force_load ;

    $self->reset_config ;

    $self->pop_no_value_check() if $force_load ;

    return $self ;
}


=head1 METHODS

=head2 name()

Returns the instance name.

=cut

sub name {
    return shift->{name} ;
}

=head2 config_root()

Returns the root object of the configuration tree.

=cut

sub config_root {
    return shift->{tree} ;
}

=head2 reset_config

Destroy current configuration tree (with data) and returns a new tree with
data (and annotations) loaded from disk.

=cut

sub reset_config {
    my $self= shift ;

    $self->{tree} = Config::Model::Node
      -> new ( config_class_name => $self->{root_class_name},
	       instance => $self,
	       config_model => $self->{config_model},
	       skip_read  => $self->{skip_read},
	     );

    # $self->{annotation_saver} = Config::Model::Annotation
    #   -> new (
    # 	      config_class_name => $self->{root_class_name},
    # 	      instance => $self ,
    # 	      root_dir => $self->{root_dir} ,
    # 	     ) ;
    # $self->{annotation_saver}->load ;

    return $self->{tree} ;
}


=head2 config_model()

Returns the model (L<Config::Model> object) of the configuration tree.

=cut

sub config_model {
    return shift->{config_model} ;
}

=head2 annotation_saver()

Returns the object loading and saving annotations. See
L<Config::Model::Annotation> for details.

=cut

# sub annotation_saver {
#     my $self = shift ;
#     return $self->{annotation_saver} ;
#}

=head2 preset_start ()

All values stored in preset mode are shown to the user as default
values. This feature is useful to enter configuration data entered by
an automatic process (like hardware scan)

=cut

sub preset_start {
    my $self = shift ;
    $logger->info("Starting preset mode");
    $self->{preset} = 1;
}

=head2 preset_stop ()

Stop preset mode

=cut

sub preset_stop {
    my $self = shift ;
    $logger->info("Stopping preset mode");
    $self->{preset} = 0;
}

=head2 preset ()

Get preset mode

=cut

sub preset {
    my $self = shift ;
    return $self->{preset} ;
}

=head2 push_no_value_check ( fetch | store | type , ... )

Tune C<Config::Model::Value> to perform check on read (fetch) or write
(store) or verify the value according to its C<value_type>.  The
passed parameters are stacked. Parameters are :

=over 8

=item store

Skip write check.

=item fetch

Skip read check.

=item type

Skip value_type check (See L<Config::Model::Value> for details). 
I.e L<Config::Model::Value> will not enforce type checking.

=back

Note that these values are stacked. They can be read by
get_value_check until the next push_no_value_check or
pop_no_value_check call.

Example:

  $i->push_no_value_check('fetch') ;
  $i->push_no_value_check('fetch','type') ;

=cut

sub push_no_value_check {
    my $self = shift ;
    my %h = ( fetch => 1, store => 1, type  => 1 ) ;

    foreach my $w (@_) {
        if (defined $h{$w}) {
            $h{$w} = 0;
	}
        else {
            croak "push_no_value_check: cannot relax $w value check";
 	}
    }

    unshift @{ $self->{check_stack} }, \%h ;
}

=head2 pop_no_value_check()

Pop off the check stack the last check set entered with
C<push_no_value_check>.

=cut

sub pop_no_value_check {
    my $self = shift ;
    my $h = $self->{check_stack} ;

    if (@$h > 1) {
      # always leave the original value
        shift @$h ;
    }
    else {
        carp "pop_no_value_check: empty check stack";
    }
}

=head2 get_value_check ( fetch | store | type | fetch_or_store | fetch_and_store )

Read the check status. Returns 1 if a check is to be done. O if not. 
When used with the C<fetch_or_store> parameter, returns a logical C<or>
or the check values, i.e. C<read_check || write_check>

=cut

sub get_value_check {
    my $self = shift ;
    my $what = shift ;

    my $ref = $self->{check_stack}[0] ;
    my $result = $what eq 'fetch_or_store'  ? ($ref->{fetch} or  $ref->{store})
               : $what eq 'fetch_and_store' ? ($ref->{fetch} and $ref->{store})
               :                               $ref->{$what} ;

    croak "get_value_check: unexpected parameter: $what, ",
      "expected 'fetch', 'type', 'store', 'fetch_or_store'" 
        unless defined $result;

    return $result ;
}

=head2 data( kind, [data] )

The data method provide a way to store some arbitrary data in the
instance object.

=cut

sub data {
    my $self = shift;
    my $kind = shift || croak "undefined data kind";
    my $store = shift ;

    $self->{safe}{$kind} = $store if defined $store;
    return $self->{safe}{$kind} ;
}


=head2 load( "..." )

Load configuration tree with configuration data. See
L<Config::Model::Loader> for more details

=cut

sub load {
    my $self = shift ;
    my $loader = Config::Model::Loader->new ;
    my %args = @_ eq 1 ? (step => $_[0]) : @_ ;
    $loader->load(node => $self->{tree}, %args) ;
}

=head2 searcher ( )

Returns an object dedicated to search an element in the configuration
model (respecting privilege level).

This method returns a L<Config::Model::Searcher> object. See
L<Config::Model::Searcher> for details on how to handle a search.

=cut

sub search_element {
    my $self = shift ;
    $self->{tree}->search_element(@_) ;
}

=head2 wizard_helper ( ... )

This method returns a L<Config::Model::WizardHelper> object. See
L<Config::Model::WizardHelper> for details on how to create a wizard
widget with this object.

wizard_helper arguments are explained in  L<Config::Model::WizardHelper>
L<constructor arguments|Config::Model::WizardHelper/"Creating a wizard helper">.

=cut

sub wizard_helper {
    my $self = shift ;
    my @args = @_ ;

    my $tree_root = $self->config_root ;

    return Config::Model::WizardHelper->new ( root => $tree_root, @args) ;
}



=head1 Auto read and write feature

Usually, a program based on config model must first create the
configuration model, then load all configuration data. 

This feature enables you to declare with the model a way to load
configuration data (and to write it back). See
L<Config::Model::AutoRead> for details.

=head2 read_root_dir()

Returns root directory where configuration data is read from.

=cut

sub read_directory {
    carp "read_directory is deprecated";
    return shift -> {root_dir} ;
}

sub read_root_dir {
    return shift -> {root_dir} ;
}

=head2 backend()

Get the preferred backend method for this instance (as passed to the
constructor).

=cut

sub backend {
    return shift -> {backend} ;
}

=head2 write_root_dir()

Returns root directory where configuration data is written to.

=cut

sub write_directory {
    my $self = shift ;
    carp "write_directory is deprecated";
    return $self -> {root_dir} ;
}

sub write_root_dir {
    my $self = shift ;
    return $self -> {root_dir} ;
}

=head2 register_write_back ( backend_name, sub_ref )

Register a sub ref (with the backend name) that will be called with
C<write_back> method.

=cut

sub register_write_back {
    my ($self,$backend,$wb) = @_ ;

    croak "register_write_back: parameter is not a code ref"
      unless ref($wb) eq 'CODE' ;
    push @{$self->{write_back}}, [$backend, $wb] ;
}

=head2 write_back ( ... )

Try to run all subroutines registered with C<register_write_back> to
write the configuration information until one succeeds (returns
true). (See L<Config::Model::AutoRead> for details).

You can specify here a pseudo root dir or another config dir to write
configuration data back with C<root> and C<config_dir> parameters. This
will override the model specifications.

You can force to use a backend by specifying C<< backend => xxx >>. 
For instance, C<< backend => 'augeas' >> or C<< backend => 'custom' >>.

You can force to use all backend to write the files by specifying 
C<< backend => 'all' >>.

C<write_back> will croak if no write call-back are known.

=cut

sub write_back {
    my $self = shift ;
    my %args = scalar @_ > 1  ? @_ 
             : scalar @_ == 1 ? (config_dir => $_[0]) 
	     :                  () ; 

    my $force_backend = delete $args{backend} || $self->{backend} ;

    map {croak "write_back: wrong parameters $_" 
	     unless /^(root|config_dir)$/ ;
	 $args{$_} ||= '' ;
	 $args{$_} .= '/' if $args{$_} and $args{$_} !~ m(/$) ;
     }
      keys %args;

    croak "write_back: no subs registered. cannot save data\n" 
      unless @{$self->{write_back}} ;

    my $dir = $args{config_dir} ;
    mkpath($dir,0,0755) if $dir and not -d $dir ;

    foreach my $wb_info (@{$self->{write_back}}) {
	my ($backend,$wb) = @$wb_info ;
	if (not $force_backend 
	    or  $force_backend eq $backend 
	    or  $force_backend eq 'all' ) {
	    # exit when write is successfull
	    my $res = $wb->(%args) ; 
	    $logger->info("write_back called with $backend backend, result is $res");
	    last if ($res and not $force_backend); 
	}
    }
}

1;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::Node>, 
L<Config::Model::Loader>,
L<Config::Model::Searcher>,
L<Config::Model::Value>,

=cut

