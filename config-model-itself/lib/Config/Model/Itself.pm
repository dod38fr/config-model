#    Copyright (c) 2007-2010 Dominique Dumont.
#
#    This file is part of Config-Model-Itself.
#
#    Config-Model-Itself is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Xorg is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

package Config::Model::Itself ;

use strict;
use warnings ;
use Carp ;
use IO::File ;
use Log::Log4perl;
use Data::Dumper ;
use File::Find ;
use File::Path ;
use File::Basename ;

our $VERSION = '1.215';

my $logger = Log::Log4perl::get_logger(__PACKAGE__);

=head1 NAME

Config::Model::Itself - Model editor for Config::Model

=head1 SYNOPSIS

 my $meta_model = Config::Model -> new ( ) ;

 # load Config::Model model
 my $meta_inst = $model->instance (root_class_name => 'Itself::Model' ,
                                   instance_name   => 'meta_model' ,
                                  );

 my $meta_root = $meta_inst -> config_root ;

 # Itself constructor returns an object to read or write the data
 # structure containing the model to be edited
 my $rw_obj = Config::Model::Itself -> new(model_object => $meta_root ) ;

 # now lead the model to be edited
 $rw_obj -> read_all( conf_dir => '/path/to/model_files') ;

 # For Curses UI prepare a call-back to write model
 my $wr_back = sub { $rw_obj->write_all(conf_dir => '/path/to/model_files');

 # create Curses user interface
 my $dialog = Config::Model::CursesUI-> new
      (
       experience => 'advanced',
       store => $wr_back,
      ) ;

 # start Curses dialog to edit the mode
 $dialog->start( $meta_model )  ;

 # that's it. When user quits curses interface, Curses will call
 # $wr_back sub ref to write the modified model.

=head1 DESCRIPTION

Config::Itself module and its model files provide a model of Config:Model
(hence the Itself name).

Let's step back a little to explain. Any configuration data is, in
essence, structured data. This data could be stored in an XML file. A
configuration model is a way to describe the structure and relation of
all items of a configuration data set.

This configuration model is also expressed as structured data. This
structure data is structured and follow a set of rules which are
described for humans in L<Config::Model>.

The structure and rules documented in L<Config::Model> are also
expressed in a model in the files provided with
C<Config::Model::Itself>.

Hence the possibity to verify, modify configuration data provided by
Config::Model can also be applied on configuration models. Using the
same user interface.

From a Perl point of view, Config::Model::Itself provides a class
dedicated to read and write a set of model files.

=head1 Constructor

=head2 new ( model_object => ... )

Creates a new read/write handler. This handler is dedicated to the
C<model_object> passed with the constructor. This parameter must be a
L<Config::Model::Node> class.

=cut

# find all .pl file in model_dir and load them...

sub new {
    my $type = shift ;
    my %args = @_ ;

    my $model_obj = $args{model_object}
      || croak __PACKAGE__," read_all: undefined model object";

     croak __PACKAGE__," read_all: model_object is not a Config::Model::Node object"
       unless $model_obj->isa("Config::Model::Node");

    bless { model_object => $model_obj }, $type ;
}

=head2 Methods

=head1 read_all ( model_dir => ... , root_model => ... , [ force_load => 1 ] )

Load all the model files contained in C<model_dir> and all its
subdirectories. C<root_model> is used to filter the classes read. 

Use C<force_load> if you are trying to load a model containing errors.

C<read_all> returns a hash ref containing ( class_name => file_name , ...)

=cut

sub read_all {
    my $self = shift ;
    my %args = @_ ;
    my $model_obj = $self->{model_object};
    my $dir = $args{model_dir} 
      || croak __PACKAGE__," read_all: undefined config dir";
    my $model = $args{root_model} 
      || croak __PACKAGE__," read_all: undefined root_model";
    my $force_load = $args{force_load} || 0 ;
    my $legacy = $args{legacy} ;

    unless (-d $dir ) {
	croak __PACKAGE__," read_all: unknown config dir $dir";
    }

    my @files ;
    my $wanted = sub { 
	my $n = $File::Find::name ;
	push @files, $n if (-f $_ and not /~$/ 
			    and $n !~ /CVS/
			    and $n !~ m!.svn!
			    and $n =~ /\b$model/
			   ) ;
    } ;
    find ($wanted, $dir ) ;

    my $i = $model_obj->instance ;
    my %read_models ;
    my %class_file_map ;

    for my $file (@files) {
	$logger->info("loading config file $file");

	# now apply some translation to read model
	# - translate legacy warp parameters
	# - expand elements name
	my $tmp_model = Config::Model -> new( skip_include => 1, legacy => $legacy ) ;
	my @models = $tmp_model -> load ( 'Tmp' , $file ) ;

	my $rel_file = $file ;
	$rel_file =~ s/^$dir\/?//;
	die "wrong reg_exp" if $file eq $rel_file ;
	$class_file_map{$rel_file} = \@models ;

	# - move experience, description and level status into parameter info.
	foreach my $model_name (@models) {
	    # no need to dclone model as Config::Model object is temporary
	    my $new_model =  $tmp_model -> get_model( $model_name ) ;

	    foreach my $item (qw/description summary level experience status/) {
		foreach my $elt_name (keys %{$new_model->{element}}) {
		    my $moved_data = delete $new_model->{$item}{$elt_name}  ;
		    next unless defined $moved_data ;
		    $new_model->{element}{$elt_name}{$item} = $moved_data ; 
		}
		delete $new_model->{$item} ;
	    }

	    # cleanup

	    # Since the element are stored in a ordered hash,
	    # load_data expects a array ref instead of a hash ref.
	    # Build this array ref taking the element order into
	    # account
	    my $list  = delete $new_model -> {element_list} ;
	    my $elt_h = delete $new_model -> {element} ;
	    $new_model -> {element} = [] ;
	    map { 
		push @{$new_model->{element}}, $_, $elt_h->{$_} 
	    } @$list ;


	    # remove hash key with undefined values
	    map { delete $new_model->{$_} unless defined $new_model->{$_} 
		                          and $new_model->{$_} ne ''
	      } keys %$new_model ;
	    $read_models{$model_name} = $new_model ;
	}

    }

    # Create all classes listed in %read_models to avoid problems with
    # include statement while calling load_data
    my $class_element = $model_obj->fetch_element('class') ;
    map { $class_element->fetch_with_id($_) } keys %read_models ;

    #print Dumper \@read_models ;
    #require Tk::ObjScanner; Tk::ObjScanner::scan_object(\%read_models) ;
    $model_obj->instance->push_no_value_check(qw/store fetch type/) if $force_load;

    $logger->info("loading all extracted data in Config::Model::Itself");
    $model_obj->load_data( {class => \%read_models} ) ;

    $model_obj->instance->pop_no_value_check() if $force_load;

    return $self->{map} = \%class_file_map ;
}

# internal
sub get_perl_data_model{
    my $self = shift ;
    my %args = @_ ;
    my $model_obj = $self->{model_object};
    my $class_name = $args{class_name}
      || croak __PACKAGE__," read: undefined class name";

    my $class_elt = $model_obj->fetch_element('class')
      ->fetch_with_id($class_name) ;

    my $model = $class_elt->dump_as_data ;

    # now apply some translation to read model
    # - Do NOT translate legacy warp parameters
    # - Do not compact elements name

    # - move experience, description and level status back in class info.
    # my $all_elt_data = $model->{element} || [] ;
    # for (my $i = 0 ; $i < @$all_elt_data; $i ++) {
    # 	my $elt_name = $all_elt_data->[$i++] ;
    # 	my $elt_data = $all_elt_data->[$i] ;
    # 	foreach my $item (qw/description/) {
    # 	    my $moved_data = delete $elt_data->{$item}  ;
    # 	    next unless defined $moved_data ;
    # 	    push @{$model->{$item}}, $elt_name, $moved_data ; 
    # 	}
    # } 

    # don't forget to add name
    $model->{name} = $class_name ;

    return $model ;
}

=head2 write_all ( model_dir => ... )

Will write back configuration model in the specified directory. The
structure of the read directory is respected.

=cut

sub write_all {
    my $self = shift ;
    my %args = @_ ;
    my $model_obj = $self->{model_object} ;
    my $dir = $args{model_dir} 
      || croak __PACKAGE__," write_all: undefined config dir";

    my $map = $self->{map} ;

    unless (-d $dir ) {
	mkpath($dir,0, 0755) || die "Can't mkpath $dir:$!";
    }

    my $i = $model_obj->instance ;

    # get list of all classes loaded by the editor
    my %loaded_classes 
      = map { ($_ => 1); } 
	$model_obj->fetch_element('class')->get_all_indexes ;

    # remove classes that are listed in map
    foreach my $file (keys %$map) {
	foreach my $class_name (@{$map->{$file}}) {
	    delete $loaded_classes{$class_name} ;
	}
    }

    # add remaining classes in map
    my %new_map =  map { 
	my $f = $_; 
	$f =~ s!::!/!g; 
	("$f.pl" => [ $_ ]) ;
    } keys %loaded_classes ;

    my %map_to_write = (%$map,%new_map) ;

    foreach my $file (keys %map_to_write) {
	$logger->info("writing config file $file");

	my @data ;

	foreach my $class_name (@{$map_to_write{$file}}) {
	    $logger->info("writing class $class_name");
	    my $model 
	      = $self-> get_perl_data_model(class_name   => $class_name) ;
	    push @data, $model ;
	    # remove class name from above list
	    delete $loaded_classes{$class_name} ;
	}

	my $wr_file = "$dir/$file" ;
	my $wr_dir  = dirname($wr_file) ;
	unless (-d $wr_dir ) {
	    mkpath($wr_dir,0, 0755) || die "Can't mkpath $wr_dir:$!";
	}

	open (WR, ">$wr_file") || croak "Cannot open file $wr_file:$!" ;
	my $dumper = Data::Dumper->new([\@data]) ;
	$dumper->Terse(1) ;
	print WR $dumper->Dump , ";\n";
	close WR ;
    }

}


=head2 list_class_element

Returns a string listing all the class and elements. Useful for
debugging your configuration model.

=cut

sub list_class_element {
    my $self = shift ;
    my $pad  =  shift || '' ;

    my $res = '';
    my $meta_class = $self->{model_object}->fetch_element('class') ;
    foreach my $class_name ($meta_class->get_all_indexes ) {
	$res .= $self->list_one_class_element($class_name) ;
    }
    return $res ;
}

sub list_one_class_element {
    my $self = shift ;
    my $class_name = shift || return '' ;
    my $pad  =  shift || '' ;

    my $res = $pad."Class: $class_name\n";
    my $meta_class = $self->{model_object}->fetch_element('class')
       -> fetch_with_id($class_name) ;

    my @elts = $meta_class->fetch_element('element')->get_all_indexes ;

    my @include = $meta_class->fetch_element('include')->fetch_all_values ;
    my $inc_after = $meta_class->grab_value('include_after') ;

    if (@include and not defined $inc_after) {
	map { $res .= $self->list_one_class_element($_,$pad.'  ') ;} @include ;
    }

    return $res unless @elts ;

    foreach my $elt_name ( @elts) {
	my $type = $meta_class->grab_value("element:$elt_name type") ;

	$res .= $pad."  - $elt_name ($type)\n";
	if (@include and defined $inc_after and $inc_after eq $elt_name) {
	    map { $res .=$self->list_one_class_element($_,$pad.'  ') ;} @include ;
	}
    }
    return $res ;
}

=head2 get_dot_diagram

Returns a graphviz dot file that represents the strcuture of the
configuration model:

=over

=item *

C<include> are represented by solid lines

=item *

Class usage (i.e. C<config_class_name> parameter) is represented by
dashed lines. The name of the element is attached to the dashed line.

=back

=cut

sub get_dot_diagram {
    my $self = shift ;
    my $dot = "digraph model {\n" ;

    my $meta_class = $self->{model_object}->fetch_element('class') ;
    foreach my $class_name ($meta_class->get_all_indexes ) {
	my $c_model = $self->{model_object}->config_model->get_raw_model($class_name);
	my $elts = $c_model->{element} || []; # array ref

	my $d_class = $class_name ;
	$d_class =~ s/::/__/g;

	my $elt_list = '';
	my $use = '';
	for (my $idx = 0; $idx < @$elts; $idx += 2) {
	    my $elt_info = $elts->[$idx] ;
	    my @elt_names = ref $elt_info ? @$elt_info : ($elt_info) ;
	    my $type = $elts->[$idx+1]{type} ;

	    foreach my $elt_name (@elt_names) {
		$elt_list .= "- $elt_name ($type)\\n";
		$use .= $self->scan_used_class($d_class,$elt_name,
					       $elts->[$idx+1]);
	    }
	}

	$dot .= $d_class 
             .  qq! [shape=box label="$class_name\\n$elt_list"];\n!
	     .  $use . "\n";

	my $include = $c_model->{include} ;
	if (defined $include) {
	    my $inc_ref = ref $include ? $include : [ $include ] ;
	    foreach my $t (@$inc_ref) {
		$t =~ s/::/__/g;
		$dot.= qq!$d_class -> $t ;\n!;
	    }
	}
    }

    $dot .="}\n";

    return $dot ;
}

sub scan_used_class {
    my ($self,$d_class,$elt_name,$ref) = @_ ;
    my $res = '' ;

    if (ref($ref) eq 'HASH') {
	foreach my $k (keys %$ref) {
	    my $v = $ref->{$k} ;
	    if ($k eq 'config_class_name') {
		$v =~ s/::/__/g;
		$res .= qq!$d_class -> $v !
		      . qq![ style=dashed, label="$elt_name" ];\n!;
	    }
	    if (ref $v) {
		$res .= $self->scan_used_class($d_class,$elt_name,$v);
	    }
	}
    }
    elsif (ref($ref) eq 'ARRAY') {
	map {$res .= $self->scan_used_class($d_class,$elt_name,$_);} @$ref ;
    }
    return $res ;
}

1;

__END__

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 COPYRIGHT

Copyright (C) 2007-2010 by Dominique Dumont

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the LGPL terms.

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Node>,

=cut

