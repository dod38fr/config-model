package Config::Model::Node;

use Any::Moose ;

use Carp ;

use Config::Model::Exception;
use Config::Model::Loader;
use Config::Model::Dumper;
use Config::Model::DumpAsData;
use Config::Model::Report;
use Config::Model::TreeSearcher;
use Config::Model::Describe;
use Config::Model::BackendMgr;
use Log::Log4perl qw(get_logger :levels);
use Storable qw/dclone/ ;

extends qw/Config::Model::AnyThing/;

use vars qw(@status @level
            @experience_list %experience_index %default_property);

*status           = *Config::Model::status ;
*level            = *Config::Model::level ;
*experience_list  = *Config::Model::experience_list ;
*experience_index = *Config::Model::experience_index ;
*default_property = *Config::Model::default_property ;

my %legal_properties = (
                        status => {qw/obsolete 1 deprecated 1 standard 1/ },
                        level  => {qw/important 1 normal 1 hidden 1/},
                        experience => {qw/master 1 advanced 1 beginner 1/},
                       ) ;

my $logger = get_logger("Tree::Node") ;


# Here are the legal element types
my %create_sub_for = 
  (
   node => \&create_node,
   leaf => \&create_leaf,
   hash => \&create_id,
   list => \&create_id,
   check_list => \&create_id ,
   warped_node => \&create_warped_node,
  ) ;


# Node internal documentation
#
# Since the class holds a significant number of element, here's its
# main structure.
#
# $self 
# = (
#    config_model      : Weak reference to Config::Model object
#    config_class_name
#    model             : model of the config class
#    instance          : Weak reference to Config::Model::Instance object 
#    element_name      : Name of the element containing this node
#                        (undef for root node).
#    parent            : weak reference of parent node (undef for root node)
#    element           : actual storage of configuration elements

#    element_by_experience: {<experience>} = [ list of elements ]
#                          e.g {
#                                master => [ list of master elements ],
#                                advanced => [ ...],
#                                beginner => [,,,]
#                              }
#  ) ;

has initialized => (is => 'rw', isa => 'Bool', default => 0 ) ;

has [qw/config_class_name/] 
    => (is => 'ro', isa => 'Str', required =>1 ) ;
has [qw/config_file element_name/] 
    => (is => 'ro', isa => 'Maybe[Str]', required => 0 ) ;

has instance => ( is => 'ro', isa => 'Config::Model::Instance', weak_ref => 1 ,required =>1 ) ;
has config_model => ( is => 'ro', isa => 'Config::Model', 
    weak_ref => 1 , lazy => 1, builder => '_config_model') ;

sub _config_model {
    my $self = shift ;
    my $p = $self->instance->config_model ;
}

has skip_read => ( is => 'ro', isa => 'Bool') ;
has check => ( is => 'ro', isa => 'Str', builder => '_check_check', lazy => 1) ;
has auto_read => ( is => 'rw' , isa => 'HashRef' ) ;
has model => ( is => 'rw' , isa => 'HashRef' ) ;

sub BUILD {
    my $self = shift;

    my $read_check = $self->instance->read_check;
    
    my $req_check = $self->check ;
    my $check = $req_check eq 'no'   || $read_check eq 'no'   ? 'no'
              : $req_check eq 'skip' || $read_check eq 'skip' ? 'skip' 
              :                                                 'yes' ;
    
    
    $self->auto_read( { skip => $self->skip_read, check => $check } );
    
    my $caller_class = defined $self->parent 
      ? $self->parent->name : 'user' ;

    my $class_name = $self->config_class_name ;
    $logger->info( "New $class_name requested by $caller_class");

    $self->model( dclone ( $self->config_model->get_model($class_name) ) );
        
    $self->check_properties ;

    return $self ;
}


## Create_* methods are all internal and should not be used directly

sub create_element {
    my $self= shift ;
    my %args = @_ > 1 ? @_ : ( name => shift ) ;
    my $element_name = $args{name} ;
    my $check = $args{check} || 'yes' ;

    my $element_info = $self->{model}{element}{$element_name}  ;

    return if $check eq 'skip' and not defined $element_info;
     
    Config::Model::Exception::UnknownElement->throw(
                                                    object   => $self,
                                                    function => 'create_element',
                                                    where    => $self->location || 'configuration root',
                                                    element     => $element_name,
                                                   )
        unless defined $element_info ;

    Config::Model::Exception::Model->throw
        (
         error=> "element '$element_name' error: "
         . "passed information is not a hash ref",
         object => $self
        ) 
          unless ref($element_info) eq 'HASH' ;

    Config::Model::Exception::Model->throw
        (
         error=> "create element '$element_name' error: "
         . "missing 'type' parameter",
         object => $self
        )
          unless defined $element_info->{type} ;

    my $method = $create_sub_for{$element_info->{type}} ;

    croak $self->{config_class_name},
      " error: no create method for element type $element_info->{type}"
        unless defined $method ;

    $self->$method($element_name, $check) ;
}




sub create_node {
    my ($self, $element_name, $check)  = @_ ;

    my $element_info = dclone($self->{model}{element}{$element_name}) ; 

    Config::Model::Exception::Model->throw
        (
         error=> "create node '$element_name' error: "
         ."missing config class name parameter",
         object => $self
        )
          unless defined $element_info->{config_class_name} ;

    my @args = (config_class_name => $element_info->{config_class_name},
                instance          => $self->{instance},
                element_name      => $element_name ,
                check             => $check ,
    ) ;

    $self->{element}{$element_name} = $self->new(@args) ;
}


sub create_warped_node {
    my ($self, $element_name, $check)  = @_ ;

    my $element_info = dclone($self->{model}{element}{$element_name}) ; 

    my @args = (instance          => $self->{instance},
                element_name      => $element_name,
                parent            => $self,
                check             => $check,
    ) ;

    require Config::Model::WarpedNode ;

    $self->{element}{$element_name} 
      = Config::Model::WarpedNode->new(%$element_info,@args) ;
}


