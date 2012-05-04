package Config::Model::Itself ;

use Any::Moose ;
use namespace::autoclean;

use IO::File ;
use Log::Log4perl;
use Carp ;
use Data::Dumper ;
use File::Find ;
use File::Path ;
use File::Basename ;
use Data::Compare ;

my $logger = Log::Log4perl::get_logger("Backend::Itself");


# find all .pl file in model_dir and load them...

has model_object => (is =>'ro', isa =>'Config::Model::Node', required => 1) ;
has model_dir    => (is =>'ro', isa =>'Str', required => 1 ) ;
has force_write  => (is =>'ro', isa => 'Bool', default => 0) ;

has modifed_classes => (
    is =>'rw', 
    isa =>'HashRef[Bool]', 
    traits => ['Hash'],
    default => sub { {} } ,
    handles => {
        clear_classes => 'clear',
        set_class => 'set',
        class_was_changed => 'get' ,
        classes_to_write => 'keys' ,
    }
) ;

sub BUILD {
    my $self = shift;

    my $cb = sub {
        my %args = @_ ;
        my $p = $args{path} || '' ;
        return unless $p =~ /^class/ ;
        return if $self->class_was_changed($args{index}) ;
        $logger->info("class $args{index} was modified");
        
        $self->add_modified_class($args{index}) ;
    } ;
    $self->model_object->instance -> on_change_cb($cb) ;
    
}


sub add_modified_class {
    my $self = shift;
    $self->set_class(shift,1) ;
}


sub read_all {
    my $self = shift ;
    my %args = @_ ;

    my $model = delete $args{root_model} 
      || croak __PACKAGE__," read_all: undefined root_model";
    my $force_load = delete $args{force_load} || 0 ;
    my $legacy = delete $args{legacy} ;

    croak "read_all: unexpected parameters ",join(' ', keys %args) if %args ;

    my $dir = $self->model_dir ;
    unless (-d $dir ) {
        croak __PACKAGE__," read_all: unknown model dir $dir";
    }

    my $root_model_file = $model ;
    $root_model_file =~ s!::!/!g ;
    
    my @files ;
    my $wanted = sub { 
        my $n = $File::Find::name ;
        push @files, $n if (-f $_ and not /~$/ 
                            and $n !~ /CVS/
                            and $n !~ m!.(svn|orig|pod)$!
                            and $n =~ m!$dir/$root_model_file!
                           ) ;
    } ;
    find ($wanted, $dir ) ;

    my $i = $self->model_object->instance ;
    
    my %read_models ;
    my %pod_data ;
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
            my $raw_model =  $tmp_model -> get_raw_model( $model_name ) ;
            my $new_model =  $tmp_model -> get_model( $model_name ) ;

            # some modifications may be done to cope with older model styles. If a modif
            # was done, mark the class as changed so it will be saved later
            $self->add_modified_class($model_name) unless Compare($raw_model, $new_model) ;

            foreach my $item (qw/description summary level experience status/) {
                foreach my $elt_name (keys %{$new_model->{element}}) {
                    my $moved_data = delete $new_model->{$item}{$elt_name}  ;
                    next unless defined $moved_data ;
                    $new_model->{element}{$elt_name}{$item} = $moved_data ; 
                }
                delete $new_model->{$item} ;
            }

            # Since accept specs and elements are stored in a ordered hash,
            # load_data expects a array ref instead of a hash ref.
            # Build this array ref taking the order into
            # account
            foreach my $what (qw/element accept/) {
                my $list  = delete $new_model -> {$what.'_list'} ;
                my $h     = delete $new_model -> {$what} ;
                $new_model -> {$what} = [] ;
                map { 
                    push @{$new_model->{$what}}, $_, $h->{$_} 
                } @$list ;
            }

            # remove hash key with undefined values
            map { delete $new_model->{$_} unless defined $new_model->{$_} 
                                          and $new_model->{$_} ne ''
              } keys %$new_model ;
            $read_models{$model_name} = $new_model ;
        }

    }

    # Create all classes listed in %read_models to avoid problems with
    # include statement while calling load_data
    my $model_obj = $self->model_object ;
    my $class_element = $model_obj->fetch_element('class') ;
    map { $class_element->fetch_with_id($_) } sort keys %read_models ;

    #require Tk::ObjScanner; Tk::ObjScanner::scan_object(\%read_models) ;

    $logger->info("loading all extracted data in Config::Model::Itself");
    # load with a array ref to avoid warnings about missing order
    $model_obj->load_data( {class => [ %read_models ] }, undef, $force_load ? 'no' : 'yes' ) ;

    # load annotations
    for my $file (@files) {
        $logger->info("loading annotations from file $file");
        my $fh = IO::File->new($file) || die "Can't open $file: $!" ;
        my @lines = $fh->getlines ;  
        $fh->close;
        $model_obj->load_pod_annotation(join('',@lines)) ;
    }

    return $self->{map} = \%class_file_map ;
}

