#!/usr/bin/perl

use strict;
use warnings;

# This script uses all the information available in LCDd.conf to create a model
# for LCDd configuration file

# How does this work ?
# The convention used in LCDd.conf template file are written in a way which
# makes it relatively easy to parse to get all required information to build a model.
# All drivers are listed, most parameters have the default values and legal values
# written in comments in a uniform way. Hence this file (and comments) can be parsed
# to retrieve information required for the model.

# this script performs 3 tasks:
# 1/ parse LCDd.conf template
# 2/ mine the information there and translate these in a format suitable to create
#    a model. Comments are used to provide default and legal values and also to provide
#    user documentation
# 3/ Write the resulting LCDd model

use Config::Model;
use Config::Model::Itself;    # to create the model
use Config::Model::Backend::IniFile;

use 5.10.0;
use IO::File;
use IO::String;

# initialise logs for Config;:Model
use Log::Log4perl qw(:easy);
my $log4perl_user_conf_file = $ENV{HOME} . '/.log4config-model';
Log::Log4perl::init($log4perl_user_conf_file);

# one model to rule them all
my $model = Config::Model->new();

###########################
#
# Step 1: parse LCDd.conf (INI file)

# Problem: comments must also be retrieved and associated with INI
# class and parameters

# Fortunately, Config::Model::Backend::IniFile can already to this.
# But Config::Model::Backend::IniFile must store its values in a
# configuration tree.

# So let's create a model suitable for LCDd.conf that accepts any
# INI class and any INI value

# The class used to store any parameter
$model->create_config_class(
    name   => 'Dummy::Class',
    accept => [ '.*' => {qw/type leaf value_type uniline/}, ],
);

# Store any INI class, and use Dummy::Class to hold parameters Note that
# a INI backend could be created here. But, some useful parameters are
# commented out in LCD.conf so some some processing is required to be
# able to create a model with these commented parameters. See below

$model->create_config_class(
    name   => 'Dummy',
    accept => [ '.*' => {qw/type node config_class_name Dummy::Class/}, ],
);

my $dummy_inst = $model->instance(
    instance_name   => 'dummy',
    root_class_name => 'Dummy',
);

my $dummy = $dummy_inst->config_root;

$dummy->init;

# read LCDd.conf
my $lcd_file = IO::File->new('examples/lcdproc/LCDd.conf');
my @lines    = $lcd_file->getlines;

# un-comment commented parameters
foreach (@lines) { s/^#(\w+=)/$1/ }

# store the munged LCDd.conf in a IO::Handle
my $ioh = IO::String->new( join( '', @lines ) );

# Create the INI backend
my $ini_backend = Config::Model::Backend::IniFile->new( node => $dummy );

# read the munged LCDd.conf content
$ini_backend->read( io_handle => $ioh );

##############################################
#
# Step 2: Mine the LCDd.conf information and create a model
#

# Create a meta_model that will contain LCDd model
my $meta_inst = $model->instance(
    root_class_name => 'Itself::Model',
    instance_name   => 'meta_model',
);

my $meta_root = $meta_inst->config_root;

# Create some documentation for end user
my $extra_description =
    "Model information extracted from template /etc/LCDd.conf"
  . "\n\n=head1 BUGS\n\nThis model does not support to load several drivers. Loading "
  . "several drivers is probably a marginal case. Please complain to the author if this "
  . "assumption is false";

# Create LCDd configuration class and store the first comment from LCDd.conf as
# class description
$meta_root->grab("class:LCDd class_description")->store( $dummy->annotation );

# append my own text
$meta_root->load(qq!class:LCDd class_description.="\n\n$extra_description"!);

# add legal stuff and backend (So LCDd model will be able to read INI files)
$meta_root->load( qq!
    class:LCDd 
    copyright:0="2011, Dominique Dumont" 
    copyright:1="1999-2011, William Ferrell and others" 
    license="GPL-2"
    element:server -
    element:menu -
    read_config:0 
       backend=ini_file 
       config_dir="/etc" 
       file="LCDd.conf"
!
);

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
    my ( $ini_class, $ini_param, $ini_note, $ini_v, $value_type ) = @_;

    # prepare a string to create the ini_class model
    my $load = qq!class:"$ini_class" element:$ini_param type=leaf !;
    $value_type ||= 'uniline';

    # get semantic information from comment (written between square barckets)
    my $info = $ini_note =~ /\[(.*)\]/ ? $1 : ''; 
    $info =~ s/\s+//g;
    # use this semantic information to better specify the parameter
    $load .=
        $info =~ /legal:(\d+)-(\d+)/ ? " value_type=integer min=$1 max=$2"
      : $info =~ /legal:([\w\,]+)/   ? " value_type=enum choice=$1"
      :                                " value_type=$value_type";

    if ( $info =~ /default:(\w+)/ ) {
        # specify upstream default value if it was found in the comment
        $load .= qq! upstream_default="$1"! if length($1);
    }
    else {
        # or use the value found in INI file as default
        $ini_v =~ s/^"//g;
        $ini_v =~ s/"$//g;
        $load .= qq! default="$ini_v"! if length($ini_v);
    }
    
    # return a string containing model specifications
    return $load;
};

