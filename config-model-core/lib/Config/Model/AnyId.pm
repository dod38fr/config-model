package Config::Model::AnyId ;

use Any::Moose ;
use namespace::autoclean;

use Config::Model::Exception ;
use Config::Model::Warper ;
use Carp qw/cluck croak carp/;
use Log::Log4perl qw(get_logger :levels);
use Storable qw/dclone/;
use Any::Moose '::Util::TypeConstraints';

extends qw/Config::Model::AnyThing/;

my $logger = get_logger("Tree::Element::Id") ;

enum 'DataMode' =>  [qw/preset layered normal/];

has data_mode => ( 
    is => 'rw', 
    isa => 'HashRef[DataMode]' , 
    traits => ['Hash'] ,
    handles => {
        get_data_mode => 'get' ,
        set_data_mode => 'set' ,
    },
    default => sub { {} ;} 
) ;

# Some idea for improvement

# suggest => 'foo' or '$bar foo'
# creates a method analog to next_id (or next_id but I need to change
# run_user_command) that suggest the next id as foo_<nb> where
# nb is incremented each time, or compute the passed formula 
# and performs the same

my @common_int_params  = qw/min_index max_index max_nb auto_create_ids/;
has \@common_int_params => (is => 'ro', isa => 'Maybe[Int]') ;

my @common_hash_params = qw/default_with_init/;
has \@common_hash_params => (is => 'ro', isa => 'Maybe[HashRef]') ;

my @common_list_params = qw/allow_keys default_keys auto_create_keys/;
has \@common_list_params => (is => 'ro', isa => 'Maybe[ArrayRef]') ;

my @common_str_params  = qw/allow_keys_from allow_keys_matching follow_keys_from migrate_keys_from 
                            duplicates warn_if_key_match warn_unless_key_match/;
has \@common_str_params => (is => 'ro', isa => 'Maybe[Str]') ;


my @common_params = (@common_int_params,@common_str_params, @common_list_params, @common_hash_params);
my @allowed_warp_params = (@common_params, qw/experience level convert/) ;

around BUILDARGS => sub {
    my $orig = shift ;
    my $class = shift ;
    my %args =  @_ ;
    my %h = map { ( $_ => $args{$_}) ;} grep {defined $args{$_}} @allowed_warp_params;
    return $class->$orig( backup => dclone (\%h), @_ );
} ;

has [qw/backup cargo/] => (is => 'ro', isa => 'HashRef', required => 1 ) ;
has warp=> (is => 'ro', isa => 'Maybe[HashRef]') ;
has [qw/morph/] => (is => 'ro', isa => 'Bool' ) ;
has content_warning_hash => ( is => 'rw', isa => 'HashRef' , default => sub {{} ;} ) ;
has content_warning_list => ( is => 'rw', isa => 'ArrayRef', default => sub {[] ;} ) ;
has [qw/config_class_name cargo_class max_index index_class index_type/] 
    => ( is => 'rw', isa => 'Maybe[Str]') ;

sub BUILD {
    my $self = shift;

    croak "Missing cargo->type parameter for element ".
      $self->{element_name} || 'unknown' 
        unless defined $self->cargo->{type};

    if ($self->cargo->{type} eq 'node') {
        $self->config_class_name( delete $self->cargo->{config_class_name})
          or croak  "Missing cargo->config_class_name "
                  . "parameter for element " 
                  . $self->element_name || 'unknown' ;
    }
    elsif ($self->{cargo}{type} eq 'hash' or $self->{cargo}{type} eq 'list') {
        die "$self->{element_name}: using $self->{cargo}{type} will probably not work";
    }

  
     $self->set_properties() ;

    if (defined $self->warp) {
        $self->{warper} = Config::Model::Warper->new (
            warped_object => $self,
            %{$self->warp} ,
            allowed => \@allowed_warp_params
        ) ;
    }

    return $self ;
}