sub create_leaf {
    my ($self, $element_name, $check)  = @_ ;

    my $element_info = dclone($self->{model}{element}{$element_name}) ; 

    delete $element_info->{type} ;
    my $leaf_class = delete $element_info->{class} || 'Config::Model::Value' ;

    if (not defined *{$leaf_class.'::'}) {
        my $file = $leaf_class.'.pm';
        $file =~ s!::!/!g;
        require $file ;
    }

    $element_info->{parent}       = $self ;
    $element_info->{element_name} = $element_name ;
    $element_info->{instance}     = $self->{instance} ;

    $self->{element}{$element_name} = $leaf_class->new( %$element_info) ;
}


my %id_class_hash = (
                     hash       => 'HashId',
                     list       => 'ListId',
                     check_list => 'CheckList' ,
                    ) ;

sub create_id {
    my ($self, $element_name, $check)  = @_ ;

    my $element_info = dclone($self->{model}{element}{$element_name}) ; 
    my $type = delete $element_info->{type} ;

    Config::Model::Exception::Model
        ->throw (
                 error=> "create $type element '$element_name' error"
                 .": missing 'type' parameter",
                 object => $self
                )
          unless defined $type ;

    croak "Undefined id_class for type '$type'" 
      unless defined $id_class_hash{$type};

    my $id_class = delete $element_info->{$type.'_class'} 
      || 'Config::Model::'.$id_class_hash{$type} ;

    if (not defined *{$id_class.'::'}) {
        my $file = $id_class.'.pm';
        $file =~ s!::!/!g;
        require $file ;
    }

    $element_info->{parent}       = $self ;
    $element_info->{element_name} = $element_name ;
    $element_info->{instance}     = $self->{instance} ;
    $element_info->{config_model} = $self->{config_model} ;

    $self->{element}{$element_name} = $id_class->new( %$element_info) ;
}


# check validity of experience,level and status declaration. 
# create a list to classify elements by experience
sub check_properties {
    my $self = shift ;

    # a model should no longer contain attributes attached to 
    # an element (like description, level ...). There are copied here
    # because Node needs them as hash or lists
    foreach my $bad (qw/description summary level experience status permission/) {
        die $self->config_class_name,": illegal '$bad' parameter in model ",
            "(Should be handled by Config::Model directly)" 
                if defined $self->{model}{$bad};
    }

    # this is a bit convoluted, but the order of element stored with
    # the "push" for each experience must respect the order of the
    # elements declared in the model by the user

    foreach my $elt_name (@{$self->{model}{element_list}}) {

        foreach my $prop (qw/summary description/) {
            my $info_to_move = delete $self->{model}{element}{$elt_name}{$prop} ;
            $self->{$prop}{$elt_name} = $info_to_move 
                if defined $info_to_move;
        }

        foreach my $prop (keys %legal_properties) {
            my $prop_v =  delete $self->{model}{element}{$elt_name}{$prop} ;
            $prop_v = $Config::Model::default_property{$prop} 
                unless defined $prop_v;
            $self->{$prop}{$elt_name} = $prop_v ;

            croak "Config class $self->{config_class_name} error: ",
              "Unknown $prop: '$prop_v'. Expected ",
                join(" or ",keys %{$self->{$prop}})
                  unless defined $legal_properties{$prop}{$prop_v} ;

            push @{$self->{element_by_experience}{$prop}}, $elt_name 
              if $prop eq 'experience' ;
        }
    }
}

sub init {
    my $self = shift;

    return if $self->{initialized};
    $self->{initialized} = 1;    # avoid recursions

    my $model = $self->{model};

    return
      unless defined $model->{read_config}
          or defined $model->{write_config};
    $self->{bmgr} ||= Config::Model::BackendMgr->new( node => $self );

    my $ar = $self->{auto_read};

    my $check = $ar->{check};
    if ( defined $model->{read_config} and not $ar->{skip_read} ) {
        $ar->{done} = 1;
        $self->read_config_data(check => $check) ;
    }

    # use read_config data if write_config is missing
    $model->{write_config} ||= dclone $model->{read_config}
      if defined $model->{read_config};

    if ( $model->{write_config} ) {

        # setup auto_write, write_config_dir is obsolete
        $self->{bmgr}->auto_write_init(
            write_config     => $model->{write_config},
            write_config_dir => $model->{write_config_dir},
        );
    }
}

sub read_config_data {
    my ($self,%args) = @_ ;
    
    my $model = $self->{model};
    
    if ($self->location and $args{config_file}) {
        die "read_config_data: cannot override config_file in non root node (",
            $self->location,")\n";
    }

    # setup auto_read, read_config_dir is obsolete
    # may use an overridden config file
    $self->{bmgr}->read_config_data(
        read_config     => $model->{read_config},
        check           => $args{check},
        read_config_dir => $model->{read_config_dir},
        config_file     => $args{config_file} || $self->{config_file},
        auto_create     => $args{auto_create} ,
    );
}

sub write_back {
    my ($self,%args) = @_ ;

    if ($self->location and $args{config_file}) {
        die "write_back: cannot override config_file in non root node (",
            $self->location,")\n";
    }
    
    $self->{bmgr}->write_back(%args) ;
}

sub is_auto_write_for_type {
    my $self = shift ;
    return 0 unless defined $self->{bmgr} ;
    return $self->{bmgr}->is_auto_write_for_type(@_) ;
}


sub name {
    my $self = shift;
    return $self->location() || $self->{config_class_name};
}


sub get_type {
    return 'node' ;
}

sub get_cargo_type {
    return 'node' ;
}