# Now let's take care of the special cases. This one deals with "Driver"
# parameter found in INI [server] class
$dispatch{"LCDd::server"}{Driver} = sub {
    my ( $class, $elt, $info, $ini_v ) = @_;
    my $load = qq!class:"$class" element:$elt type=leaf value_type=enum !;
    my @drivers = split /\W+/, $info;
    while ( @drivers and ( shift @drivers ) !~ /supported/ ) { }
    $load .= 'choice=' . join( ',', @drivers ) . ' ';

    #say $load; exit;
    return $load;
};

# like default but ensure that DriverPath ends with '/'
$dispatch{"LCDd::server"}{DriverPath} = sub {
    my ( $class, $elt, $info, $ini_v ) = @_;
    return $dispatch{_default_}->(@_) . q! match="/$" !;
};

# like default but ensure that parameter is integer
$dispatch{"LCDd::server"}{WaitTime} = $dispatch{"LCDd::server"}{ReportLevel} =
  $dispatch{"LCDd::server"}{Port}   = sub {
    my ( $class, $elt, $info, $ini_v ) = @_;
    return $dispatch{_default_}->( @_, 'integer' );
  };

# ensure that default values are "Hello LCDproc" (or "GoodBye LCDproc")
$dispatch{"LCDd::server"}{GoodBye} = $dispatch{"LCDd::server"}{Hello} = sub {
    my ( $class, $elt, $info, $ini_v ) = @_;
    return qq(
    class:"$class" 
        element:$elt 
        type=list 
        cargo 
            type=leaf 
            value_type=uniline - 
        default_with_init:0="    $elt" 
        default_with_init:1="    LCDproc!" 
    );
};

# Now really mine LCDd.conf information

# loop over all INI classes
foreach my $ini_class (@ini_classes) {
    say "Handling INI class $ini_class";
    my $ini_obj = $dummy->grab($ini_class);
    my $config_class   = "LCDd::$ini_class";

    # create config class in case there's no parameter in INI file
    $meta_root->load(qq!class:"LCDd::$ini_class"!);

    # loop over all INI parameters
    foreach my $ini_param ( $ini_obj->get_element_name ) {
        # retrieve INI value
        my $ini_v    = $ini_obj->grab_value($ini_param);

        # retrieve INI comment attached to $ini_param
        my $ini_comment = $ini_obj->grab($ini_param)->annotation;
        # embedded quotes causes trouble, replace them with single quotes.
        $ini_comment =~ s/"/'/g;

        # remove unnecessary quotes
        $ini_v    =~ s/^"//g;
        $ini_v    =~ s/"$//g;

        # retrieve the correct sub from the dispatch table
        my $sub = $dispatch{$config_class}{$ini_param} || $dispatch{_default_};
        
        # runs the sub to get the model string
        my $model_spec = $sub->( $config_class, $ini_param, $ini_comment, $ini_v );

        $model_spec .= qq! description="$ini_comment"! if length($ini_comment);

        # load class specification in model
        $meta_root->load($model_spec);
    }

    if ( $ini_class ne 'server' and $ini_class ne 'menu' ) {
        # Arrange a driver class is shown only if the driver was selected
        # in the [server] class
        my $driver_class_spec = qq!
            class:LCDd 
                element:$ini_class 
                type=warped_node 
                config_class_name="LCDd::$ini_class"
                level=hidden
                follow:selected="- server Driver"
                rules:"\$selected eq '$ini_class'" 
                    level=normal
            !;
        $meta_root->load($driver_class_spec);
    }
}

say "Creating LCDs root elements (server and menu)";

# create the root LCDd class
$meta_root->load(
    qq!
    class:LCDd  
        element:server  
            type=node 
            config_class_name="LCDd::server" -
        element:menu
            type=node
            config_class_name="LCDd::menu" -
    !
);

######################
#
# Step3: write the model 


# Itself constructor returns an object to read or write the data
# structure containing the model to be edited
my $rw_obj = Config::Model::Itself->new( model_object => $meta_root );
say "Writing all models in file (please wait)";
$rw_obj->write_all( model_dir => 'lib/Config/Model/models/' );

say "Done";
