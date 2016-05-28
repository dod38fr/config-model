package Config::Model;

use strict ;
use warnings;
use 5.10.1;

use Mouse;
use Mouse::Util::TypeConstraints;
use MouseX::StrictConstructor;

use Carp;
use Storable ('dclone');
use Data::Dumper ();
use Log::Log4perl 1.11 qw(get_logger :levels);
use Config::Model::Instance;
use Hash::Merge 0.12 qw/merge/;
use File::Path qw/make_path/;

use Cwd;
use Config::Model::Lister;

use parent qw/Exporter/;
our @EXPORT_OK = qw/cme/;

# this class holds the version number of the package
use vars qw(@status @level %default_property);

my $legacy_logger = get_logger("Model::Legacy") ;
my $logger = get_logger("Model") ;

# used to keep one Config::Model object to simplify programs based on
# cme function
my $model_storage;

%default_property = (
    status      => 'standard',
    level       => 'normal',
    summary     => '',
    description => '',
);

enum LegacyTreament => qw/die warn ignore/;

has skip_include => ( isa => 'Bool',           is => 'ro', default => 0 );
has model_dir    => ( isa => 'Str',            is => 'ro', default => 'Config/Model/models' );
has legacy       => ( isa => 'LegacyTreament', is => 'ro', default => 'warn' );
has instances => ( isa => 'HashRef[Config::Model::Instance]', is => 'ro', default => sub { {} } );

# Config::Model stores 3 versions of each model

# raw_model is the model exactly as passed by the user. Since the format is quite
# liberal (e.g legacy parameters, grouped declaration of elements like '[qw/foo bar/] => {}}',
# element description in class or in element declaration)), this raw format is not
# usable without normalization (done by normalize_class_parameters)

has raw_models => (
    isa     => 'HashRef',
    is      => 'ro',
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        raw_model_exists  => 'exists',
        raw_model_defined => 'defined',
        raw_model         => 'get',
        store_raw_model   => 'set',
        raw_model_names   => 'keys',
    },
);

sub get_raw_model {
    my $self = shift;
    return $self->raw_model(@_);
}

# the result of normalization is stored here. Normalized model aggregate user models and
# augmented features (the one found in Foo.d directory). inclusion of other class is NOT
# yet done. normalized_models are created while loading files (load method) or creating
# configuration classes (create_config_class)
has normalized_models => (
    isa     => 'HashRef',
    is      => 'ro',
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        normalized_model_exists  => 'exists',
        normalized_model_defined => 'defined',
        normalized_model         => 'get',
        store_normalized_model   => 'set',
        normalized_model_names   => 'keys',
    },
);

# This attribute contain the model that will be used by Config::Model::Node. They
# are created on demand when get_model is called. When created the inclusion of
# other classes is done according to the class 'include' parameter. Note that get_model
# will try to call load if the required normalized_model is not known (lazy loading)
has models => (
    isa     => 'HashRef',
    is      => 'ro',
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        model_exists  => 'exists',
        model_defined => 'defined',
        model         => 'get',
        _store_model  => 'set',
    },
);

has skip_inheritance => (
    isa     => 'Bool',
    is      => 'ro',
    default => 0,
    trigger => sub {
        my $self = shift;
        $self->show_legacy_issue("skip_inheritance is deprecated, use skip_include");
        $self->skip_include = $self->skip_inheritance;
    } );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my %args = @_;
    my %new = map { defined $args{$_} ? ( $_ => $args{$_} ) : () } keys %args;

    return $class->$orig(%new);
};

# keep this as a separate sub from BUILD. So user can call it before
# creating Config::Model object
sub initialize_log4perl {
    my $log4perl_syst_conf_file = '/etc/log4config-model.conf';
    my $log4perl_user_conf_file = $ENV{HOME} . '/.log4config-model';

    my $fallback_conf           = << 'EOC';
log4perl.logger=WARN, Screen
log4perl.appender.Screen        = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr = 0
log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %m %n
EOC

    my $log4perl_conf =
        -e $log4perl_user_conf_file ? $log4perl_user_conf_file
      : -e $log4perl_syst_conf_file ? $log4perl_syst_conf_file
      :                               \$fallback_conf;

    Log::Log4perl::init_once($log4perl_conf);

}

sub BUILD {
    my $self = shift;
    $self->initialize_log4perl ;
}

sub show_legacy_issue {
    my $self     = shift;
    my $behavior = $self->legacy;

    if ( $behavior eq 'die' ) {
        die @_, "\n";
    }
    elsif ( $behavior eq 'warn' ) {
        warn @_, "\n";
    }
}

sub _tweak_instance_args {
    my ($args) = @_  ;

    my $application = $args->{application} ;
    my $cat = '';
    if (defined $application) {
        my ( $categories, $appli_info, $appli_map ) = Config::Model::Lister::available_models;
        $args->{root_class_name} ||= $appli_map->{$application} ;
        $cat = $appli_info->{_category} //  ''; # may be empty in tests
    }

    my $app_name = $application;
    if ($cat eq 'application') {
        # store dir in name to distinguish different runs of the same
        # app in different directories.
        $application .= " in " . cwd;
    }
    $args->{name}
        =  delete $args->{instance_name}
        || delete $args->{name}
        || $app_name
        || 'default';
}

sub cme {
    my %args = @_ == 1 ? ( application => $_[0]) : @_ ;

    my $cat =_tweak_instance_args(\%args);

    my $m_args = delete $args{model_args} // {} ; # used for tests
    # model_storage is used to keep Config::Model object alive
    $model_storage //= Config::Model->new(%$m_args);

    my $app = $args{application};
    return $model_storage->instance(@_);
}

sub instance {
    my $self = shift;
    my %args = @_ == 1 ? ( application => $_[0]) : @_ ;

    _tweak_instance_args(\%args);

    croak "Model: can't create instance without application or root_class_name "
        unless $args{root_class_name};

    my $instance_name = $args{name};
    # could add more syntactic suger with 'hash' trait
    # see Moose::Meta::Attribute::Native
    if ( defined $self->instances->{$instance_name} ) {
        return $self->instances->{$instance_name};
    }

    if ( defined $args{model_file} ) {
        my $file = delete $args{model_file};
        $self->load( $args{root_class_name}, $file );
    }

    my $i = Config::Model::Instance->new(
        config_model    => $self,
        %args    # for optional parameters like *directory
    );

    $self->instances->{$instance_name} = $i;
    return $i;
}

sub instance_names {
    my $self = shift;
    return sort keys %{ $self->instances };
}

@level = qw/hidden normal important/;

@status = qw/obsolete deprecated standard/;

# unpacked model is:
# {
#   element_list  => [ ... ],
#   element       => { element_name => element_data (left as is)    },
#   class_description => <class description string>,
#   include       => 'class_name',
#   include_after => 'element_name',
# }
# description, summary, level, status are moved
# into element description.

my @legal_params_to_move = (
    qw/read_config  read_config_dir
       write_config write_config_dir/,    # read/write stuff

    # this parameter is filled by class generated by a program. It may
    # be used to avoid interactive edition of a generated model
    'generated_by',
    qw/class_description author copyright license include include_after include_backend class/
);

my @other_legal_params = qw/ author element status description summary level accept/;

# keep as external API. All internal call go through _store_model
#  See comments around raw_models attribute for explanations
sub create_config_class {
    my $self      = shift;
    my %raw_model = @_;

    my $config_class_name = delete $raw_model{name}
        or croak "create_config_class: no config class name";

    get_logger("Model")->info("Creating class $config_class_name");

    if ( $self->model_exists($config_class_name) ) {
        Config::Model::Exception::ModelDeclaration->throw(
            error => "create_config_class: attempt to clobber $config_class_name"
                . " config class name " );
    }

    $self->store_raw_model( $config_class_name, dclone( \%raw_model ) );

    my $model = $self->normalize_class_parameters( $config_class_name, \%raw_model );

    $self->store_normalized_model( $config_class_name, $model );

    return $config_class_name;
}

