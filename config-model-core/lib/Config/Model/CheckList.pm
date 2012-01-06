package Config::Model::CheckList ;
use Any::Moose ;

use Config::Model::Exception ;
use Config::Model::IdElementReference ;
use Config::Model::Warper ;
use Carp;
use Log::Log4perl qw(get_logger :levels);
use Storable qw/dclone/;

extends qw/Config::Model::AnyThing/ ;


my $logger = get_logger("Tree::Element::CheckList") ;

my @introspect_params = qw/refer_to computed_refer_to/ ;

my @accessible_params =  qw/default_list upstream_default_list choice ordered/ ;
my @allowed_warp_params = (@accessible_params, qw/level experience/);

has [qw/data preset layered refer_to computed_refer_to/] 
    => ( is => 'rw', isa => 'HashRef' , default => sub { {} ;} ) ;
has [qw/ordered_data choice/]
    => ( is => 'rw', isa => 'ArrayRef' , default => sub { [] ;} ) ;

has [qw/warp help/]  => (is => 'rw', isa => 'Maybe[HashRef]') ;

around BUILDARGS => sub {
    my $orig = shift ;
    my $class = shift ;
    my %args =  @_ ;
    map {delete $args{$_}} qw/element_name instance config_model 
	warp help refer_to computed_refer_to/ ;
    return $class->$orig( backup => dclone (\%args), @_ );
} ;


sub BUILD {
    my $self = shift;

    if (defined $self->refer_to or defined $self->computed_refer_to) {
	$self->submit_to_refer_to() ;
    }

    $self->set_properties() ; # set will use backup data

    if (defined $self->warp) {
        my $warp_info = $self->warp ;
        $self->{warper} = Config::Model::Warper->new (
            warped_object => $self,
            %$warp_info ,
            allowed => \@allowed_warp_params
        ) ;
    }

    $self->cl_init ;

    $logger->info("Created check_list element ".$self->element_name);
    return $self ;
}

sub cl_init {
    my $self = shift ;

    $self->warp if ($self->{warp});

    if (defined $self->{ref_object} ) {
	my $level = $self->parent
	  -> get_element_property(element => $self->{element_name},
				  property => 'level',
				 ) ;
	$self->{ref_object}->get_choice_from_refered_to if $level ne 'hidden';
    }
}

sub name {
    my $self = shift ;
    my $name =  $self->{parent}->name . ' '.$self->{element_name} ;
    return $name ;
}

sub value_type { return 'check_list' ;} 


# accessor to get some fields through methods (See man perltootc)
foreach my $datum (@accessible_params, @introspect_params ) {
    no strict "refs";       # to register new methods in package
    *$datum = sub {
	my $self= shift;
	return $self->{$datum};
    } ;
}



# warning : call to 'set' are not cumulative. Default value are always
# restored. Lest keeping track of what was modified with 'set' is
# too hard for the user.
sub set_properties {
    my $self = shift ;

    # cleanup all parameters that are handled by warp
    map(delete $self->{$_}, @allowed_warp_params ) ;

    if ($logger->is_debug()) {
      my %h = @_;
      my $keys = join(',',keys %h) ;
      $logger->debug("set_properties called on $self->{element_name} with $keys");
    }

    # merge data passed to the constructor with data passed to set
    my %args = (%{$self->{backup}},@_ );

    # these are handled by Node or Warper
    map { delete $args{$_} } qw/level experience/ ;

    $self->{ordered} = delete $args{ordered} || 0 ;

    if (defined $args{choice}) {
	my @choice = @{ delete $args{choice} } ;
	$self->{default_choice} = \@choice ;
	$self->setup_choice( @choice ) ;
    }

    if (defined $args{default}) {
	warn $self->name,": default param is deprecated, use default_list\n";
	$args{default_list} = delete $args{default} ;
    }

    if (defined $args{default_list}) {
	$self->{default_list} = delete $args{default_list} ;
    }

    # store default data in a hash (more convenient)
    $self->{default_data} = { map { $_ => 1 } @{$self->{default_list}} } ;

    if (defined $args{upstream_default_list}) {
	$self->{upstream_default_list} = delete $args{upstream_default_list} ;
    }

    # store upstream default data in a hash (more convenient)
    $self->{upstream_default_data} = 
      { map { $_ => 1 } @{$self->{upstream_default_list}} } ;

    Config::Model::Exception::Model
	-> throw (
		  object => $self,
		  error => "Unexpected parameters :".join(' ', keys %args )
		 ) 
	  if scalar keys %args ;
}