# always true. this method is required so that WarpedNode and Node
# have a similar API.
sub is_accessible {
    return 1;
}


# should I autovivify this element: NO
sub has_element {
    my $self = shift ;
    my %args = ( @_ > 1 ) ? @_ : ( name => shift ) ;
    my $name = $args{name};
    my $type = $args{type} ;

    if (not defined $name) {
        Config::Model::Exception::Internal->throw(
            object   => $self,
            info     => "has_element: missing element name",
        ) ;
    }

    $self->accept_element($name);
    return 0 unless defined $self->{model}{element}{$name} ;
    return 1 unless defined $type ;
    return $self->{model}{element}{$name}{type} eq $type ? 1 : 0 ;
}


# should I autovivify this element: NO
sub find_element {
    my ($self,$name, %args ) = @_ ;
    croak "find_element: missing element name" unless defined $name ;

    # look for a close element playing with cases;
    if (defined $args{case} and $args{case} eq 'any') {
        foreach my $elt (keys %{$self->{model}{element}}) {
            return $elt if lc($elt) eq lc ($name) ;
        }
    }

    # now look if the element can be accepted
    $self->accept_element($name);
    return $name if defined $self->{model}{element}{$name} ;

    return ;
}



sub element_model {
    my $self= shift ;
    croak "element_model: missing element name" unless @_ ;
    return $self->{model}{element}{$_[0]} ;
}


sub element_type {
    my $self= shift ;
    croak "element_type: missing element name" unless @_ ;
    my $element_info = $self->{model}{element}{$_[0]} ;

    Config::Model::Exception::UnknownElement->throw(
                                                    object   => $self,
                                                    function => 'element_type',
                                                    where    => $self->location || 'configuration root',
                                                    element     => $_[0],
                                                   )
        unless defined $element_info ;

    return $element_info->{type} ;
}


sub get_element_name {
    my $self      = shift;
    my %args = @_ ;

    my $for  = $args{for} || 'master' ;
    my $type = $args{type} ;			 # optional
    my $cargo_type = $args{cargo_type} ; # optional

    if ($for eq 'intermediate') {
        carp "get_element_name: 'intermediate' is deprecated in favor of beginner";
        $for = 'beginner' ;
    }

    croak "get_element_name: wrong 'for' parameter. Expected ", 
      join (' or ', @experience_list) 
        unless defined $experience_index{$for} ;

    $self->init ;

    my $for_idx = $experience_index{$for} ;

    my @result ;

    my $info = $self->{model} ;
    my @element_list = @{$self->{model}{element_list}} ;

    # this is a bit convoluted, but the order of the returned element
    # must respect the order of the elements declared in the model by
    # the user
    foreach my $elt (@element_list) {
        # create element if they don't exist, this enables warp stuff
        # to kick in
        $self->create_element(name => $elt, check => $args{check} || 'yes') 
            unless defined $self->{element}{$elt};

        next if $self->{level}{$elt} eq 'hidden' ;

        my $status = $self->{status}{$elt} || $default_property{status};
        next if ($status eq 'deprecated' or $status eq 'obsolete') ;

        my $experience = $self->{experience}{$elt} || $default_property{experience} ;
        my $elt_idx =  $experience_index{$experience} ;
        my $elt_type =  $self->{element}{$elt}->get_type ;
        my $elt_cargo = $self->{element}{$elt}->get_cargo_type ;
        if ($for_idx >= $elt_idx 
            and (not defined $type       or $type       eq $elt_type)
            and (not defined $cargo_type or $cargo_type eq $elt_cargo)
           ) {
            push @result, $elt ;
        }
    }

    $logger->debug( "get_element_name: got @result for level $for");

    return wantarray ? @result : join( ' ', @result );
}


sub children {
    my $self = shift ;
    return $self-> get_element_name ;
}


sub next_element {
    my $self      = shift;
    my %args = @_ ;
    my $element   = $args{name} ;

    my @elements = @{$self->{model}{element_list}} ;
    @elements = reverse @elements if $args{reverse} ;

    # if element is empty, start from first element
    my $found_elt = (defined $element and $element) ? 0 : 1 ;

    while (my $name = shift @elements) {
        if ($found_elt) {
            return $name 
              if $self->is_element_available(name => $name, 
                                             experience => $args{experience},
                                             status => $args{status});
        }
        $found_elt = 1 if defined $element and $element eq $name ;
    }

    croak "next_element: element $element is unknown. Expected @elements" 
      unless $found_elt;
    return;
}


sub previous_element {
    my $self      = shift;
    $self->next_element(@_, reverse => 1) ;
}


sub get_element_property {
    my $self = shift ;
    my %args = @_ ;

    my ($prop,$elt) 
      = $self->check_property_args('get_element_property',%args) ;

    return $self->{$prop}{$elt} || $default_property{$prop};
}


sub set_element_property {
    my $self = shift ;
    my %args = @_ ;

    my ($prop,$elt) 
      = $self->check_property_args('set_element_property',%args) ;

    my $new_value = $args{value} || 
      croak "set_element_property:: missing 'value' parameter";

    $logger->debug("Node ",$self->name,": set $elt property $prop to $new_value");

    return $self->{$prop}{$elt} = $new_value ;
}


sub reset_element_property {
    my $self = shift ;
    my %args = @_ ;

    my ($prop,$elt) 
      = $self->check_property_args('reset_element_property',%args) ;

    my $original_value = $self->{config_model} 
      -> get_element_property (
                               class => $self->{config_class_name},
                               %args
                              );

    $logger->debug( "Node ",$self->name,
                    ": reset $elt property $prop to $original_value");

    return $self->{$prop}{$elt} = $original_value ;
}

