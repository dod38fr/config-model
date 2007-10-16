# $Author: ddumont $
# $Date: 2007-10-16 11:15:38 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

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

$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

my $logger = Log::Log4perl::get_logger(__PACKAGE__);

# find all .pl file in conf_dir and load them...

sub new {
    my $type = shift ;
    my %args = @_ ;

    my $model_obj = $args{model_object}
      || croak __PACKAGE__," read_all: undefined model object";

    bless { model_object => $model_obj }, $type ;
}

sub read_all {
    my $self = shift ;
    my %args = @_ ;
    my $model_obj = $self->{model_object};
    my $dir = $args{conf_dir} 
      || croak __PACKAGE__," read_all: undefined config dir";

    unless (-d $dir ) {
	croak __PACKAGE__," read_all: unknown config dir $dir";
    }

    my @files ;
    my $wanted = sub { push @files, $File::Find::name 
			 if (-f $_ and not /~$/) ;
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

sub write_all {
    my $self = shift ;
    my %args = @_ ;
    my $model_obj = $self->{model_object} ;
    my $dir = $args{conf_dir} 
      || croak __PACKAGE__," write_all: undefined config dir";

    my $map = $self->{map} ;

    unless (-d $dir ) {
	mkpath($dir, 0755) || die "Can't mkpath $dir:$!";
    }

    my $i = $model_obj->instance ;

    foreach my $file (keys %$map) {
	$logger->info("writing config file $file");

	my @data ;

	foreach my $class_name (@{$map->{$file}}) {
	    $logger->info("writing class $class_name");
	    my $model 
	      = $self-> get_perl_data_model(class_name   => $class_name) ;
	    push @data, $model ;
	}

	my $wr_file = "$dir/$file" ;
	my $wr_dir  = dirname($wr_file) ;
	unless (-d $wr_dir ) {
	    mkpath($wr_dir, 0755) || die "Can't mkpath $wr_dir:$!";
	}

	open (WR, ">$wr_file") || croak "Cannot open file $wr_file:$!" ;
	my $dumper = Data::Dumper->new([\@data]) ;
	$dumper->Terse(1) ;
	print WR $dumper->Dump , ";\n";
	close WR ;
    }

}
1;