sub setup_choice {
    my $self = shift ;
    my @choice = ref $_[0] ? @{$_[0]} : @_ ;

    $logger->debug("CheckList $self->{element_name}: setup_choice with @choice");
    # store all enum values in a hash. This way, checking
    # whether a value is present in the enum set is easier
    delete $self->{choice_hash} if defined $self->{choice_hash} ;
    map {$self->{choice_hash}{$_} =  1;} @choice ;

    $self->{choice}  = \@choice ;

    # cleanup current preset and data if it does not fit current choices
    foreach my $field (qw/preset data layered/) {
	next unless defined $self->{$field} ; # do not create if not present
	foreach my $item (keys %{$self->{$field}}) {
	    delete $self->{$field}{$item} unless defined $self->{choice_hash}{$item} ;
	}
    }
}

# Need to extract Config::Model::Reference (used by Value, and maybe AnyId).


sub submit_to_refer_to {
    my $self = shift ;

    if (defined $self->{refer_to}) {
	$self->{ref_object} = Config::Model::IdElementReference 
	  -> new ( refer_to   => $self->{refer_to} ,
		   config_elt => $self,
		 ) ;
    }
    elsif (defined $self->{computed_refer_to}) {
	$self->{ref_object} = Config::Model::IdElementReference 
	  -> new ( computed_refer_to => $self->{computed_refer_to} ,
		   config_elt => $self,
		 ) ;
        my $var = $self->{computed_refer_to}{variables} ;

	# refer_to registration is done for all element that are used as
	# variable for complex reference (ie '- $foo' , {foo => '- bar'} )
        foreach my $path (values %$var) {
            # is ref during test case
            #print "path is '$path'\n";
            next if $path =~ /\$/ ; # next if path also contain a variable
            my $master = $self->grab($path);
            next unless $master->can('register_dependency');
            $master->register_dependency($self) ;
        }
    }
    else {
	croak "checklist submit_to_refer_to: undefined refer_to or computed_refer_to" ;
    }
}

sub setup_reference_choice {
    my $self = shift ;
    $self->setup_choice(@_) ;
}



sub get_type {
    my $self = shift;
    return 'check_list' ;
}


sub get_cargo_type { goto &cargo_type } 

sub cargo_type {
    my $self = shift ;
    return 'leaf' ;
}