sub merge_included_class {
    my ( $self, $config_class_name ) = @_;

    my $normalized_model = $self->normalized_model($config_class_name);
    my $model            = dclone $normalized_model ;

    # add included elements
    if ( $self->skip_include and defined $normalized_model->{include} ) {
        my $inc = $normalized_model->{include};
        $model->{include} = ref $inc ? $inc : [$inc];
        $model->{include_after} = $normalized_model->{include_after}
            if defined $normalized_model->{include_after};
    }
    else {
        # include class in raw_copy, normalized_model is left as is
        $self->include_class( $config_class_name, $model );
    }

    # add included backend
    if ( $self->skip_include and defined $normalized_model->{include_backend} ) {
        my $inc = $normalized_model->{include_backend};
        $model->{include_backend} = ref $inc ? $inc : [$inc];
    }
    else {
        # include read/write config specifications in raw_copy,
        # normalized_model is left as is
        $self->include_backend( $config_class_name, $model );
    }

    return $model;
}

sub include_backend {
    my $self         = shift;
    my $class_name   = shift || croak "include_backend: undef includer";
    my $target_model = shift || die "include_backend:: undefined target_model";

    my $included_classes = delete $target_model->{include_backend};
    return () unless defined $included_classes;

    foreach my $included_class (@$included_classes) {
        # takes care of recursive include, because get_model will perform
        # includes (and normalization). Is already a dclone
        my $included_model = $self->get_model($included_class);

        foreach my $rw (qw/read_config write_config config_dir/) {
            if ($target_model->{$rw} and $included_model->{$rw}) {
                my $msg = "Included $rw from $included_class cannot clobber "
                    . "existing data in $class_name";
                Config::Model::Exception::ModelDeclaration->throw( error => $msg );
            }
            elsif ($included_model->{$rw}) {
                $target_model->{$rw} = $included_model->{$rw};
            }
        }
    }
}

sub normalize_class_parameters {
    my $self              = shift;
    my $config_class_name = shift || die;
    my $normalized_model  = shift || die;

    my $model = {};

    # sanity check
    my $raw_name = delete $normalized_model->{name};
    if ( defined $raw_name and $config_class_name ne $raw_name ) {
        my $e = "internal: config_class_name $config_class_name ne model name $raw_name";
        Config::Model::Exception::ModelDeclaration->throw( error => $e );
    }

    my @element_list;

    # first construct the element list
    my @compact_list = @{ $normalized_model->{element} || [] };
    while (@compact_list) {
        my ( $item, $info ) = splice @compact_list, 0, 2;

        # store the order of element as declared in 'element'
        push @element_list, ref($item) ? @$item : ($item);
    }

    # optional parameter to force element order. Useful when parameters declarations
    # are grouped. Although interaction with include may be tricky. Let's not advertise it.
    # yet.

    if ( defined $normalized_model->{force_element_order} ) {
        my @forced_list = @{ delete $normalized_model->{force_element_order} };
        my %forced = map { ( $_ => 1 ) } @forced_list;
        foreach (@element_list) {
            next if delete $forced{$_};
            Config::Model::Exception::ModelDeclaration->throw( error =>
                    "class $config_class_name: element $_ is not in force_element_order list" );
        }
        if (%forced) {
            Config::Model::Exception::ModelDeclaration->throw(
                error => "class $config_class_name: force_element_order list has unknown elements "
                    . join( ' ', keys %forced ) );
        }
    }

    if ( defined $normalized_model->{inherit_after} ) {
        $self->show_legacy_issue( "Model $config_class_name: inherit_after is deprecated ",
            "in favor of include_after" );
        $normalized_model->{include_after} = delete $normalized_model->{inherit_after};
    }
    if ( defined $normalized_model->{inherit} ) {
        $self->show_legacy_issue(
            "Model $config_class_name: inherit is deprecated in favor of include");
        $normalized_model->{include} = delete $normalized_model->{inherit};
    }

    # get data read/write information (if any)
    $model->{read_config_dir} = $model->{write_config_dir} = delete $normalized_model->{config_dir}
        if defined $normalized_model->{config_dir};

    foreach my $info (@legal_params_to_move) {
        next unless defined $normalized_model->{$info};
        $model->{$info} = delete $normalized_model->{$info};
    }

    # handle accept parameter
    my @accept_list;
    my %accept_hash;
    my $accept_info = delete $normalized_model->{'accept'} || [];
    while (@$accept_info) {
        my $name_match = shift @$accept_info;    # should be a regexp

        # handle legacy
        if ( ref $name_match ) {
            my $implicit = defined $name_match->{name_match} ? '' : 'implicit ';
            unshift @$accept_info, $name_match;    # put data back in list
            $name_match = delete $name_match->{name_match} || '.*';
            warn "class $config_class_name: name_match ($implicit$name_match)",
                " in accept is deprecated\n";
        }

        push @accept_list, $name_match;
        $accept_hash{$name_match} = shift @$accept_info;
    }

    $model->{accept}      = \%accept_hash;
    $model->{accept_list} = \@accept_list;

    # check for duplicate in @element_list.
    my %check_list;
    map { $check_list{$_}++ } @element_list;
    my @extra = grep { $check_list{$_} > 1 } keys %check_list;
    if (@extra) {
        Config::Model::Exception::ModelDeclaration->throw(
            error => "class $config_class_name: @extra element "
                . "is declared more than once. Check the included parts" );
    }

    $self->handle_experience_permission( $config_class_name, $normalized_model );

    # element is handled first
    foreach my $info_name (qw/element status description summary level/) {
        my $raw_compact_info = delete $normalized_model->{$info_name};

        next unless defined $raw_compact_info;

        Config::Model::Exception::ModelDeclaration->throw(
            error => "Data for parameter $info_name of $config_class_name"
                . " is not an array ref" )
            unless ref($raw_compact_info) eq 'ARRAY';

        my @raw_info = @$raw_compact_info;
        while (@raw_info) {
            my ( $item, $info ) = splice @raw_info, 0, 2;
            my @element_names = ref($item) ? @$item : ($item);

            # move element informations (handled first)
            if ( $info_name eq 'element' ) {

                # warp can be found only in element item
                $self->translate_legacy_info( $config_class_name, $element_names[0], $info );

                $self->handle_experience_permission( $config_class_name, $info );

                # copy in element data *after* legacy translation
                map { $model->{element}{$_} = dclone($info); } @element_names;
            }

            # move some information into element declaration (without clobberring)
            elsif ( $info_name =~ /description|level|summary|status/ ) {
                foreach (@element_names) {
                    Config::Model::Exception::ModelDeclaration->throw(
                        error => "create class $config_class_name: '$info_name' "
                            . "declaration for non declared element '$_'" )
                        unless defined $model->{element}{$_};

                    $model->{element}{$_}{$info_name} ||= $info;
                }
            }
            else {
                die "Unexpected element $item in $config_class_name model";
            }

        }
    }

    Config::Model::Exception::ModelDeclaration->throw(
              error => "create class $config_class_name: unexpected "
            . "parameters '"
            . join( ', ', sort keys %$normalized_model ) . "' "
            . "Expected '"
            . join( "', '", @legal_params_to_move, @other_legal_params )
            . "'" )
        if keys %$normalized_model;

    $model->{element_list} = \@element_list;

    return $model;
}

sub handle_experience_permission {
    my ( $self, $config_class_name, $model ) = @_;

    if (delete $model->{permission}) {
        die "$config_class_name: parameter permission is obsolete\n";
    }
    if (delete $model->{experience}) {
        carp "experience parameter is deprecated";
    }
}

