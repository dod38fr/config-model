#!/usr/bin/perl

use strict;
use warnings;

# This script uses all the information available in LCDd.conf to create a model
# for LCDd configuration file

# How does this work ?

# The convention used in LCDd.conf template file are written in a way which
# makes it relatively easy to parse to get all required information to build a model.
# All drivers are listed, most parameters have default values and legal values
# written in comments in a uniform way. Hence this file (and comments) can be parsed
# to retrieve information required for the model.

# This script performs 3 tasks:
# 1/ parse LCDd.conf template
# 2/ mine the information there and translate them in a format suitable to create
#    a model. Comments are used to provide default and legal values and also to provide
#    user documentation
# 3/ Write the resulting LCDd model

use Config::Model;
use Config::Model::Itself ;    # to create the model
use Config::Model::Backend::IniFile;

use 5.010;
use IO::File;
use IO::String;
use Getopt::Long;

# initialise logs for Config;:Model
use Log::Log4perl qw(:easy);
my $log4perl_user_conf_file = $ENV{HOME} . '/.log4config-model';
Log::Log4perl::init($log4perl_user_conf_file);

my $verbose = 0;
my $show_model = 0;
my $result = GetOptions ("verbose"  => \$verbose,
    "model" => \$show_model);

die "Unknown option. Expected -verbose or -show_model" unless $result ;

# Dump stack trace in case of error
Config::Model::Exception::Any->Trace(1) ;

# one model to rule them all
my $model = Config::Model->new();

###########################
#
# Step 1: parse LCDd.conf (INI file)

# Problem: comments must also be retrieved and associated with INI
# class and parameters

# Fortunately, Config::Model::Backend::IniFile can already perform this
# task. But Config::Model::Backend::IniFile must store its values in a
# configuration tree.

# So let's create a model suitable for LCDd.conf that accepts any
# INI class and any INI parameter

# The class is used to store any parameter found in an INI class
$model->create_config_class(
    name   => 'Dummy::Class',
    accept => [ '.*' => {qw/type leaf value_type uniline/}, ],
);

# Store any INI class, and use Dummy::Class to hold parameters. 

# Note that a INI backend could be created here. But, some useful
# parameters are commented out in LCD.conf. Some some processing is
# required to be able to create a model with these commented parameters.
# See below for this processing.

$model->create_config_class(
    name   => 'Dummy',
    accept => [ '.*' => {qw/type node config_class_name Dummy::Class/}, ],
);

# Now the dummy configuration class is created. Let's create a 
# configuration tree to store the data from LCDd.conf

my $dummy = $model->instance(
    instance_name   => 'dummy',
    root_class_name => 'Dummy',
)-> config_root;

# read LCDd.conf
my $lcd_file = IO::File->new('examples/lcdproc/LCDd.conf');
my @lines    = $lcd_file->getlines;

# Here's the LCDd.conf pre-processing mentioned above

