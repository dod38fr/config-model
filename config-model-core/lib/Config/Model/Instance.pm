package Config::Model::Instance;
use Scalar::Util qw(weaken) ;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

use Config::Model::Annotation;
use Config::Model::Exception ;
use Config::Model::Node ;
use Config::Model::Loader;
use Config::Model::SearchElement;
use Config::Model::Iterator;
use Config::Model::ObjTreeScanner;

use strict ;
use Carp;
use warnings FATAL => qw(all);
use warnings::register ;


use Carp qw/croak confess cluck/;

my $logger = get_logger("Instance") ;


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

    my $read_check = delete $args{check} || 'yes' ;
    carp "instance new: force_load is deprecated" if defined $args{force_load} ;
    $read_check = 'no' if delete $args{force_load} ;

    my $self  = {
	 # a unique (instance wise) placeholder for various tree objects
	 # to store information
	 safe => {
		 } ,

        read_check => $read_check ,

	 # preset mode to load values found by HW scan or other
	 # automatic scheme
	 preset => 0,

	 # layered mode to load values found in included files (e.g. a la multistrap)
	 layered => 0,

         # initial_load mode: when data is loaded the first time
         initial_load => 1,
         needs_save => 0,

	 config_model => $config_model ,
	 root_class_name => $root_class_name ,

	 # This array holds a set of sub ref that will be invoked when
	 # the users requires to write all configuration tree in their
	 # backend storage.
	 write_back => [] ,

	 # used for auto_read auto_write feature
	 name            =>  delete $args{name} ,
	 root_dir        =>  delete $args{root_dir},
	 config_file     =>  delete $args{config_file} , 

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

    $self->reset_config() ;

    return $self ;
}



sub name {
    return shift->{name} ;
}


sub config_root {
    return shift->{tree} ;
}


sub read_check {
    return shift->{read_check} ;
}


sub reset_config {
    my ( $self, %args ) = @_;

    $self->{tree} = Config::Model::Node->new(
        config_class_name => $self->{root_class_name},
        instance          => $self,
        container         => $self,
        skip_read         => $self->{skip_read},
        config_file       => $self->{config_file} ,
    );

    # $self->{annotation_saver} = Config::Model::Annotation
    #   -> new (
    # 	      config_class_name => $self->{root_class_name},
    # 	      instance => $self ,
    # 	      root_dir => $self->{root_dir} ,
    # 	     ) ;
    # $self->{annotation_saver}->load ;

    return $self->{tree};
}



sub config_model {
    return shift->{config_model} ;
}


# sub annotation_saver {
#     my $self = shift ;
#     return $self->{annotation_saver} ;
#}


sub preset_start {
    my $self = shift ;
    $logger->info("Starting preset mode");
    carp "Cannot start preset mode during layered mode" 
        if $self->{layered} ;
    $self->{preset} = 1;
}


sub preset_stop {
    my $self = shift ;
    $logger->info("Stopping preset mode");
    $self->{preset} = 0;
}


sub preset {
    my $self = shift ;
    return $self->{preset} ;
}


sub preset_clear {
    my $self = shift ;

    my $leaf_cb = sub {
        my ($scanner, $data_ref,$node,$element_name,$index, $leaf_object) = @_ ;
        $leaf_object->clear_preset ;
    } ;
    
    $self->_stuff_clear($leaf_cb) ;
}


sub layered_start {
    my $self = shift ;
    $logger->info("Starting layered mode");
    carp "Cannot start layered mode during preset mode" 
        if $self->{preset} ;
    $self->{layered} = 1;
}


sub layered_stop {
    my $self = shift ;
    $logger->info("Stopping layered mode");
    $self->{layered} = 0;
}


sub layered {
    my $self = shift ;
    return $self->{layered} ;
}


sub layered_clear {
    my $self = shift ;
    
    my $leaf_cb = sub {
        my ($scanner, $data_ref,$node,$element_name,$index, $leaf_object) = @_ ;
        $$data_ref ||= $leaf_object->clear_layered ;
    };

    $self->_stuff_clear($leaf_cb);
}


sub get_data_mode {
    my $self = shift;
    return
        $self->{layered} ? 'layered'
      : $self->{preset}  ? 'preset'
      :                    'normal';
}


sub _stuff_clear {
    my ($self,$leaf_cb) = @_ ;
    
    # this sub may remove hash keys that were entered by user if the 
    # corresponding hash value has no data. 
    # it also clear auto_created ids if there's no data in there
    my $h_cb = sub {
        my  ($scanner, $data_ref,$node,$element_name,@keys) = @_ ;
        my $obj = $node->fetch_element($element_name) ;
        
        foreach my $k (@keys) {
            my $has_data = 0;
            $scanner->scan_hash(\$has_data,$node,$element_name,$k);
            $obj->remove($k) unless $has_data ;
            $$data_ref ||= $has_data ;
        }
    };
    
    my $wiper = Config::Model::ObjTreeScanner->new (
        fallback => 'all',
        auto_vivify => 0,
        check => 'skip' ,
        leaf_cb => $leaf_cb ,
        hash_element_cb => $h_cb,
        list_element_cb => $h_cb,
    );

    $wiper->scan_node(undef,$self->config_root) ;

}