# this method can be called by the warp mechanism to alter (warp) the
# feature of the Id object.
sub set_properties {
    my $self= shift;

    # mega cleanup
    map(delete $self->{$_}, @allowed_warp_params);

    my %args = (%{$self->{backup}},@_) ;

    # these are handled by Node or Warper
    map { delete $args{$_} } qw/level experience/ ;

    $logger->debug($self->name," set_properties called with @_");

    map { $self->{$_} =  delete $args{$_} if defined $args{$_} }
      @common_params ;
      
    $self->set_convert        ( \%args ) if defined $args{convert};

    Config::Model::Exception::Model
        ->throw (
                 object => $self,
                 error => "Undefined index_type"
                ) unless defined $self->{index_type};

    Config::Model::Exception::Model
        ->throw (
                 object => $self,
                 error => "Unexpected index_type $self->{index_type}"
                ) unless ($self->{index_type} eq 'integer' or 
                          $self->{index_type} eq 'string');

    my @current_idx = $self->_get_all_indexes( );
    if (@current_idx) {
        my $first_idx = shift @current_idx ;
        my $last_idx  = pop   @current_idx ;

        foreach my $idx ( ($first_idx, $last_idx)) {
            my $ok = $self->check_idx($first_idx) ;
            next if $ok ;

            # here a user input may trigger an exception even if fetch
            # or set value check is disabled. That's mostly because,
            # we cannot enforce more strict settings without random
            # deletion of data. For instance, if a hash contains 5
            # items and the max_nb of items is reduced to 3. Which 2
            # items should we remove ?

            # Since we cannot choose, we must raise an exception in
            # all cases.
            Config::Model::Exception::WrongValue 
                -> throw (
                          error => "Error while setting id property:".
                          join("\n\t",@{$self->{idx_error_list}}),
                          object => $self
                         ) ;
        }
    }

    $self->auto_create_elements ;
    
    if (    defined $self->{duplicates}
        and defined $self->{cargo}
        and $self->{cargo}{type} ne 'leaf' )
    {
        Config::Model::Exception::Model->throw(
            object => $self,
            error => "Cannot specify 'duplicates' with cargo type '$self->{cargo}{type}'",
        );
    }

    my $ok_dup = 'forbid|suppress|warn|allow';
    if ( defined $self->{duplicates} and $self->{duplicates} !~ /^$ok_dup$/ ) {
        Config::Model::Exception::Model->throw(
            object => $self,
            error => "Unexpected 'duplicates' $self->{duplicates} expected $ok_dup",
        );
    }

    # $self->{current} = { level      => $args{level} ,
                         # experience => $args{experience}
                       # } ;
    #$self->SUPER::set_parent_element_property(\%args) ;
    
    Config::Model::Exception::Model ->throw (
                 object => $self,
                 error => "Unexpected parameters: ". join(' ', keys %args)
                ) if scalar keys %args ;
}

# # this method will overide setting comings from a value (or maybe a
# # warped node) with warped settings coming from this warped id. Only
# # level hidden is forwarded no matter what
# sub set_parent_element_property {
    # my $self = shift;
    # my $arg_ref = shift ;
# 
    # my $cur = $self->{current} ;
# 
    # # override if necessary
    # $arg_ref->{experience} = $cur->{experience} 
      # if defined $cur->{experience} ;
# 
    # if (    defined $cur->{level} 
        # and ( not defined $arg_ref->{level} 
              # or $arg_ref->{level} ne 'hidden'
            # )
       # ) {
        # $arg_ref->{level} = $cur->{level} ;
    # }
# 
    # $self->SUPER::set_parent_element_property($arg_ref) ;
# }

sub create_default_with_init {
    my $self = shift;

    return unless defined $self->{default_with_init};

    my $h = $self->{default_with_init};
    foreach my $def_key ( keys %$h ) {
        my $v_obj = $self->fetch_with_id($def_key);
        if ( $v_obj->get_type eq 'leaf' ) {
            $v_obj->store( $h->{$def_key} );
        }
        else {
            $v_obj->load( $h->{$def_key} );
        }
    }
}

sub max {
    my $self=shift ;
    carp $self->name,": max param is deprecated, use max_index\n";
    $self->max_index ;
}

sub min {
    my $self=shift ;
    carp $self->name,": min param is deprecated, use min_index\n";
    $self->min_index ;
}


sub cargo_type { goto &get_cargo_type; }

sub get_cargo_type {
    my $self = shift ;
    #my @ids = $self->get_all_indexes ;
    # the returned cargo type might be different from collected type
    # when collected type is 'warped_node'. 
    #return @ids ? $self->fetch_with_id($ids[0])->get_cargo_type
    #  : $self->{cargo_type} ;
    return $self->{cargo}{type} ;
}


sub get_cargo_info {
    my $self = shift ;
    my $what = shift ;
    return $self->{cargo}{$what} ;
}

# internal, does a grab with improved error mesage
sub safe_typed_grab {
  my $self  = shift ;
  my %args = @_ ;
  my $param = $args{param} || croak "safe_typed_grab: missing param" ;

  my $res = eval {
    $self->grab(step => $self->{$param},
                type => $self->get_type,
                check => $args{check} || 'yes' ,
               ) ;
  };

  if ($@) {
    my $e = $@ ;
    my $msg = $e ? $e->full_message : '' ;
    Config::Model::Exception::Model
        -> throw (
                  object => $self,
                  error => "'$param' parameter: "
                  . $msg
                 ) ;
  }

  return $res ;
}


sub get_default_keys {
    my $self = shift ;

    if ($self->{follow_keys_from}) {
        my $followed = $self->safe_typed_grab(param => 'follow_keys_from') ;
        my @res = $followed -> get_all_indexes ;
        return wantarray ? @res : \@res ;
    }

    my @res ;

    if ($self->{migrate_keys_from}) {
        my $followed = $self->safe_typed_grab(param => 'migrate_keys_from', check => 'no') ;
        push @res , $followed -> get_all_indexes ;
    }

    push @res , @{ $self->{default_keys} }
      if defined $self->{default_keys} ;

    push @res , keys %{$self->{default_with_init}}
      if defined $self->{default_with_init} ;

    return wantarray ? @res : \@res ;
}