sub translate_legacy_info {
    my $self              = shift;
    my $config_class_name = shift || die;
    my $elt_name          = shift;
    my $info              = shift;

    #translate legacy warp information
    if ( defined $info->{warp} ) {
        $self->translate_warp_info( $config_class_name, $elt_name, $info->{type}, $info->{warp} );
    }

    $self->translate_cargo_info( $config_class_name, $elt_name, $info );

    if (    defined $info->{cargo}
        and defined $info->{cargo}{warp} ) {
        $self->translate_warp_info(
            $config_class_name, $elt_name,
            $info->{cargo}{type},
            $info->{cargo}{warp} );
    }

    if (   defined $info->{cargo}
        && defined $info->{cargo}{type}
        && $info->{cargo}{type} eq 'warped_node' ) {
        $self->translate_warp_info( $config_class_name, $elt_name, 'warped_node', $info->{cargo} );
    }

    if ( defined $info->{type} && $info->{type} eq 'warped_node' ) {
        $self->translate_warp_info( $config_class_name, $elt_name, 'warped_node', $info );
    }

    # compute cannot be warped
    if ( defined $info->{compute} ) {
        $self->translate_compute_info( $config_class_name, $elt_name, $info, 'compute' );
        $self->translate_allow_compute_override( $config_class_name, $elt_name, $info );
    }
    if (    defined $info->{cargo}
        and defined $info->{cargo}{compute} ) {
        $self->translate_compute_info( $config_class_name, $elt_name, $info->{cargo}, 'compute' );
        $self->translate_allow_compute_override( $config_class_name, $elt_name, $info->{cargo} );
    }

    # refer_to cannot be warped
    if ( defined $info->{refer_to} ) {
        $self->translate_compute_info( $config_class_name, $elt_name, $info,
            refer_to => 'computed_refer_to' );
    }
    if (    defined $info->{cargo}
        and defined $info->{cargo}{refer_to} ) {
        $self->translate_compute_info( $config_class_name, $elt_name,
            $info->{cargo}, refer_to => 'computed_refer_to' );
    }

    # translate id default param
    # default cannot be stored in cargo since is applies to the id itself
    if ( defined $info->{type}
        and ( $info->{type} eq 'list' or $info->{type} eq 'hash' ) ) {
        if ( defined $info->{default} ) {
            $self->translate_id_default_info( $config_class_name, $elt_name, $info );
        }
        if ( defined $info->{auto_create} ) {
            $self->translate_id_auto_create( $config_class_name, $elt_name, $info );
        }
        $self->translate_id_min_max( $config_class_name, $elt_name, $info );
        $self->translate_id_names( $config_class_name, $elt_name, $info );
        if ( defined $info->{warp} ) {
            my $rules_a = $info->{warp}{rules};
            my %h       = @$rules_a;
            foreach my $rule_effect ( values %h ) {
                $self->translate_id_names( $config_class_name, $elt_name, $rule_effect );
                $self->translate_id_min_max( $config_class_name, $elt_name, $rule_effect );
                next unless defined $rule_effect->{default};
                $self->translate_id_default_info( $config_class_name, $elt_name, $rule_effect );
            }
        }
        $self->translate_id_class($config_class_name, $elt_name, $info );
    }

    if ( defined $info->{type} and ( $info->{type} eq 'leaf' ) ) {
        $self->translate_legacy_builtin( $config_class_name, $info, $info, );
    }

    if ( defined $info->{type} and ( $info->{type} eq 'check_list' ) ) {
        $self->translate_legacy_built_in_list( $config_class_name, $info, $info, );
    }

    $legacy_logger->debug(
        Data::Dumper->Dump( [$info], [ 'translated_' . $elt_name ] ) 
    ) if $legacy_logger->is_debug;
}

sub translate_cargo_info {
    my $self              = shift;
    my $config_class_name = shift;
    my $elt_name          = shift;
    my $info              = shift;

    my $c_type = delete $info->{cargo_type};
    return unless defined $c_type;
    $self->show_legacy_issue("$config_class_name->$elt_name: parameter cargo_type is deprecated.");
    my %cargo;

    if ( defined $info->{cargo_args} ) {
        %cargo = %{ delete $info->{cargo_args} };
        $self->show_legacy_issue(
            "$config_class_name->$elt_name: parameter cargo_args is deprecated.");
    }

    $cargo{type} = $c_type;

    if ( defined $info->{config_class_name} ) {
        $cargo{config_class_name} = delete $info->{config_class_name};
        $self->show_legacy_issue(
            "$config_class_name->$elt_name: parameter config_class_name is ",
            "deprecated. This one must be specified within cargo. ",
            "Ie. cargo=>{config_class_name => 'FooBar'}"
        );
    }

    $info->{cargo} = \%cargo;
    $legacy_logger->debug( 
        Data::Dumper->Dump( [$info], [ 'translated_' . $elt_name ] ) 
    ) if $legacy_logger->is_debug;
}

sub translate_id_names {
    my $self              = shift;
    my $config_class_name = shift;
    my $elt_name          = shift;
    my $info              = shift;
    $self->translate_name( $config_class_name, $elt_name, $info, 'allow',      'allow_keys' );
    $self->translate_name( $config_class_name, $elt_name, $info, 'allow_from', 'allow_keys_from' );
    $self->translate_name( $config_class_name, $elt_name, $info, 'follow',     'follow_keys_from' );
}

sub translate_name {
    my $self              = shift;
    my $config_class_name = shift;
    my $elt_name          = shift;
    my $info              = shift;
    my $from              = shift;
    my $to                = shift;

    if ( defined $info->{$from} ) {
        $self->show_legacy_issue(
            "$config_class_name->$elt_name: parameter $from is deprecated in favor of $to");
        $info->{$to} = delete $info->{$from};
    }
}

sub translate_allow_compute_override {
    my $self              = shift;
    my $config_class_name = shift;
    my $elt_name          = shift;
    my $info              = shift;

    if ( defined $info->{allow_compute_override} ) {
        $self->show_legacy_issue(
            "$config_class_name->$elt_name: parameter allow_compute_override is deprecated in favor of compute -> allow_override"
        );
        $info->{compute}{allow_override} = delete $info->{allow_compute_override};
    }
}