sub initial_load_stop {
    my $self = shift ;
    $logger->info("Stopping initial_load mode");
    $self->{initial_load} = 0;
}


sub initial_load {
    my $self = shift ;
    my $v = shift ;
    $self->{initial_load} = $v if defined $v ;
    return $self->{initial_load} ;
}



sub data {
    my $self = shift;
    my $kind = shift || croak "undefined data kind";
    my $store = shift ;

    $self->{safe}{$kind} = $store if defined $store;
    return $self->{safe}{$kind} ;
}



sub load {
    my $self = shift ;
    my $loader = Config::Model::Loader->new ;
    my %args = @_ eq 1 ? (step => $_[0]) : @_ ;
    $loader->load(node => $self->{tree}, %args) ;
}


sub search_element {
    my $self = shift ;
    $self->{tree}->search_element(@_) ;
}


sub wizard_helper {
    carp __PACKAGE__,"::wizard_helper helped is deprecated. Call iterator instead" ;
    goto &iterator ;
}


sub iterator {
    my $self = shift ;
    my @args = @_ ;

    my $tree_root = $self->config_root ;

    return Config::Model::Iterator->new ( root => $tree_root, @args) ;
}


sub read_directory {
    carp "read_directory is deprecated";
    return shift -> {root_dir} ;
}

sub read_root_dir {
    return shift -> {root_dir} ;
}


sub backend {
    return shift -> {backend} ;
}


sub write_directory {
    my $self = shift ;
    carp "write_directory is deprecated";
    return $self -> {root_dir} ;
}

sub write_root_dir {
    my $self = shift ;
    return $self -> {root_dir} ;
}


sub register_write_back {
    my ($self,$node_path) = @_ ;
    $logger->debug("register_write_back: instance '$self->{name}' registers node '$node_path'") ;

    push @{$self->{write_back}}, $node_path ;
}


sub has_changed {
    my $self = shift ;
    $self->{needs_save} = 1;
}


sub write_back {
    my $self = shift ;
    my %args = scalar @_ > 1  ? @_ 
             : scalar @_ == 1 ? (config_dir => $_[0]) 
	     :                  () ; 

    my $force_backend = delete $args{backend} || $self->{backend} ;

    foreach (keys %args) {
        if (/^(root|config_dir)$/) {
            $args{$_} ||= '' ;
            $args{$_} .= '/' if $args{$_} and $args{$_} !~ m(/$) ;
        }
        elsif (not /^config_file$/) {
            croak "write_back: wrong parameters $_" ;
        }
     }

    croak "write_back: no subs registered in instance $self->{name}. cannot save data\n" 
      unless @{$self->{write_back}} ;

    foreach my $path (@{$self->{write_back}}) {
	$logger->info("write_back called on node $path");
        my $node = $self->config_root->grab(step => $path, type => 'node');
        $node->write_back(
            %args, 
            config_file => $self->{config_file} ,
            backend => $force_backend
        );
    }
}


sub apply_fixes {
    my $self = shift ;

    # define leaf call back
    my $fix_leaf = sub { 
      my ($scanner, $data_ref, $node,$element_name,$index, $leaf_object) = @_ ;
      $leaf_object->apply_fixes ;
    } ;

    my $fix_hash = sub {
        my ( $scanner, $data_r, $node, $element, @keys ) = @_;

        return unless @keys;

        # leaves must be fixed before the hash, hence the 
        # calls to scan_hash before apply_fixes
        map {$scanner->scan_hash($data_r,$node,$element,$_)} @keys ;

        $node->fetch_element($element)->apply_fixes ;
    } ;
    
    my $fix_list = sub {
        my ( $scanner, $data_r, $node, $element, @keys ) = @_;

        return unless @keys;

        map {$scanner->scan_list($data_r,$node,$element,$_)} @keys ;
        $node->fetch_element($element)->apply_fixes ;
    } ;
    
   my $scan = Config::Model::ObjTreeScanner-> new ( 
        hash_element_cb => $fix_hash ,
        list_element_cb => $fix_list ,
        leaf_cb => $fix_leaf ,
        check => 'no',
    ) ;

    $scan->scan_node(undef, $self->config_root) ;
}

sub push_no_value_check { carp "push_no_value_check is deprecated";}
sub pop_no_value_check  { carp "pop_no_value_check is deprecated";}
sub get_value_check { carp "get_value_check is deprecated";}

1;



__END__

=pod

=head1 NAME

Config::Model::Instance - Instance of configuration tree