# internal
sub get_perl_data_model{
    my $self = shift ;
    my %args = @_ ;
    my $model_obj = $self->{model_object};
    my $class_name = $args{class_name}
      || croak __PACKAGE__," read: undefined class name";

    my $class_element = $model_obj->fetch_element('class') ; 

    # skip if class was deleted during edition
    return unless $class_element->defined($class_name) ;
    
    my $class_elt = $class_element -> fetch_with_id($class_name) ;

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
    $model->{name} = $class_name if keys %$model;

    return $model ;
}


sub write_all {
    my $self = shift ;
    my %args = @_ ;
    my $model_obj = $self->model_object ;
    my $dir = $self->model_dir ;

    croak "write_all: unexpected parameters ",join(' ', keys %args) if %args ;

    my $map = $self->{map} ;

    unless (-d $dir ) {
        mkpath($dir,0, 0755) || die "Can't mkpath $dir:$!";
    }

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
        $logger->info("checking model file $file");

        my @data ;
        my @notes ;
        my $file_needs_write = 0;
        
        # check if any a class of a file was modified
        foreach my $class_name (@{$map_to_write{$file}}) {
            $file_needs_write++ if $self->force_write or $self->class_was_changed($class_name) ;
            $logger->info("file $file class $class_name needs write ",$file_needs_write);
        }
        
        next unless $file_needs_write ;    

        foreach my $class_name (@{$map_to_write{$file}}) {
            $logger->info("writing class $class_name");
            my $model 
              = $self-> get_perl_data_model(class_name => $class_name) ;
            push @data, $model if defined $model and keys %$model;
            
            my $node = $self->{model_object}->grab("class:".$class_name) ;
            push @notes, $node->dump_annotations_as_pod ;
            # remove class name from above list
            delete $loaded_classes{$class_name} ;
        }

        next unless @data ; # don't write empty model

        write_model_file ("$dir/$file", \@notes, \@data);
    }
    
    $self->model_object->instance->needs_save(0) ;
}

sub write_model_snippet {
    my $self = shift ;
    my %args = @_ ;
    my $snippet_dir = delete $args{snippet_dir} 
      || croak __PACKAGE__," write_model_snippet: undefined snippet_dir";
    my $model_file = delete $args{model_file} 
      || croak __PACKAGE__," write_model_snippet: undefined model_file";
    croak "write_model_snippet: unexpected parameters ",join(' ', keys %args) if %args ;

    my $model = $self->model_object->dump_as_data ;
    # print (Dumper( $model)) ;

    my @raw_data = @{$model->{class}} ;
    while (@raw_data) {
        my ( $class , $data ) = splice @raw_data,0,2 ;
        $data ->{name} = $class ;
 
        # does not distinguish between notes from underlying model or snipper notes ...
        my @notes = $self->model_object->grab("class:$class")->dump_annotations_as_pod ;
        my $class_dir = $class.'.d';
        $class_dir =~ s!::!/!g;
        write_model_file ("$snippet_dir/$class_dir/$model_file", \@notes, [ $data ]);
    }

    $self->model_object->instance->needs_save(0) ;
}