# internal: called by the proterty methods to check their arguments
sub check_property_args {
    my $self = shift;
    my $method_name = shift ;
    my %args = @_ ;

    my $elt = $args{element} || 
      croak "$method_name: missing 'element' parameter";
    my $prop = $args{property} || 
      croak "$method_name: missing 'property' parameter";

    if ($prop eq 'permission') {
        carp "check_property_args: 'permission' is deprecated in favor of 'experience'";
        $prop = 'experience' ;
    }

    my $prop_values = $legal_properties{$prop} ;
    confess "Unknown property in $method_name: $prop, expected status or ",
      "level or experience"
        unless defined $prop_values ;

    return ($prop,$elt) ;
}


sub fetch_element {
    my $self = shift ;
    my %args = @_ > 1 ? @_ : ( name => shift ) ;
    my $element_name = $args{name} ;
    
    Config::Model::Exception::Internal -> throw (
        error => "fetch_element: missing name" 
    ) unless defined $element_name ;
    
    my $user = $args{experience} || 'master' ;
    my $check = $self->_check_check($args{check}) ;
    my $accept_hidden = $args{accept_hidden} || 0 ;

    if ($user eq 'intermediate') {
        carp "fetch_element: 'intermediate' is deprecated in favor of 'beginner'";
        $user = 'beginner' ;
    }

    $self->init($check);

    my $model = $self->{model} ;

    # retrieve element (and auto-vivify if needed)
    if (not defined $self->{element}{$element_name}) {
        # We also need to check if element name is matched by any of 'accept' parameters
        $self->accept_element($element_name);
        $self->create_element(name => $element_name, check => $check ) or return ;
    }

    # check level
    my $element_level 
      = $self->get_element_property(property => 'level',
                                    element  => $element_name) ;

    if ($element_level eq 'hidden' and not $accept_hidden) {
        Config::Model::Exception::UnavailableElement
            ->throw(
                    object   => $self,
                    element  => $element_name,
                    info     => 'hidden element',
                   );
    }


    # check status
    if ($self->{status}{$element_name} eq 'obsolete') {
        # obsolete is a status not very different from a missing
        # item. The only difference is that user will get more
        # information
        Config::Model::Exception::ObsoleteElement
            ->throw(
                    object   => $self,
                    element  => $element_name,
                   );
    }

    if ($self->{status}{$element_name} eq 'deprecated' 
        and $check ne 'no'
       ) {
        # FIXME elaborate more ? or include parameter description ??
        warn "Element '$element_name' of node '",$self->name,
          "' is deprecated\n";
    }

    # check experience
    my $elt_experience = $self->{experience}{$element_name};
    my $elt_idx   = $experience_index{$elt_experience} ; 
    croak "Unknown experience '$elt_experience' for element ",
      "'$element_name'. Expected ",join(' ', keys %experience_index)
        unless defined $elt_idx ;
    my $user_idx  = $experience_index{$user} ;

    croak "Unexpected experience '$user'" unless defined $user_idx ;

    if ($user_idx < $elt_idx and $check eq 'yes') {
        Config::Model::Exception::RestrictedElement
            ->throw(
                    object   => $self,
                    element  => $element_name,
                    level    => $user,
                    req_experience => $elt_experience,
                   );
    }

    return $self->fetch_element_no_check($element_name) ;
}

sub fetch_element_no_check {
    my ($self,$element_name) = @_ ;
    return $self->{element}{$element_name} ;
}


sub fetch_element_value {
    my $self = shift ;
    my %args = @_ > 1 ? @_ : (name => $_[0]) ;
    my $element_name = $args{name} ;
    my $user = $args{experience} || 'master' ;
    my $check = $self->_check_check($args{check}) ;

    if ($self->element_type($element_name)  ne 'leaf') {
        Config::Model::Exception::WrongType
            ->throw(
                    object   => $self->fetch_element($element_name),
                    function => 'fetch_element_value',
                    got_type => $self->element_type($element_name),
                    expected_type => 'leaf',
                   );
    }

    return $self->fetch_element(%args)->fetch( check => $check ) ;
}


sub store_element_value {
    my $self = shift ;
    my %args = @_ > 2 ? @_ : (name => $_[0] , value => $_[1]) ;

    return $self->fetch_element( %args )->store( %args ) ;
}


sub is_element_available {
    my $self = shift;
    my ($elt_name, $user_experience,$status) = (undef, 'beginner','deprecated');
    if (@_ == 1) {
        $elt_name = shift ;
    } else {
        my %args = @_ ;
        $elt_name = $args{name} ;
        $user_experience = $args{experience} if defined $args{experience} ;
        $status = $args{status} if defined $args{status} ;
        if (defined $args{permission}) {
            $user_experience = $args{permission};
            carp "is_element_available: permission is deprecated" ;
        }
    }

    croak "is_element_available: missing name parameter" 
      unless defined $elt_name ;

    # force the warp to be done (if possible) so the catalog name
    # is updated
    my $element = $self->fetch_element(name => $elt_name,
        experience => 'master', check => 'no', accept_hidden => 1) ;

    my $element_level = $self->get_element_property(property => 'level',
                                                    element => $elt_name) ;
    return 0 if $element_level eq 'hidden' ;

    my $element_status = $self->get_element_property(property => 'status',
                                                    element => $elt_name) ;

    return 0 unless ($element_status eq 'standard' or $element_status eq $status) ;

    my $element_exp = $self->get_element_property(property => 'experience',
                                                  element => $elt_name) ;

    croak "is_element_available: unknown experience for ",
      "user experience: $user_experience"
        unless defined $experience_index{$user_experience} ;

    croak "is_element_available: unknown experience for element",
      " $elt_name: $$element_exp"
        unless defined $experience_index{$element_exp} ;

    return 
      $experience_index{$user_experience}
        >= $experience_index{$element_exp} ? 1 : 0;
}