# un-comment commented parameters
foreach (@lines) { s/^#(\w+=)/$1/ }

# store the munged LCDd.conf in a IO::Handle usable by INI backend
my $ioh = IO::String->new( join( '', @lines ) );

# Create the INI backend
my $ini_backend = Config::Model::Backend::IniFile->new( node => $dummy );

# feed the munged LCDd.conf content into INI backend
$ini_backend->read( io_handle => $ioh );

##############################################
#
# Step 2: Mine the LCDd.conf information and create a model
#

# Create a meta tree that will contain LCDd model
my $meta_root = $model->instance(
    root_class_name => 'Itself::Model',
    instance_name   => 'meta_model',
) -> config_root;

# Create LCDd configuration class and store the first comment from LCDd.conf as
# class description
$meta_root->grab("class:LCDd class_description")->store( $dummy->annotation );

# append my own text
my $extra_description =
    "Model information extracted from template /etc/LCDd.conf"
  . "\n\n=head1 BUGS\n\nThis model does not support to load several drivers. Loading "
  . "several drivers is probably a marginal case. Please complain to the author if this "
  . "assumption is false";
$meta_root->load(qq!class:LCDd class_description.="\n\n$extra_description"!);

# add legal stuff
$meta_root->load( qq!
    class:LCDd 
        copyright:0="2011, Dominique Dumont" 
        copyright:1="1999-2011, William Ferrell and others" 
        license="GPL-2"
!
);

# add INI backend (So LCDd model will be able to read INI files)
$meta_root->load( qq!
    class:LCDd 
        read_config:0 
            backend=ini_file 
            config_dir="/etc" 
            file="LCDd.conf"
!
);

# Note: all the load calls above could be done as one call. But I choose
#       to split them for better clarity


# This array contains all INI classes found in LCDd.conf
my @ini_classes = $dummy->get_element_name;

# Now before actually mining LCDd.conf information, we must prepare
# subs to handle them. This is done using a dispatch table.
my %dispatch;

# first create the default case which will be used for most parameters
# This subs is passed: the INI class name, the INI parameter name
# the comment attached to the parameter, the INI value, and an optional
# value type  
$dispatch{_default_} = sub {
    my ( $ini_class, $ini_param, $info_r, $ini_v, $value_type ) = @_;

    # prepare a string to create the ini_class model
    my $load = qq!class:"$ini_class" element:$ini_param type=leaf !;
    $value_type ||= 'uniline';

    # get semantic information from comment (written between square brackets)
    my $square_model = '';
    
    my $square_rexp = '\[(\s*\w+\s*:[^\]]*)\]';
    while ($$info_r =~ /$square_rexp/ ) {
        my $info = $1 ;
        say "class $ini_class element $ini_param info: '$info'" if $verbose;
        $$info_r =~ s/$square_rexp//;
        $square_model .= ' '. info_to_model($info,$value_type) ;
    }
    
    unless ($square_model) {
        # or use the value found in INI file as default
        $ini_v =~ s/^"//g;
        $ini_v =~ s/"$//g;
        $square_model .= qq! value_type=$value_type default="$ini_v"! if length($ini_v);
    }

    # get model information from comment (written between curly brackets)
    my $curly_model = '';
    my $curly_rexp = '{(\s*\w+.*)}' ;
    while ($$info_r =~ /$curly_rexp/) { 
        my $model_snippet = $1 ;
        say "class $ini_class element $ini_param model snippet: '$model_snippet'"
            if $verbose;
        $$info_r =~ s/$curly_rexp//;
        $load .= ' '. $model_snippet ;
    }
    
    # return a string containing model specifications
    return $load.$square_model;
};

# Now let's take care of the special cases. This one deals with "Driver"
# parameter found in INI [server] class
$dispatch{"LCDd::server"}{Driver} = sub {
    my ( $class, $elt, $info_r, $ini_v ) = @_;
    my $load = qq!class:"$class" element:$elt type=leaf value_type=enum !;
    my @drivers = split /\W+/, $$info_r;
    while ( @drivers and ( shift @drivers ) !~ /supported/ ) { }
    $load .= 'choice=' . join( ',', @drivers ) . ' ';

    #say $load; exit;
    return $load;
};

# like default but ensure that parameter is integer
$dispatch{"LCDd::server"}{WaitTime} = $dispatch{"LCDd::server"}{ReportLevel} =
 $dispatch{"LCDd::picolcd"}{LircFlushThreshold} = $dispatch{"LCDd::server"}{Port}   = sub {
    my ( $class, $elt, $info_r, $ini_v ) = @_;
    return $dispatch{_default_}->( @_, 'integer' );
  };

# ensure that default values are "Hello LCDproc" (or "GoodBye LCDproc")
$dispatch{"LCDd::server"}{GoodBye} = $dispatch{"LCDd::server"}{Hello} = sub {
    my ( $class, $elt, $info_r, $ini_v ) = @_;
    my $ret = qq( class:"$class" element:$elt type=list ) ;
    $ret .= 'cargo type=leaf value_type=uniline - ' ;  
    $ret .= 'default_with_init:0="\"    '.$elt.'\"" ' ; 
    $ret .= 'default_with_init:1="\"    LCDproc!\""'; 
    return $ret ;
};

# Now really mine LCDd.conf information

# loop over all INI classes
foreach my $ini_class (@ini_classes) {
    say "Handling INI class $ini_class" if $verbose;
    my $ini_obj = $dummy->grab($ini_class);
    my $config_class   = "LCDd::$ini_class";

    # create config class in case there's no parameter in INI file
    $meta_root->load(qq!class:"LCDd::$ini_class"!);

    # loop over all INI parameters and create LCDd::$ini_class elements
    foreach my $ini_param ( $ini_obj->get_element_name ) {
        # retrieve INI value
        my $ini_v    = $ini_obj->grab_value($ini_param);

        # retrieve INI comment attached to $ini_param
        my $ini_comment = $ini_obj->grab($ini_param)->annotation;

        # retrieve the correct sub from the dispatch table
        my $sub = $dispatch{$config_class}{$ini_param} || $dispatch{_default_};
        
        # runs the sub to get the model string
        my $model_spec = $sub->( $config_class, $ini_param, \$ini_comment, $ini_v );

        # show the model without the doc (too verbose)
        say "load -> $model_spec" if $show_model ;

        # escape embedded quotes
        $ini_comment =~ s/"/\\"/g;
        $ini_comment =~ s/\n*$//;
        $model_spec .= qq! description="$ini_comment"! if length($ini_comment);

        # load class specification in model
        $meta_root->load($model_spec);
    }

    # Now create a an $ini_class element in LCDd class (to link LCDd
    # class and LCDd::$ini_class)
    my $driver_class_spec = qq!
        class:LCDd 
            element:$ini_class 
    ! ;

    if ( $ini_class eq 'server' or $ini_class eq 'menu' ) {
        $driver_class_spec .= qq! 
            type=node 
            config_class_name="LCDd::$ini_class" 
        ! ;
    }
    else {
        # Arrange a driver class is shown only if the driver was selected
        # in the [server] class
        $driver_class_spec .= qq! 
            type=warped_node 
            config_class_name="LCDd::$ini_class"
            level=hidden
            follow:selected="- server Driver"
            rules:"\$selected eq '$ini_class'" 
                level=normal
        !;
    }
    $meta_root->load($driver_class_spec);
}

######################
#
# Step3: write the model 


# Itself constructor returns an object to read or write the data
# structure containing the model to be edited. force_write is required
# because writer object, being created *after* loading the model in the
# instance, is not aware of these changes.
my $rw_obj = Config::Model::Itself->new( 
    model_object => $meta_root,
    model_dir => 'lib/Config/Model/models/',
    force_write => 1,
);

say "Writing all models in file (please wait)";
$rw_obj->write_all;

say "Done";

# this function extracts info specified between square brackets and returns a model snippet
sub info_to_model {
    my ($info,$value_type) = @_ ;

    $info =~ s/\s+//g;
    my @model ;

    # legal needs to be parsed first to setup value_type first
    my %info = map { split /[:=]/,$_ ,2 ; } split /;/,$info ; 

    # use this semantic information to better specify the parameter
    my $legal = delete $info{legal} || '';
    given ($legal) {
        when (/^(\d+)-(\d+)$/) { push @model, "value_type=integer min=$1 max=$2"}
        when (/^([\w\,]+)$/)   { push @model, "value_type=enum choice=$1"}
        default                { push @model, "value_type=$value_type"}
    }

    foreach my $k (keys %info) {
        my $v = $info{$k} ;
        die "Undefined value. Something is wrong in info '$info'" unless defined $v ;
        $v = '"'.$v.'"' unless $v=~/^"/ ;

        given ($k) {
            when (/default/ ) {
                # specify upstream default value if it was found in the comment
                push @model ,qq!upstream_default=$v! if length($v);
            }
            when (/assert/ ) {
                push @model ,qq!warn_unless:0 code=$v -!;
            }
            default {
                push @model, "$k=$v" ;
            }
        }
    }

    return join(' ',@model) ;
}