sub name
  {
    my $self = shift ;
    return $self->{parent}->name . ' '.$self->{element_name}.' id' ;
  }


# internal. Handle model declaration arguments
sub handle_args {
    my $self = shift ;
    my %args = @_ ;

    my $warp_info = delete $args{warp} ;

    map { $self->{$_} =  delete $args{$_} if defined $args{$_} }
         qw/index_class index_type morph ordered/;

    $self->{backup}  = dclone (\%args) ;

    $self->set_properties(%args) if defined $self->{index_type} ;

    if (defined $warp_info) {
        $self->{warper} = Config::Model::Warper->new (
            warped_object => $self,
            %$warp_info ,
            allowed => \@allowed_warp_params
        ) ;
    }

    return $self ;
}

sub apply_fixes {
    my $self = shift ; 
    $logger->debug( $self->location.": apply_fixes called" ) ;

    $self->check_content(fix => 1) ;

}


sub has_fixes {
    my $self = shift; 
    return $self->{nb_of_content_fixes} ;
}



my %check_idx_dispatch =
  map { ( $_ => 'check_' . $_ ); }
  qw/follow_keys_from allow_keys allow_keys_from allow_keys_matching
  warn_if_key_match warn_unless_key_match/;

my %check_content_dispatch = map { ($_ => 'check_'.$_) ;}
    qw/duplicates/;

my %mode_move = ( 
    layered => { preset => 1, normal => 1} ,
    preset  => { normal => 1 },
    normal => {} ,
 ) ;

sub notify_change {
    my $self = shift ;
    my %args = @_ ;
    
    # $idx may be undef if $self has changed, not necessarily its content
    my $idx = $args{index} ; 
    if (defined $idx) {
        # use $idx to trigger move from layered->preset->normal
        my $imode = $self->instance->get_data_mode ;
        my $old_mode = $self->get_data_mode($idx) if defined $idx ;
        $self->set_data_mode($idx,$imode) if $mode_move{$old_mode}{$imode} ; 
    }
    
    return if $self->instance->initial_load ;

    $self->needs_check(1) ;
    $self->SUPER::notify_change(@_) ;
}

sub check {
    my $self = shift;
    carp __PACKAGE__,"check is deprecated. Use check_content";
    $self->check_content(@_) ;
}


# check globally the list or hash
sub check_content {
    my $self = shift;

    my %args = @_ > 1 ? @_ : ( index => $_[0] );
    my $silent    = $args{silent} || 0;
    my $apply_fix = $args{fix}    || 0;

    Config::Model::Exception::Internal->throw(
        object => $self,
        error  => "check method: index or key should not be defined"
    ) if defined $args{index};

    if ( $self->needs_check ) {
        # need to keep track to update GUI
        $self->{nb_of_content_fixes} = 0;    # reset before check

        my @error;
        my @warn;

        foreach my $key_check_name ( keys %check_content_dispatch ) {
            next unless $self->{$key_check_name};
            my $method = $check_content_dispatch{$key_check_name};
            $self->$method( \@error, \@warn, $apply_fix );
        }

        my $nb = $self->fetch_size;
        push @error, "Too many instances ($nb) limit $self->{max_nb}, "
          if defined $self->{max_nb} and $nb > $self->{max_nb};

        map { warn( "Warning in '" . $self->location . "': $_\n" ) } @warn
          unless $silent;

        $self->{content_warning_list} = \@warn;
        $self->{content_error_list}   = \@error;
        $self->needs_check(0) ;

        return scalar @error ? 0 : 1;
    }
    else {
        $logger->debug( $self->location, " has not changed, actual check skipped" )
          if $logger->is_debug;
        my $err = $self->{content_error_list} ;
        return scalar @$err ? 0 : 1;
    }
}

# internal function to check the validity of the index. Called when creating a new
# index or when set_properties is called (init or during warp)
sub check_idx {
    my $self = shift ;
    
    my %args = @_ > 1 ? @_ : (index => $_[0]) ;
    my $idx = $args{index} ;
    my $silent = $args{silent} || 0 ;
    my $check = $args{check} || 'yes' ;
    my $apply_fix = $check eq 'fix' ? 1 : 0 ;

    Config::Model::Exception::Internal
        -> throw (
                  object => $self,
                  error => "check_idx method: key or index is not defined"
                 ) unless defined $idx ;

    my @error ;
    my @warn ;

    foreach my $key_check_name (keys %check_idx_dispatch) {
        next unless $self->{$key_check_name} ;
        my $method = $check_idx_dispatch{$key_check_name} ;
        $self->$method($idx,\@error,\@warn,$apply_fix) ;
    }

    my $nb =  $self->fetch_size ;
    my $new_nb = $nb ;
    $new_nb++ unless $self->_exists($idx) ;

    if ($idx eq '') {
        push @error,"Index is empty";
    }
    elsif ($self->{index_type} eq 'integer' and $idx =~ /\D/) {
        push @error,"Index is not integer ($idx)";
    }
    elsif (defined $self->{max_index} and $idx > $self->{max_index}) {
        push @error,"Index $idx > max_index limit $self->{max_index}" ;
    }
    elsif ( defined $self->{min_index} and $idx < $self->{min_index}) {
        push @error,"Index $idx < min_index limit $self->{min_index}";
    }

    push @error,"Too many instances ($new_nb) limit $self->{max_nb}, ".
      "rejected id '$idx'"
        if defined $self->{max_nb} and $new_nb > $self->{max_nb};

    if (scalar @error) {
        my @a = $self->get_all_indexes ;
        push @error, "Instance ids are '".join(',', @a)."'" ,
          $self->warp_error  ;
    }

    $self->{idx_error_list} = \@error ;

    if (@warn) {
        $self->{warning_hash}{$idx} = \@warn ;
        map { warn ("Warning in '".$self->location."': $_\n") } @warn unless $silent;
    }
    else {
        delete $self->{warning_hash}{$idx} ;
    }
        
    return scalar @error ? 0 : 1 ;
}