sub accept_element {
    my ($self,$name) = @_;

    my $model_data = $self->{model}{element};
    
    return $model_data->{$name} if defined $model_data->{$name} ;
    
    return unless defined $self->{model}{accept};
    
    foreach my $accept_regexp ( @{$self->{model}{accept_list}} ) {
        if ($name =~ /^$accept_regexp$/) {
            my $acc = $self->{model}{accept}{$accept_regexp} ;
            return $self->reset_accepted_element_model ($name,$acc);
        }
    }
    
    return;
}


sub accept_regexp {
    my ($self) = @_;

    return @{$self->{model}{accept_list} || []};
}


sub reset_accepted_element_model {
    my ($self,$element_name,$accept_model) = @_;

    my $model = dclone $accept_model ;
    delete $model->{name_match} ;
    
    foreach my $info_to_move (qw/description summary/) {
        my $moved_data = delete $model->{$info_to_move}  ;
        next unless defined $moved_data ;
        $self->{$info_to_move}{$element_name} = $moved_data ;
    }

    foreach my $info_to_move (qw/level experience status/) {
        $self->reset_element_property(element => $element_name, 
                                      property => $info_to_move) ;
    }

    $self->{model}{element}{$element_name} = $model ;

    #add to element list...
    push @{$self->{model}{element_list}}, $element_name;

    return ($model);
}


sub element_exists {
    my $self= shift ;
    my $element_name = shift ;

    return defined $self->{model}{element}{$element_name} ? 1 : 0 ;
}


sub is_element_defined {
    my $self = shift ;
    return defined $self->{element}{$_[0]}
}


sub get {
    my $self = shift ;
    my %args = @_ > 1 ? @_ : ( path => $_[0] ) ;
    my $path = delete $args{path} ;
    my $get_obj = delete $args{get_obj} || 0 ;
    $path =~ s!^/!! ;
    return $self unless length($path) ;
    my ($item,$new_path) = split m!/!,$path,2 ;
    $logger->debug("get: path $path, item $item");
    my $elt = $self->fetch_element(name => $item, %args) ;
    
    return unless defined $elt ;
    return $elt if ( ($elt->get_type ne 'leaf' or $get_obj) and not defined $new_path) ;
    return $elt->get(path => $new_path, get_obj => $get_obj, %args) ;
}


sub set {
    my $self = shift ;
    my $path = shift ;
    $path =~ s!^/!! ;
    my ($item,$new_path) = split m!/!,$path,2 ;
    if ($item =~ /([\w\-]+)\[(\d+)\]/) {
        return $self->fetch_element($1)->fetch_with_id($2)->set($new_path,@_) ;
    } else {
        return $self->fetch_element($item)->set($new_path,@_) ;
    }
}


sub load {
    my $self = shift ;
    my $loader = Config::Model::Loader->new ;

    my %args = @_ eq 1 ? (step => $_[0]) : @_ ;
    if (defined $args{step}) {
        $loader->load(node => $self, %args) ;
#    } elsif (defined $args{ref}) {
#        $self->load_data($args{ref}) ; # 
    }
    else {
        Config::Model::Exception::Load
            -> throw (
                      object => $self,
                      message => "load called with no 'step' parameter",
                     )  ;
    }
}

sub load_data {
    my $self                = shift ;
    my $raw_perl_data       = shift ;

    my $check = $self->_check_check(shift) ;

    if (    not defined $raw_perl_data 
        or (ref($raw_perl_data) ne 'HASH' 
            #and not $raw_perl_data->isa( 'HASH' )
            ) ) {
        Config::Model::Exception::LoadData
            -> throw (
                      object => $self,
                      message => "load_data called with non hash ref arg",
                      wrong_data => $raw_perl_data,
                     )  if $check eq 'yes' ;
        return ;
    }


    my $perl_data       = dclone $raw_perl_data ;

    $logger->info("Node load_data (",$self->location,") will load elt ",
                  join (' ',keys %$perl_data));

    # data must be loaded according to the element order defined by
    # the model. This will not load not yet accepted parameters
    foreach my $elt ( @{$self->{model}{element_list}} ) {
        next unless defined $perl_data->{$elt} ;

        if ($self->is_element_available(name => $elt, experience => 'master')
            or $check eq 'no'
           ) {
            $logger->debug("Node load_data for element $elt");
            my $obj = $self->fetch_element(name => $elt, experience => 'master', 
                                           check => $check) ;

            $obj -> load_data(delete $perl_data->{$elt}) ;
        } elsif ($check ne 'skip')  {
            Config::Model::Exception::LoadData 
                -> throw (
                          message => "load_data: tried to load hidden "
                          . "element '$elt' with",
                          wrong_data => $perl_data->{$elt},
                          object => $self,
                         ) ;
        }
    }


    # Load elements matched by accept parameter
    if (defined $self->{model}{accept}) {
        #Now, $perl_data contains all elements not yet parsed
        foreach my $elt (keys %$perl_data) {
            #load value
            #TODO: annotations
            my $obj = $self->fetch_element(name => $elt, experience => 'master', check => $check) ;
            $logger->debug("Node load_data: accepting element $elt");
            $obj ->load_data(delete $perl_data->{$elt}) if defined $obj;
            }
    }

    if (%$perl_data and $check eq 'yes') {
        Config::Model::Exception::LoadData 
            -> throw (
                      message => "load_data: unknown elements (expected "
                      . join(' ' ,@{$self->{model}{element_list}} ). ") ",
                      wrong_data => $perl_data,
                      object => $self,
                     ) ;
    }
}


# TBD explain full_dump
# Does not dump sub-tree below an AutoRead object unless full_dump is
# set to 1.

sub dump_tree {
    my $self = shift ;
    $self->init ;
    my $dumper = Config::Model::Dumper->new ;
    $dumper->dump_tree(node => $self, @_) ;
}