sub check {
    my $self = shift ;
    my @list = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_ ;
    my %args = ref $_[0] eq 'ARRAY' ? @_[1,$#_] : (check => 'yes') ;
    my $check = $self->_check_check ($args{check}) ;
    
    if (defined $self->{ref_object}) {
	$self->{ref_object}->get_choice_from_refered_to ;
    }

    map {$self->store($_ , 1, $check ) } @list ;
}

# internal
sub store {
    my ($self, $choice, $value, $check) = @_;

    my $inst = $self->instance ;

    if ($value != 0 and $value != 1) {
        Config::Model::Exception::WrongValue 
	    -> throw ( error => "store: check item value must be boolean, "
		              . "not '$value'.",
		       object => $self) ;
	return ;
    }

    my $ok = $self->{choice_hash}{$choice} || 0 ;

    if ($ok ) {
	if ($inst->preset) {
	    $self->{preset}{$choice} = $value ;
	}
	elsif ($inst->layered) {
	    $self->{layered}{$choice} = $value ;
	}
	else {
	    $self->{data}{$choice} = $value ;
	}
	if ($self->{ordered} and $value) {
	    my $ord = $self->{ordered_data} ;
	    push @$ord,$choice unless scalar grep {$choice eq $_} @$ord ;
	}
    }
    elsif ($check eq 'yes')  {
	my $err_str = "Unknown check_list item '$choice'. Expected '"
                    . join("', '",@{$self->{choice}}) . "'" ;
	$err_str .= "\n\t". $self->{ref_object}->reference_info 
	  if defined $self->{ref_object};
        Config::Model::Exception::WrongValue 
	    -> throw ( error =>  $err_str , object => $self) ;
    }
}


sub uncheck {
    my $self = shift ;
    my @list = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_ ;
    my %args = ref $_[0] eq 'ARRAY' ? @_[1,$#_] : (check => 'yes') ;
    my $check = $self->_check_check ($args{check}) ;

    if (defined $self->{ref_object}) {
	$self->{ref_object}->get_choice_from_refered_to ;
    }

    map {$self->store($_ , 0 , $check) } @list ;
}


my %accept_mode = map { ( $_ => 1) } 
                      qw/custom standard preset default layered upstream_default/;


sub is_checked {
    my $self = shift ;
    my $choice = shift ;
    my %args = @_ ;
    my $type = $args{mode} || '';
    my $check = $self->_check_check($args{check}) ;

    my $ok = $self->{choice_hash}{$choice} || 0 ;

    if ($ok ) {

	if ($type and not defined $accept_mode{$type}) {
	    croak "is_checked: expected ", join (' or ',keys %accept_mode),
	      "parameter, not $type" ;
	}

	my $dat = $self->{data} ;
	my $pre = $self->{preset} ;
	my $def = $self->{default_data} ;
	my $ud  = $self->{upstream_default_data} ;
	my $std_v = (defined $pre->{$choice} ? $pre->{$choice} : $def->{$choice}) || 0 ;

	my $result 
	  = $type eq 'custom'           ? ( $dat->{$choice} && ! $std_v ? 1 : 0 )
          : $type eq 'preset'           ? $pre->{$choice}
          : $type eq 'layered'          ? $self->{layered}{$choice}
          : $type eq 'upstream_default' ? $ud ->{$choice}
          : $type eq 'default'          ? $def->{$choice}
          : $type eq 'standard'         ? $std_v
          : defined $dat->{$choice}     ? $dat->{$choice}
          :                               $std_v ;

	return $result ;
    }
    elsif ($check eq 'yes')  {
	my $err_str = "Unknown check_list item '$choice'. Expected '"
                    . join("', '",@{$self->{choice}}) . "'" ;
	$err_str .= "\n\t". $self->{ref_object}->reference_info 
	  if defined $self->{ref_object};
        Config::Model::Exception::WrongValue 
	    -> throw ( error =>  $err_str ,
		       object => $self) ;
    }
}


# get_choice is always called when using check_list, so having a
# warp safety check here makes sense

sub get_choice {
    my $self = shift ;

    if (defined $self->{ref_object}) {
	$self->{ref_object}->get_choice_from_refered_to ;
    }

    if (not defined $self->{choice}) {
        my $msg = "check_list element has no defined choice. " . 
	  $self->warp_error;
	Config::Model::Exception::UnavailableElement
	    -> throw (
		      info => $msg,
		      object => $self->parent,
		      element => $self->element_name,
		     ) ;
    }

    return @{ $self->{choice} } ;
}

sub get_default_choice {
    my $self = shift ;
    return @{$self->{default_choice} || [] } ;
}

sub get_builtin_choice {
    carp "get_builtin_choice is deprecated, use get_upstream_default_choice";
    goto &get_upstream_default_choice ;
}

sub get_upstream_default_choice {
    my $self = shift ;
    return @{$self->{upstream_default_data} || [] } ;
}


sub get_help {
    my $self = shift ;
    my $help = $self->{help} ;

    return $help unless @_ ;

    my $on_value = shift ;
    return $help->{$on_value} if defined $help and defined $on_value ;

    return ;
}


sub clear {
    my $self = shift ;
    map { $self->store($_ , 0 ) } $self->get_choice ;
}

sub clear_values { goto &clear ; } 


my %old_mode = ( built_in_list => 'upstream_default_list',
	       );

sub get_checked_list_as_hash {
    my $self = shift ;
    my %args = @_ > 1 ? @_ : (mode => $_[0]) ;
    my $mode = $args{mode}|| '';

    foreach my $k (keys %old_mode) {
	next unless $mode eq $k;
	$mode = $old_mode{$k} ;
	carp $self->location," warning: deprecated mode parameter: $k, ",
	    "expected $mode\n";
    }

    if ($mode and not defined $accept_mode{$mode}) {
	croak "get_checked_list_as_hash: expected ", 
	    join (' or ',keys %accept_mode),
		" parameter, not $mode" ;
    }

    # fill empty hash result missing data
    my %h = map { $_ => 0 } $self->get_choice ;

    my $dat = $self->{data} ;
    my $pre = $self->{preset} ;
    my $def = $self->{default_data} ;
    my $lay = $self->{layered} ;
    my $ud  = $self->{upstream_default_data} ;

    # copy hash and return it
    my %std = (%h, %$ud, %$lay, %$def, %$pre ) ;

    # custom test must compare the whole list at once, not just one item at a time.
    my %result 
      = $mode eq 'custom'   ? ( ( grep { $dat->{$_} xor $std{$_} } keys %h ) ? (%h, %$pre ,%$dat) : %h )
      : $mode eq 'preset'   ? (%h, %$pre )
      : $mode eq 'layered'  ? (%h, %$lay )
      : $mode eq 'upstream_default' ? (%h, %$ud) 
      : $mode eq 'default'          ? (%h, %$def )
      : $mode eq 'standard' ? %std
      :                       (%h, %$def, %$pre, %$dat );

    return wantarray ? %result : \%result;
}


sub get_checked_list {
    my $self = shift ;

    my %h = $self->get_checked_list_as_hash(@_) ;
    my @good_order = $self->{ordered} ? @{$self->{ordered_data}} : sort keys %h ;
    my @res = grep { $h{$_} } @good_order ;
    return wantarray ? @res : \@res ;
}


sub fetch {
    my $self = shift ;
    return join (',', $self->get_checked_list(@_));
}

sub fetch_custom {
    my $self = shift ;
    return join (',', $self->get_checked_list('custom'));
}

sub fetch_preset {
    my $self = shift ;
    return join (',', $self->get_checked_list('preset'));
}

sub fetch_layered {
    my $self = shift ;
    return join (',', $self->get_checked_list('layered'));
}

sub get {
    my $self = shift ;
    my $path = shift ;
    if ($path) {
	Config::Model::Exception::User
	    -> throw (
		      object => $self,
		      message => "get() called with a value with non-empty path: '$path'"
		     ) ;
    }
    return $self->fetch(@_) ;
}


sub set {
    my $self = shift ;
    my $path = shift ;
    my $list = shift ;

    if ($path) {
	Config::Model::Exception::User
	    -> throw (
		      object => $self,
		      message => "set() called with a value with non-empty path: '$path'"
		     ) ;
    }

    return $self->set_checked_list(split /,/,$list) ;
}

sub load {
    my ($self,$string) = @_ ;
    my @set = split /,/,$string;
    foreach (@set) { s/^"|"$//g; s/\\"/"/g ;}
    $self->set_checked_list(@set) ;
}


sub store_set { goto &set_checked_list } 

sub set_checked_list {
    my $self = shift ;
    $logger->debug("called with @_");
    $self->clear ;
    $self->{ordered_data} = [ @_ ] ; # copy list
    $self->check (@_) ;
}


sub set_checked_list_as_hash {
    my $self = shift ;
    my %check = ref $_[0] ? %{$_[0]} : @_ ;

    $self->clear ; 

    if (defined $self->{ref_object}) {
	$self->{ref_object}->get_choice_from_refered_to ;
    }

    while (my ($key, $value) = each %check) {
	$self->store($key,$value) ;
    }
}


sub load_data {
    my $self = shift ;
    my $data  = shift ;

    if (ref ($data)  eq 'ARRAY') {
	$self->set_checked_list(@$data) ;
    }
    else {
	Config::Model::Exception::LoadData
	    -> throw (
		      object => $self,
		      message => "load_data called with non array ref arg",
		      wrong_data => $data ,
		     ) ;
    }
}


sub swap {
    my ($self,$a,$b) = @_ ;

    foreach my $param ($a,$b) {
	unless ($self->is_checked($param)) {
	    my $err_str = "swap: choice $param must be set";
	    Config::Model::Exception::WrongValue 
		-> throw ( error =>  $err_str ,
			   object => $self) ;
	}
    }

    # perform swap in ordered list
    foreach (@{$self->{ordered_data}}) {
	if ($_ eq $a) {
	    $_ = $b ;
	}
	elsif ($_ eq $b) {
	    $_ = $a ;
	}
    }
}


sub move_up {
    my ($self,$c) = @_ ;

    unless ($self->is_checked($c)) {
	my $err_str = "swap: choice $c must be set";
	Config::Model::Exception::WrongValue 
	    -> throw ( error =>  $err_str ,
		       object => $self) ;
    }

    # perform move in ordered list
    my $list = $self->{ordered_data} ;
    for (my $i = 1 ; $i < @$list; $i++) {
	if ($list->[$i] eq $c ) {
	    $list->[$i] = $list->[$i - 1 ];
	    $list->[$i - 1] = $c ;
	    last;
	}
    }
}


sub move_down {
    my ($self,$c) = @_ ;

    unless ($self->is_checked($c)) {
	my $err_str = "swap: choice $c must be set";
	Config::Model::Exception::WrongValue 
	    -> throw ( error =>  $err_str ,
		       object => $self) ;
    }

    # perform move in ordered list
    my $list = $self->{ordered_data} ;
    for (my $i = 0 ; $i + 1 < @$list; $i++) {
	if ($list->[$i] eq $c ) {
	    $list->[$i] = $list->[$i + 1 ];
	    $list->[$i + 1] = $c ;
	    last;
	}
    }
}

# dummy to match Value call
sub warning_msg { '' } 

1;

__END__


=pod

=head1 NAME

Config::Model::CheckList - Handle check list element

=head1 SYNOPSIS

 use Config::Model;
 use Log::Log4perl qw(:easy);
 Log::Log4perl->easy_init($WARN);

 # define configuration tree object
 my $model = Config::Model->new;
 $model->create_config_class(
    name => "MyClass",

    element => [

        # type check_list will use Config::Model::CheckList
        my_check_list => {
            type   => 'check_list',
            choice => [ 'A', 'B', 'C', 'D' ],
            help   => {
                A => 'A effect is this',
                D => 'D does that',
            }
        },
    ],
 );

 my $inst = $model->instance( root_class_name => 'MyClass' );

 my $root = $inst->config_root;

 # put data
 $root->load( step => 'my_check_list=A' ); 

 my $obj = $root->grab('my_check_list');

 my $v = $root->grab_value('my_check_list');
 print "check_list value '$v' with help '", $obj->get_help($v), "'\n";

 # more data
 $obj->check('D');
 $v = $root->grab_value('my_check_list');
 print "check_list new value is '$v'\n";   # prints check_list new value is 'A,D'

=head1 DESCRIPTION

This class provides a check list element for a L<Config::Model::Node>.
In other words, this class provides a list of booleans items. Each item
can be set to 1 or 0.

The available items in the check list can be :

=over

=item * 

A fixed list (with the C<choice> parameter)

=item *

A dynamic list where the available choice are the keys of another hash
of the configuration tree. See L</"Choice reference"> for details.

=back

=head1 CONSTRUCTOR

CheckList object should not be created directly.

=head1 CheckList model declaration

A check list element must be declared with the following parameters:

=over

=item type

Always C<checklist>.

=item choice

A list ref containing the check list items (optional)

=item refer_to

This parameter is used when the keys of a hash are used to specify the
possible choices of the check list. C<refer_to> point to a hash or list
element in the configuration tree. See L<Choice reference> for
details. (optional)

=item computed_refer_to

Like C<refer_to>, but use a computed value to find the hash or list
element in the configuration tree. See L<Choice reference> for
details. (optional)

=item default_list

List ref to specify the check list items which are "on" by default.
(optional)

=item ordered

Specify whether the order of checked items must be preserved. 

=item help

Hash ref to provide information on the check list items.

=item warp

Used to provide dynamic modifications of the check list properties
See L<Config::Model::WarpedThing> for details

=back

For example:

=over

=item *

A simple check list with help:

       choice_list
       => { type => 'check_list',
            choice     => ['A' .. 'Z'],
            help => { A => 'A help', E => 'E help' } ,
          },

=item *

A check list with default values:

       choice_list_with_default
       => { type => 'check_list',
            choice     => ['A' .. 'Z'],
            default_list   => [ 'A', 'D' ],
          },

=item *

A check list whose available choice and default change depending on
the value of the C<macro> parameter:

       'warped_choice_list'
       => { type => 'check_list',
            warp => { follow => '- macro',
                      rules  => { AD => { choice => [ 'A' .. 'D' ], 
                                          default_list => ['A', 'B' ] },
                                  AH => { choice => [ 'A' .. 'H' ] },
                                }
                    }
          },

=back

=head1 Introspection methods

The following methods returns the checklist parameter :

=over

=item refer_to

=item computed_refer_to

=back

=head1 Choice reference

The choice items of a check_list can be given by another configuration
element. This other element can be:

=over

=item *

The keys of a hash

=item *

Another checklist. In this case only the checked items of the other
checklist will be available.

=back

This other hash or other checklist is indicated by the C<refer_to> or
C<computed_refer_to> parameter. C<refer_to> uses the syntax of the
C<step> parameter of L<grab(...)|Config::AnyThing/"grab(...)">

See L<refer_to parameter|Config::Model::IdElementReference/"refer_to parameter">.

=head2 Reference examples

=over

=item *

A check list where the available choices are the keys of C<my_hash>
configuration parameter:

       refer_to_list
       => { type => 'check_list',
            refer_to => '- my_hash'
          },

=item *

A check list where the available choices are the checked items of
C<other_check_list> configuration parameter:

       other_check_list => { type => 'check_list', 
                             choice => [qw/A B C/]
                           },
       refer_to_list
       => { type => 'check_list',
            refer_to => '- other_check_list'
          },

=item *

A check list where the available choices are the keys of C<my_hash>
and C<my_hash2> and C<my_hash3> configuration parameter:


       refer_to_3_lists
       => { type => 'check_list',
            refer_to => '- my_hash + - my_hash2   + - my_hash3'
          },

=item *

A check list where the available choices are the specified choice and
the choice of C<refer_to_3_lists> and a hash whose name is specified
by the value of the C<indirection> configuration parameter (this
example is admittedly convoluted):


       refer_to_check_list_and_choice
       => { type => 'check_list',
            computed_refer_to => { formula => '- refer_to_2_list + - $var',
                                   variables { 'var' => '- indirection ' }
                                 },
            choice  => [qw/A1 A2 A3/],
          },

=back

=head1 Methods

=head2 get_type

Returns C<check_list>.

=head2 cargo_type()

Returns 'leaf'.

=head2 check ( ... )

Set choice. Parameter is either a list of choices to set or 
a list ref and some optional parameter. I.e:

  check (\@list, check => 'skip') ;

C<check> parameter decide on behavior in case of invalid
choice value: either die (if yes) or discard bad value (if skip)

=head2 uncheck (...)

Unset choice. Parameter is either a list of choices to unset or 
a list ref and some optional parameter. I.e:

  uncheck (\@list, check => 'skip') ;

C<check> parameter decide on behavior in case of invalid
choice value: either die (if yes) or discard bad value (if skip)

=head2 is_checked( choice, [ check => yes|skip ] , [ mode => ... ])

Return 1 if the given C<choice> was set. Returns 0 otherwise.

C<check> parameter decide on behavior in case of invalid
choice value: either die (if yes) or discard bad value (if skip)

C<mode> is either: custom standard preset default layered upstream_default

=head2 get_choice

Returns an array of all items names that can be checked (i.e.
that can have value 0 or 1).

=head2 get_help (choice_value)

Return the help string on this choice value

=head2 clear

Reset the check list (all items are set to 0) (can also be called as
C<clear_values>)

=head2 get_checked_list_as_hash ( [ custom | preset | standard | default ] )

Returns a hash (or a hash ref) of all items. The boolean value is the
value of the hash.

Example:

 { A => 0, B => 1, C => 0 , D => 1}


By default, this method will return all items set by the user, or
items set in preset mode or checked by default.

With a parameter, this method will return either:

=over

=item custom

The list entered by the user

=item preset

The list entered in preset mode

=item standard

The list set in preset mode or checked by default.

=item default

The default list (defined by the configuration model)

=item layered

The list specified in layered mode. 

=item upstream_default

The list implemented by upstream project (defined in the configuration
model)

=back

=head2 get_checked_list ( < mode >  )

Returns a list (or a list ref) of all checked items (i.e. all items
set to 1). 

=head2 fetch ( < mode > )

Returns a string listing the checked items (i.e. "A,B,C")

=head2 get( path  [, < mode> ] )

Get a value from a directory like path.

=head2 set( path , values )

Set a checklist with a directory like path. Since a checklist is a leaf, the path
should be empty. The values are a comma separated list of checked items.

Example : C<< $leaf->set('','A,C,Z') ; >>

=head2 set_checked_list ( item1, item2, ..)

Set all passed items to checked (1). All other available items
in the check list are set to 0.

Example:

  # set cl to A=0 B=1 C=0 D=1
  $cl->set_checked_list('B','D')

=head2 set_checked_list_as_hash ( A => 1, B => 1 )

Set check_list items. Missing items in the given list of parameters
are set to 0.

The example ( A => 1, B => 1 ) above will give :

 A = 1 , B = 1, C = 0 , D = 0

=head2 load_data ( list_ref )

Load check_list as an array ref. Data is simply forwarded to
L<set_checked_list>.

=head1 Ordered checklist methods

All the methods below are valid only for ordered checklists.

=head1 swap ( choice_a, choice_b)

Swap the 2 given choice in the list. Both choice must be already set.

=head1 move_up ( choice )

Move the choice up in the checklist. 

=head1 move_down ( choice )

Move the choice down in the checklist. 

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::Node>, 
L<Config::Model::AnyId>,
L<Config::Model::ListId>,
L<Config::Model::HashId>,
L<Config::Model::Value>

=cut