#internal
sub check_follow_keys_from {
    my ($self,$idx,$error) = @_ ; 

    my $followed = $self->safe_typed_grab(param => 'follow_keys_from') ;
    return if $followed->exists($idx) ;

    push @$error, "key '$idx' does not exists in '".$followed->name 
              . "'. Expected '" . join("', '", $followed->get_all_indexes) . "'" ;
}

#internal
sub check_allow_keys {
    my ($self,$idx,$error) = @_ ; 

    my $ok = grep { $_ eq $idx } @{$self->{allow_keys}} ;

    push @$error, "Unexpected key '$idx'. Expected '".
                      join("', '",@{$self->{allow_keys}} ). "'" 
        unless $ok ;
}

#internal
sub check_allow_keys_matching {
    my ($self,$idx,$error) = @_ ; 
    my $match = $self->{allow_keys_matching} ;

    push @$error,"Unexpected key '$idx'. Key must match $match" 
        unless $idx =~ /$match/;
}

#internal
sub check_allow_keys_from {
    my ($self,$idx,$error) = @_ ; 

    my $from = $self->safe_typed_grab(param => 'allow_keys_from');
    my $ok = grep { $_ eq $idx } $from->get_all_indexes ;

    return if $ok ;

    push @$error, "key '$idx' does not exists in '"
                      . $from->name 
                      . "'. Expected '"
                      . join( "', '", $from->get_all_indexes). "'"  ;

}

sub check_warn_if_key_match {
    my ($self,$idx,$error,$warn) = @_ ; 
    my $re = $self->{warn_if_key_match} ;

    push @$warn, "key '$idx' should not match $re\n" if $idx =~ /$re/ ;
}

sub check_warn_unless_key_match {
    my ($self,$idx,$error,$warn) = @_ ; 
    my $re = $self->{warn_unless_key_match} ;

    push @$warn, "key '$idx' should match $re\n" unless $idx =~ /$re/;
}

sub check_duplicates {
    my ( $self, $error, $warn, $apply_fix ) = @_;

    my $dup = $self->{duplicates} ;
    return if $dup eq 'allow' ;
    
    $logger->debug("check_duplicates called");
    my %h;
    my @issues;
    my @to_delete ;
    foreach my $i ( $self->get_all_indexes ) {
        my $v = $self->fetch_with_id(index => $i, check => 'no')->fetch;
        next unless $v ;
        $h{$v} = 0 unless defined $h{$v} ;
        $h{$v}++;
        if ($h{$v} > 1) {
            $logger->debug("got duplicates $i -> $v : $h{$v}");
            push @to_delete, $i ;
            push @issues, qq!$i:"$v"! ; 
        }
    }

    return unless @issues ;
    
    if ($apply_fix) {
        $logger->debug("Fixing duplicates @issues");
        map { $self->remove($_) } reverse @to_delete ;
    }
    elsif ($dup eq 'forbid') {
        $logger->debug("Found forbidden duplicates @issues");
        push @$error, "Forbidden duplicates value @issues";
    }
    elsif ($dup eq 'warn') {
        $logger->debug("warning condition: found duplicate @issues");
        push @$warn, "Duplicated value: @issues";
        $self->{nb_of_content_fixes} += scalar @issues ;
    }
    elsif ($dup eq 'suppress') {
        $logger->debug("suppressing duplicates @issues");
        map { $self->remove($_) } reverse @to_delete ;
    }
    else {
        die "Internal error: duplicates is $dup";
    }
}




sub fetch_with_id {
    my $self = shift ;
    my %args = @_ > 1 ? @_ : ( index => shift ) ;
    my $check = $self->_check_check($args{check}) ;    
    my $idx = $args{index} ;

    $idx = $self->{convert_sub}($idx) 
      if (defined $self->{convert_sub} and defined $idx) ;

    my $ok = 1 ;
    # check index only if it's unknown
    $ok = $self->check_idx(index => $idx, check => $check) 
        unless $self->_defined($idx) or $check eq 'no' ;

    if ($ok or $check eq 'no') {
        $self->auto_vivify($idx) unless $self->_defined($idx) ;
        return $self->_fetch_with_id($idx) ;
      }
    else {
        Config::Model::Exception::WrongValue 
            -> throw (
                      error => join("\n\t",@{$self->{idx_error_list}}),
                      object => $self
                     ) ;
    }

    return ;
}