sub dump_annotations_as_pod {
    my $self = shift ;
    $self->init ;
    my $dumper = Config::Model::DumpAsData->new ;
    $dumper->dump_annotations_as_pod(node => $self, @_) ;
}



sub describe {
    my $self = shift ;
    $self->init ;

    my $descriptor = Config::Model::Describe->new ;
    $descriptor->describe(node => $self, @_) ;
}


sub report {
    my $self = shift ;
    $self->init ;
    my $reporter = Config::Model::Report->new ;
    $reporter->report(node => $self) ;
}


sub audit {
    my $self = shift ;
    $self->init ;
    my $reporter = Config::Model::Report->new ;
    $reporter->report(node => $self, audit => 1) ;
}



sub copy_from {
    my $self = shift ;
    my $from = shift ;
    $logger->debug("node ".$self->location." copy from ".$from->location);
    my $dump = $from->dump_tree(check => 'no') ;
    $self->load( step => $dump, check => 'skip' ) ;
}


sub get_help {
    my $self  = shift;

    my $help;
    if ( scalar @_ > 1 ) {
        my ($tag,$elt_name) = @_ ;

        if ($tag !~ /summary|description/) {
            croak "get_help: wrong argument $tag, expected ",
              "'description' or 'summary'";
        }

        $help = $self->{$tag}{$elt_name};
    } elsif ( @_ ) {
        $help = $self->{description}{$_[0]};
    } else {
        $help = $self->{model}{class_description};
    }

    return defined $help ? $help : '';
}


sub tree_searcher {
    my $self = shift;
    
    return Config::Model::TreeSearcher->new ( node => $self, @_ );
}

1;


__END__

=pod

=head1 NAME

Config::Model::Node - Class for configuration tree node