sub read_model_snippet {
    my $self = shift ;
    my %args = @_ ;
    my $snippet_dir = delete $args{snippet_dir} 
      || croak __PACKAGE__," write_model_snippet: undefined snippet_dir";
    my $model_file = delete $args{model_file} 
      || croak __PACKAGE__," read_model_snippet: undefined model_file";

    croak "read_model_snippet: unexpected parameters ",join(' ', keys %args) if %args ;

    my @files ;
    my $wanted = sub { 
        my $n = $File::Find::name ;
        push @files, $n if (-f $_ and not /~$/ 
                            and $n !~ /CVS/
                            and $n !~ m!.(svn|orig|pod)$!
                            and $n =~ m!\.d/$model_file!
                           ) ;
    } ;
    find ($wanted, $snippet_dir ) ;

    my $class_element = $self->model_object->fetch_element('class') ;

    foreach my $load_file (@files) {
        $logger->info("trying to read snippet $load_file");
    
        my $snippet = do $load_file ;

        unless ($snippet) {
            if ($@) {die "couldn't parse $load_file: $@"; }
            elsif (not defined $snippet) {die  "couldn't do $load_file: $!"}
            else { die  "couldn't run $load_file" ;}
        }

        # there should be only only class in each snippet file
        foreach my $model (@$snippet) {
            my $class_name = delete $model->{name} ;
            # load with a array ref to avoid warnings about missing order
            $class_element->fetch_with_id($class_name)->load_data( $model ) ;
        }

        # load annotations
        $logger->info("loading annotations from snippet file $load_file");
        my $fh = IO::File->new($load_file) || die "Can't open $load_file: $!" ;
        my @lines = $fh->getlines ;  
        $fh->close;
        $self->model_object->load_pod_annotation(join('',@lines)) ;
    }
}


#
# New subroutine "write_model_file" extracted - Mon Mar 12 13:38:29 2012.
#
sub write_model_file {
    my $wr_file = shift;
    my $notes   = shift;
    my $data    = shift;

    my $wr_dir = dirname($wr_file);
    unless ( -d $wr_dir ) {
        mkpath( $wr_dir, 0, 0755 ) || die "Can't mkpath $wr_dir:$!";
    }

    my $wr = IO::File->new( $wr_file, '>' )
      || croak "Cannot open file $wr_file:$!" ;
    $logger->info("in $wr_file");

    my $dumper = Data::Dumper->new( [ \@$data ] );
    $dumper->Indent(1);    # avoid too deep indentation
    $dumper->Terse(1);     # allow unnamed variables in dump

    my $dump = $dumper->Dump;

    # munge pod text embedded in values to avoid spurious pod formatting
    $dump =~ s/\n=/\n'.'=/g;

    $wr->print( $dump, ";\n\n" );

    $wr->print( join( "\n", @$notes ) );

    $wr->close;

}



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
                my $of = '';
                my $cargo = $elts->[$idx+1]{cargo}{type} ;
                $of = " of $cargo" if defined $cargo ;
                $elt_list .= "- $elt_name ($type$of)\\n";
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

__PACKAGE__->meta->make_immutable;

1;

__END__



=pod

=head1 NAME

Config::Model::Itself - Model editor for Config::Model

=head1 SYNOPSIS

 my $meta_model = Config::Model -> new ( ) ;

 # load Config::Model model
 my $meta_inst = $model->instance (
    root_class_name => 'Itself::Model' ,
    instance_name   => 'meta_model' ,
 );

 my $meta_root = $meta_inst -> config_root ;

 # Itself constructor returns an object to read or write the data
 # structure containing the model to be edited
 my $rw_obj = Config::Model::Itself -> new(
    model_object => $meta_root,
    model_dir => '/path/to/model_files' ,
 ) ;

 # now load the model to be edited
 $rw_obj -> read_all( ) ;

 # For Curses UI prepare a call-back to write model
 my $wr_back = sub { $rw_obj->write_all();

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

=head2 new ( model_object => ... , model_dir => ... )

Creates a new read/write handler. This handler is dedicated to the
C<model_object> passed with the constructor. This parameter must be a
L<Config::Model::Node> class.

=head2 Methods

=head1 read_all (  root_model => ... , [ force_load => 1 ] )

Load all the model files contained in C<model_dir> and all its
subdirectories. C<root_model> is used to filter the classes read. 

Use C<force_load> if you are trying to load a model containing errors.

C<read_all> returns a hash ref containing ( class_name => file_name , ...)

=head2 write_all

Will write back configuration model in the specified directory. The
structure of the read directory is respected.

=head2 write_model_snippet( snippet_dir => foo, model_file => bar.pl )

Write snippet models in separate C<.d> directory. E.g. a snippet for class
C<Foo::Bar> will be written in C<Foo/Bar.d/bar.pl> file. This file is to be used
by L<augment_config_class|Config::Model/"augment_config_class (name => '...', class_data )">

=head2 read_model_snippet( snippet_dir => foo, model_file => bar.pl )

To read model snippets, this methid will search recursively C<$snippet_dir> and load
all C<bar.pl> files found in there.

=head2 list_class_element

Returns a string listing all the class and elements. Useful for
debugging your configuration model.

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

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 COPYRIGHT

Copyright (C) 2007-2012 by Dominique Dumont

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the LGPL terms.

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Node>,

=cut