sub get {
    my $self = shift ;
    my %args = @_ > 1 ? @_ : ( path => $_[0] ) ;
    my $path = delete $args{path} ;
    my $autoadd = 1 ;
    $autoadd = $args{autoadd} if defined $args{autoadd};
    my $get_obj = delete $args{get_obj} || 0 ;
    $path =~ s!^/!! ;
    my ($item,$new_path) = split m!/!,$path,2 ;

    return unless ($self->exists($item) or $autoadd) ;

    $logger->debug("get: path $path, item $item");
    
    my $obj = $self->fetch_with_id(index => $item, %args) ;
    return $obj if (($get_obj or $obj->get_type ne 'leaf') and not defined $new_path) ;
    return $obj->get(path => $new_path,get_obj => $get_obj, %args) ;
}


sub set {
    my $self = shift ;
    my $path = shift ;
    $path =~ s!^/!! ;
    my ($item,$new_path) = split m!/!,$path,2 ;
    return $self->fetch_with_id($item)->set($new_path,@_) ;
}



sub copy {
    my ($self,$from, $to) = @_ ;

    my $from_obj = $self->fetch_with_id($from) ;
    my $ok = $self->check_idx($to) ;

    if ($ok && $self->{cargo}{type} eq 'leaf') {
        $logger->trace("AnyId: copy leaf value from ".$self->name." $from to $to") ;
        $self->fetch_with_id($to)->store($from_obj->fetch()) ;
    }
    elsif ( $ok ) {
        # node object 
        $logger->trace("AnyId: deep copy node from ".$self->name) ;
        my $target = $self->fetch_with_id($to);
        $logger->trace("AnyId: deep copy node to ".$target->name) ;
        $target->copy_from($from_obj) ;
    }
    else {
        Config::Model::Exception::WrongValue 
            -> throw (
                      error => join("\n\t",@{$self->{idx_error_list}}),
                      object => $self
                     ) ;
    }
}


sub fetch_all {
    my $self = shift ;
    my @keys  = $self->get_all_indexes ;
    return map { $self->fetch_with_id($_) ;} @keys ;
}


sub fetch_all_values {
    my $self = shift ;
    my %args = @_ > 1 ? @_ : ( mode => shift ) ;
    my $mode = $args{mode};
    my $check = $self->_check_check($args{check}) ;
    
    my @keys  = $self->get_all_indexes ;

    if ( $self->{cargo}{type} eq 'leaf' ) {
        my $ok = $check eq 'no' ? 1 : $self->check_content( );

        if ( $ok or $check eq 'no' ) {
            return grep { defined $_ }
              map {
                $self->fetch_with_id($_)
                  ->fetch( check => $check, mode => $mode );
              } @keys;
        }
        else {
            Config::Model::Exception::WrongValue->throw(
                error  => join( "\n\t", @{ $self->{content_error_list} } ),
                object => $self
            );
        }

    }
    else {
        my $info = "current keys are '" . join( "', '", @keys ) . "'.";
        if ( $self->{cargo}{type} eq 'node' ) {
            $info .= "config class is "
              . $self->fetch_with_id( $keys[0] )->config_class_name;
        }
        Config::Model::Exception::WrongType->throw(
            object        => $self,
            function      => 'fetch_all_values',
            got_type      => $self->{cargo}{type},
            expected_type => 'leaf',
            info          => $info,
        );
    }
}


sub get_all_indexes {
    my $self = shift;
    $self->create_default ; # will check itself if creation is necessary
    return $self->_get_all_indexes ;
}


sub children {
    my $self = shift ;
    return $self->get_all_indexes ;
}


# auto vivify must create according to cargo}{type
# node -> Node or user class
# leaf -> Value or user class

# warped node cannot be used. Same effect can be achieved by warping 
# cargo_args 

my %element_default_class 
  = (
     warped_node => 'WarpedNode',
     node        => 'Node',
     leaf        => 'Value',
    );

my %can_override_class 
  = (
     node        => 0,
     leaf        => 1,
    );