=head1 SYNOPSIS

 use Config::Model;
 use Log::Log4perl qw(:easy);
 Log::Log4perl->easy_init($WARN);

 # define configuration tree object
 my $model = Config::Model->new;
 $model->create_config_class(
    name              => 'OneConfigClass',
    class_description => "OneConfigClass detailed description",

    element => [
        [qw/X Y Z/] => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/Av Bv Cv/]
        }
    ],

    experience => [
        Y => 'beginner',
        X => 'master'
    ],
    status      => [ X => 'deprecated' ],
    description => [ X => 'X-ray description (can be long)' ],
    summary     => [ X => 'X-ray' ],

    accept => [
        'ip.*' => {
            type       => 'leaf',
            value_type => 'uniline',
            summary    => 'ip address',
        }
    ]
 );
 my $instance = $model->instance (root_class_name => 'OneConfigClass');
 my $root = $instance->config_root ;

 # X is not shown below because of its deprecated status
 print $root->describe,"\n" ;
 # name         value        type         comment
 # Y            [undef]      enum         choice: Av Bv Cv
 # Z            [undef]      enum         choice: Av Bv Cv

 # add some data
 $root->load( step => 'Y=Av' );

 # add some accepted element, ipA and ipB are created on the fly
 $root->load( step => q!ipA=192.168.1.0 ipB=192.168.1.1"! );

 # show also ip* element created in the last "load" call
 print $root->describe,"\n" ;
 # name         value        type         comment
 # Y            Av           enum         choice: Av Bv Cv
 # Z            [undef]      enum         choice: Av Bv Cv
 # ipA          192.168.1.0  uniline
 # ipB          192.168.1.1  uniline

=head1 DESCRIPTION

This class provides the nodes of a configuration tree. When created, a
node object will get a set of rules that will define its properties
within the configuration tree.

Each node contain a set of elements. An element can contain:

=over

=item *

A leaf element implemented with L<Config::Model::Value>. A leaf can be
plain (unconstrained value) or be strongly typed (values are checked
against a set of rules).

=item *

Another node.

=item *

A collection of items: a list element, implemented with
L<Config::Model::ListId>. Each item can be another node or a leaf.

=item *

A collection of identified items: a hash element, implemented with
L<Config::Model::HashId>.  Each item can be another node or a leaf.

=back

=head1 Configuration class declaration

A class declaration is made of the following parameters:

=over

=item B<name> 

Mandatory C<string> parameter. This config class name can be used by a node
element in another configuration class.

=item B<class_description> 

Optional C<string> parameter. This description will be used when
generating user interfaces.

=item B<element> 

Mandatory C<list ref> of elements of the configuration class : 

  element => [ foo => { type = 'leaf', ... },
               bar => { type = 'leaf', ... }
             ]

Element names can be grouped to save typing:

  element => [ [qw/foo bar/] => { type = 'leaf', ... } ]

See below for details on element declaration.

=item B<experience>

Optional C<list ref> of the elements whose experience are different
from default value (C<beginner>). Possible values are C<master>,
C<advanced> and C<beginner>.

  experience   => [ Y => 'beginner', 
                    [qw/foo bar/] => 'master' 
                  ],

=item B<level>

Optional C<list ref> of the elements whose level are different from
default value (C<normal>). Possible values are C<important>, C<normal>
or C<hidden>.

The level is used to set how configuration data is presented to the
user in browsing mode. C<Important> elements will be shown to the user
no matter what. C<hidden> elements will be explained with the I<warp>
notion.

  level  => [ [qw/X Y/] => 'important' ]

=item B<status>

Optional C<list ref> of the elements whose status are different from
default value (C<standard>). Possible values are C<obsolete>,
C<deprecated> or C<standard>.

Using a deprecated element will issue a warning. Using an obsolete
element will raise an exception (See L<Config::Model::Exception>.

  status  => [ [qw/X Y/] => 'obsolete' ]

=item B<description>

Optional C<list ref> of element description. These descriptions will
be used when generating user interfaces.

=item B<description>

Optional C<list ref> of element summary. These descriptions will be
used when generating user interfaces or as comment when writing
configuration files.

=item B<read_config>

=item B<write_config>

=item B<config_dir>

Parameters used to load on demand configuration data. 
See L<Config::Model::AutoRead> for details.

=item B<accept>

Optional list of criteria (i.e. a regular expression to match ) to
accept unknown parameters. Each criteria will have a list of
specification that will enable C<Config::Model> to create a model
snippet for the unknown element.

Example:

 accept => [
    'list.*' => {
        type  => 'list',
        cargo => {
            type       => 'leaf',
            value_type => 'string',
        },
    },
    'str.*' => {
        type       => 'leaf',
        value_type => 'uniline'
    },
  ]

All C<element> parameters can be used in specifying accepted parameters.

=for html
<p>For more information, see <a href="http://ddumont.wordpress.com/2010/05/19/improve-config-upgrade-ep-02-minimal-model-for-opensshs-sshd_config/">this blog<\a>.</p>

=back

=head1 Element declaration

=head2 Element type

Each element is declared with a list ref that contains all necessary
information:

  element => [ 
               foo => { ... }
             ]

This most important information from this hash ref is the mandatory
B<type> parameter. The I<type> type can be:

=over 8

=item C<node>

The element is a simple node of a tree instantiated from a 
configuration class (declared with 
L<Config::Model/"create_config_class( ... )">). 
See L</"Node element">.

=item C<warped_node>

The element is a node whose properties (mostly C<config_class_name>)
can be changed (warped) according to the values of one or more leaf
elements in the configuration tree.  See L<Config::Model::WarpedNode>
for details.

=item C<leaf>

The element is a scalar value. See L</"Leaf element">

=item C<hash>

The element is a collection of nodes or values (default). Each 
element of this collection is identified by a string (Just like a regular
hash, except that you can set up constraint of the keys).
See L</"Hash element">

=item C<list> 

The element is a collection of nodes or values (default). Each element
of this collection is identified by an integer (Just like a regular
perl array, except that you can set up constraint of the keys).  See
L</"List element">

=item C<check_list> 

The element is a collection of values which are unique in the
check_list. See L<CheckList>.

=back

=head2 Node element

When declaring a C<node> element, you must also provide a
C<config_class_name> parameter. For instance:

 $model ->create_config_class 
   (
   name => "ClassWithOneNode",
   element => [
                the_node => { 
                              type => 'node',
                              config_class_name => 'AnotherClass',
                            },
              ]
   ) ;

=head2 Leaf element

When declaring a C<leaf> element, you must also provide a
C<value_type> parameter. See L<Config::Model::Value> for more details.

=head2 Hash element

When declaring a C<hash> element, you must also provide a
C<index_type> parameter.

You can also provide a C<cargo_type> parameter set to C<node> or
C<leaf> (default).

See L<Config::Model::HashId> and L<Config::Model::AnyId> for more
details.

=head2 List element

You can also provide a C<cargo_type> parameter set to C<node> or
C<leaf> (default).

See L<Config::Model::ListId> and L<Config::Model::AnyId> for more
details.

=head1 Introspection methods

=head2 name

Returns the location of the node, or its config class name (for root
node).

=head2 get_type

Returns C<node>.

=head2 config_model

Returns the B<entire> configuration model (L<Config::Model> object).

=head2 model

Returns the configuration model of this node (data structure).

=head2 config_class_name

Returns the configuration class name of this node.

=head2 instance

Returns the instance object containing this node. Inherited from 
L<Config::Model::AnyThing>

=head2 has_element ( name => element_name, [ type => searched_type ] )

Returns 1 if the class model has the element declared or if the element 
name is matched by the optional C<accept> parameter. If C<type> is specified, the 
element name must also match the type.

=head2 find_element ( element_name , [ case => any ])

Returns $name if the class model has the element declared or if the element 
name is matched by the optional C<accept> parameter. 

If case is set to any, has_element will return the element name who match the passed
name in a case-insensitive manner.

Returns empty if no matching element is found.

=head2 model_searcher ()

Returns an object dedicated to search an element in the configuration
model (respecting privilege level).

This method returns a L<Config::Model::SearchElement> object. See
L<Config::Model::SearchElement> for details on how to handle a search.

This method is inherited from L<Config::Model::AnyThing>.

=head2 element_model ( element_name )

Returns model of the element. 

=head2 element_type ( element_name )

Returns the type (e.g. leaf, hash, list, checklist or node) of the
element.

=head2 element_name()

Returns the element name that contain this object. Inherited from 
L<Config::Model::AnyThing>

=head2 index_value()

See L<Config::Model::AnyThing/"index_value()">

=head2 parent()

See L<Config::Model::AnyThing/"parent()">

=head2 root()

See L<Config::Model::AnyThing/"root()">

=head2 location()

See L<Config::Model::AnyThing/"location()">

=head1 Element property management

=head2 get_element_name ( for => <experience>, ...  )

Return all elements names available for C<experience>.
If no experience is specified, will return all
elements available at 'master' level (I.e all elements).

Optional parameters are:

=over

=item *

B<type>: Returns only element of requested type (e.g. C<list>,
C<hash>, C<leaf>,...). By default return elements of any type.

=item *

B<cargo_type>: Returns only element which contain requested type.
E.g. if C<get_element_name> is called with C<< cargo_type => leaf >>,
C<get_element_name> will return simple leaf elements, but also hash
or list element that contain L<leaf|Config::Model::Value> object. By
default return elements of any type.

=item *

B<check>: C<yes>, C<no> or C<skip>

=back

Returns an array in array context, and a string 
(e.g. C<join(' ',@array)>) in scalar context.

=head2 children 

Like get_element_name without parameters. Returns the list of elements. This method is
polymorphic for all non-leaf objects of the configuration tree.

=head2 next_element ( ... )

This method provides a way to iterate through the elements of a node.
Mandatory parameter is C<name>. Optional parameters are C<experience>
and C<status>.

Returns the next element name for a given experience (default
C<master>) and status (default C<normal>).
Returns undef if no next element is available.

=head2 previous_element ( name => element_name, [ experience => min_experience ] )

This method provides a way to iterate through the elements of a node.

Returns the previous element name for a given experience (default
C<master>).  Returns undef if no previous element is available.

=head2 get_element_property ( element => ..., property => ... )

Retrieve a property of an element.

I.e. for a model :

  experience => [ X => 'master'],
  status     => [ X => 'deprecated' ]
  element    => [ X => { ... } ]

This call will return C<deprecated>:

  $node->get_element_property ( element => 'X', property => 'status' )

=head2 set_element_property ( element => ..., property => ... )

Set a property of an element.

=head2 reset_element_property ( element => ... )

Reset a property of an element according to the original model.

=head1 Information management

=head2 fetch_element ( name => ..  [ , user_experience => .. ] , [ check => ..] )

Fetch and returns an element from a node.

If user_experience is given, this method will check that the user has
enough privilege to access the element. If not, a C<RestrictedElement>
exception will be raised.

check can be set to yes, no or skip

=head2 fetch_element_value ( name => ... [ check => ...] )

Fetch and returns the I<value> of a leaf element from a node.

If user_experience is given, this method will check that the user has
enough privilege to access the element. If not, a C<RestrictedElement>
exception will be raised.

=head2 store_element_value ( name, value )

Store a I<value> in a leaf element from a node.

Can be invoked with named parameters (name, value, experience, check)

If user_experience is given, this method will check that the user has
enough privilege to access the element. If not, a C<RestrictedElement>
exception will be raised.

=head2 is_element_available( name => ...,  experience => ... )


Returns 1 if the element C<name> is available for the given
C<experience> ('beginner' by default) and if the element is
not "hidden". Returns 0 otherwise.

As a syntactic sugar, this method can be called with only one parameter:

   is_element_available( 'element_name' ) ; 

=head2 accept_element( name )

Checks and returns the appropriate model of an acceptable element 
(be it explicitly declared, or part of an C<accept> declaration).
Returns undef if the element cannot be accepted.

=head2 accept_regexp( name )

Returns the list of regular expressions used to check for acceptable parameters. 
Useful for diagnostics.

=head2 element_exists( element_name )

Returns 1 if the element is known in the model.

=head2 is_element_defined( element_name )

Returns 1 if the element is defined.

=head2 grab(...)

See L<Config::Model::AnyThing/"grab(...)">.

=head2 grab_value(...)

See L<Config::Model::AnyThing/"grab_value(...)">.


=head2 grab_root()

See L<Config::Model::AnyThing/"grab_root()">.

=head2 get( path => ..., mode => ... ,  check => ... , get_obj => 1|0, autoadd => 1|0)

Get a value from a directory like path. If C<get_obj> is 1, C<get> will return leaf object
instead of returning their value.

=head2 set( path  , value)

Set a value from a directory like path.

=head1 Serialization

=head2 load ( step => string [, experience => ... ] )

Load configuration data from the string into the node and its siblings.

This string follows the syntax defined in L<Config::Model::Loader>.
See L<Config::Model::Loader/"load ( ... )"> for details on parameters.
C<experience> is 'master' by default.

This method can also be called with a single parameter:

  $node->load("some data:to be=loaded");

=head2 load_data ( hash_ref, [ $check  ])

Load configuration data with a hash ref (first parameter). The hash ref key must match
the available elements of the node. The hash ref structure must match
the structure of the configuration model.

=head2 dump_tree ( ... )

Dumps the configuration data of the node and its siblings into a
string.  See L<Config::Model::Dumper/dump_tree> for parameter details.

This string follows the syntax defined in
L<Config::Model::Loader>. The string produced by C<dump_tree> can be
passed to C<load>.

=head2 dump_annotations_as_pod ( ... )

Dumps the configuration annotations of the node and its siblings into a
string.  See L<Config::Model::Dumper/dump_annotations_as_pod> for parameter details.

=head2 describe ( [ element => ... ] )

Provides a description of the node elements or of one element.

=head2 report ()

Provides a text report on the content of the configuration below this
node.

=head2 audit ()

Provides a text audit on the content of the configuration below this
node. This audit will show only value different from their default
value.

=head2 copy_from ( another_node_object )

Copy configuration data from another node into this node and its
siblings. The copy is made in a I<tolerant> mode where invalid data
are simply discarded.

=head1 Help management

=head2 get_help ( [ [ description | summary ] => element_name ] )

If called without element, returns the description of the class
(Stored in C<class_description> attribute of a node declaration).

If called with an element name, returns the description of the
element (Stored in C<description> attribute of a node declaration).

If called with 2 argument, either return the C<summary> or the
C<description> of the element.

Returns an empty string if no description was found.

=head2 tree_searcher( type => ... )

Returns an object able to search the configuration tree. 
Parameters are :

=over

=item type

Where to perform the search. It can be C<element>, C<value>,
C<key>, C<summary>, C<description>, C<help> or C<all>.

=back

Typically, you will have to call C<search> on this object.

Returns a L<Config::Model::TreeSearcher> object.

=head2 AutoRead nodes

As configuration model are getting bigger, the load time of a tree
gets longer. The L<Config::Model::AutoRead> class provides a way to
load the configuration information only when needed.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::HashId>,
L<Config::Model::ListId>,
L<Config::Model::CheckList>,
L<Config::Model::WarpedNode>,
L<Config::Model::Value>

=cut