=head1 SYNOPSIS

 use Config::Model;
 use Log::Log4perl qw(:easy);
 use File::Path ;
 Log::Log4perl->easy_init($WARN);

 # setup a dummy popcon conf file
 my $wr_dir = '/tmp/etc/';
 my $conf_file = "$wr_dir/popularity-contest.conf" ;

 unless (-d $wr_dir) {
     mkpath($wr_dir, { mode => 0755 }) 
       || die "can't mkpath $wr_dir: $!";
 }
 open(my $conf,"> $conf_file" ) || die "can't open $conf_file: $!";
 $conf->print( qq!MY_HOSTID="aaaaaaaaaaaaaaaaaaaa"\n!,
   qq!PARTICIPATE="yes"\n!,
   qq!USEHTTP="yes" # always http\n!,
   qq!DAY="6"\n!);
 $conf->close ;

 my $model = Config::Model->new;

 # PopCon model is provided. Create a new Config::Model::Instance object
 my $inst = $model->instance (root_class_name   => 'PopCon',
                              root_dir          => '/tmp',
                             );
 my $root = $inst -> config_root ;

 print $root->describe;



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

=item check

'yes', 'skip' or 'no'

=back

Note that the root directory specified within the configuration model
will be overridden by C<root_dir> parameter.

If you need to load configuration data that are not correct, you can
use C<< force_load => 1 >>. Then, wrong data will be discarded (equivalent to 
C<check => 'no'> ).

=head1 METHODS

=head2 name()

Returns the instance name.

=head2 config_root()

Returns the root object of the configuration tree.

=head2 read_check()

Returns how to check read files.

=head2 reset_config

Destroy current configuration tree (with data) and returns a new tree with
data (and annotations) loaded from disk.

=head2 config_model()

Returns the model (L<Config::Model> object) of the configuration tree.

=head2 annotation_saver()

Returns the object loading and saving annotations. See
L<Config::Model::Annotation> for details.

=head2 preset_start ()

All values stored in preset mode are shown to the user as default
values. This feature is useful to enter configuration data entered by
an automatic process (like hardware scan)

=head2 preset_stop ()

Stop preset mode

=head2 preset ()

Get preset mode

=head2 preset_clear()

Clear all preset values stored.

=head2 layered_start ()

All values stored in layered mode are shown to the user as default
values. This feature is useful to enter configuration data entered by
an automatic process (like hardware scan)

=head2 layered_stop ()

Stop layered mode

=head2 layered ()

Get layered mode

=head2 layered_clear()

Clear all layered values stored.

=head2 get_data_mode 

Returns 'normal' or 'preset' or 'layered'. Does not take into account initial_load.

=head2 initial_load_stop ()

Stop initial_load mode. Instance is built with initial_load as 1. Read backend
will clear this value once the first read is done.

=head2 initial_load ()

Get initial_load mode

=head2 data( kind, [data] )

The data method provide a way to store some arbitrary data in the
instance object.

=head2 load( "..." )

Load configuration tree with configuration data. See
L<Config::Model::Loader> for more details

=head2 searcher ( )

Returns an object dedicated to search an element in the configuration
model (respecting privilege level).

This method returns a L<Config::Model::Searcher> object. See
L<Config::Model::Searcher> for details on how to handle a search.

=head2 wizard_helper ( ... )

Deprecated. Call L</iterator> instead.

=head2 iterator 

This method returns a L<Config::Model::Iterator> object. See
L<Config::Model::Iterator> for details.

Arguments are explained in  L<Config::Model::Iterator>
L<constructor arguments|Config::Model::Iterator/"Creating an iterator">.

=head2 

=head1 Auto read and write feature

Usually, a program based on config model must first create the
configuration model, then load all configuration data. 

This feature enables you to declare with the model a way to load
configuration data (and to write it back). See
L<Config::Model::AutoRead> for details.

=head2 read_root_dir()

Returns root directory where configuration data is read from.

=head2 backend()

Get the preferred backend method for this instance (as passed to the
constructor).

=head2 write_root_dir()

Returns root directory where configuration data is written to.

=head2 register_write_back ( node_location )

Register a node path that will be called back with
C<write_back> method.

=head2 has_changed

Notify that some data has changed in the tree. 

=head2 write_back ( ... )

Try to run all subroutines registered with C<register_write_back> to
write the configuration information until one succeeds (returns
true). (See L<Config::Model::AutoRead> for details).

You can specify here a pseudo root directory or another config
directory to write configuration data back with C<root> and
C<config_dir> parameters. This will override the model specifications.

You can force to use a backend by specifying C<< backend => xxx >>. 
For instance, C<< backend => 'augeas' >> or C<< backend => 'custom' >>.

You can force to use all backend to write the files by specifying 
C<< backend => 'all' >>.

C<write_back> will croak if no write call-back are known.

=head2 apply_fixes

Scan the tree and apply fixes that are attached to warning specifications. 
See C<warn_if_match> or C<warn_unless_match> in L<Config::Model::Value/>.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::Node>, 
L<Config::Model::Loader>,
L<Config::Model::Searcher>,
L<Config::Model::Value>,

=cut