#internal
sub auto_vivify {
    my ( $self, $idx ) = @_;
    my %cargo_args = %{ $self->cargo };
    my $class      = delete $cargo_args{class};    # to override class in cargo

    my $cargo_type = delete $cargo_args{type};

    Config::Model::Exception::Model->throw(
        object  => $self,
        message => "unknown '$cargo_type' cargo type:  "
          . "in cargo_args. Expected "
          . join( ' or ', keys %element_default_class )
    ) unless defined $element_default_class{$cargo_type};

    my $el_class = 'Config::Model::' . $element_default_class{$cargo_type};

    if ( defined $class ) {
        Config::Model::Exception::Model->throw(
            object  => $self,
            message => "$cargo_type class " . "cannot be overidden by '$class'"
        ) unless $can_override_class{$cargo_type};
        $el_class = $class;
    }

    if ( not defined *{ $el_class . '::new' } ) {
        my $file = $el_class . '.pm';
        $file =~ s!::!/!g;
        require $file;
    }

    my @common_args = (
        element_name => $self->{element_name},
        index_value  => $idx,
        instance     => $self->{instance},
        parent       => $self->parent,
        container    => $self,
        %cargo_args,
    );

    my $item;

    # check parameters passed by the user
    if ( $cargo_type eq 'node' ) {
        Config::Model::Exception::Model->throw(
            object  => $self,
            message => "missing 'cargo->config_class_name' " . "parameter",
        ) unless defined $self->{config_class_name};

        $item = $self->{parent}->new( @common_args,
            config_class_name => $self->{config_class_name} );
    }
    else {
        $item = $el_class->new(@common_args);
    }
    
    my $imode = $self->instance->get_data_mode ;
    $self->set_data_mode( $idx, $imode ) ;
    
    $self->_store( $idx, $item );
}

sub defined {
    my ($self,$idx) = @_ ;

    return $self->_defined($idx);
}


sub exists {
    my ($self,$idx) = @_ ;

    return $self->_exists($idx);
}


sub delete {
    my ($self,$idx) = @_ ;

    delete $self->{warning_hash}{$idx}  ;
    # this will trigger a notify_change
    return $self->_delete($idx);
}


sub clear {
    my ($self) = @_ ;

    $self->{warning_hash} = {} ;
    # this will trigger a notify_change
    $self->_clear;
  }


sub clear_values {
    my ($self) = @_ ;

    my $ct = $self->get_cargo_type ;
    Config::Model::Exception::User
        -> throw (
                  object => $self,
                  message => "clear_values() called on non leaf cargo type: '$ct'"
                 ) 
          if $ct ne 'leaf';


    # this will trigger a notify_change
    map {$self->fetch_with_id($_)->store(undef)} $self->get_all_indexes ;
  }


sub warning_msg {
    my ($self,$idx) = @_ ;
    
    if (defined $idx) {
        return $self->{warning_hash}{$idx} ;
    }
    elsif (scalar %{$self->{content_warning_hash}} or @{$self->{content_warning_list}}) {
        my @list = @{$self->{content_warning_list}} ;
        push @list , map ( "key $_: ".$self->{content_warning_hash}{$_}, keys %{$self->{content_warning_hash}}) ;
        return join("\n",@list) ;
    }
}



sub error_msg {
    my $self = shift ;
    my @list ;
    map { push @list, @{$self->{$_}} if $self->{$_} ;} qw/idx_error_list content_error_list/ ;

    return unless @list ;
    return wantarray ? @list : join("\n\t",@list) ;
}

__PACKAGE__->meta->make_immutable;

1;

__END__



=pod

=head1 NAME

Config::Model::AnyId - Base class for hash or list element

=head1 SYNOPSIS

 use Config::Model;
 use Log::Log4perl qw(:easy);
 Log::Log4perl->easy_init($WARN);

 # define configuration tree object
 my $model = Config::Model->new;
 $model->create_config_class(
    name    => "Foo",
    element => [
        [qw/foo bar/] => {
            type       => 'leaf',
            value_type => 'string'
        },
    ]
 );

 $model->create_config_class(
    name    => "MyClass",
    element => [
        plain_hash => {
            type       => 'hash',
            index_type => 'string',
            cargo      => {
                type       => 'leaf',
                value_type => 'string',
            },
        },
        bounded_hash => {
            type       => 'hash',      # hash id
            index_type => 'integer',

            # hash boundaries
            min_index => 1, max_index => 123, max_nb => 2,

            # specify cargo held by hash
            cargo => {
                type       => 'leaf',
                value_type => 'string'
            },
        },
        bounded_list => {
            type => 'list',    # list id

            max_index => 123,
            cargo     => {
                type       => 'leaf',
                value_type => 'string'
            },
        },
        hash_of_nodes => {
            type       => 'hash',     # hash id
            index_type => 'string',
            cargo      => {
                type              => 'node',
                config_class_name => 'Foo'
            },
        },
    ],
 );

 my $inst = $model->instance( root_class_name => 'MyClass' );

 my $root = $inst->config_root;

 # put data
 my $step = 'plain_hash:foo=boo bounded_list=foo,bar,baz
   bounded_hash:3=foo bounded_hash:30=baz 
   hash_of_nodes:"foo node" foo="in foo node" -
   hash_of_nodes:"bar node" bar="in bar node" ';
 $root->load( step => $step );

 # dump resulting tree
 print $root->dump_tree;

=head1 DESCRIPTION

This class provides hash or list elements for a L<Config::Model::Node>.

The hash index can either be en enumerated type, a boolean, an integer
or a string.

=head1 CONSTRUCTOR

AnyId object should not be created directly.

=head1 Hash or list model declaration

A hash or list element must be declared with the following parameters:

