# $Author: ddumont $
# $Date: 2008-03-10 13:39:10 $
# $Revision: 1.5 $

#    Copyright (c) 2007 Dominique Dumont.
#
#    This file is part of Config-Model-Itself.
#
#    Config-Xorg is free software; you can redistribute it and/or
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

use vars qw($VERSION) ;

$VERSION = sprintf "1.%04d", q$Revision: 541 $ =~ /(\d+)/;

my $logger = Log::Log4perl::get_logger(__PACKAGE__);

=head1 NAME

Config::Model::Itself - Model of Config::Model

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
       permission => 'advanced',
       store => $wr_back,
      ) ;

 # start Curses dialog to edit the mode
 $dialog->start( $meta_model )  ;

 # that's it. When user quits curses interface, Curses will call
 # $wr_back sub ref to write the modified model.

=head1 DESCRIPTION

The Config::Itself and its model files provide a model of Config:Model
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

# find all .pl file in conf_dir and load them...

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

=head1 read_all ( conf_dir => ...)

Load all the model files contained in C<conf_dir> and all its
subdirectories.

C<read_all> returns a hash ref containing ( class_name => file_name , ...)

=cut

sub read_all {
    my $self = shift ;
    my %args = @_ ;
    my $model_obj = $self->{model_object};
    my $dir = $args{conf_dir} 
      || croak __PACKAGE__," read_all: undefined config dir";
    my $model = $args{root_model} 
      || croak __PACKAGE__," read_all: undefined root_model";

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
	my $tmp_model = Config::Model -> new( skip_include => 1 ) ;
	my @models = $tmp_model -> load ( 'Tmp' , $file ) ;

	my $rel_file = $file ;
	$rel_file =~ s/^$dir\///;
	die "wrong reg_exp" if $file eq $rel_file ;
	$class_file_map{$rel_file} = \@models ;

	# - move permission, description and level status into parameter info.
	foreach my $model_name (@models) {
	    # no need to dclone model as Config::Model object is temporary
	    my $new_model =  $tmp_model -> get_model( $model_name ) ;

	    foreach my $item (qw/description level permission status/) {
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
    #require Tk::ObjScanner; Tk::ObjScanner::scan_object(\@read_models) ;
    #$model_obj->instance->push_no_value_check(qw/store fetch type/) ;

    $logger->info("loading all extracted data in Config::Model::Itself");
    $model_obj->load_data( {class => \%read_models} ) ;

    #$model_obj->instance->pop_no_value_check() ;

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

    # - move permission, description and level status back in class info.
    my $all_elt_data = $model->{element} || [] ;
    for (my $i = 0 ; $i < @$all_elt_data; $i ++) {
	my $elt_name = $all_elt_data->[$i++] ;
	my $elt_data = $all_elt_data->[$i] ;
	foreach my $item (qw/description level permission status/) {
	    my $moved_data = delete $elt_data->{$item}  ;
	    next unless defined $moved_data ;
	    push @{$model->{$item}}, $elt_name, $moved_data ; 
	}
    } 

    # don't forget to add name
    $model->{name} = $class_name ;

    return $model ;
}

=head2 write_all ( conf_dir => ... )

Will write back configuration model in the specified directory. The
structure of the read directory is respected.

=cut

sub write_all {
    my $self = shift ;
    my %args = @_ ;
    my $model_obj = $self->{model_object} ;
    my $dir = $args{conf_dir} 
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
1;

__END__

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Node>,

=cut