sub translate_compute_info {
    my $self              = shift;
    my $config_class_name = shift;
    my $elt_name          = shift;
    my $info              = shift;
    my $old_name          = shift;
    my $new_name          = shift || $old_name;

    if ( ref( $info->{$old_name} ) eq 'ARRAY' ) {
        my $compute_info = delete $info->{$old_name};
        $legacy_logger->debug(
            "translate_compute_info $elt_name input:\n",
            Data::Dumper->Dump( [$compute_info], [qw/compute_info/] )
        ) if $legacy_logger->is_debug;

        $self->show_legacy_issue( "$config_class_name->$elt_name: specifying compute info with ",
            "an array ref is deprecated" );

        my ( $user_formula, %var ) = @$compute_info;
        my $replace_h;
        map { $replace_h = delete $var{$_} if ref( $var{$_} ) } keys %var;

        # cleanup user formula
        $user_formula =~ s/\$(\w+){/\$replace{/g;

        # cleanup variable
        map { s/\$(\w+){/\$replace{/g } values %var;

        # change the hash *in* the info structure
        $info->{$new_name} = {
            formula   => $user_formula,
            variables => \%var,
        };
        $info->{$new_name}{replace} = $replace_h if defined $replace_h;

        $legacy_logger->debug(
            "translate_warp_info $elt_name output:\n",
            Data::Dumper->Dump( [ $info->{$new_name} ], [ 'new_' . $new_name ] )
        ) if $legacy_logger->is_debug;
    }
}

sub translate_id_class {
    my $self              = shift;
    my $config_class_name = shift || die;
    my $elt_name          = shift;
    my $info              = shift;


    $legacy_logger->debug(
        "translate_id_class $elt_name input:\n",
        Data::Dumper->Dump( [$info], [qw/info/] )
    ) if $legacy_logger->is_debug;

    my $class_overide_param = $info->{type}.'_class';
    my $class_overide = $info->{$class_overide_param};
    if ($class_overide) {
        $info->{class} = $class_overide;
        $self->show_legacy_issue(
            "$config_class_name->$elt_name: '$class_overide_param' is deprecated, ",
            "Use 'class' instead."
        );
    }

    $legacy_logger->debug(
        "translate_id_class $elt_name output:",
        Data::Dumper->Dump( [$info], [qw/new_info/])
    ) if $legacy_logger->is_debug;
}

# internal: translate default information for id element
sub translate_id_default_info {
    my $self              = shift;
    my $config_class_name = shift || die;
    my $elt_name          = shift;
    my $info              = shift;

    $legacy_logger->debug(
        "translate_id_default_info $elt_name input:\n",
        Data::Dumper->Dump( [$info], [qw/info/] )
    ) if $legacy_logger->is_debug;

    my $warn = "$config_class_name->$elt_name: 'default' parameter for list or "
        . "hash element is deprecated. ";

    my $def_info = delete $info->{default};
    if ( ref($def_info) eq 'HASH' ) {
        $info->{default_with_init} = $def_info;
        $self->show_legacy_issue( $warn, "Use default_with_init" );
    }
    elsif ( ref($def_info) eq 'ARRAY' ) {
        $info->{default_keys} = $def_info;
        $self->show_legacy_issue( $warn, "Use default_keys" );
    }
    else {
        $info->{default_keys} = [$def_info];
        $self->show_legacy_issue( $warn, "Use default_keys" );
    }

    $legacy_logger->debug( 
        "translate_id_default_info $elt_name output:",
        Data::Dumper->Dump( [$info], [qw/new_info/])
    ) if $legacy_logger->is_debug;
}

# internal: translate auto_create information for id element
sub translate_id_auto_create {
    my $self              = shift;
    my $config_class_name = shift || die;
    my $elt_name          = shift;
    my $info              = shift;

    $legacy_logger->debug(
        "translate_id_auto_create $elt_name input:",
        Data::Dumper->Dump( [$info], [qw/info/] )
    ) if $legacy_logger->is_debug;

    my $warn = "$config_class_name->$elt_name: 'auto_create' parameter for list or "
        . "hash element is deprecated. ";

    my $ac_info = delete $info->{auto_create};
    if ( $info->{type} eq 'hash' ) {
        $info->{auto_create_keys} =
            ref($ac_info) eq 'ARRAY' ? $ac_info : [$ac_info];
        $self->show_legacy_issue( $warn, "Use auto_create_keys" );
    }
    elsif ( $info->{type} eq 'list' ) {
        $info->{auto_create_ids} = $ac_info;
        $self->show_legacy_issue( $warn, "Use auto_create_ids" );
    }
    else {
        die "Unexpected element ($elt_name) type $info->{type} ", "for translate_id_auto_create";
    }

    $legacy_logger->debug(
        "translate_id_default_info $elt_name output:\n",
        Data::Dumper->Dump( [$info], [qw/new_info/] )
    ) if $legacy_logger->is_debug;
}

sub translate_id_min_max {
    my $self              = shift;
    my $config_class_name = shift || die;
    my $elt_name          = shift;
    my $info              = shift;

    foreach my $bad (qw/min max/) {
        next unless defined $info->{$bad};

        $legacy_logger->debug( "translate_id_min_max $elt_name $bad:")
            if $legacy_logger->is_debug;

        my $good = $bad . '_index';
        my $warn = "$config_class_name->$elt_name: '$bad' parameter for list or "
            . "hash element is deprecated. Use '$good'";

        $info->{$good} = delete $info->{$bad};
    }
}

# internal: translate warp information into 'boolean expr' => { ... }
sub translate_warp_info {
    my ( $self, $config_class_name, $elt_name, $type, $warp_info ) = @_;

    $legacy_logger->debug(
        "translate_warp_info $elt_name input:\n",
        Data::Dumper->Dump( [$warp_info], [qw/warp_info/] )
    ) if $legacy_logger->is_debug;

    my $follow = $self->translate_follow_arg( $config_class_name, $elt_name, $warp_info->{follow} );

    # now, follow is only { w1 => 'warp1', w2 => 'warp2'}
    my @warper_items = values %$follow;

    my $multi_follow = @warper_items > 1 ? 1 : 0;

    my $rules =
        $self->translate_rules_arg( $config_class_name, $elt_name, $type, \@warper_items,
        $warp_info->{rules} );

    $warp_info->{follow} = $follow;
    $warp_info->{rules}  = $rules;

    $legacy_logger->debug(
        "translate_warp_info $elt_name output:\n",
        Data::Dumper->Dump( [$warp_info], [qw/new_warp_info/] )
    ) if $legacy_logger->is_debug;
}

# internal
sub translate_multi_follow_legacy_rules {
    my ( $self, $config_class_name, $elt_name, $warper_items, $raw_rules ) = @_;
    my @rules;

    # we have more than one warper_items

    for ( my $r_idx = 0 ; $r_idx < $#$raw_rules ; $r_idx += 2 ) {
        my $key_set = $raw_rules->[$r_idx];
        my @keys = ref($key_set) ? @$key_set : ($key_set);

        # legacy: check the number of keys in the @rules set
        if ( @keys != @$warper_items and $key_set !~ /\$\w+/ ) {
            Config::Model::Exception::ModelDeclaration->throw( error => "Warp rule error in "
                    . "'$config_class_name->$elt_name'"
                    . ": Wrong nb of keys in set '@keys',"
                    . " Expected "
                    . scalar @$warper_items
                    . " keys" );
        }

        # legacy:
        # if a key of a rule (e.g. f1 or b1) is an array ref, all the
        # values passed in the array are considered as valid.
        # i.e. [ [ f1a, f1b] , b1 ] => { ... }
        # is equivalent to
        # [ f1a, b1 ] => { ... }, [  f1b , b1 ] => { ... }

        # now translate [ [ f1a, f1b] , b1 ] => { ... }
        # into "( $f1 eq f1a or $f1 eq f1b ) and $f2 eq b1)" => { ... }
        my @bool_expr;
        my $b_idx = 0;
        foreach my $key (@keys) {
            if ( ref $key ) {
                my @expr = map { "\$f$b_idx eq '$_'" } @$key;
                push @bool_expr, "(" . join( " or ", @expr ) . ")";
            }
            elsif ( $key !~ /\$\w+/ ) {
                push @bool_expr, "\$f$b_idx eq '$key'";
            }
            else {
                push @bool_expr, $key;
            }
            $b_idx++;
        }
        push @rules, join( ' and ', @bool_expr ), $raw_rules->[ $r_idx + 1 ];
    }
    return @rules;
}

sub translate_follow_arg {
    my $self              = shift;
    my $config_class_name = shift;
    my $elt_name          = shift;
    my $raw_follow        = shift;

    if ( ref($raw_follow) eq 'HASH' ) {

        # follow is { w1 => 'warp1', w2 => 'warp2'}
        return $raw_follow;
    }
    elsif ( ref($raw_follow) eq 'ARRAY' ) {

        # translate legacy follow arguments ['warp1','warp2',...]
        my $follow = {};
        my $idx    = 0;
        map { $follow->{ 'f' . $idx++ } = $_ } @$raw_follow;
        return $follow;
    }
    elsif ( defined $raw_follow ) {

        # follow is a simple string
        return { f1 => $raw_follow };
    }
    else {
        return {};
    }
}

sub translate_rules_arg {
    my ( $self, $config_class_name, $elt_name, $type, $warper_items, $raw_rules ) = @_;

    my $multi_follow = @$warper_items > 1 ? 1 : 0;
    my $follow = @$warper_items;

    # $rules is either:
    # { f1 => { ... } }  (  may be [ f1 => { ... } ] ?? )
    # [ 'boolean expr' => { ... } ]
    # legacy:
    # [ f1, b1 ] => {..} ,[ f1,b2 ] => {...}, [f2,b1] => {...} ...
    # foo => {...} , bar => {...}
    my @rules;
    if ( ref($raw_rules) eq 'HASH' ) {

        # transform the simple hash { foo => { ...} }
        # into array ref [ '$f1 eq foo' => { ... } ]
        my $h = $raw_rules;
        @rules = $follow ? map { ( "\$f1 eq '$_'", $h->{$_} ) } keys %$h : keys %$h;
    }
    elsif ( ref($raw_rules) eq 'ARRAY' ) {
        if ($multi_follow) {
            push @rules,
                $self->translate_multi_follow_legacy_rules( $config_class_name, $elt_name,
                $warper_items, $raw_rules );
        }
        else {
            # now translate [ f1a, f1b]  => { ... }
            # into "$f1 eq f1a or $f1 eq f1b " => { ... }
            my @raw_rules = @{$raw_rules};
            for ( my $r_idx = 0 ; $r_idx < $#raw_rules ; $r_idx += 2 ) {
                my $key_set   = $raw_rules[$r_idx];
                my @keys      = ref($key_set) ? @$key_set : ($key_set);
                my @bool_expr = $follow ? map { /\$/ ? $_ : "\$f1 eq '$_'" } @keys : @keys;
                push @rules, join( ' or ', @bool_expr ), $raw_rules[ $r_idx + 1 ];
            }
        }
    }
    elsif ( defined $raw_rules ) {
        Config::Model::Exception::ModelDeclaration->throw(
                  error => "Warp rule error in element "
                . "'$config_class_name->$elt_name': "
                . "rules must be a hash ref. Got '$raw_rules'" );
    }

    for ( my $idx = 1 ; $idx < @rules ; $idx += 2 ) {
        next unless ( ref $rules[$idx] eq 'HASH' );    # other cases are illegal and trapped later
        $self->handle_experience_permission( $config_class_name, $rules[$idx] );
        next unless defined $type and $type eq 'leaf';
        $self->translate_legacy_builtin( $config_class_name, $rules[$idx], $rules[$idx] );
    }

    return \@rules;
}

sub translate_legacy_builtin {
    my ( $self, $config_class_name, $model, $normalized_model ) = @_;

    my $raw_builtin_default = delete $normalized_model->{built_in};
    return unless defined $raw_builtin_default;

    $legacy_logger->debug( 
        Data::Dumper->Dump( [$normalized_model], ['builtin to translate'] )
    ) if $legacy_logger->is_debug;

    $self->show_legacy_issue( "$config_class_name: parameter 'built_in' is deprecated "
            . "in favor of 'upstream_default'" );

    $model->{upstream_default} = $raw_builtin_default;

    $legacy_logger->debug( Data::Dumper->Dump( [$model], ['translated_builtin'] )) 
        if $legacy_logger->is_debug;
}

sub translate_legacy_built_in_list {
    my ( $self, $config_class_name, $model, $normalized_model ) = @_;

    my $raw_builtin_default = delete $normalized_model->{built_in_list};
    return unless defined $raw_builtin_default;

    $legacy_logger->debug( 
        Data::Dumper->Dump( [$normalized_model], ['built_in_list to translate'] )
    ) if $legacy_logger->is_debug;

    $self->show_legacy_issue( "$config_class_name: parameter 'built_in_list' is deprecated "
            . "in favor of 'upstream_default_list'" );

    $model->{upstream_default_list} = $raw_builtin_default;

    $legacy_logger->debug( Data::Dumper->Dump( [$model], ['translated_built_in_list'] ))
        if $legacy_logger->is_debug;
}

sub include_class {
    my $self         = shift;
    my $class_name   = shift || croak "include_class: undef includer";
    my $target_model = shift || die "include_class: undefined target_model";

    my $include_class = delete $target_model->{include};

    return () unless defined $include_class;

    my $include_after = delete $target_model->{include_after};

    my @includes = ref $include_class ? @$include_class : ($include_class);

    # use reverse because included classes are *inserted* in front
    # of the list (or inserted after $include_after
    foreach my $inc ( reverse @includes ) {
        $self->include_one_class( $class_name, $target_model, $inc, $include_after );
    }
}

sub include_one_class {
    my $self          = shift;
    my $class_name    = shift || croak "include_class: undef includer";
    my $target_model  = shift || croak "include_class: undefined target_model";
    my $include_class = shift || croak "include_class: undef include_class param";
    my $include_after = shift;

    get_logger('Model')->info("class $class_name includes $include_class");

    if (    defined $include_class
        and defined $self->{included_class}{$class_name}{$include_class} ) {
        Config::Model::Exception::ModelDeclaration->throw(
            error => "Recursion error ? $include_class has "
                . "already been included by $class_name." );
    }
    $self->{included_class}{$class_name}{$include_class} = 1;

    # takes care of recursive include, because get_model will perform
    # includes (and normalization). Is already a dclone
    my $included_model = $self->get_model($include_class);

    # now include element in element_list (special treatment because order is
    # important)
    my $target_list   = $target_model->{element_list};
    my $included_list = $included_model->{element_list};
    my $splice_idx    = 0;
    if ( defined $include_after and defined $included_model->{element} ) {
        my $idx = 0;
        my %elt_idx = map { ( $_, $idx++ ); } @$target_list;

        if ( not defined $elt_idx{$include_after} ) {
            my $msg =
                  "Unknown element for 'include_after': "
                . "$include_after, expected "
                . join( ' ', sort keys %elt_idx );
            Config::Model::Exception::ModelDeclaration->throw( error => $msg );
        }

        # + 1 because we splice *after* $include_after
        $splice_idx = $elt_idx{$include_after} + 1;
    }

    splice( @$target_list, $splice_idx, 0, @$included_list );
    get_logger('Model')->debug("class $class_name new elt list: @$target_list");

    # now actually include all elements
    my $target_element = $target_model->{element} ||= {};
    foreach my $included_elt (@$included_list) {
        if ( not defined $target_element->{$included_elt} ) {
            get_logger('Model')->debug("class $class_name includes elt $included_elt");
            $target_element->{$included_elt} = $included_model->{element}{$included_elt};
        }
        else {
            Config::Model::Exception::ModelDeclaration->throw(
                error => "Cannot clobber element '$included_elt' in $class_name"
                    . " (included from $include_class)" );
        }
    }
    get_logger('Model')->info("class $class_name include $include_class done");
}

# load a model from file. See comments around raw_models attribute for explanations
sub load {
    my $self       = shift;
    my $model_name = shift;    # model name like Foo::Bar
    my $load_file  = shift;    # model file (override model name), used for tests

    my $load_path = $model_name;
    $load_path =~ s/::/\//g;

    $load_file ||= $self->model_dir . '/' . $load_path . '.pl';

    get_logger("Model::Loader")->debug("model $model_name from file $load_file");

    # no special treatment, returns an array
    my %models_by_name;
    my @loaded_classes = $self->_load_model_in_hash( \%models_by_name, $load_file );
    $self->store_raw_model( $model_name, dclone( \%models_by_name ) );
    foreach my $name ( keys %models_by_name ) {
        my $data = $self->normalize_class_parameters( $name, $models_by_name{$name} );
        get_logger("Model::Loader")->debug("Store normalized model $name");
        $self->store_normalized_model( $name, $data );
    }

    # look for additional model information
    my %model_graft_by_name;
    my %done;  # avoid loading twice the same snippet (where system version may clobber dev version)
    foreach my $inc (@INC) {
        foreach my $name ( keys %models_by_name ) {
            my $snippet_path = $name;
            $snippet_path =~ s/::/\//g;
            my $snippet_dir = "$inc/" . $self->model_dir . '/' . $snippet_path . '.d';
            get_logger("Model::Loader")->trace("looking for snippet in $snippet_dir");
            if ( -d $snippet_dir ) {
                foreach my $snippet_file ( glob("$snippet_dir/*.pl") ) {
                    my $done_key = $name . ':' . $snippet_file;
                    next if $done{$done_key};
                    get_logger("Model::Loader")->info("Found snippet $snippet_file");
                    $self->_load_model_in_hash( \%model_graft_by_name, $snippet_file );
                    $done{$done_key} = 1;
                }
            }
        }
    }

    foreach my $class_to_merge ( keys %model_graft_by_name ) {
        my $data = $model_graft_by_name{$class_to_merge};
        $self->augment_config_class_really( $class_to_merge, $data );
    }

    # return the list of classes found in $load_file. Respecting the order of the class
    # declaration is important for Config::Model::Itself so the class are written back
    # in the same order.
    return @loaded_classes;
}

# New subroutine "_load_model_in_hash" extracted - Fri Apr 12 17:29:56 2013.
#
sub _load_model_in_hash {
    my ( $self, $hash_ref, $load_file ) = @_;

    my $model = $self->_do_model_file($load_file);

    my @names;
    foreach my $config_class_info (@$model) {
        my %data =
              ref $config_class_info eq 'HASH'  ? %$config_class_info
            : ref $config_class_info eq 'ARRAY' ? @$config_class_info
            :   croak "load $load_file: config_class_info is not a ref";
        my $config_class_name = $data{name}
            or croak "load: missing config class name in $load_file";

        # check config class parameters and fill %model
        $hash_ref->{$config_class_name} = \%data;
        push @names, $config_class_name;
    }

    return @names;
}

#
# New subroutine "_do_model_file" extracted - Sun Nov 28 17:25:35 2010.
#
sub _do_model_file {
    my ( $self, $load_file ) = @_;

    get_logger("Model::Loader")->info("load model $load_file");

    my $err_msg = '';
    my $model   = do $load_file;

    unless ($model) {
        if    ($@)                   { $err_msg = "couldn't parse $load_file: $@"; }
        elsif ( not defined $model ) { $err_msg = "couldn't do $load_file: $!" }
        else                         { $err_msg = "couldn't run $load_file"; }
    }
    elsif ( ref($model) ne 'ARRAY' ) {
        $model = [$model];
    }

    Config::Model::Exception::ModelDeclaration->throw( message => "load error: $err_msg" )
        if $err_msg;

    return $model;
}

sub augment_config_class {
    my ( $self, %augment_data ) = @_;

    # %args must contain existing class name to augment

    # plus other data to merge to raw model
    my $config_class_name = delete $augment_data{name}
        || croak "augment_config_class: missing class name";

    $self->augment_config_class_really( $config_class_name, \%augment_data );
}

sub augment_config_class_really {
    my ( $self, $config_class_name, $augment_data ) = @_;

    my $orig_model = $self->normalized_model($config_class_name);
    croak "unknown class to augment: $config_class_name" unless defined $orig_model;

    my $model_addendum = $self->normalize_class_parameters( $config_class_name, $augment_data );

    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');
    my $new_model = $merge->merge( $orig_model, $model_addendum );

    # remove duplicates in element_list and accept_list while keeping order
    foreach my $list_name (qw/element_list accept_list/) {
        my %seen;
        my @newlist;
        foreach my $elt ( @{ $new_model->{$list_name} } ) {
            push @newlist, $elt unless $seen{$elt};
            $seen{$elt} = 1;
        }

        $new_model->{$list_name} = \@newlist;
    }

    $self->store_normalized_model( $config_class_name => $new_model );
}

sub get_model {
    my $self              = shift;
    my $config_class_name = shift
        || die "Model::get_model: missing config class name argument";

    $self->load($config_class_name)
        unless $self->normalized_model_exists($config_class_name);

    if ( not $self->model_defined($config_class_name) ) {
        get_logger("Model::Loader")->debug("creating model $config_class_name");

        my $model = $self->merge_included_class($config_class_name);
        $self->_store_model( $config_class_name, $model );
    }

    my $model = $self->model($config_class_name)
        || croak "get_model error: unknown config class name: $config_class_name";

    return dclone($model);
}

# internal
sub get_model_doc {
    my ( $self, $top_class_name, $done ) = @_;

    $done //= {};
    if ( not defined $self->normalized_model($top_class_name) ) {
        croak "get_model_doc error : unknown config class name: $top_class_name";
    }

    my @classes = ($top_class_name);
    my %result;

    while (@classes) {
        my $class_name = shift @classes;
        next if $done->{$class_name} ;

        my $c_model = $self->get_model($class_name)
            || croak "get_model_doc model error : unknown config class name: $class_name";

        my $full_name = "Config::Model::models::$class_name";

        my %see_also;

        my @pod = (

            # Pod::Weaver compatibility
            "# PODNAME: $full_name",
            "# ABSTRACT:  Configuration class " . $class_name,

            # assume utf8 for all docs
            "=encoding utf8", '',

            # plain old pod compatibility
            "=head1 NAME",                                     '',
            "$full_name - Configuration class " . $class_name, '',

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
            $summary &&= " - $summary";
            push @elt, "=head2 $elt_name$summary", '';
            push @elt, $self->get_element_description($elt_info), '';

            foreach ( $elt_info, $elt_info->{cargo} ) {
                if ( my $ccn = $_->{config_class_name} ) {
                    push @classes, $ccn;
                    $see_also{$ccn} = 1;
                }
                if ( my $migr = $_->{migrate_from} ) {
                    push @elt, $self->get_migrate_doc( $elt_name, 'is migrated with', $migr );
                }
                if ( my $migr = $_->{migrate_values_from} ) {
                    push @elt, "Note: $elt_name values are migrated from '$migr'", '';
                }
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
                ( map { ( "=item $_", '' ); } map { ref $_ ? @$_ : $_ } @{ $legalese{$what} } ),
                '', '=back', '';
        }

        my @see_also = (
            "=head1 SEE ALSO",
            '',
            "=over",
            '',
            "=item *",
            '',
            "L<cme>",
            '',
            ( map { ( "=item *", '', "L<Config::Model::models::$_>", '' ); } sort keys %see_also ),
            "=back",
            ''
        );

        $result{$full_name} = join( "\n", @pod, @elt, @see_also, @end, '=cut', '' ) . "\n";
        $done->{$class_name} = 1;
    }
    return \%result;
}

#
# New subroutine "get_migrate_doc" extracted - Tue Jun  5 13:31:20 2012.
#
sub get_migrate_doc {
    my ( $self, $elt_name, $desc, $migr ) = @_;

    my $mv    = $migr->{variables};
    my $mform = $migr->{formula};

    if ( $migr->{use_eval} ) { $mform =~ s/^/ /mg; $mform = "\n\n$mform\n\n"; }
    else                     { $mform = "'C<$mform>' " }

    my $mdoc = "Note: $elt_name $desc ${mform}and with "
        . join( ", ", map { qq!\$$_ => "C<$mv->{$_}>"! } sort keys %$mv );
    if ( my $rep = $migr->{replace} ) {
        $mdoc .=
            ' and ' . join( ", ", map { qq!'C<\$replace{$_}>' => "C<$rep->{$_}>"! } sort keys %$rep );
    }

    return ( $mdoc, '' );
}

sub get_element_description {
    my ( $self, $elt_info ) = @_;

    my $type  = $elt_info->{type};
    my $cargo = $elt_info->{cargo};
    my $vt    = $elt_info->{value_type};

    my $of         = '';
    my $cargo_type = $cargo->{type};
    my $cargo_vt   = $cargo->{value_type};
    $of = " of " . ( $cargo_vt or $cargo_type ) if defined $cargo_type;

    my $ccn = $elt_info->{config_class_name} || $cargo->{config_class_name};
    $of .= " of class L<$ccn|Config::Model::models::$ccn> " if $ccn;

    my $desc = $elt_info->{description} || '';
    if ($desc) {
        $desc .= '.' if $desc =~ /\w$/;
        $desc .= ' ' unless $desc =~ /\s$/;
    }

    if ( my $status = $elt_info->{status} ) {
        $desc .= 'B<' . ucfirst($status) . '> ';
    }

    my $info = $elt_info->{mandatory} ? 'Mandatory. ' : 'Optional. ';

    $info .= "Type " . ( $vt || $type ) . $of . '. ';

    foreach (qw/choice default upstream_default/) {
        my $item = $elt_info->{$_};
        next unless defined $item;
        my @list = ref($item) ? @$item : ($item);
        $info .= "$_: '" . join( "', '", @list ) . "'. ";
    }

    my $elt_help = $self->get_element_value_help($elt_info);

    return $desc . "I<< $info >> " . $elt_help;
}

sub get_element_value_help {
    my ( $self, $elt_info ) = @_;

    my $help = $elt_info->{help};
    return '' unless defined $help;

    my $help_text = "\n\nHere are some explanations on the possible values:\n\n=over\n\n";
    foreach my $v ( sort keys %$help ) {
        $help_text .= "=item '$v'\n\n$help->{$v}\n\n";
    }

    return $help_text . "=back\n\n";
}

sub generate_doc {
    my ( $self, $top_class_name, $dir, $done ) = @_;

    $done //= {} ;
    my $res = $self->get_model_doc($top_class_name, $done);

    if ( defined $dir and $dir ) {
        foreach my $class_name ( sort keys %$res ) {
            my $file = $class_name;
            $file =~ s!::!/!g;
            my $pl_file  = $dir . "/$file.pl";
            my $pod_file = $dir . "/$file.pod";
            my $pod_dir  = $pod_file;
            $pod_dir =~ s!/[^/]+$!!;
            make_path( $pod_dir, { mode => 0755 } ) unless -d $pod_dir;

            # -M returns age of file, not date or epoch. hence greater is older
            my $old = '';
            if ( -e $pod_file ) {
                my $fh = IO::File->new( $pod_file, 'r' ) || die "Can't open $pod_file: $!";
                $old = join( '', $fh->getlines );
                $fh->close;
            }
            if ( $old ne $res->{$class_name} ) {
                my $fh = IO::File->new( $pod_file, 'w' ) || die "Can't open $pod_file: $!";
                $fh->binmode(":utf8");
                $fh->print( $res->{$class_name} );
                $fh->close;
                print "Wrote documentation in $pod_file\n";
            }
        }
    }
    else {
        foreach my $class_name ( sort keys %$res ) {
            print "########## $class_name ############ \n\n";
            print $res->{$class_name};
        }
    }
}

sub get_element_model {
    my $self              = shift;
    my $config_class_name = shift
        || die "Model::get_element_model: missing config class name argument";
    my $element_name = shift
        || die "Model::get_element_model: missing element name argument";

    my $model = $self->get_model($config_class_name);

    my $element_m = $model->{element}{$element_name}
        || croak "get_element_model error: unknown element name: $element_name";

    return dclone($element_m);
}

# returns a hash ref containing the raw model, i.e. before expansion of
# multiple keys (i.e. [qw/a b c/] => ... )
# internal. For now ...
sub get_normalized_model {
    my $self              = shift;
    my $config_class_name = shift;

    $self->load($config_class_name)
        unless defined $self->normalized_model($config_class_name);

    my $normalized_model = $self->normalized_model($config_class_name)
        || croak "get_normalized_model error: unknown config class name: $config_class_name";

    return dclone($normalized_model);
}

sub get_element_name {
    my $self = shift;
    my %args = @_;

    my $class = $args{class}
        || croak "get_element_name: missing 'class' parameter";

    if (delete $args{for}) {
        carp "get_element_name: 'for' parameter is deprecated";
    }

    my $model = $self->get_model($class);
    my @result;

    # this is a bit convoluted, but the order of the returned element
    # must respect the order of the elements declared in the model by
    # the user
    foreach my $elt ( @{ $model->{element_list} } ) {
        my $elt_data = $model->{element}{$elt};
        my $l = $elt_data->{level} || $default_property{level};
        push @result, $elt if $l ne 'hidden' ;
    }

    return wantarray ? @result : join( ' ', @result );
}

sub get_element_property {
    my $self = shift;
    my %args = @_;

    my $elt = $args{element}
        || croak "get_element_property: missing 'element' parameter";
    my $prop = $args{property}
        || croak "get_element_property: missing 'property' parameter";
    my $class = $args{class}
        || croak "get_element_property:: missing 'class' parameter";

    my $model = $self->model($class);

    # must take into account 'accept' model parameter
    if ( not defined $model->{element}{$elt} ) {
        $logger->debug("test accept for class $class elt $elt prop $prop");
        foreach my $acc_re ( @{ $model->{accept_list} } ) {
            return $model->{accept}{$acc_re}{$prop} || $default_property{$prop}
                if $elt =~ /^$acc_re$/;
        }
    }

    return $self->model($class)->{element}{$elt}{$prop}
        || $default_property{$prop};
}

sub list_class_element {
    my $self = shift;
    my $pad = shift || '';

    my $res = '';
    foreach my $class_name ( $self->normalized_model_names ) {
        $res .= $self->list_one_class_element($class_name);
    }
    return $res;
}

sub list_one_class_element {
    my $self       = shift;
    my $class_name = shift;
    my $pad        = shift || '';

    my $res     = $pad . "Class: $class_name\n";
    my $c_model = $self->normalized_model($class_name);
    my $elts    = $c_model->{element_list};               # array ref

    return $res unless defined $elts and @$elts;

    foreach my $elt_name (@$elts) {
        my $type = $c_model->{element}{$elt_name}{type};
        $res .= $pad . "  - $elt_name ($type)\n";
    }
    return $res;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT:  Create tools to validate, migrate and edit configuration files

__END__

=pod

=head1 SYNOPSIS

=head2 Perl program to use an existing model

 use Config::Model qw(cme);
 # load, modify and save popcon configuration file
 cme('popcon')->modify("PARTICIPATE=yes");

=head2 Command line to use an existing model

 # with App::Cme
 cme modify popcon 'PARTICIPATE=yes'

=head2 Perl program with a custom model

 use Config::Model;

 # create new Model object
 my $model = Config::Model->new() ; # Config::Model object

 # create config model. Most users will want to store the model in a
 # file in lib/Config/Model/models and run cme as explained below
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

=head2 Create a new model file and use it

 $ mkdir -p lib/Config/Model/models/
 $ echo "[ { name => 'MiniModel', \
             element => [ [qw/foo bar baz/ ] => { type => 'leaf', value_type => 'uniline' }, ], \
             read_config => { backend => 'IniFile', auto_create => 1, \
                              config_dir => '.', file => 'mini.ini', \
                            } \
           } \
         ] ; " > lib/Config/Model/models/MiniModel.pl
 # require App::Cme
 $ cme modify -try MiniModel -dev bar=BARV foo=FOOV baz=BAZV
 $ cat mini.ini

Note that model creation is easier running C<cme meta edit> with
L<App::Cme> and L<Config::Model::Itself>.

=head1 DESCRIPTION

Config::Model enables a project developer to provide an interactive
configuration editor (graphical, curses based or plain terminal) to
users.

To provide these tools, Config::Model needs:

=over

=item *

A description of the structure and constraints of the project's configuration
(fear not, a GUI is available with L<App::Cme>)

=item *

A module to read and write configuration data. This can be one of the
read/write backends provided by Config::Model or a custom backend.

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
user interface (with C<cme meta edit> once L<Config::Model::Itself> is
installed)

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

L<Config::Model::Manual::ModelCreationIntroduction>

=item *

L<Config::Model::Cookbook::CreateModelFromDoc>

=back

=head2 Advanced

=over

=item *

L<Config::Model::models::Itself::Class>: This doc and its siblings
describes all parameters available to create a model. These are the
parameters available in the GUI launched by C<cme meta edit> command.

=item *

L<Config::Model::Manual::ModelCreationAdvanced>

=back

=head2 Masters

use the source, Luke

=head1 STOP

The documentation below is quite detailed and is more a reference doc regarding
C<Config::Model> class.

For an introduction to model creation, please check:
L<Config::Model::Manual::ModelCreationIntroduction>

Dedicated Config::Model::Manual pages will follow soon.

=head1 Storage backend, configuration reader and writer

See L<Config::Model::BackendMgr> for details

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
See also
L<Directed acyclic graph on Wikipedia|http://en.wikipedia.org/wiki/Directed_acyclic_graph">More on DAGs>

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

A configuration instance is created from a model and is the starting
point of a configuration tree.

=head2 instance(...)

An instance must be created with a model name (using the root class
name) or an application name (as shown by "L<cme> C<list>" command).

For example:

 my $model = Config::Model->new() ;
 $model->instance( application => 'approx');

Or:

 my $model = Config::Model->new() ;
 # note that the model class is slightly different compared to
 # application name
 $model->instance( root_class_name => 'Approx');

A custom configuration class can also be used with C<root_class_name> parameter:

 my $model = Config::Model->new() ;
 # create_config_class is described below
 $model ->create_config_class (
   name => "SomeRootClass",
   element => [ ...  ]
 ) ;

 # instance name is 'default'
 my $inst = $model->instance (root_class_name => 'SomeRootClass');

You can create several separated instances from a model using
C<name> option:

 # instance name is 'default'
 my $inst = $model->instance (
   root_class_name => 'SomeRootClass',
   name            => 'test1'
 );

Usually, model files will be loaded automatically depending on
C<root_class_name>. But you can choose to specify the file containing
the model with C<model_file> parameter. This is mostly useful for
tests.

=head2 cme(...)

This method is syntactic sugar for short program. It creates a new
C<Config::Model> object and returns a new instance. See L</instance(...)>
for the parameters.

=head1 Configuration class

A configuration class is made of series of elements which are detailed
in L<Config::Model::Node>.

Whatever its type (node, leaf,... ), each element of a node has
several other properties:

=over

=item level

Level is C<important>, C<normal> or C<hidden>.

The level is used to set how configuration data is presented to the
user in browsing mode. C<Important> elements will be shown to the user
no matter what. C<hidden> elements will be explained with the I<warp>
notion.

=item status

Status is C<obsolete>, C<deprecated> or C<standard> (default).

Using a deprecated element will issue a warning. Using an obsolete
element will raise an exception.

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

=item generated_by

Mention with a descriptive string if this class was generated by a
program.  This parameter is currently reserved for
L<Config::Model::Itself> model editor.

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

Note that include may not clobber an existing element.

=item include_backend

Include read/write specification from another class.

  include_backend => 'AnotherClass' ,

or

  include_backend => [qw/ClassOne ClassTwo/]

=back

Note that include may not clobber an existing read/write specification.

=head2 create_config_class

This method creates configuration classes. The parameters are
described above and are forwarded to L<Config::Model::Node>
constructor. See
L<Config::Model::Node/"Configuration class declaration">
for more details on configuration class parameters.

Example:

  my $model = Config::Model -> new ;

  $model->create_config_class
  (
   config_class_name => 'SomeRootClass',
   description       => [ X => 'X-ray' ],
   level             => [ 'tree_macro' => 'important' ] ,
   class_description => "SomeRootClass description",
   element           => [ ... ]
  ) ;

For convenience, C<level> and C<description> parameters
can also be declared within the element declaration:

  $model->create_config_class
  (
   config_class_name => 'SomeRootClass',
   class_description => "SomeRootClass description",
   'element'
   => [
        tree_macro => { level => 'important'},
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

=head2 augment_config_class (name => '...', class_data )

Enhance the feature of a configuration class. This method uses the same parameters
as L<create_config_class>. See
L<Config::Model::Manual::ModelCreationAdvanced/"Model Plugin">
for more details on creating model plugins.

=head1 Model query

=head2 get_model( config_class_name )

Return a hash containing the model declaration (in a deep clone copy of the hash).
You may modify the hash at leisure.

=head2 generate_doc ( top_class_name , directory , [ \%done ] )

Generate POD document for configuration class top_class_name and all
classes used by top_class_name, and write them in specified directory.

C<\%done> is an optional reference to a hash used to avoid writing
twice the same documentation when this method is called several times.

=head2 get_element_model( config_class_name , element)

Return a hash containing the model declaration for the specified class
and element.

=head2 get_element_name( class => Foo )

Get all names of the elements of class C<Foo>.

=head2 get_element_property

Returns the property of an element from the model.

Parameters are:

=over

=item class

=item element

=item property

=back

=head2 list_class_element

Returns a string listing all the class and elements. Useful for
debugging your configuration model.

=head1 Error handling

Errors are handled with an exception mechanism.

When a strongly typed Value object gets an authorized value, it raises
an exception. If this exception is not caught, the programs exits.

See L<Config::Model::Exception|Config::Model::Exception> for details on
the various exception classes provided with C<Config::Model>.

=head1 Logging

See L<cme/Logging>

=head1 BUGS

Given Murphy's law, the author is fairly confident that you will find
bugs or miss some features. Please report them to
https://github.com/dod38fr/config-model/issues
The author will be notified, and then you'll automatically be
notified of progress on your bug.

=head1 FEEDBACK

Feedback from users are highly desired. If you find this module useful, please
share your use cases, success stories with the author or with the config-model-
users mailing list.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 LICENSE

    Copyright (c) 2005-2012 Dominique Dumont.

    This file is part of Config-Model.

    Config-Model is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation; either version 2.1 of
    the License, or (at your option) any later version.

    Config-Model is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with Config-Model; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
    02110-1301 USA

=head1 SEE ALSO

L<Config::Model::Instance>,

L<https://github.com/dod38fr/config-model/wiki>

L<https://github.com/dod38fr/config-model/wiki/Creating-models>

=head2 Model elements

The arrow shows the inheritance of the classes

=over

=item *

L<Config::Model::Node> <- L<Config::Model::AnyThing>

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

L<cme>.

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

L<Config::Model::BackendMgr>: Used by C<Config::Model::Node> object

=item *

L<Config::Model::Describe>

=item *

L<Config::Model::Dumper>

=item *

L<Config::Model::DumpAsData>

=item *

L<Config::Model::IdElementReference>

=item *

L<Config::Model::Iterator>

=item *

L<Config::Model::Loader>

=item *

L<Config::Model::ObjTreeScanner>

=item *

L<Config::Model::Report>

=item *

L<Config::Model::Searcher>: Search element in configuration model.

=item *

L<Config::Model::SimpleUI>

=item *

L<Config::Model::TreeSearcher>: Search string or regexp in configuration tree.

=item *

L<Config::Model::TermUI>

=item *

L<Config::Model::Iterator>

=item *

L<Config::Model::ValueComputer>

=item *

L<Config::Model::Warper>

=back

=head2 Test framework

=over

=item *

L<Config::Model::Tester>

=back

=cut