=over

=item type

Mandatory element type. Must be C<hash> or C<list> to have a
collection element.  The actual element type must be specified by
C<cargo => type> (See L</"CAVEATS">).

=item index_type

Either C<integer> or C<string>. Mandatory for hash.

=item ordered

Whether to keep the order of the hash keys (default no). (a bit like
L<Tie::IxHash>).  The hash keys are ordered along their creation. The
order can be modified with L<swap|Config::Model::HashId/"swap ( key1 , key2 )">,
L<move_up|Config::Model::HashId/"move_up ( key )"> or
L<move_down|Config::Model::HashId/"move_down ( key )">.

=item duplicates

Specify the policy regarding duplicated values stored in the list or as
hash values (valid only when cargo type is C<leaf>). The policy can be
C<allow> (default), C<suppress>, C<warn> (which offers the possibility
to apply a fix), C<forbid>. Note that duplicates I<check cannot be
performed when the duplicated value is stored>: this happens outside of
this object. Duplicates can be check only after when the value is read.

=item cargo

Hash ref specifying the cargo held by the hash of list. This has must
contain:

=over 8

=item type

Can be C<node> or C<leaf> (default).

=item config_class_name

Specifies the type of configuration object held in the hash. Only
valid when C<cargo> C<type> is C<node>.

=item <other>

Constructor arguments passed to the cargo object. See
L<Config::Model::Node> when C<< cargo->type >> is C<node>. See 
L<Config::Model::Value> when C<< cargo->type >> is C<leaf>.

=back

=item min_index

Specify the minimum value (optional, only for hash and for integer index)

=item max_index

Specify the maximum value (optional, only for list or for hash with 
integer index)

=item max_nb

Specify the maximum number of indexes. (hash only, optional, may also
be used with string index type)

=item default_keys

When set, the default parameter (or set of parameters) are used as
default keys hashes and created automatically when the C<keys> or C<exists>
functions are used on an I<empty> hash..

You can use C<< default_keys => 'foo' >>, 
or C<< default_keys => ['foo', 'bar'] >>.

=item default_with_init

To perform special set-up on children nodes you can also use 

   default_with_init =>  { 'foo' => 'X=Av Y=Bv' ,
                           'bar' => 'Y=Av Z=Cv' }
                           
When the hash contains leaves, you can also use:

   default_with_init => { 'def_1' => 'def_1 stuff' ,
                          'def_2' => 'def_2 stuff' }


=item migrate_keys_from

Specifies that the keys of the hash or list are copied from another hash or list in
the configuration tree only when the hash is created. 

   migrate_keys_from => '- another_hash_or_list'

=item follow_keys_from

Specifies that the keys of the hash follow the keys of another hash in
the configuration tree. In other words, the hash you're creating will
always have the same keys as the other hash.

   follow_keys_from => '- another_hash'

=item allow_keys

Specifies authorized keys:

  allow_keys => ['foo','bar','baz']

=item allow_keys_from

A bit like the C<follow_keys_from> parameters. Except that the hash pointed to
by C<allow_keys_from> specified the authorized keys for this hash.

  allow_keys_from => '- another_hash'

=item allow_keys_matching

Keys must match the specified regular expression. For instance:

  allow_keys_matching => '^foo\d\d$'

=item auto_create_keys

When set, the default parameter (or set of parameters) are used as
keys hashes and created automatically. (valid only for hash elements)

Called with C<< auto_create_keys => ['foo'] >>, or 
C<< auto_create_keys => ['foo', 'bar'] >>.

=item warn_if_key_match

Issue a warning if the key matches the specified regular expression

=item warn_unless_key_match

Issue a warning unless the key matches the specified regular expression

=item auto_create_ids

Specifies the number of elements to create automatically. E.g.  C<<
auto_create_ids => 4 >> will initialize the list with 4 undef elements.
(valid only for list elements)

=item convert => [uc | lc ]

The hash key will be converted to uppercase (uc) or lowercase (lc).

=item warp

See L</"Warp: dynamic value configuration"> below.

=back

=head1 Warp: dynamic value configuration

The Warp functionality enables an L<HashId|Config::Model::HashId> or
L<ListId|Config::Model::ListId> object to change its default settings
(e.g. C<min_index>, C<max_index> or C<max_nb> parameters) dynamically according to
the value of another C<Value> object. (See
L<Config::Model::WarpedThing> for explanation on warp mechanism)

For instance, with this model:

 $model ->create_config_class 
  (
   name => 'Root',
   'element'
   => [
       macro => { type => 'leaf',
                  value_type => 'enum',
                  name       => 'macro',
                  choice     => [qw/A B C/],
                },
       warped_hash => { type => 'hash',
                        index_type => 'integer',
                        max_nb     => 3,
                        warp       => {
                                       follow => '- macro',
                                       rules => { A => { max_nb => 1 },
                                                  B => { max_nb => 2 }
                                                }
                                      },
                        cargo => { type => 'node',
                                   config_class_name => 'Dummy'
                                 }
                      },
     ]
  );

Setting C<macro> to C<A> will mean that C<warped_hash> can only accept
one instance of C<Dummy>.

Setting C<macro> to C<B> will mean that C<warped_hash> will accept two
instances of C<Dummy>.

Like other warped class, a HashId or ListId can have multiple warp
masters (See L<Config::Model::WarpedThing/"Warp follow argument">:

  warp => { follow => { m1 => '- macro1', 
                        m2 => '- macro2' 
                      },
            rules  => [ '$m1 eq "A" and $m2 eq "A2"' => { max_nb => 1},
                        '$m1 eq "A" and $m2 eq "B2"' => { max_nb => 2}
                      ],
          }

=head2 Warp and auto_create_ids or auto_create_keys

When a warp is applied with C<auto_create_keys> or C<auto_create_ids>
parameter, the auto_created items are created if they are not already
present. But this warp will never remove items that were previously
auto created.

For instance, if a tied hash is created with 
C<< auto_create => [a,b,c] >>, the hash contains C<(a,b,c)>.

Then if a warp is applied with C<< auto_create_keys => [c,d,e] >>, the hash
will contain C<(a,b,c,d,e)>. The items created by the first
auto_create_keys are not removed.

=head2 Warp and max_nb

When a warp is applied, the items that do not fit the constraint
(e.g. min_index, max_index) are removed.

For the max_nb constraint, an exception will be raised if a warp 
leads to a number of items greater than the max_nb constraint.

=head1 Introspection methods

The following methods returns the current value stored in the Id
object (as declared in the model unless they were warped):

=over

=item min_index 

=item max_index 

=item max_nb 

=item index_type 

=item default_keys 

=item default_with_init 

=item follow_keys_from

=item auto_create_ids

=item auto_create_keys

=item ordered

=item morph

=item config_model

=back

=head2 get_cargo_type()

Returns the object type contained by the hash or list (i.e. returns
C<< cargo -> type >>).

=head2 get_cargo_info( < what > )

Returns more info on the cargo contained by the hash or list. C<what>
may be C<value_type> or any other cargo info stored in the model. Will
return undef if the requested info was not provided in the model.

=head2 get_default_keys

Returns a list (or a list ref) of the current default keys. These keys
can be set by the C<default_keys> or C<default_with_init> parameters
or by the other hash pointed by C<follow_keys_from> parameter.

=head2 name()

Returns the object name. The name finishes with ' id'.

=head2 config_class_name()

Returns the config_class_name of collected elements. Valid only
for collection of nodes.

This method will return undef if C<cargo> C<type> is not C<node>.

=head2 has_fixes

Returns the number of fixes that can be applied to the current value. 

=head1 Information management

=head2 fetch_with_id ( index => $idx , [ check => 'no' ])

Fetch the collected element held by the hash or list. Index check is 'yes' by default.
Can be called with one parameter which will be used as index.

=head2 C<get( path => ..., mode => ... ,  check => ... , get_obj => 1|0, autoadd => 1|0)>

Get a value from a directory like path.

=head2 set( path, value )

Set a value with a directory like path.

=head2 copy ( from_index, to_index )

Deep copy an element within the hash or list. If the element contained
by the hash or list is a node, all configuration information is
copied from one node to another.

=head2 fetch_all()

Returns an array containing all elements held by the hash or list.

=head2 fetch_all_values( mode => ..., check => ...)

Returns an array containing all defined values held by the hash or
list. (undefined values are simply discarded). This method is only 
valid for hash or list containing leaves.

With C<mode> parameter, this method will return either:

=over

=item custom

The value entered by the user

=item preset

The value entered in preset mode

=item standard

The value entered in preset mode or checked by default.

=item default

The default value (defined by the configuration model)

=back

=head2 get_all_indexes()

Returns an array containing all indexes of the hash or list. Hash keys
are sorted alphabetically, except for ordered hashed.

=head2 children 

Like get_all_indexes. This method is
polymorphic for all non-leaf objects of the configuration tree.

=head2 defined ( index )

Returns true if the value held at C<index> is defined.

=head2 exists ( index )

Returns true if the value held at C<index> exists (i.e the key exists
but the value may be undefined). This method may not make sense for
list element.

=head2 delete ( index )

Delete the C<index>ed value 

=head2 clear()

Delete all values (also delete underlying value or node objects).

=head2 clear_values()

Delete all values (without deleting underlying value objects).

=head2 warning_msg ( [index] )

Returns warnings concerning indexes of this hash. 
Without parameter, returns a string containing all warnings or undef. With an index, return the warnings
concerning this index or undef.

=head2 error_msg 

Returns the error messages of this object (if any)

=head1 AUTHOR

Dominique Dumont, ddumont [AT] cpan [DOT] org

=head1 SEE ALSO

L<Config::Model>,
L<Config::Model::Instance>,
L<Config::Model::Node>,
L<Config::Model::WarpedNode>,
L<Config::Model::HashId>,
L<Config::Model::ListId>,
L<Config::Model::CheckList>,
L<Config::Model::Value>

=cut
